const mongoose = require("mongoose");

const whatsappConversationSchema = new mongoose.Schema(
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
    // CUSTOMER
    // ============================================================

    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      default: null,
      index: true,
    },

    // WhatsApp number of the customer
    customerPhone: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    // ============================================================
    // WHATSAPP
    // ============================================================

    phoneNumberId: {
      type: String,
      required: true,
      index: true,
    },

    // ============================================================
    // CONVERSATION
    // ============================================================

    messages: [
      {
        messageId: {
          type: String,
          default: null,
        },

        direction: {
          type: String,
          enum: ["incoming", "outgoing"],
          required: true,
        },

        type: {
          type: String,
          default: "text",
        },

        text: {
          type: String,
          default: "",
          trim: true,
        },

        timestamp: {
          type: Date,
          default: Date.now,
        },

        aiGenerated: {
          type: Boolean,
          default: false,
        },
      },
    ],

    // ============================================================
    // STATUS
    // ============================================================

    isActive: {
      type: Boolean,
      default: true,
    },

    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// One conversation per customer per garage.
whatsappConversationSchema.index({
  garageId: 1,
  customerPhone: 1,
});

module.exports = mongoose.model(
  "WhatsAppConversation",
  whatsappConversationSchema
);