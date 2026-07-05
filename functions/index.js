// Arena Cloud Function.
//
// Whenever a new message is written to a room, push a notification to everyone
// who turned on notifications for that room (they are subscribed to the room's
// Firebase Cloud Messaging "topic"). This is what makes room notifications
// arrive even when the app is closed.
//
// Deploy with:  firebase deploy --only functions
// (Requires the Firebase project to be on the Blaze plan.)

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Must match RoomNotifyService.topicFor() in the Flutter app.
function topicFor(roomId) {
  return "room_" + roomId.replace(/[^a-zA-Z0-9-_.~%]/g, "_");
}

// Must match RoomNotifyService.userTopicFor() in the Flutter app.
function userTopicFor(uid) {
  return "user_" + uid.replace(/[^a-zA-Z0-9-_.~%]/g, "_");
}

// Must match RoomNotifyService.participantsTopicFor() in the Flutter app.
function participantsTopicFor(roomId) {
  return "room_participants_" + roomId.replace(/[^a-zA-Z0-9-_.~%]/g, "_");
}

// "Trending" tuning: a burst of THRESHOLD messages within WINDOW_MS marks a room
// as on fire; at most one trending push per room every COOLDOWN_MS.
const TREND_WINDOW_MS = 30 * 60 * 1000; // 30 minutes
const TREND_THRESHOLD = 20; // messages within the window
const TREND_COOLDOWN_MS = 3 * 60 * 60 * 1000; // 3 hours

const TREND_LINES = [
  "🔥 is on fire — new arguments are flying. Jump back in!",
  "⚔️ is heating up! People are waiting for your comeback.",
  "🔥 Your debate is trending — don't let them win. Reply now!",
  "💬 is buzzing right now. Share your side before it cools off!",
];

exports.notifyRoomOnNewMessage = onDocumentCreated(
  "rooms/{roomId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data() || {};
    const roomId = event.params.roomId;

    // Look up the room's name to use as the notification title.
    let roomName = "A debate";
    try {
      const roomDoc = await getFirestore().collection("rooms").doc(roomId).get();
      if (roomDoc.exists && roomDoc.data().name) {
        roomName = roomDoc.data().name;
      }
    } catch (e) {
      // Non-fatal — fall back to the default title.
    }

    const sender = msg.senderName || "Someone";
    const text = msg.text || "";
    // Keep the body short so it fits a notification.
    const body = (sender + ": " + text).slice(0, 180);

    try {
      await getMessaging().send({
        topic: topicFor(roomId),
        notification: { title: roomName, body: body },
        data: { roomId: roomId, type: "room_message" },
        android: {
          priority: "high",
          notification: { channelId: "room_messages" },
        },
      });
    } catch (e) {
      console.error("Failed to send room notification:", e);
    }

    // If this message is a reply, also notify the author of the quoted message
    // directly (via their personal user topic) — even if they don't follow the
    // room. Skip when someone replies to their own message.
    const replyToSenderId = msg.replyToSenderId;
    if (replyToSenderId && replyToSenderId !== msg.senderId) {
      try {
        await getMessaging().send({
          topic: userTopicFor(replyToSenderId),
          notification: {
            title: sender + " replied to you",
            body: text.slice(0, 180),
          },
          data: { roomId: roomId, type: "reply" },
          android: {
            priority: "high",
            notification: { channelId: "replies" },
          },
        });
      } catch (e) {
        console.error("Failed to send reply notification:", e);
      }
    }

    // ---- Trending re-engagement -----------------------------------------
    // Track the room's message pace. If it bursts past the threshold within the
    // window (and we haven't pushed recently), nudge everyone who took part.
    try {
      const db = getFirestore();
      const roomRef = db.collection("rooms").doc(roomId);
      const now = Date.now();
      const fire = await db.runTransaction(async (tx) => {
        const doc = await tx.get(roomRef);
        const d = doc.exists ? doc.data() : {};
        let windowStart = d.trendWindowStart || 0;
        let count = d.trendCount || 0;
        const lastPush = d.lastTrendingPushAt || 0;

        if (now - windowStart > TREND_WINDOW_MS) {
          windowStart = now; // window expired — start a new one
          count = 1;
        } else {
          count += 1;
        }

        let shouldFire = false;
        const update = { trendWindowStart: windowStart, trendCount: count };
        if (count >= TREND_THRESHOLD && now - lastPush > TREND_COOLDOWN_MS) {
          shouldFire = true;
          update.lastTrendingPushAt = now;
          update.trendCount = 0; // reset so it doesn't re-fire immediately
        }
        tx.set(roomRef, update, { merge: true });
        return shouldFire;
      });

      if (fire) {
        const line = TREND_LINES[Math.floor(Math.random() * TREND_LINES.length)];
        await getMessaging().send({
          topic: participantsTopicFor(roomId),
          notification: { title: roomName, body: '"' + roomName + '" ' + line },
          data: { roomId: roomId, type: "trending" },
          android: {
            priority: "high",
            notification: { channelId: "trending" },
          },
        });
      }
    } catch (e) {
      console.error("Failed trending check:", e);
    }
  }
);
