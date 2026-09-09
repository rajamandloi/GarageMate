const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      default: null,
      trim: true,
    },

    emailVerified: {
      type: Boolean,
      default: false,
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
      maxlength: 128,
    },

    role: {
      type: String,
      enum: [
        "super_admin",
        "garage_owner",
        "staff",
      ],
      default: "garage_owner",
    },

    garageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Garage",
      default: null,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    fcmToken: {
      type: String,
      default: null,
    },

    lastLogin: {
      type: Date,
      default: null,
    },

    sessionVersion: {
      type: Number,
      default: 0,
      min: 0,
    },

    refreshTokenHash: {
      type: String,
      default: null,
      select: false,
    },

    refreshTokenExpires: {
      type: Date,
      default: null,
      select: false,
    },

    passwordResetToken: {
      type: String,
      default: null,
      select: false,
    },

    passwordResetExpires: {
      type: Date,
      default: null,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

userSchema.index(
  { phone: 1 },
  {
    unique: true,
    partialFilterExpression: {
      phone: {
        $exists: true,
        $ne: "",
      },
    },
  }
);

module.exports = mongoose.model(
  "User",
  userSchema
);