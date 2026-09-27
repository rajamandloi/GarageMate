const mongoose = require("mongoose");

const activityLogSchema = new mongoose.Schema(
  {
    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      required: true,
      index: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    userName: {
      type: String,
      default: "",
      trim: true,
    },

    userRole: {
      type: String,
      default: "",
      trim: true,
    },

    action: {
      type: String,
      required: true,
      index: true,
      // Example: "service.create", "customer.update", "payment.delete"
    },

    entity: {
      type: String,
      default: "",
      trim: true,
      // Example: "service", "customer", "invoice"
    },

    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },

    description: {
      type: String,
      default: "",
      trim: true,
      maxlength: 500,
    },

    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

activityLogSchema.index({
  garageId: 1,
  createdAt: -1,
});

activityLogSchema.index({
  garageId: 1,
  userId: 1,
  createdAt: -1,
});

module.exports = mongoose.model(
  "ActivityLog",
  activityLogSchema
);