const mongoose = require("mongoose");

const invoiceSchema = new mongoose.Schema(
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
    // SOURCE SERVICE
    // ============================================================

    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
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
    // VEHICLE
    // ============================================================

    vehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vehicle",
      required: true,
      index: true,
    },

    // ============================================================
    // INVOICE NUMBER
    // ============================================================

    invoiceNumber: {
      type: String,
      required: true,
      trim: true,
    },

    // ============================================================
    // INVOICE DATE
    // ============================================================

    invoiceDate: {
      type: Date,
      default: Date.now,
    },

    // ============================================================
    // AMOUNTS
    // ============================================================

    subtotal: {
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
      required: true,
      min: 0,
    },

    paidAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    pendingAmount: {
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
        "pending",
        "partiallyPaid",
        "paid",
      ],
      default: "pending",
    },

    paymentMethod: {
      type: String,
      default: "Cash",
      trim: true,
    },


    pdfUrl: {
        type: String,
        default: null,
    },

    // ============================================================
    // WHATSAPP
    // ============================================================

    whatsappSent: {
      type: Boolean,
      default: false,
    },

    whatsappSentAt: {
      type: Date,
      default: null,
    },

    whatsappMessageId: {
      type: String,
      default: null,
    },

    // ============================================================
    // STATUS
    // ============================================================

    status: {
      type: String,
      enum: [
        "draft",
        "issued",
        "cancelled",
      ],
      default: "issued",
    },
  },
  {
    timestamps: true,
  }
);


// ============================================================
// INDEXES
// ============================================================

invoiceSchema.index({
  garageId: 1,
  invoiceNumber: 1,
});

invoiceSchema.index({
  garageId: 1,
  customerId: 1,
});



// One invoice per service per garage
invoiceSchema.index(
  {
    garageId: 1,
    serviceId: 1,
  },
  {
    unique: true,
  }
);


module.exports = mongoose.model(
  "Invoice",
  invoiceSchema
);