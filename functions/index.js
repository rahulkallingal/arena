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
  }
);
