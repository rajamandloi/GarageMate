const Notification = require("../models/Notification");
const User = require("../models/User");

const {
  sendPushNotification,
} = require("./firebaseNotificationService");

// =====================================================
// CREATE SUPER ADMIN NOTIFICATION
// =====================================================

const createSuperAdminNotification = async ({
  type,
  title,
  message,
  garageId = null,
}) => {
  try {
    // Find all active Super Admins
    const superAdmins = await User.find({
      role: "super_admin",
      isActive: true,
    }).select("_id fcmToken");

    if (!superAdmins.length) {
      console.log(
        "No active Super Admin found for notification"
      );

      return [];
    }

    const notifications = [];

    for (const admin of superAdmins) {
      // ===============================================
      // SAVE NOTIFICATION TO DATABASE
      // ===============================================

      const notification =
        await Notification.create({
          recipient: admin._id,
          type,
          title,
          message,
          garageId,
          isRead: false,
        });

      notifications.push(notification);

      // ===============================================
      // SEND PUSH NOTIFICATION
      // ===============================================

      if (admin.fcmToken) {
        await sendPushNotification({
          fcmToken: admin.fcmToken,

          title,

          body: message,

          data: {
            type,
            notificationId:
              notification._id.toString(),

            ...(garageId && {
              garageId: garageId.toString(),
            }),
          },
        });
      }
    }

    console.log(
      `Super Admin notification created for ${superAdmins.length} admin(s)`
    );

    return notifications;
  } catch (error) {
    console.error(
      "Create Super Admin notification error:",
      error
    );

    // Notification failure should NOT break
    // the main registration/business operation.
    return [];
  }
};

module.exports = {
  createSuperAdminNotification,
};