const cron = require("node-cron");

const Subscription = require(
  "../models/Subscription"
);

const {
  resetMonthlyCounters,
} = require("./subscriptionService");

const {
  notifyTrialExpiry,
  notifySubscriptionExpiry,
  notifyDailySummary,
} = require("./notificationService");

const Service = require("../models/Service");
const Reminder = require("../models/Reminder");

// ============================================================
// START SUBSCRIPTION SCHEDULER
// ============================================================

const startSubscriptionScheduler = () => {
  // --------------------------------------------------------
  // 1. Monthly counter reset (1st of every month, 00:05)
  // --------------------------------------------------------
  const monthlyCron =
    process.env.SUBSCRIPTION_CRON || "5 0 1 * *";

  console.log(
    `💳 Monthly counter reset started (${monthlyCron})`
  );

  cron.schedule(monthlyCron, async () => {
    console.log("🔄 Monthly counter reset running...");
    try {
      const count = await resetMonthlyCounters();
      console.log(
        `✅ Counters reset for ${count} subscriptions`
      );
    } catch (error) {
      console.error(
        "Monthly reset error:",
        error.message
      );
    }
  });

  // --------------------------------------------------------
  // 2. Daily trial/subscription expiry check (Every day 9 AM)
  // --------------------------------------------------------
  const expiryCron =
    process.env.EXPIRY_CRON || "0 9 * * *";

  console.log(
    `⏰ Expiry check started (${expiryCron})`
  );

  cron.schedule(expiryCron, async () => {
    console.log("⏰ Expiry check running...");

    try {
      // Trial ending in 3 days
      const threeDaysLater = new Date();
      threeDaysLater.setDate(
        threeDaysLater.getDate() + 3
      );
      threeDaysLater.setHours(0, 0, 0, 0);

      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 4);
      tomorrow.setHours(0, 0, 0, 0);

      const trialsEnding = await Subscription.find({
        isTrial: true,
        trialEndDate: {
          $gte: threeDaysLater,
          $lt: tomorrow,
        },
        isActive: true,
      });

      for (const sub of trialsEnding) {
        await notifyTrialExpiry({
          garageId: sub.garageId,
          daysLeft: 3,
        });
      }

      console.log(
        `✅ Sent ${trialsEnding.length} trial expiry notifications`
      );

      // Subscription ending in 3 days
      const subsEnding = await Subscription.find({
        isTrial: false,
        plan: { $in: ["pro", "business", "founder"] },
        currentPeriodEnd: {
          $gte: threeDaysLater,
          $lt: tomorrow,
        },
      });

      for (const sub of subsEnding) {
        await notifySubscriptionExpiry({
          garageId: sub.garageId,
          daysLeft: 3,
          plan: sub.plan,
        });
      }

      console.log(
        `✅ Sent ${subsEnding.length} subscription expiry notifications`
      );
    } catch (error) {
      console.error(
        "Expiry check error:",
        error.message
      );
    }
  });

  // --------------------------------------------------------
  // 3. Daily summary (Every day 8 AM)
  // --------------------------------------------------------
  const dailySummaryCron =
    process.env.DAILY_SUMMARY_CRON || "0 8 * * *";

  console.log(
    `📊 Daily summary started (${dailySummaryCron})`
  );

  cron.schedule(dailySummaryCron, async () => {
    console.log("📊 Daily summary running...");

    try {
      const subscriptions = await Subscription.find({
        automationEnabled: true,
      });

      // Get all active garages
      const garages = await Subscription.distinct(
        "garageId"
      );

      let sentCount = 0;

      for (const garageId of garages) {
        try {
          // Count today's tasks for this garage
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          const tomorrow = new Date(today);
          tomorrow.setDate(tomorrow.getDate() + 1);

          const [
            servicesDueToday,
            paymentsPending,
            remindersDueToday,
          ] = await Promise.all([
            // Services with nextServiceDate = today
            Service.countDocuments({
              garageId,
              nextServiceDate: {
                $gte: today,
                $lt: tomorrow,
              },
            }),

            // Payment pending (overdue by 7+ days)
            Service.countDocuments({
              garageId,
              paymentStatus: {
                $in: ["pending", "partiallyPaid"],
              },
              serviceDate: {
                $lt: new Date(
                  Date.now() -
                    7 * 24 * 60 * 60 * 1000
                ),
              },
            }),

            // Reminders due today
            Reminder.countDocuments({
              garageId,
              status: {
                $in: ["dueToday", "overdue"],
              },
            }),
          ]);

          const total =
            servicesDueToday +
            paymentsPending +
            remindersDueToday;

          if (total > 0) {
            await notifyDailySummary({
              garageId,
              servicesDueToday,
              paymentsPending,
              remindersDueToday,
            });
            sentCount++;
          }
        } catch (garageError) {
          console.error(
            `Daily summary for garage ${garageId}:`,
            garageError.message
          );
        }
      }

      console.log(
        `✅ Sent ${sentCount} daily summary notifications`
      );
    } catch (error) {
      console.error(
        "Daily summary error:",
        error.message
      );
    }
  });
};

module.exports = {
  startSubscriptionScheduler,
};