const mongoose = require("mongoose");

const registrationVerificationSchema =
  new mongoose.Schema(
    {
      garageName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 150,
      },

      ownerName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 120,
      },

      email: {
        type: String,
        required: true,
        lowercase: true,
        trim: true,
      },

      phone: {
        type: String,
        required: true,
        trim: true,
      },

      passwordHash: {
        type: String,
        required: true,
        select: false,
      },

      address: {
        type: String,
        default: "",
        trim: true,
        maxlength: 500,
      },

      city: {
        type: String,
        default: "",
        trim: true,
        maxlength: 100,
      },

      fcmToken: {
        type: String,
        default: null,
      },

      emailOtpHash: {
        type: String,
        default: null,
        select: false,
      },

      emailOtpExpires: {
        type: Date,
        default: null,
      },

      emailVerified: {
        type: Boolean,
        default: false,
      },

      otpAttempts: {
        type: Number,
        default: 0,
        min: 0,
        max: 10,
      },

      lastOtpSentAt: {
        type: Date,
        default: null,
      },
    },
    {
      timestamps: true,
    }
  );

// Automatically remove abandoned registration sessions.
registrationVerificationSchema.index(
  { createdAt: 1 },
  {
    expireAfterSeconds: 30 * 60,
  }
);

registrationVerificationSchema.index({
  email: 1,
});

registrationVerificationSchema.index({
  phone: 1,
});

module.exports = mongoose.model(
  "RegistrationVerification",
  registrationVerificationSchema
);