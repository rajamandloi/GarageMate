const mongoose = require("mongoose");

const whatsappIntegrationSchema = new mongoose.Schema(
  {
    // ============================================================
    // GARAGE
    // ============================================================

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      unique: true,
      index: true,
    },

    // ============================================================
    // META / WHATSAPP BUSINESS
    // ============================================================

    businessAccountId: {
      type: String,
      default: null,
      trim: true,
    },

    phoneNumberId: {
      type: String,
      default: null,
      trim: true,
      index: true,
    },

    displayPhoneNumber: {
      type: String,
      default: null,
      trim: true,
    },

    // ============================================================
    // ACCESS TOKEN
    // ============================================================

    accessToken: {
      type: String,
      default: null,
    },

    // ============================================================
    // CONNECTION STATUS
    // ============================================================

    isConnected: {
      type: Boolean,
      default: false,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    // ============================================================
    // AI SETTINGS
    // ============================================================

    aiEnabled: {
      type: Boolean,
      default: false,
    },

    aiName: {
      type: String,
      default: "GarageMate Assistant",
      trim: true,
    },

    greeting: {
      type: String,
      default:
        "Hello! Welcome to our garage. How can I help you today?",
      trim: true,
    },

    aiInstructions: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // BUSINESS SETTINGS
    // ============================================================

    businessHours: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // WEBHOOK
    // ============================================================

    webhookVerified: {
      type: Boolean,
      default: false,
    },

    // ============================================================
    // TIMESTAMPS
    // ============================================================

    lastConnectedAt: {
      type: Date,
      default: null,
    },

    lastMessageAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "WhatsAppIntegration",
  whatsappIntegrationSchema
);