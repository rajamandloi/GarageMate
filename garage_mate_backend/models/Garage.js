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
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Garage", garageSchema);