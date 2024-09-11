const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Function to send notifications when a new message is sent
exports.sendNotificationOnNewMessage = functions.firestore
    .document("conversations/{conversationId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const newMessage = snap.data();
      const recipientUID = newMessage.recipientUID;

      try {
      // Fetch the recipient's FCM token from Firestore
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(recipientUID)
            .get();
        const fcmToken = userDoc.data().fcmToken;

        const payload = {
          notification: {
            title: "New Message",
            body: `${newMessage.messageText}`,
            sound: "default",
          },
        };

        if (fcmToken) {
          await admin.messaging().sendToDevice(fcmToken, payload);
          console.log("Notification sent successfully");
        } else {
          console.log("No FCM token for user");
        }
      } catch (error) {
        console.log("Error sending notification:", error);
      }
    });
