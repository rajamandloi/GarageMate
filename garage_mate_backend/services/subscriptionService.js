const Subscription = require("../models/Subscription");
const { PLANS } = require("../models/Subscription");

// ============================================================
// GET OR CREATE SUBSCRIPTION
// ============================================================

const getOrCreateSubscription = async (garageId) => {
  if (!garageId) {
    throw new Error("Garage ID is required");
  }

  let subscription = await Subscription.findOne({
    garageId,
  });

  if (!subscription) {
    subscription = await Subscription.create({
      garageId,
      plan: "free",
      isTrial: false,
      hasUsedTrial: false,
      whatsappMessagesSent: 0,
      totalMessagesSent: 0,
    });

    console.log(
      `✅ New free subscription created for garage ${garageId}`
    );
  }

  return subscription;
};

// ============================================================
// CHECK WHATSAPP LIMIT
// Returns: { allowed, used, limit, remaining, reason }
// ============================================================

const checkWhatsAppLimit = async (garageId) => {
  const subscription = await getOrCreateSubscription(
    garageId
  );

  const limit = subscription.getWhatsappLimit();
  const used = subscription.whatsappMessagesSent || 0;
  const remaining = Math.max(0, limit - used);

  const allowed = remaining > 0;

  let reason = null;

  if (!allowed) {
    if (subscription.isTrialActive()) {
      reason = "Trial limit reached";
    } else if (subscription.plan === "free") {
      reason = "Free plan limit reached";
    } else {
      reason = "Monthly limit reached";
    }
  }

  return {
    allowed,
    used,
    limit,
    remaining,
    reason,
    plan: subscription.getEffectivePlan(),
    isTrial: subscription.isTrialActive(),
  };
};

// ============================================================
// INCREMENT WHATSAPP COUNT
// Call this after successfully sending a message
// ============================================================

const incrementWhatsAppCount = async (garageId) => {
  const subscription = await getOrCreateSubscription(
    garageId
  );

  subscription.whatsappMessagesSent =
    (subscription.whatsappMessagesSent || 0) + 1;

  subscription.totalMessagesSent =
    (subscription.totalMessagesSent || 0) + 1;

  await subscription.save();

  return subscription;
};

// ============================================================
// START TRIAL
// ============================================================

const startTrial = async (garageId) => {
  const subscription = await getOrCreateSubscription(
    garageId
  );

  if (subscription.hasUsedTrial) {
    throw new Error("Trial already used");
  }

  if (subscription.isTrialActive()) {
    throw new Error("Trial already active");
  }

  const now = new Date();
  const trialEnd = new Date();
  trialEnd.setDate(trialEnd.getDate() + 14); // 14 days

  subscription.isTrial = true;
  subscription.trialStartDate = now;
  subscription.trialEndDate = trialEnd;
  subscription.hasUsedTrial = true;

  // Reset usage for trial
  subscription.whatsappMessagesSent = 0;

  await subscription.save();

  return subscription;
};

// ============================================================
// UPGRADE PLAN (manual — admin will call this)
// ============================================================

const upgradePlan = async ({
  garageId,
  newPlan,
  upgradedBy = "admin",
  notes = "",
}) => {
  if (!PLANS[newPlan]) {
    throw new Error(`Invalid plan: ${newPlan}`);
  }

  const subscription = await getOrCreateSubscription(
    garageId
  );

  // Founder plan — special handling
  if (newPlan === "founder") {
    if (!subscription.isFounderPlan) {
      subscription.isFounderPlan = true;
      subscription.founderLockedAt = new Date();
    }
  }

  subscription.plan = newPlan;
  subscription.isTrial = false;
  subscription.lastUpgradeAt = new Date();
  subscription.lastUpgradeBy = upgradedBy;

  if (notes) {
    subscription.notes = notes;
  }

  await subscription.save();

  console.log(
    `✅ Garage ${garageId} upgraded to ${newPlan}`
  );

  return subscription;
};

// ============================================================
// RESET MONTHLY COUNTER
// Called by cron job on 1st of every month
// ============================================================

const resetMonthlyCounters = async () => {
  const now = new Date();
  const nextPeriodEnd = new Date();
  nextPeriodEnd.setMonth(nextPeriodEnd.getMonth() + 1);

  const result = await Subscription.updateMany(
    {},
    {
      $set: {
        whatsappMessagesSent: 0,
        currentPeriodStart: now,
        currentPeriodEnd: nextPeriodEnd,
      },
    }
  );

  console.log(
    `🔄 Monthly counters reset for ${result.modifiedCount} subscriptions`
  );

  return result.modifiedCount;
};

// ============================================================
// GET USAGE SUMMARY (for UI)
// ============================================================

const getUsageSummary = async (garageId) => {
  const subscription = await getOrCreateSubscription(
    garageId
  );

  const limit = subscription.getWhatsappLimit();
  const used = subscription.whatsappMessagesSent || 0;
  const remaining = Math.max(0, limit - used);

  const plan = subscription.getEffectivePlan();
  const planDetails = PLANS[plan] || PLANS.free;

  return {
    plan,
    planDisplayName: planDetails.displayName,
    planPrice: planDetails.priceInr,
    isTrial: subscription.isTrialActive(),
    trialEndsAt: subscription.trialEndDate,
    hasUsedTrial: subscription.hasUsedTrial,
    isFounderPlan: subscription.isFounderPlan,
    whatsapp: {
      used,
      limit,
      remaining,
      percentage:
        limit > 0 ? Math.round((used / limit) * 100) : 0,
    },
    periodStart: subscription.currentPeriodStart,
    periodEnd: subscription.currentPeriodEnd,
    totalMessagesSent: subscription.totalMessagesSent,
  };
};

// ============================================================
// GET ALL PLANS (for UI comparison)
// ============================================================

const getAllPlansForUI = () => {
  return [
    {
      name: "free",
      displayName: "Free",
      priceInr: 0,
      features: [
        "50 customers",
        "50 vehicles",
        "100 services/month",
        "50 WhatsApp messages/month",
        "Basic invoices",
        "1 staff user",
      ],
    },
    {
      name: "pro",
      displayName: "Pro",
      priceInr: 199,
      popular: true,
      features: [
        "Unlimited customers",
        "Unlimited vehicles",
        "Unlimited services",
        "500 WhatsApp messages/month",
        "Custom branded invoices",
        "Advanced analytics",
        "All reminder types",
        "3 staff users",
        "Daily cloud backup",
      ],
    },
    {
      name: "business",
      displayName: "Business",
      priceInr: 499,
      features: [
        "Everything in Pro",
        "2000 WhatsApp messages/month",
        "10 staff users",
        "Real-time backup",
        "Phone + WhatsApp support",
      ],
    },
  ];
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getOrCreateSubscription,
  checkWhatsAppLimit,
  incrementWhatsAppCount,
  startTrial,
  upgradePlan,
  resetMonthlyCounters,
  getUsageSummary,
  getAllPlansForUI,
};