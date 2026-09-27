const mongoose = require("mongoose");

const whatsappTemplateSchema = new mongoose.Schema(
  {
    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      index: true,
    },

    // Meta approved template name
    name: {
      type: String,
      required: true,
      trim: true,
    },

    language: {
      type: String,
      default: "en",
      trim: true,
    },

    type: {
      type: String,
      enum: [
        "serviceReminder",
        "paymentReminder",
        "bill",
        "offer",
        "general",
      ],
      required: true,
    },

    // Meta template status
    status: {
      type: String,
      enum: [
        "pending",
        "approved",
        "rejected",
        "disabled",
      ],
      default: "pending",
    },

    // Optional description for GarageMate UI
    description: {
      type: String,
      default: "",
      trim: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

whatsappTemplateSchema.index({
  garageId: 1,
  type: 1,
});

whatsappTemplateSchema.index({
  garageId: 1,
  name: 1,
});

module.exports = mongoose.model(
  "WhatsAppTemplate",
  whatsappTemplateSchema
);