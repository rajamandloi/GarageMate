const cron = require("node-cron");

const AutomationSettings = require(
  "../models/AutomationSettings"
);

const {
  runAutomationForGarage,
} = require("./automationService");

// ============================================================
// START AUTOMATION SCHEDULER
// Runs daily at 10:00 AM (server time)
// ============================================================

const startAutomationScheduler = () => {
  // "0 10 * * *" => daily at 10:00 AM
  // For testing use "*/5 * * * *" => every 5 minutes
  const cronExpression =
    process.env.AUTOMATION_CRON || "0 10 * * *";

  console.log(
    `🤖 Automation scheduler started (${cronExpression})`
  );

  cron.schedule(cronExpression, async () => {
    console.log("⏰ Automation scheduler running...");

    try {
      const settingsList = await AutomationSettings.find({
        automationEnabled: true,
      });

      console.log(
        `Found ${settingsList.length} garage(s) with automation enabled`
      );

      for (const settings of settingsList) {
        try {
          const result = await runAutomationForGarage({
            garageId: settings.garageId,
            settings,
          });

          const totalSent =
            result.serviceReminders.sent +
            result.paymentReminders.sent +
            result.specialOffers.sent;

          const totalFailed =
            result.serviceReminders.failed +
            result.paymentReminders.failed +
            result.specialOffers.failed;

          settings.lastRunAt = new Date();
          settings.totalSentCount =
            (settings.totalSentCount || 0) + totalSent;

          if (totalFailed === 0) {
            settings.lastRunStatus = "success";
            settings.lastRunMessage = `${totalSent} message(s) sent`;
          } else if (totalSent > 0) {
            settings.lastRunStatus = "partial";
            settings.lastRunMessage = `${totalSent} sent, ${totalFailed} failed`;
          } else {
            settings.lastRunStatus = "failed";
            settings.lastRunMessage = `${totalFailed} failed`;
          }

          await settings.save();

          console.log(
            `Garage ${settings.garageId}: ${settings.lastRunMessage}`
          );
        } catch (garageError) {
          console.error(
            `Automation error for garage ${settings.garageId}:`,
            garageError.message
          );
        }
      }

      console.log("✅ Automation scheduler finished");
    } catch (error) {
      console.error(
        "Automation scheduler error:",
        error.message
      );
    }
  });
};

module.exports = {
  startAutomationScheduler,
};