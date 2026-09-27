const mongoose = require("mongoose");

const automationSettingsSchema = new mongoose.Schema(
  {
    // ============================================================
    // GARAGE (one settings per garage)
    // ============================================================

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      unique: true,
      index: true,
    },

    // ============================================================
    // MASTER SWITCH
    // ============================================================

    automationEnabled: {
      type: Boolean,
      default: true,
    },

    // ============================================================
    // CATEGORY SWITCHES
    // ============================================================

    serviceRemindersEnabled: {
      type: Boolean,
      default: true,
    },

    specialOffersEnabled: {
      type: Boolean,
      default: false,
    },

    paymentRemindersEnabled: {
      type: Boolean,
      default: false,
    },

    // ============================================================
    // TEMPLATE NAMES (Meta approved template names)
    // ============================================================

    serviceTemplate: {
      type: String,
      default: "service_reminder",
      trim: true,
    },

    offerTemplate: {
      type: String,
      default: "special_offer",
      trim: true,
    },

    paymentTemplate: {
      type: String,
      default: "payment_reminder",
      trim: true,
    },

    // ============================================================
    // SCHEDULER STATE
    // ============================================================

    lastRunAt: {
      type: Date,
      default: null,
    },

    lastRunStatus: {
      type: String,
      enum: ["never", "success", "partial", "failed"],
      default: "never",
    },

    lastRunMessage: {
      type: String,
      default: "",
      trim: true,
    },

    totalSentCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// ============================================================
// INDEXES
// ============================================================

automationSettingsSchema.index({
  automationEnabled: 1,
});

// ============================================================
// EXPORT
// ============================================================

module.exports = mongoose.model(
  "AutomationSettings",
  automationSettingsSchema
);