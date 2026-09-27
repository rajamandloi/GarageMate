const Subscription = require("../models/Subscription");

const {
  getOrCreateSubscription,
  startTrial,
  upgradePlan,
  getUsageSummary,
  getAllPlansForUI,
} = require("../services/subscriptionService");

const {
  notifyWhatsAppLimit,
} = require("../services/notificationService");

// ============================================================
// GET CURRENT SUBSCRIPTION + USAGE
// GET /api/subscription/current
// ============================================================

const getCurrentSubscription = async (req, res) => {
  try {
    const garageId =
      req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const usage = await getUsageSummary(garageId);

    // --------------------------------------------------------
    // ✅ FCM NOTIFICATION — WhatsApp limit warning
    // (Only once per day when 80%+ used)
    // --------------------------------------------------------
    try {
      const subscription = await Subscription.findOne({
        garageId,
      });

      if (subscription) {
        const { whatsapp } = usage;

        // Notify only when >= 80% used
        if (whatsapp.percentage >= 80) {
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          const lastNotified =
            subscription.lastLimitNotifiedAt;

          const shouldNotify =
            !lastNotified || lastNotified < today;

          if (shouldNotify) {
            await notifyWhatsAppLimit({
              garageId,
              used: whatsapp.used,
              limit: whatsapp.limit,
              remaining: whatsapp.remaining,
            });

            subscription.lastLimitNotifiedAt =
              new Date();
            await subscription.save();

            console.log(
              "✅ WhatsApp limit notification sent"
            );
          }
        }
      }
    } catch (notifyError) {
      console.error(
        "WhatsApp limit notification error:",
        notifyError.message
      );
    }

    return res.status(200).json({
      success: true,
      usage,
    });
  } catch (error) {
    console.error(
      "Get subscription error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch subscription",
    });
  }
};

// ============================================================
// GET ALL PLANS (for UI comparison)
// GET /api/subscription/plans
// ============================================================

const getPlans = async (req, res) => {
  try {
    const plans = getAllPlansForUI();

    return res.status(200).json({
      success: true,
      plans,
    });
  } catch (error) {
    console.error("Get plans error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch plans",
    });
  }
};

// ============================================================
// START FREE TRIAL
// POST /api/subscription/start-trial
// ============================================================

const startFreeTrial = async (req, res) => {
  try {
    const garageId =
      req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const subscription = await startTrial(garageId);

    return res.status(200).json({
      success: true,
      message: "14-day Pro trial started successfully",
      trialEndDate: subscription.trialEndDate,
    });
  } catch (error) {
    console.error(
      "Start trial error:",
      error.message
    );

    return res.status(400).json({
      success: false,
      message: error.message || "Unable to start trial",
    });
  }
};

// ============================================================
// ADMIN — UPGRADE PLAN
// POST /api/subscription/upgrade
// ============================================================

const adminUpgradePlan = async (req, res) => {
  try {
    const {
      garageId,
      newPlan,
      notes = "",
    } = req.body;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "garageId is required",
      });
    }

    if (!newPlan) {
      return res.status(400).json({
        success: false,
        message: "newPlan is required",
      });
    }

    const validPlans = [
      "free",
      "pro",
      "business",
      "founder",
    ];

    if (!validPlans.includes(newPlan)) {
      return res.status(400).json({
        success: false,
        message: `Invalid plan. Allowed: ${validPlans.join(
          ", "
        )}`,
      });
    }

    const subscription = await upgradePlan({
      garageId,
      newPlan,
      upgradedBy: req.user?.name || "admin",
      notes,
    });

    return res.status(200).json({
      success: true,
      message: `Plan upgraded to ${newPlan}`,
      subscription: {
        garageId: subscription.garageId,
        plan: subscription.plan,
        isFounderPlan: subscription.isFounderPlan,
        lastUpgradeAt: subscription.lastUpgradeAt,
      },
    });
  } catch (error) {
    console.error(
      "Upgrade plan error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to upgrade plan",
    });
  }
};

// ============================================================
// ADMIN — GET FOUNDER'S PLAN SLOTS
// GET /api/subscription/founder-slots
// ============================================================

const getFounderSlots = async (req, res) => {
  try {
    const FOUNDER_LIMIT = 100;

    const usedCount =
      await Subscription.countDocuments({
        isFounderPlan: true,
      });

    const remaining = Math.max(
      0,
      FOUNDER_LIMIT - usedCount
    );

    return res.status(200).json({
      success: true,
      total: FOUNDER_LIMIT,
      used: usedCount,
      remaining,
      available: remaining > 0,
    });
  } catch (error) {
    console.error(
      "Get founder slots error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch founder slots",
    });
  }
};

// ============================================================
// ADMIN — LIST ALL SUBSCRIPTIONS
// GET /api/subscription/admin/all
// ============================================================

const adminListSubscriptions = async (req, res) => {
  try {
    const {
      plan,
      isTrial,
      isFounderPlan,
      page = 1,
      limit = 50,
    } = req.query;

    const filter = {};

    if (plan) filter.plan = plan;

    if (isTrial !== undefined) {
      filter.isTrial = isTrial === "true";
    }

    if (isFounderPlan !== undefined) {
      filter.isFounderPlan = isFounderPlan === "true";
    }

    const skip =
      (Number(page) - 1) * Number(limit);

    const [subscriptions, total] = await Promise.all([
      Subscription.find(filter)
        .populate("garageId", "name phone email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),

      Subscription.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
      subscriptions,
    });
  } catch (error) {
    console.error(
      "List subscriptions error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch subscriptions",
    });
  }
};

// ============================================================
// MANUAL UPGRADE REQUEST (User side)
// POST /api/subscription/request-upgrade
// ============================================================

const requestUpgrade = async (req, res) => {
  try {
    const garageId =
      req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const {
      requestedPlan,
      paymentReference = "",
      notes = "",
    } = req.body;

    if (!requestedPlan) {
      return res.status(400).json({
        success: false,
        message: "requestedPlan is required",
      });
    }

    const validPlans = ["pro", "business", "founder"];

    if (!validPlans.includes(requestedPlan)) {
      return res.status(400).json({
        success: false,
        message: `Invalid plan. Allowed: ${validPlans.join(
          ", "
        )}`,
      });
    }

    const subscription = await getOrCreateSubscription(
      garageId
    );

    const requestNote = [
      `[UPGRADE REQUEST]`,
      `Plan: ${requestedPlan}`,
      `Ref: ${paymentReference}`,
      `Notes: ${notes}`,
      `At: ${new Date().toISOString()}`,
    ].join(" | ");

    subscription.notes = subscription.notes
      ? `${subscription.notes}\n${requestNote}`
      : requestNote;

    await subscription.save();

    // --------------------------------------------------------
    // Notify admin (console log — WhatsApp/email can be added)
    // --------------------------------------------------------
    try {
      const Garage = require("../models/Garage");
      const User = require("../models/User");

      const garage = await Garage.findById(
        garageId
      ).select("name phone email");

      const user = await User.findOne({
        garageId,
      }).select("name email phone");

      const adminMessage =
        `🔔 *New Upgrade Request*\n\n` +
        `Garage: ${garage?.name || "Unknown"}\n` +
        `Owner: ${user?.name || "Unknown"}\n` +
        `Phone: ${garage?.phone || user?.phone || "N/A"}\n` +
        `Email: ${garage?.email || user?.email || "N/A"}\n\n` +
        `Requested Plan: *${requestedPlan.toUpperCase()}*\n` +
        `Payment Ref: ${paymentReference || "N/A"}\n` +
        `Notes: ${notes || "N/A"}\n\n` +
        `Time: ${new Date().toLocaleString("en-IN")}`;

      console.log(
        "================================================="
      );
      console.log("🔔 UPGRADE REQUEST NOTIFICATION:");
      console.log(adminMessage);
      console.log(
        "================================================="
      );
    } catch (notifyError) {
      console.error(
        "Admin notify error:",
        notifyError.message
      );
    }

    return res.status(200).json({
      success: true,
      message:
        "Upgrade request submitted. Our team will verify and activate within 24 hours.",
    });
  } catch (error) {
    console.error(
      "Request upgrade error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to submit upgrade request",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getCurrentSubscription,
  getPlans,
  startFreeTrial,
  adminUpgradePlan,
  getFounderSlots,
  adminListSubscriptions,
  requestUpgrade,
};