const mongoose = require("mongoose");

const serviceSchema = new mongoose.Schema(
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
    },

    // ============================================================
    // VEHICLE
    // ============================================================

    vehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vehicle",
      required: true,
    },

    // ============================================================
    // SERVICE DATE
    // ============================================================

    serviceDate: {
      type: Date,
      default: Date.now,
      required: true,
    },

    // ============================================================
    // SERVICE TYPE
    // ============================================================

    serviceType: {
      type: String,
      required: true,
      trim: true,
    },

    // ============================================================
    // MILEAGE
    // ============================================================

    mileage: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ============================================================
    // DESCRIPTION
    // ============================================================

    description: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // PARTS USED
    // ============================================================

    partsUsed: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // COSTS
    // ============================================================

    laborCost: {
      type: Number,
      default: 0,
      min: 0,
    },

    partsCost: {
      type: Number,
      default: 0,
      min: 0,
    },

    discount: {
      type: Number,
      default: 0,
      min: 0,
    },

    tax: {
      type: Number,
      default: 0,
      min: 0,
    },

    totalAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    paidAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ============================================================
    // PAYMENT
    // ============================================================

    paymentStatus: {
      type: String,
      enum: [
        "paid",
        "partiallyPaid",
        "pending",
      ],
      default: "pending",
    },

    paymentMethod: {
      type: String,
      enum: [
        "Cash",
        "UPI",
        "Card",
        "Bank Transfer",
        "Other",
      ],
      default: "Cash",
    },

    // ============================================================
    // NEXT SERVICE
    // ============================================================

    nextServiceDate: {
      type: Date,
      default: null,
    },

    nextServiceMileage: {
      type: Number,
      default: null,
    },

    // ============================================================
    // MECHANIC
    // ============================================================

    mechanic: {
      type: String,
      default: "",
      trim: true,
    },

    // ============================================================
    // NOTES
    // ============================================================

    notes: {
      type: String,
      default: "",
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// ============================================================
// INDEXES
// ============================================================

serviceSchema.index({
  garageId: 1,
  serviceDate: -1,
});

serviceSchema.index({
  garageId: 1,
  customerId: 1,
});

serviceSchema.index({
  garageId: 1,
  vehicleId: 1,
});

serviceSchema.index({
  garageId: 1,
  paymentStatus: 1,
});

// ============================================================
// AUTOMATIC PAYMENT STATUS
// ============================================================

serviceSchema.pre(
  "save",
  async function () {
    // Keep paid amount within invoice total.
    if (this.paidAmount > this.totalAmount) {
      this.paidAmount = this.totalAmount;
    }

    if (this.paidAmount <= 0) {
      this.paymentStatus = "pending";
    } else if (
      this.paidAmount >= this.totalAmount &&
      this.totalAmount > 0
    ) {
      this.paymentStatus = "paid";
    } else {
      this.paymentStatus =
        "partiallyPaid";
    }
  }
);

// ============================================================
// EXPORT
// ============================================================

module.exports = mongoose.model(
  "Service",
  serviceSchema
);