const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    // =====================================================
    // RECIPIENT
    // =====================================================

    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // =====================================================
    // TYPE
    // =====================================================

    type: {
      type: String,
      enum: [
        // Admin notifications
        "new_garage_registration",
        "new_upgrade_request",

        // Garage owner — service
        "service_complete",

        // Garage owner — payment
        "payment_received",
        "payment_pending",

        // Garage owner — daily
        "daily_summary",

        // Garage owner — subscription
        "whatsapp_limit",
        "trial_expiry",
        "subscription_expiry",

        // General
        "general",
        "test",
      ],
      required: true,
      index: true,
    },

    // =====================================================
    // CONTENT
    // =====================================================

    title: {
      type: String,
      required: true,
      trim: true,
    },

    message: {
      type: String,
      required: true,
      trim: true,
    },

    // =====================================================
    // GARAGE (if related)
    // =====================================================

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      default: null,
      index: true,
    },

    // =====================================================
    // STATUS
    // =====================================================

    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },

    readAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// =====================================================
// INDEXES
// =====================================================

notificationSchema.index({
  recipient: 1,
  isRead: 1,
  createdAt: -1,
});

notificationSchema.index({
  recipient: 1,
  createdAt: -1,
});

// =====================================================
// EXPORT
// =====================================================

module.exports = mongoose.model(
  "Notification",
  notificationSchema
);