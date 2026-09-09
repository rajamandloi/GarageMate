const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    // Super Admin receiving this notification
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    type: {
      type: String,
      enum: [
        "new_registration",
        "garage_approved",
        "garage_suspended",
        "system",
      ],
      required: true,
    },

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

    // Related garage
    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      default: null,
    },

    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "Notification",
  notificationSchema
);