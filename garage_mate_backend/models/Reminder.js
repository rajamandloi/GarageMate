const mongoose = require("mongoose");

const reminderSchema = new mongoose.Schema(
  {
    // ============================================================
    // GARAGE
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
      required: true,
      index: true,
    },

    // ============================================================
    // SERVICE
    // ============================================================

    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
      default: null,
      index: true,
    },

    // ============================================================
    // VEHICLE
    // ============================================================

    vehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vehicle",
      required: true,
      index: true,
    },

    // ============================================================
    // REMINDER TYPE
    // ============================================================

    type: {
      type: String,
      enum: [
        "service",
        "payment",
        "general",
        "specialOffer",
      ],
      required: true,
    },

    // ============================================================
    // DUE DATE
    // ============================================================

    dueDate: {
      type: Date,
      default: null,
    },

    // ============================================================
    // DUE MILEAGE
    // ============================================================

    dueMileage: {
      type: Number,
      default: null,
    },

    // ============================================================
    // TITLE
    // ============================================================

    title: {
      type: String,
      required: true,
      trim: true,
    },

    // ============================================================
    // MESSAGE
    // ============================================================

    message: {
      type: String,
      required: true,
      trim: true,
    },

    // ============================================================
    // STATUS
    // ============================================================

    status: {
      type: String,
      enum: [
        "upcoming",
        "dueSoon",
        "dueToday",
        "overdue",
        "completed",
        "cancelled",
      ],
      default: "upcoming",
    },
  },
  {
    timestamps: true,
  }
);

// ============================================================
// INDEXES
// ============================================================

reminderSchema.index({
  garageId: 1,
  dueDate: 1,
});

reminderSchema.index({
  garageId: 1,
  customerId: 1,
});

reminderSchema.index({
  garageId: 1,
  vehicleId: 1,
});

reminderSchema.index({
  garageId: 1,
  status: 1,
});

reminderSchema.index({
  garageId: 1,
  serviceId: 1,
  type: 1,
});

// ============================================================
// EXPORT
// ============================================================

module.exports = mongoose.model(
  "Reminder",
  reminderSchema
);