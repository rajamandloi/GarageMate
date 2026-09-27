const Notification = require("../models/Notification");
const User = require("../models/User");
const Garage = require("../models/Garage");

const {
  sendPushNotification,
} = require("./firebaseNotificationService");

// =====================================================
// CREATE SUPER ADMIN NOTIFICATION (EXISTING)
// =====================================================

const createSuperAdminNotification = async ({
  type,
  title,
  message,
  garageId = null,
}) => {
  try {
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
      const notification = await Notification.create({
        recipient: admin._id,
        type,
        title,
        message,
        garageId,
        isRead: false,
      });

      notifications.push(notification);

      if (admin.fcmToken) {
        await sendPushNotification({
          fcmToken: admin.fcmToken,
          title,
          body: message,
          data: {
            type,
            notificationId: notification._id.toString(),
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
    return [];
  }
};

// =====================================================
// ✅ NEW: SEND TO GARAGE OWNER
// =====================================================

const sendToGarageOwner = async ({
  garageId,
  type,
  title,
  message,
  data = {},
}) => {
  try {
    if (!garageId) {
      console.log("Garage ID is required");
      return [];
    }

    // Find all active users of this garage
    const users = await User.find({
      garageId,
      isActive: true,
      role: "garage_owner",
    }).select("_id fcmToken");

    if (!users.length) {
      console.log(
        `No active users for garage ${garageId}`
      );
      return [];
    }

    const notifications = [];

    for (const user of users) {
      // Save to DB
      const notification = await Notification.create({
        recipient: user._id,
        type,
        title,
        message,
        garageId,
        isRead: false,
      });

      notifications.push(notification);

      // Send push
      if (user.fcmToken) {
        await sendPushNotification({
          fcmToken: user.fcmToken,
          title,
          body: message,
          data: {
            type,
            notificationId: notification._id.toString(),
            garageId: garageId.toString(),
            ...data,
          },
        });
      }
    }

    console.log(
      `✅ Notification sent to ${users.length} user(s) of garage ${garageId}`
    );

    return notifications;
  } catch (error) {
    console.error(
      "Send to garage owner error:",
      error
    );
    return [];
  }
};

// =====================================================
// ✅ NEW: NOTIFY SERVICE COMPLETE
// =====================================================

const notifyServiceComplete = async ({
  garageId,
  customerName,
  vehicleNumber,
  totalAmount,
  invoiceNumber = null,
}) => {
  const title = "✅ Service Complete";

  const message = invoiceNumber
    ? `${customerName} • ${vehicleNumber} • ₹${totalAmount} • ${invoiceNumber}`
    : `${customerName} • ${vehicleNumber} • ₹${totalAmount}`;

  return await sendToGarageOwner({
    garageId,
    type: "service_complete",
    title,
    message,
    data: {
      screen: "services",
      customerName,
      vehicleNumber,
      totalAmount: totalAmount.toString(),
      ...(invoiceNumber && { invoiceNumber }),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY PAYMENT RECEIVED
// =====================================================

const notifyPaymentReceived = async ({
  garageId,
  customerName,
  amount,
}) => {
  return await sendToGarageOwner({
    garageId,
    type: "payment_received",
    title: "💰 Payment Received",
    message: `₹${amount} received from ${customerName}`,
    data: {
      screen: "services",
      customerName,
      amount: amount.toString(),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY PAYMENT PENDING
// =====================================================

const notifyPaymentPending = async ({
  garageId,
  customerName,
  amount,
  daysPending,
}) => {
  return await sendToGarageOwner({
    garageId,
    type: "payment_pending",
    title: "💸 Payment Pending",
    message: `${customerName} • ₹${amount} pending (${daysPending} days)`,
    data: {
      screen: "services",
      customerName,
      amount: amount.toString(),
      daysPending: daysPending.toString(),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY DAILY SUMMARY
// =====================================================

const notifyDailySummary = async ({
  garageId,
  servicesDueToday = 0,
  paymentsPending = 0,
  remindersDueToday = 0,
}) => {
  const total =
    servicesDueToday + paymentsPending + remindersDueToday;

  if (total === 0) {
    return [];
  }

  const title = "🔔 Today's Tasks";
  const message = `${total} task${total === 1 ? "" : "s"} pending today. Tap to view.`;

  return await sendToGarageOwner({
    garageId,
    type: "daily_summary",
    title,
    message,
    data: {
      screen: "dashboard",
      servicesDueToday: servicesDueToday.toString(),
      paymentsPending: paymentsPending.toString(),
      remindersDueToday: remindersDueToday.toString(),
      total: total.toString(),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY WHATSAPP LIMIT WARNING
// =====================================================

const notifyWhatsAppLimit = async ({
  garageId,
  used,
  limit,
  remaining,
}) => {
  let title;
  let message;

  if (remaining <= 0) {
    title = "⚠️ WhatsApp Limit Reached";
    message = `You have used all ${limit} messages this month. Upgrade to send more.`;
  } else if (remaining <= limit * 0.2) {
    title = "⚠️ WhatsApp Messages Low";
    message = `Only ${remaining} messages left (${used}/${limit}). Upgrade soon.`;
  } else {
    return [];
  }

  return await sendToGarageOwner({
    garageId,
    type: "whatsapp_limit",
    title,
    message,
    data: {
      screen: "subscription",
      used: used.toString(),
      limit: limit.toString(),
      remaining: remaining.toString(),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY TRIAL EXPIRY
// =====================================================

const notifyTrialExpiry = async ({
  garageId,
  daysLeft,
}) => {
  return await sendToGarageOwner({
    garageId,
    type: "trial_expiry",
    title: "⏰ Trial Ending Soon",
    message: `Your Pro trial ends in ${daysLeft} day${daysLeft === 1 ? "" : "s"}. Upgrade now!`,
    data: {
      screen: "subscription",
      daysLeft: daysLeft.toString(),
    },
  });
};

// =====================================================
// ✅ NEW: NOTIFY SUBSCRIPTION EXPIRY
// =====================================================

const notifySubscriptionExpiry = async ({
  garageId,
  daysLeft,
  plan,
}) => {
  return await sendToGarageOwner({
    garageId,
    type: "subscription_expiry",
    title: "📅 Subscription Expiring",
    message: `Your ${plan} plan expires in ${daysLeft} day${daysLeft === 1 ? "" : "s"}.`,
    data: {
      screen: "subscription",
      daysLeft: daysLeft.toString(),
      plan,
    },
  });
};

// =====================================================
// EXPORT
// =====================================================

module.exports = {
  createSuperAdminNotification,

  // New
  sendToGarageOwner,
  notifyServiceComplete,
  notifyPaymentReceived,
  notifyPaymentPending,
  notifyDailySummary,
  notifyWhatsAppLimit,
  notifyTrialExpiry,
  notifySubscriptionExpiry,
};