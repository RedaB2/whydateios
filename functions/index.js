const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

exports.sendNotificationOnNewMessage = onDocumentCreated(
    "conversations/{conversationId}/messages/{messageId}",
    async (event) => {
      const newMessage = event.data.data(); 
      const recipientUID = newMessage.recipientUID;

      try {
        const userDoc = await db.collection("users").doc(recipientUID).get();
        const userData = userDoc.data();
        const fcmToken = userData && userData.fcmToken;

        if (!fcmToken) {
          console.log("No FCM token for user");
          return;
        }

        const message = {
          token: fcmToken,
          notification: {
            title: "Your match just texted you!",
            body: newMessage.messageText,
          },
          data: {
            conversationId: event.params.conversationId,
            senderId: newMessage.senderUID,
          },
        };

        await messaging.send(message);
        console.log("Notification sent successfully");
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    },
);
