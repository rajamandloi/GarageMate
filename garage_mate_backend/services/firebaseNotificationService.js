const {
  messaging,
} = require("../config/firebaseAdmin");


// =====================================================
// SEND PUSH NOTIFICATION
// =====================================================

const sendPushNotification = async ({
  fcmToken,
  title,
  body,
  data = {},
}) => {
  if (!fcmToken) {
    console.log(
      "FCM notification skipped: token not available"
    );

    return null;
  }

  try {

    const message = {
      token: fcmToken,

      notification: {
        title,
        body,
      },

      data: Object.fromEntries(
        Object.entries(data).map(
          ([key, value]) => [
            key,
            String(value),
          ]
        )
      ),

      android: {
        priority: "high",

        notification: {
          channelId:
            "garagemate_notifications",
        },
      },
    };


    // =================================================
    // SEND
    // =================================================

    const response =
      await messaging.send(
        message
      );


    console.log(
      "FCM notification sent:",
      response
    );

    return response;

  } catch (error) {

    console.error(
      "FCM notification error:",
      error
    );

    return null;
  }
};


module.exports = {
  sendPushNotification,
};