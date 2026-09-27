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
  try {
    if (!fcmToken) {
      console.log("❌ No FCM token provided");
      return { success: false, error: "No FCM token" };
    }

    console.log("📤 Sending FCM to:", fcmToken.substring(0, 20) + "...");
    console.log("   Title:", title);

    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: convertDataToStrings(data),
      android: {
        priority: "high",
        notification: {
          channelId: "garagemate_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(message);

    console.log("✅ FCM sent successfully:", response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("❌ FCM send error:", error);
    console.error("   Code:", error.code);
    console.error("   Message:", error.message);
    return {
      success: false,
      error: error.message,
      code: error.code,
    };
  }
};

// =====================================================
// HELPER: Convert data values to strings
// (FCM requires all data values to be strings)
// =====================================================

const convertDataToStrings = (data) => {
  if (!data || typeof data !== "object") {
    return {};
  }

  const result = {};

  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      result[key] = "";
    } else if (typeof value === "object") {
      result[key] = JSON.stringify(value);
    } else {
      result[key] = String(value);
    }
  }

  return result;
};

module.exports = {
  sendPushNotification,
  convertDataToStrings,
};