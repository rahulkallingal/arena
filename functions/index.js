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
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("crypto");

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

// Everyone who runs the app subscribes to this one topic (see
// RoomNotifyService.allUsersTopic). An admin broadcast is pushed here so it
// reaches every user at once. MUST match the Flutter app.
const ALL_USERS_TOPIC = "all_users";

// Shared secret that guards the broadcast endpoint so only you can trigger it.
// Stored in Google Secret Manager (NOT in this public repo). Set it once with:
//   firebase functions:secrets:set BROADCAST_SECRET
// and send the same value as the "x-arena-key" header from Postman.
const broadcastSecret = defineSecret("BROADCAST_SECRET");

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

// ---- Admin broadcast (call from Postman) --------------------------------
// POST a sentence (the debate topic). This creates a fresh public room for it
// and pushes ONE notification to every user (the "all_users" topic). Tapping
// the notification opens that new room in the app.
//
// Usage from Postman:
//   POST https://<region>-<project>.cloudfunctions.net/broadcastTopic
//   Header:  x-arena-key: <BROADCAST_SECRET above>
//   Body (either works):
//     • raw JSON:  { "topic": "Should AI replace teachers?" }
//     • raw text:  Should AI replace teachers?
//   Optional JSON field: "category": "Technology"
exports.broadcastTopic = onRequest(
  { region: "asia-south1", secrets: [broadcastSecret] },
  async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Use POST" });
  }

  // Only you, holding the shared secret, may fire a broadcast. If the secret was
  // never set, reject everything (never fall open).
  const expected = broadcastSecret.value();
  const key = req.get("x-arena-key") || req.query.key;
  if (!expected || key !== expected) {
    return res.status(401).json({ error: "Unauthorized — wrong or missing key" });
  }

  // Accept the topic as raw text, or as JSON { topic: "..." }.
  let topic = "";
  let category = "Other";
  if (typeof req.body === "string") {
    topic = req.body;
  } else if (req.body && typeof req.body === "object") {
    topic = req.body.topic || "";
    if (req.body.category) category = String(req.body.category);
  }
  topic = String(topic || "").trim();
  if (!topic) {
    return res.status(400).json({ error: "Provide a topic sentence" });
  }

  try {
    const db = getFirestore();

    // Create the room this broadcast points at. Shape matches Room.toCreateMap()
    // in the Flutter app so it renders like any other room.
    const roomRef = await db.collection("rooms").add({
      name: topic.slice(0, 80),
      topic: topic,
      category: category,
      isPrivate: false,
      passwordHash: null,
      createdBy: "admin",
      createdByName: "Arena",
      isDaily: false,
      isBroadcast: true,
      createdAt: FieldValue.serverTimestamp(),
      lastActivity: FieldValue.serverTimestamp(),
    });
    const roomId = roomRef.id;

    // One push to everyone. data.roomId + type let the app open the room on tap.
    await getMessaging().send({
      topic: ALL_USERS_TOPIC,
      notification: { title: "🔥 New debate is live!", body: topic.slice(0, 180) },
      data: { roomId: roomId, type: "broadcast" },
      android: {
        priority: "high",
        notification: { channelId: "broadcast" },
      },
    });

    return res.status(200).json({ ok: true, roomId, topic });
  } catch (e) {
    console.error("broadcastTopic failed:", e);
    return res.status(500).json({ error: e.message || String(e) });
  }
});

// ---- Verify a private room's password (server-side) ---------------------
// The room password is checked here instead of on the phone, so a tampered
// client can't bypass it and the hash is never exposed to clients. New private
// rooms store a salted hash in the unreadable rooms/{id}/secure/auth subdoc;
// older rooms fall back to the legacy (unsalted) passwordHash on the room doc.
exports.verifyRoomPassword = onCall({ region: "asia-south1" }, async (req) => {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const roomId = String((req.data && req.data.roomId) || "").trim();
  const password = String((req.data && req.data.password) || "");
  if (!roomId) {
    throw new HttpsError("invalid-argument", "Missing roomId.");
  }

  const db = getFirestore();
  const roomRef = db.collection("rooms").doc(roomId);
  const roomSnap = await roomRef.get();
  if (!roomSnap.exists) {
    throw new HttpsError("not-found", "Room not found.");
  }
  const room = roomSnap.data() || {};
  if (!room.isPrivate) return { ok: true }; // public room — no password needed

  let storedHash = null;
  let salt = "";
  const secure = await roomRef.collection("secure").doc("auth").get();
  if (secure.exists) {
    storedHash = secure.data().hash;
    salt = secure.data().salt || "";
  } else if (room.passwordHash) {
    storedHash = room.passwordHash; // legacy room — unsalted
  }
  if (!storedHash) return { ok: false };

  const attempt = crypto
    .createHash("sha256")
    .update(salt + password.trim())
    .digest("hex");
  return { ok: attempt === storedHash };
});

// ---- Clean up stale, empty rooms ----------------------------------------
// Runs daily. Deletes rooms whose last activity is older than the cutoff AND
// that have no messages — so abandoned daily/broadcast rooms don't pile up.
// Conservative: any room with even one message is kept.
const STALE_ROOM_DAYS = 7;

exports.cleanupStaleRooms = onSchedule(
  { schedule: "every 24 hours", region: "asia-south1" },
  async () => {
    const db = getFirestore();
    const cutoff = new Date(Date.now() - STALE_ROOM_DAYS * 24 * 60 * 60 * 1000);
    const stale = await db
      .collection("rooms")
      .where("lastActivity", "<", cutoff)
      .get();

    let deleted = 0;
    for (const doc of stale.docs) {
      const msgs = await doc.ref.collection("messages").limit(1).get();
      if (!msgs.empty) continue; // keep any room that has messages
      // Remove the protected password subdoc too, if present.
      const secure = await doc.ref.collection("secure").doc("auth").get();
      if (secure.exists) await secure.ref.delete();
      await doc.ref.delete();
      deleted++;
    }
    console.log(`cleanupStaleRooms: deleted ${deleted} empty stale room(s)`);
  }
);

// ---- SAFETY: clear every room (call from Postman) -----------------------
// Recursively deletes ALL rooms and their messages/votes/subdocs — the same
// wipe as a manual cleanup, but on demand. User accounts and config are NOT
// touched. Guarded by BOTH the shared secret AND an explicit confirmation
// string, so it can never fire by accident.
//
// Usage from Postman:
//   POST https://asia-south1-arena-a049d.cloudfunctions.net/clearAllRooms
//   Header:  x-arena-key: <BROADCAST_SECRET>
//   Body (raw JSON):  { "confirm": "DELETE ALL ROOMS" }
exports.clearAllRooms = onRequest(
  { region: "asia-south1", secrets: [broadcastSecret] },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Use POST" });
    }
    const expected = broadcastSecret.value();
    const key = req.get("x-arena-key") || req.query.key;
    if (!expected || key !== expected) {
      return res.status(401).json({ error: "Unauthorized — wrong or missing key" });
    }
    const confirm =
      (req.body && typeof req.body === "object" && req.body.confirm) ||
      req.query.confirm;
    if (confirm !== "DELETE ALL ROOMS") {
      return res.status(400).json({
        error: 'Send {"confirm":"DELETE ALL ROOMS"} to proceed.',
      });
    }
    try {
      const db = getFirestore();
      await db.recursiveDelete(db.collection("rooms"));
      return res.status(200).json({ ok: true, cleared: "rooms" });
    } catch (e) {
      console.error("clearAllRooms failed:", e);
      return res.status(500).json({ error: e.message || String(e) });
    }
  }
);
