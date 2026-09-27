const mongoose = require("mongoose");

const garageSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    ownerName: {
      type: String,
      required: true,
      trim: true,
    },

    phone: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
    },

    address: {
      type: String,
      default: "",
      trim: true,
    },

    city: {
      type: String,
      default: "",
      trim: true,
    },

    status: {
      type: String,
      enum: ["active", "suspended", "pending"],
      default: "pending",
    },

    subscriptionPlan: {
      type: String,
      enum: ["trial", "basic", "premium"],
      default: "trial",
    },

    subscriptionExpiry: {
      type: Date,
      default: null,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    profileImage: {
      type: String,
      default: "",
    },

    // ============================================================
    // INVOICE BRANDING SETTINGS
    // ============================================================

    invoiceSettings: {
      // Logo URL (uploaded separately)
      logo: {
        type: String,
        default: "",
      },

      // Brand colors (hex)
      primaryColor: {
        type: String,
        default: "#4A6CF7",
        trim: true,
      },

      secondaryColor: {
        type: String,
        default: "#25D366",
        trim: true,
      },

      // Custom footer message
      footerMessage: {
        type: String,
        default:
          "Thank you for choosing our garage!",
        trim: true,
        maxlength: 200,
      },

      // Terms & Conditions
      termsAndConditions: {
        type: String,
        default: "",
        trim: true,
        maxlength: 500,
      },

      // UPI ID for QR code
      upiId: {
        type: String,
        default: "",
        trim: true,
      },
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "Garage",
  garageSchema
);