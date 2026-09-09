const mongoose = require("mongoose");

const whatsappMessageSchema = new mongoose.Schema(
  {
    // ============================================================
    // TENANT
    // ============================================================

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      index: true,
    },

    // ============================================================
    // CUSTOMER / VEHICLE / REMINDER
    // ============================================================

    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      default: null,
      index: true,
    },

    vehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vehicle",
      default: null,
      index: true,
    },

    reminderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Reminder",
      default: null,
      index: true,
    },

    // ============================================================
    // MESSAGE CATEGORY
    // ============================================================

    type: {
      type: String,
      enum: [
        "service_reminder",
        "payment_reminder",
        "bill",
        "appointment_confirmation",
        "offer",
        "general",
      ],
      required: true,
      index: true,
    },

    // ============================================================
    // WHATSAPP
    // ============================================================

    phoneNumberId: {
      type: String,
      default: null,
      index: true,
    },

    recipientPhone: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    // ============================================================
    // TEMPLATE
    // ============================================================

    templateName: {
      type: String,
      default: null,
      trim: true,
    },

    templateLanguage: {
      type: String,
      default: "en",
      trim: true,
    },

    // ============================================================
    // MESSAGE CONTENT
    // ============================================================

    message: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // PROVIDER
    // ============================================================

    provider: {
      type: String,
      enum: [
        "meta",
        "other",
      ],
      default: "meta",
    },

    providerMessageId: {
      type: String,
    },

    // ============================================================
    // DELIVERY STATUS
    // ============================================================

    status: {
      type: String,
      enum: [
        "queued",
        "sending",
        "sent",
        "delivered",
        "read",
        "failed",
      ],
      default: "queued",
      index: true,
    },

    // ============================================================
    // RETRY
    // ============================================================

    attempts: {
      type: Number,
      default: 0,
      min: 0,
    },

    maxAttempts: {
      type: Number,
      default: 3,
      min: 1,
    },

    nextRetryAt: {
      type: Date,
      default: null,
    },

    // ============================================================
    // ERROR
    // ============================================================

    errorCode: {
      type: String,
      default: null,
    },

    errorMessage: {
      type: String,
      default: null,
      trim: true,
    },

    // ============================================================
    // TIMESTAMPS
    // ============================================================

    queuedAt: {
      type: Date,
      default: Date.now,
    },

    sentAt: {
      type: Date,
      default: null,
    },

    deliveredAt: {
      type: Date,
      default: null,
    },

    readAt: {
      type: Date,
      default: null,
    },

    failedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);


// ============================================================
// INDEXES
// ============================================================

whatsappMessageSchema.index({
  garageId: 1,
  createdAt: -1,
});

whatsappMessageSchema.index({
  garageId: 1,
  customerId: 1,
  createdAt: -1,
});

whatsappMessageSchema.index({
  garageId: 1,
  status: 1,
});

whatsappMessageSchema.index({
  garageId: 1,
  type: 1,
});

whatsappMessageSchema.index({
  providerMessageId: 1,
});


// ============================================================
// EXPORT
// ============================================================

module.exports = mongoose.model(
  "WhatsAppMessage",
  whatsappMessageSchema
);