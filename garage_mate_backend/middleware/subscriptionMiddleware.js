const {
  checkWhatsAppLimit,
} = require("../services/subscriptionService");

// ============================================================
// CHECK WHATSAPP LIMIT MIDDLEWARE
// Attach to any route that sends WhatsApp messages
// ============================================================

const checkWhatsAppLimitMiddleware = async (
  req,
  res,
  next
) => {
  try {
    const garageId =
      req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
        code: "NO_GARAGE",
      });
    }

    const usage = await checkWhatsAppLimit(garageId);

    // Attach usage to request for later use
    req.subscriptionUsage = usage;

    if (!usage.allowed) {
      return res.status(402).json({
        success: false,
        message:
          usage.reason ||
          "WhatsApp message limit reached",
        code: "LIMIT_REACHED",
        usage: {
          plan: usage.plan,
          isTrial: usage.isTrial,
          used: usage.used,
          limit: usage.limit,
          remaining: usage.remaining,
        },
      });
    }

    next();
  } catch (error) {
    console.error(
      "Subscription middleware error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to check subscription limit",
    });
  }
};

// ============================================================
// REQUIRE SPECIFIC PLAN FEATURES
// ============================================================

const requirePlanFeature = (featureKey) => {
  return async (req, res, next) => {
    try {
      const garageId =
        req.garageId || req.user?.garageId;

      if (!garageId) {
        return res.status(400).json({
          success: false,
          message: "Garage is not associated",
        });
      }

      const Subscription = require("../models/Subscription");

      let subscription = await Subscription.findOne({
        garageId,
      });

      if (!subscription) {
        subscription = await Subscription.create({
          garageId,
          plan: "free",
        });
      }

      const effectivePlan =
        subscription.getEffectivePlan();

      const planDetails =
        Subscription.getPlanDetails(effectivePlan);

      if (!planDetails || !planDetails[featureKey]) {
        return res.status(402).json({
          success: false,
          message:
            "This feature requires an upgraded plan",
          code: "UPGRADE_REQUIRED",
          requiredFeature: featureKey,
          currentPlan: effectivePlan,
        });
      }

      next();
    } catch (error) {
      console.error(
        "Plan feature middleware error:",
        error.message
      );

      return res.status(500).json({
        success: false,
        message: "Unable to verify plan feature",
      });
    }
  };
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  checkWhatsAppLimitMiddleware,
  requirePlanFeature,
};