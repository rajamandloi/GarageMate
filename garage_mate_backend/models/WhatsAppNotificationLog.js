const mongoose = require("mongoose");

const whatsappNotificationLogSchema =
  new mongoose.Schema(
    {
      garageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Garage",
        required: true,
        index: true,
      },

      customerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Customer",
        required: true,
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

      templateName: {
        type: String,
        required: true,
        trim: true,
      },

      recipientPhone: {
        type: String,
        required: true,
        trim: true,
      },

      status: {
        type: String,
        enum: [
          "pending",
          "sent",
          "failed",
        ],
        default: "pending",
      },

      whatsappMessageId: {
        type: String,
        default: null,
      },

      errorMessage: {
        type: String,
        default: "",
      },

      sentAt: {
        type: Date,
        default: null,
      },
    },
    {
      timestamps: true,
    }
  );

whatsappNotificationLogSchema.index({
  garageId: 1,
  reminderId: 1,
  type: 1,
});

whatsappNotificationLogSchema.index({
  garageId: 1,
  customerId: 1,
  createdAt: -1,
});

module.exports =
  mongoose.model(
    "WhatsAppNotificationLog",
    whatsappNotificationLogSchema
  );