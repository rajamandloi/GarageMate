const User = require("../models/User");
const {
  sendPushNotification,
} = require("../services/firebaseNotificationService");

// ============================================================
// SEND TEST NOTIFICATION TO LOGGED-IN USER
// POST /api/notifications/test
// ============================================================

const sendTestNotification = async (req, res) => {
  try {
    const {
      title = "Test Notification",
      body = "This is a test notification",
    } = req.body;

    const user = await User.findById(req.user._id).select(
      "fcmToken name email role garageId"
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!user.fcmToken) {
      return res.status(400).json({
        success: false,
        message: "User has no FCM token. Please login from app first.",
        user: {
          name: user.name,
          email: user.email,
          role: user.role,
        },
      });
    }

    console.log(
      "📤 Sending test FCM to:",
      user.fcmToken.substring(0, 20) + "..."
    );

    const result = await sendPushNotification({
      fcmToken: user.fcmToken,
      title,
      body,
      data: {
        type: "test",
        screen: "dashboard",
      },
    });

    return res.status(200).json({
      success: true,
      message: "Test notification sent",
      user: {
        name: user.name,
        email: user.email,
        role: user.role,
        fcmTokenPreview:
          user.fcmToken.substring(0, 20) + "...",
      },
      result,
    });
  } catch (error) {
    console.error(
      "Send test notification error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// DEBUG — GET CURRENT USER'S FCM TOKEN INFO
// GET /api/notifications/debug/fcm
// ============================================================

const debugFcmInfo = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select(
      "name email role phone fcmToken garageId"
    );

    return res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        garageId: user.garageId,
        hasFcmToken: !!user.fcmToken,
        fcmTokenLength: user.fcmToken
          ? user.fcmToken.length
          : 0,
        fcmTokenPreview: user.fcmToken
          ? user.fcmToken.substring(0, 30) + "..."
          : "NO TOKEN",
      },
    });
  } catch (error) {
    console.error("Debug FCM error:", error.message);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// SEND TO SPECIFIC FCM TOKEN (Admin test)
// POST /api/notifications/test-token
// ============================================================

const sendToSpecificToken = async (req, res) => {
  try {
    const { fcmToken, title, body } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: "fcmToken is required",
      });
    }

    const result = await sendPushNotification({
      fcmToken,
      title: title || "Test",
      body: body || "Test notification",
      data: {
        type: "test",
        screen: "dashboard",
      },
    });

    return res.status(200).json({
      success: true,
      result,
    });
  } catch (error) {
    console.error(
      "Send to token error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  sendTestNotification,
  debugFcmInfo,
  sendToSpecificToken,
};