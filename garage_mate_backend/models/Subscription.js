const mongoose = require("mongoose");

// ============================================================
// PLAN CONSTANTS
// ============================================================

const PLANS = {
  free: {
    name: "free",
    displayName: "Free",
    priceInr: 0,
    whatsappLimit: 50,
    customersLimit: 50,
    vehiclesLimit: 50,
    servicesLimit: 100,
    staffLimit: 1,
    hasCustomInvoices: false,
    hasAdvancedAnalytics: false,
    hasAllReminders: false,
  },
  pro: {
    name: "pro",
    displayName: "Pro",
    priceInr: 199,
    whatsappLimit: 500,
    customersLimit: null, // unlimited
    vehiclesLimit: null,
    servicesLimit: null,
    staffLimit: 3,
    hasCustomInvoices: true,
    hasAdvancedAnalytics: true,
    hasAllReminders: true,
  },
  business: {
    name: "business",
    displayName: "Business",
    priceInr: 499,
    whatsappLimit: 2000,
    customersLimit: null,
    vehiclesLimit: null,
    servicesLimit: null,
    staffLimit: 10,
    hasCustomInvoices: true,
    hasAdvancedAnalytics: true,
    hasAllReminders: true,
  },
  founder: {
    // Special lifetime plan for first 100 users
    name: "founder",
    displayName: "Founder's Plan",
    priceInr: 149,
    whatsappLimit: 500,
    customersLimit: null,
    vehiclesLimit: null,
    servicesLimit: null,
    staffLimit: 3,
    hasCustomInvoices: true,
    hasAdvancedAnalytics: true,
    hasAllReminders: true,
  },
};

// ============================================================
// SUBSCRIPTION SCHEMA
// ============================================================

const subscriptionSchema = new mongoose.Schema(
  {
    // ============================================================
    // GARAGE (one subscription per garage)
    // ============================================================

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      unique: true,
      index: true,
    },

    // ============================================================
    // CURRENT PLAN
    // ============================================================

    plan: {
      type: String,
      enum: ["free", "pro", "business", "founder"],
      default: "free",
      index: true,
    },

    // ============================================================
    // TRIAL
    // ============================================================

    isTrial: {
      type: Boolean,
      default: false,
    },

    trialStartDate: {
      type: Date,
      default: null,
    },

    trialEndDate: {
      type: Date,
      default: null,
      index: true,
    },

    hasUsedTrial: {
      type: Boolean,
      default: false,
    },

    // ============================================================
    // FOUNDER'S PLAN (lifetime lock)
    // ============================================================

    isFounderPlan: {
      type: Boolean,
      default: false,
      index: true,
    },

    founderLockedAt: {
      type: Date,
      default: null,
    },

    // ============================================================
    // USAGE — CURRENT MONTH
    // ============================================================

    whatsappMessagesSent: {
      type: Number,
      default: 0,
      min: 0,
    },

    currentPeriodStart: {
      type: Date,
      default: Date.now,
      index: true,
    },

    currentPeriodEnd: {
      type: Date,
      default: () => {
        // 1 month from now
        const d = new Date();
        d.setMonth(d.getMonth() + 1);
        return d;
      },
    },

    // ============================================================
    // LIFETIME COUNTERS
    // ============================================================

    totalMessagesSent: {
      type: Number,
      default: 0,
      min: 0,
    },

    totalRevenueInr: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ============================================================
    // MANUAL UPGRADE TRACKING
    // ============================================================

    lastUpgradeAt: {
      type: Date,
      default: null,
    },

    lastUpgradeBy: {
      type: String,
      default: null,
    },

        // ============================================================
    // LIMIT NOTIFICATION TRACKING
    // ============================================================

    lastLimitNotifiedAt: {
      type: Date,
      default: null,
    },
    
    notes: {
      type: String,
      default: "",
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// ============================================================
// INDEXES
// ============================================================

subscriptionSchema.index({
  plan: 1,
  isTrial: 1,
});

subscriptionSchema.index({
  currentPeriodEnd: 1,
});

// ============================================================
// STATIC: GET PLAN DETAILS
// ============================================================

subscriptionSchema.statics.getPlanDetails = (planName) => {
  return PLANS[planName] || PLANS.free;
};

subscriptionSchema.statics.getAllPlans = () => {
  return PLANS;
};

// ============================================================
// INSTANCE: GET EFFECTIVE PLAN
// (Trial active hone par Pro treat karein)
// ============================================================

subscriptionSchema.methods.getEffectivePlan = function () {
  // Trial active?
  if (
    this.isTrial &&
    this.trialEndDate &&
    new Date() < new Date(this.trialEndDate)
  ) {
    return "pro"; // Trial mein Pro features
  }

  // Founder plan?
  if (this.isFounderPlan) {
    return "founder";
  }

  return this.plan || "free";
};

// ============================================================
// INSTANCE: IS TRIAL ACTIVE
// ============================================================

subscriptionSchema.methods.isTrialActive = function () {
  return (
    this.isTrial &&
    this.trialEndDate &&
    new Date() < new Date(this.trialEndDate)
  );
};

// ============================================================
// INSTANCE: GET WHATSAPP LIMIT
// ============================================================

subscriptionSchema.methods.getWhatsappLimit = function () {
  // Trial active → 100 messages hard limit
  if (this.isTrialActive()) {
    return 100;
  }

  const plan = this.getEffectivePlan();
  return PLANS[plan]?.whatsappLimit ?? 50;
};

// ============================================================
// INSTANCE: REMAINING MESSAGES
// ============================================================

subscriptionSchema.methods.getRemainingMessages = function () {
  const limit = this.getWhatsappLimit();
  const used = this.whatsappMessagesSent || 0;
  return Math.max(0, limit - used);
};

// ============================================================
// EXPORT
// ============================================================

const Subscription = mongoose.model(
  "Subscription",
  subscriptionSchema
);

module.exports = Subscription;
module.exports.PLANS = PLANS;