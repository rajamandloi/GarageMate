const Reminder = require("../models/Reminder");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const WhatsAppMessage = require("../models/WhatsAppMessage");

const {
  sendWhatsAppMessage,
} = require("./whatsappService");

// ============================================================
// DATE HELPERS
// ============================================================

const startOfDay = (date) => {
  const value = new Date(date);

  value.setHours(0, 0, 0, 0);

  return value;
};

const endOfDay = (date) => {
  const value = new Date(date);

  value.setHours(23, 59, 59, 999);

  return value;
};


// ============================================================
// CHECK DUPLICATE MESSAGE
// ============================================================

const alreadyQueuedOrSent = async ({
  reminderId,
  type,
}) => {
  const existing =
    await WhatsAppMessage.findOne({
      reminderId,
      type,
      status: {
        $in: [
          "queued",
          "sending",
          "sent",
          "delivered",
          "read",
        ],
      },
    });

  return !!existing;
};


// ============================================================
// BUILD MESSAGE
// ============================================================

const buildReminderMessage = ({
  reminder,
  customer,
  vehicle,
}) => {
  const customerName =
    customer?.name || "Customer";

  const vehicleNumber =
    vehicle?.registrationNumber ||
    "your vehicle";

  const vehicleName =
    vehicle
      ? `${vehicle.brand || ""} ${vehicle.model || ""}`.trim()
      : "your vehicle";

  // ==========================================================
  // SERVICE
  // ==========================================================

  if (reminder.type === "service") {
    return `Hello ${customerName},

This is a reminder from your garage regarding ${vehicleName} (${vehicleNumber}).

${reminder.title}

${reminder.message}

Please contact the garage to schedule your service.

Thank you.`;
  }

  // ==========================================================
  // PAYMENT
  // ==========================================================

  if (reminder.type === "payment") {
    return `Hello ${customerName},

This is a payment reminder regarding your vehicle ${vehicleNumber}.

${reminder.title}

${reminder.message}

Please contact the garage if you need any assistance.

Thank you.`;
  }

  // ==========================================================
  // SPECIAL OFFER
  // ==========================================================

  if (reminder.type === "specialOffer") {
    return `Hello ${customerName},

${reminder.title}

${reminder.message}

Thank you for choosing our garage.`;
  }

  // ==========================================================
  // GENERAL
  // ==========================================================

  return `Hello ${customerName},

${reminder.title}

${reminder.message}

Thank you for choosing our garage.`;
};


// ============================================================
// PROCESS SINGLE REMINDER
// ============================================================

const processReminder = async (reminder) => {
  try {
    // ========================================================
    // CUSTOMER
    // ========================================================

    const customer =
      await Customer.findOne({
        _id: reminder.customerId,
        garageId: reminder.garageId,
      });

    if (!customer) {
      console.log(
        "Reminder skipped: customer not found",
        reminder._id
      );

      return {
        success: false,
        skipped: true,
        reason: "customer_not_found",
      };
    }

    if (!customer.phone) {
      console.log(
        "Reminder skipped: customer phone missing",
        reminder._id
      );

      return {
        success: false,
        skipped: true,
        reason: "phone_missing",
      };
    }

    // ========================================================
    // VEHICLE
    // ========================================================

    const vehicle =
      await Vehicle.findOne({
        _id: reminder.vehicleId,
        garageId: reminder.garageId,
        customerId: customer._id,
      });

    if (!vehicle) {
      console.log(
        "Reminder skipped: vehicle not found",
        reminder._id
      );

      return {
        success: false,
        skipped: true,
        reason: "vehicle_not_found",
      };
    }

    // ========================================================
    // DUPLICATE PROTECTION
    // ========================================================

    const sentAlready =
      await alreadyQueuedOrSent({
        reminderId: reminder._id,
        type:
          reminder.type === "service"
            ? "service_reminder"
            : reminder.type === "payment"
              ? "payment_reminder"
              : reminder.type === "specialOffer"
                ? "offer"
                : "general",
      });

    if (sentAlready) {
      return {
        success: true,
        skipped: true,
        reason: "already_processed",
      };
    }

    // ========================================================
    // MESSAGE TYPE
    // ========================================================

    let messageType = "general";

    if (reminder.type === "service") {
      messageType = "service_reminder";
    }

    if (reminder.type === "payment") {
      messageType = "payment_reminder";
    }

    if (reminder.type === "specialOffer") {
      messageType = "offer";
    }

    // ========================================================
    // BUILD MESSAGE
    // ========================================================

    const message =
      buildReminderMessage({
        reminder,
        customer,
        vehicle,
      });

    // ========================================================
    // SEND
    // ========================================================

    const result =
      await sendWhatsAppMessage({
        garageId:
          reminder.garageId,

        customerId:
          customer._id,

        vehicleId:
          vehicle._id,

        reminderId:
          reminder._id,

        to:
          customer.phone,

        message,

        type:
          messageType,
      });

    console.log(
      "Reminder WhatsApp sent:",
      reminder._id.toString()
    );

    return {
      success: true,
      skipped: false,
      result,
    };
  } catch (error) {
    console.error(
      "Reminder processing error:",
      reminder._id,
      error.message
    );

    return {
      success: false,
      skipped: false,
      error: error.message,
    };
  }
};


// ============================================================
// PROCESS DUE REMINDERS
// ============================================================

const processDueReminders = async () => {
  try {
    const now = new Date();

    const todayStart =
      startOfDay(now);

    const todayEnd =
      endOfDay(now);

    // ========================================================
    // FIND TODAY / OVERDUE REMINDERS
    // ========================================================

    const reminders =
      await Reminder.find({
        status: {
          $in: [
            "upcoming",
            "dueSoon",
            "dueToday",
            "overdue",
          ],
        },

        dueDate: {
          $lte: todayEnd,
        },

      }).limit(100);

    console.log(
      `Reminder scheduler found ${reminders.length} reminders`
    );

    let processed = 0;
    let skipped = 0;
    let failed = 0;

    // ========================================================
    // PROCESS
    // ========================================================

    for (const reminder of reminders) {
      const result =
        await processReminder(
          reminder
        );

      if (result.success) {
        if (result.skipped) {
          skipped++;
        } else {
          processed++;
        }
      } else {
        failed++;
      }
    }

    console.log(
      "Reminder scheduler completed:",
      {
        processed,
        skipped,
        failed,
      }
    );

    return {
      success: true,
      processed,
      skipped,
      failed,
    };
  } catch (error) {
    console.error(
      "Reminder scheduler error:",
      error
    );

    return {
      success: false,
      error: error.message,
    };
  }
};


// ============================================================
// START SCHEDULER
// ============================================================

let schedulerStarted = false;

const startReminderScheduler = () => {
  if (schedulerStarted) {
    console.log(
      "Reminder scheduler already running"
    );

    return;
  }

  schedulerStarted = true;

  console.log(
    "GarageMate reminder scheduler started"
  );

  // ==========================================================
  // RUN EVERY 5 MINUTES
  // ==========================================================

  setInterval(
    async () => {
      await processDueReminders();
    },
    5 * 60 * 1000
  );

  // ==========================================================
  // RUN ON SERVER START
  // ==========================================================

  processDueReminders();
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  processDueReminders,
  processReminder,
  startReminderScheduler,
};