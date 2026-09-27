const cron = require("node-cron");

const Reminder =
  require("../models/Reminder");

const WhatsAppNotificationLog =
  require(
    "../models/WhatsAppNotificationLog"
  );

const {
  sendWhatsAppTemplate,
} = require(
  "./whatsappTemplateService"
);


// ============================================================
// CHECK IF ALREADY SENT
// ============================================================

const alreadySent = async ({
  garageId,
  reminderId,
  type,
}) => {
  const existing =
    await WhatsAppNotificationLog.findOne({
      garageId,
      reminderId,
      type,
      status: "sent",
    });

  return !!existing;
};


// ============================================================
// SERVICE REMINDERS
// ============================================================

const processServiceReminders =
  async () => {
    try {
      console.log(
        "Checking service reminders..."
      );

      const reminders =
        await Reminder.find({
          type: "service",

          status: {
            $in: [
              "dueToday",
              "overdue",
            ],
          },
        })
          .populate(
            "customerId",
            "name phone"
          )
          .populate(
            "vehicleId",
            "registrationNumber brand model"
          );

      for (const reminder of reminders) {
        if (!reminder.customerId) {
          continue;
        }

        if (
          !reminder.customerId.phone
        ) {
          continue;
        }

        const sent =
          await alreadySent({
            garageId:
              reminder.garageId,

            reminderId:
              reminder._id,

            type:
              "serviceReminder",
          });

        if (sent) {
          continue;
        }

        const customer =
          reminder.customerId;

        const vehicle =
          reminder.vehicleId;

        const vehicleName =
          vehicle
            ? `${vehicle.brand} ${vehicle.model}`
            : "your vehicle";

        try {
          await sendWhatsAppTemplate({
            garageId:
              reminder.garageId,

            customerId:
              customer._id,

            vehicleId:
              vehicle?._id || null,

            reminderId:
              reminder._id,

            to:
              customer.phone,

            templateName:
              "service_reminder",

            language:
              "en",

            parameters: [
              customer.name,
              vehicleName,
              reminder.title,
            ],

            type:
              "serviceReminder",
          });

          console.log(
            "Service reminder sent to:",
            customer.phone
          );
        } catch (error) {
          console.error(
            "Service reminder failed:",
            error.message
          );
        }
      }
    } catch (error) {
      console.error(
        "Service reminder scheduler error:",
        error
      );
    }
  };

// ============================================================
// PAYMENT REMINDERS
// ============================================================

const processPaymentReminders =
  async () => {
    try {
      console.log(
        "Checking payment reminders..."
      );

      const reminders =
        await Reminder.find({
          type: "payment",

          status: {
            $in: [
              "dueToday",
              "overdue",
            ],
          },
        })
          .populate(
            "customerId",
            "name phone"
          )
          .populate(
            "vehicleId",
            "registrationNumber brand model"
          );

      for (
        const reminder of reminders
      ) {
        if (
          !reminder.customerId ||
          !reminder.customerId.phone
        ) {
          continue;
        }

        const sent =
          await alreadySent({
            garageId:
              reminder.garageId,

            reminderId:
              reminder._id,

            type:
              "paymentReminder",
          });

        if (sent) {
          continue;
        }

        try {
          await sendWhatsAppTemplate({
            garageId:
              reminder.garageId,

            customerId:
              reminder.customerId._id,

            vehicleId:
              reminder.vehicleId?._id ||
              null,

            reminderId:
              reminder._id,

            to:
              reminder.customerId.phone,

            templateName:
              "payment_reminder",

            language:
              "en",

            parameters: [
              reminder.customerId.name,
              reminder.message,
            ],

            type:
              "paymentReminder",
          });

          console.log(
            "Payment reminder sent to:",
            reminder.customerId.phone
          );
        } catch (error) {
          console.error(
            "Payment reminder failed:",
            error.message
          );
        }
      }
    } catch (error) {
      console.error(
        "Payment reminder scheduler error:",
        error
      );
    }
  };

// ============================================================
// START SCHEDULER
// ============================================================

const startReminderScheduler =
  () => {
    console.log(
      "GarageMate reminder scheduler started"
    );

    // Every day at 9:00 AM
    cron.schedule(
      "0 9 * * *",
      async () => {
        console.log(
          "Running daily reminder job..."
        );

        await processServiceReminders();
        await processPaymentReminders();
      }
    );
  };


module.exports = {
  startReminderScheduler,
  processServiceReminders,
  processPaymentReminders,
};