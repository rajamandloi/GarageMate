const mongoose = require("mongoose");

const vehicleSchema = new mongoose.Schema(
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

    registrationNumber: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    brand: {
      type: String,
      required: true,
      trim: true,
    },

    model: {
      type: String,
      required: true,
      trim: true,
    },

    variant: {
      type: String,
      trim: true,
      default: "",
    },

    manufacturingYear: {
      type: String,
      trim: true,
      default: "",
    },

    fuelType: {
      type: String,
      enum: [
        "Petrol",
        "Diesel",
        "CNG",
        "Electric",
        "Hybrid",
      ],
      default: "Petrol",
    },

    currentMileage: {
      type: Number,
      default: 0,
      min: 0,
    },

    vin: {
      type: String,
      trim: true,
      default: "",
    },

    engineNumber: {
      type: String,
      trim: true,
      default: "",
    },

    notes: {
      type: String,
      trim: true,
      default: "",
    },

    insuranceExpiry: {
      type: Date,
      default: null,
    },

    pucExpiry: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Vehicle", vehicleSchema);