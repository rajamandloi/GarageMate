const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const dns = require("dns").promises;

const User = require("../models/User");
const Garage = require("../models/Garage");
const RegistrationVerification = require("../models/RegistrationVerification");

const {
  sendPasswordResetEmail,
  sendRegistrationOtpEmail,
} = require("../services/emailService");

const {
  sendPushNotification,
} = require("../services/firebaseNotificationService");

// =====================================================
// TOKEN CONFIGURATION
// =====================================================

const ACCESS_TOKEN_EXPIRES_IN = "15m";

const REFRESH_TOKEN_DURATION_MS =
  365 * 24 * 60 * 60 * 1000;

// =====================================================
// CREATE ACCESS TOKEN
// =====================================================

const createAccessToken = (user) => {
  return jwt.sign(
    {
      userId: user._id,
      role: user.role,
      garageId: user.garageId,
      sessionVersion: Number(user.sessionVersion || 0),
    },
    process.env.JWT_SECRET,
    {
      expiresIn: ACCESS_TOKEN_EXPIRES_IN,
      algorithm: "HS256",
      issuer: process.env.JWT_ISSUER || "garagemate-api",
      audience: process.env.JWT_AUDIENCE || "garagemate-app",
      jwtid: crypto.randomUUID(),
    }
  );
};

// =====================================================
// CREATE REFRESH TOKEN
// =====================================================

const createRefreshToken = () => {
  return crypto.randomBytes(64).toString("hex");
};

// =====================================================
// HASH REFRESH TOKEN
// =====================================================

const hashRefreshToken = (refreshToken) => {
  return crypto
    .createHash("sha256")
    .update(refreshToken)
    .digest("hex");
};

// =====================================================
// SAVE REFRESH TOKEN
// =====================================================

const saveRefreshToken = async (user, refreshToken) => {
  user.refreshTokenHash = hashRefreshToken(refreshToken);

  user.refreshTokenExpires = new Date(
    Date.now() + REFRESH_TOKEN_DURATION_MS
  );

  await user.save();
};

// =====================================================
// CLEAR REFRESH TOKEN
// =====================================================

const clearRefreshToken = async (user) => {
  user.refreshTokenHash = null;
  user.refreshTokenExpires = null;

  await user.save();
};

// =====================================================
// REGISTRATION VERIFICATION HELPERS
// =====================================================

const REGISTRATION_OTP_DURATION_MS = 10 * 60 * 1000;
const REGISTRATION_OTP_RESEND_MS = 60 * 1000;
const MAX_REGISTRATION_OTP_ATTEMPTS = 5;

// =====================================================
// NORMALIZE PHONE
// =====================================================

const normalizePhone = (value) => {
  const raw = String(value || "").trim();
  const digits = raw.replace(/\D/g, "");

  if (/^\+91\d{10}$/.test(raw)) {
    return raw;
  }

  if (/^91\d{10}$/.test(digits)) {
    return `+${digits}`;
  }

  if (/^\d{10}$/.test(digits)) {
    return `+91${digits}`;
  }

  return null;
};

// =====================================================
// EMAIL VALIDATION
// =====================================================

const isValidEmailSyntax = (email) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
};

// =====================================================
// CHECK EMAIL DOMAIN
// =====================================================

const hasMailExchange = async (email) => {
  const domain = email.split("@")[1];

  try {
    const records = await dns.resolveMx(domain);

    return Array.isArray(records) && records.length > 0;
  } catch {
    return false;
  }
};

// =====================================================
// GENERATE EMAIL OTP
// =====================================================

const generateOtp = () => {
  return crypto.randomInt(100000, 1000000).toString();
};

// =====================================================
// HASH OTP
// =====================================================

const hashOtp = (otp) => {
  return crypto
    .createHash("sha256")
    .update(otp)
    .digest("hex");
};

// =====================================================
// SAFE OTP COMPARISON
// =====================================================

const safeOtpEqual = (plainOtp, hashedOtp) => {
  const incoming = Buffer.from(
    hashOtp(plainOtp),
    "hex"
  );

  const stored = Buffer.from(
    hashedOtp || "",
    "hex"
  );

  return (
    incoming.length === stored.length &&
    crypto.timingSafeEqual(incoming, stored)
  );
};

// =====================================================
// START REGISTRATION
// =====================================================

const startRegistration = async (req, res) => {
  try {
    const {
      garageName,
      ownerName,
      email,
      phone,
      password,
      address,
      city,
    } = req.body;

    if (
      !garageName ||
      !ownerName ||
      !email ||
      !phone ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message:
          "All required registration fields must be provided",
      });
    }

    if (
      typeof password !== "string" ||
      password.length < 6 ||
      password.length > 128
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Password must be between 6 and 128 characters",
      });
    }

    const normalizedEmail =
      String(email)
        .toLowerCase()
        .trim();

    const normalizedPhone =
      normalizePhone(phone);

    if (!isValidEmailSyntax(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message:
          "Please enter a valid email address",
      });
    }

    if (!normalizedPhone) {
      return res.status(400).json({
        success: false,
        message:
          "Please enter a valid Indian mobile number",
      });
    }

    // Verify that the email domain can receive email.
    if (!(await hasMailExchange(normalizedEmail))) {
      return res.status(400).json({
        success: false,
        message:
          "This email domain cannot receive email. Please use a valid email address.",
      });
    }

    const [
      existingUserByEmail,
      existingUserByPhone,
    ] = await Promise.all([
      User.findOne({
        email: normalizedEmail,
      }).select("_id"),

      User.findOne({
        phone: normalizedPhone,
      }).select("_id"),
    ]);

    if (existingUserByEmail) {
      return res.status(409).json({
        success: false,
        message:
          "Email already registered",
      });
    }

    if (existingUserByPhone) {
      return res.status(409).json({
        success: false,
        message:
          "Mobile number already registered",
      });
    }

    const now = Date.now();

    const existingPending =
      await RegistrationVerification.findOne({
        email: normalizedEmail,
      }).select(
        "+passwordHash +emailOtpHash emailOtpExpires lastOtpSentAt"
      );

    if (
      existingPending &&
      existingPending.lastOtpSentAt
    ) {
      const elapsed =
        now -
        existingPending.lastOtpSentAt.getTime();

      if (
        elapsed <
        REGISTRATION_OTP_RESEND_MS
      ) {
        return res.status(429).json({
          success: false,
          message: `Please wait ${Math.ceil(
            (REGISTRATION_OTP_RESEND_MS -
              elapsed) /
              1000
          )} seconds before requesting another OTP`,
        });
      }
    }

    const passwordHash =
      await bcrypt.hash(password, 12);

    const otp = generateOtp();

    const registration =
      existingPending ||
      new RegistrationVerification();

    registration.garageName =
      String(garageName).trim();

    registration.ownerName =
      String(ownerName).trim();

    registration.email =
      normalizedEmail;

    registration.phone =
      normalizedPhone;

    registration.passwordHash =
      passwordHash;

    registration.address =
      String(address || "").trim();

    registration.city =
      String(city || "").trim();

    registration.emailOtpHash =
      hashOtp(otp);

    registration.emailOtpExpires =
      new Date(
        now +
          REGISTRATION_OTP_DURATION_MS
      );

    registration.emailVerified =
      false;

    registration.otpAttempts = 0;

    registration.lastOtpSentAt =
      new Date(now);

    await registration.save();

    await sendRegistrationOtpEmail({
      to: normalizedEmail,
      ownerName: registration.ownerName,
      otp,
    });

    return res.status(201).json({
      success: true,
      message:
        "Verification started. Check your email for the OTP.",
      registrationId:
        registration._id,
      email: normalizedEmail,
      phone: normalizedPhone,
      emailOtpExpiresIn: "10m",
    });
  } catch (error) {
    console.error(
      "Start registration error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to start registration",
    });
  }
};

// =====================================================
// VERIFY EMAIL OTP
// =====================================================

const verifyRegistrationEmail = async (
  req,
  res
) => {
  try {
    const {
      registrationId,
      otp,
    } = req.body;

    if (
      !registrationId ||
      !/^\d{6}$/.test(
        String(otp || "")
      )
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Registration ID and a 6-digit OTP are required",
      });
    }

    const registration =
      await RegistrationVerification.findById(
        registrationId
      ).select("+emailOtpHash");

    if (!registration) {
      return res.status(404).json({
        success: false,
        message:
          "Registration verification session not found or expired",
      });
    }

    if (registration.emailVerified) {
      return res.json({
        success: true,
        message:
          "Email is already verified",
        emailVerified: true,
      });
    }

    if (
      registration.otpAttempts >=
      MAX_REGISTRATION_OTP_ATTEMPTS
    ) {
      return res.status(429).json({
        success: false,
        message:
          "Too many incorrect OTP attempts. Please restart registration.",
      });
    }

    if (
      !registration.emailOtpExpires ||
      registration.emailOtpExpires.getTime() <
        Date.now()
    ) {
      return res.status(400).json({
        success: false,
        message:
          "OTP has expired. Please request a new OTP.",
      });
    }

    if (
      !safeOtpEqual(
        String(otp),
        registration.emailOtpHash
      )
    ) {
      registration.otpAttempts += 1;

      await registration.save();

      return res.status(400).json({
        success: false,
        message:
          "Invalid OTP",
      });
    }

    registration.emailVerified =
      true;

    registration.emailOtpHash =
      undefined;

    registration.emailOtpExpires =
      undefined;

    registration.otpAttempts = 0;

    await registration.save();

    return res.json({
      success: true,
      message:
        "Email verified successfully",
      emailVerified: true,
    });
  } catch (error) {
    console.error(
      "Verify registration email error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to verify email",
    });
  }
};

// =====================================================
// RESEND REGISTRATION EMAIL OTP
// =====================================================

const resendRegistrationEmailOtp = async (
  req,
  res
) => {
  try {
    const {
      registrationId,
    } = req.body;

    if (!registrationId) {
      return res.status(400).json({
        success: false,
        message:
          "Registration ID is required",
      });
    }

    const registration =
      await RegistrationVerification.findById(
        registrationId
      );

    if (!registration) {
      return res.status(404).json({
        success: false,
        message:
          "Registration verification session not found or expired",
      });
    }

    if (registration.emailVerified) {
      return res.status(400).json({
        success: false,
        message:
          "Email is already verified",
      });
    }

    const elapsed =
      registration.lastOtpSentAt
        ? Date.now() -
          registration.lastOtpSentAt.getTime()
        : REGISTRATION_OTP_RESEND_MS;

    if (
      elapsed <
      REGISTRATION_OTP_RESEND_MS
    ) {
      return res.status(429).json({
        success: false,
        message: `Please wait ${Math.ceil(
          (REGISTRATION_OTP_RESEND_MS -
            elapsed) /
            1000
        )} seconds before requesting another OTP`,
      });
    }

    const otp = generateOtp();

    registration.emailOtpHash =
      hashOtp(otp);

    registration.emailOtpExpires =
      new Date(
        Date.now() +
          REGISTRATION_OTP_DURATION_MS
      );

    registration.otpAttempts = 0;

    registration.lastOtpSentAt =
      new Date();

    await registration.save();

    await sendRegistrationOtpEmail({
      to: registration.email,
      ownerName:
        registration.ownerName,
      otp,
    });

    return res.json({
      success: true,
      message:
        "A new email verification OTP has been sent",
      emailOtpExpiresIn: "10m",
    });
  } catch (error) {
    console.error(
      "Resend registration email OTP error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to resend verification OTP",
    });
  }
};

// =====================================================
// VERIFY PHONE
// REMOVED
// =====================================================

// Mobile/Firebase verification has intentionally been
// removed from the registration flow.
//
// Email verification is now the only verification
// required before account creation.

// =====================================================
// COMPLETE VERIFIED REGISTRATION
// =====================================================

const completeRegistration = async (
  req,
  res
) => {
  try {
    const {
      registrationId,
      fcmToken,
    } = req.body;

    if (!registrationId) {
      return res.status(400).json({
        success: false,
        message:
          "Registration ID is required",
      });
    }

    const registration =
      await RegistrationVerification.findById(
        registrationId
      ).select("+passwordHash");

    if (!registration) {
      return res.status(404).json({
        success: false,
        message:
          "Registration verification session not found or expired",
      });
    }

    // Only email verification is required.
    if (!registration.emailVerified) {
      return res.status(400).json({
        success: false,
        message:
          "Email must be verified before account creation",
      });
    }

    const [
      existingUserByEmail,
      existingUserByPhone,
    ] = await Promise.all([
      User.findOne({
        email: registration.email,
      }).select("_id"),

      User.findOne({
        phone: registration.phone,
      }).select("_id"),
    ]);

    if (existingUserByEmail) {
      return res.status(409).json({
        success: false,
        message:
          "Email already registered",
      });
    }

    if (existingUserByPhone) {
      return res.status(409).json({
        success: false,
        message:
          "Mobile number already registered",
      });
    }

    // =================================================
    // CREATE GARAGE
    // =================================================

    const garage =
      await Garage.create({
        name:
          registration.garageName,

        ownerName:
          registration.ownerName,

        phone:
          registration.phone,

        email:
          registration.email,

        address:
          registration.address || "",

        city:
          registration.city || "",

        status: "pending",
      });

    let user;

    try {
      user = await User.create({
        name:
          registration.ownerName,

        email:
          registration.email,

        phone:
          registration.phone,

        password:
          registration.passwordHash,

        role:
          "garage_owner",

        garageId:
          garage._id,

        isActive:
          true,

        // Email is verified.
        emailVerified:
          true,

        // No Firebase/mobile verification.
        fcmToken:
          fcmToken || null,
      });
    } catch (userError) {
      await Garage.findByIdAndDelete(
        garage._id
      );

      throw userError;
    }

    // =================================================
    // NOTIFY SUPER ADMIN
    // =================================================

    try {
      const superAdmins =
        await User.find({
          role: "super_admin",
          isActive: true,
          fcmToken: {
            $ne: null,
          },
        }).select(
          "fcmToken name"
        );

      for (const adminUser of superAdmins) {
        await sendPushNotification({
          fcmToken:
            adminUser.fcmToken,

          title:
            "New Garage Registration 🔔",

          body:
            `${garage.name} has submitted a verified registration request.`,

          data: {
            type:
              "new_garage_registration",

            garageId:
              garage._id.toString(),

            ownerName:
              registration.ownerName,

            garageName:
              garage.name,
          },
        });
      }
    } catch (notificationError) {
      console.error(
        "Super Admin notification error:",
        notificationError
      );
    }

    // Delete temporary verification record.
    await RegistrationVerification.findByIdAndDelete(
      registration._id
    );

    return res.status(201).json({
      success: true,

      message:
        "Registration successful. Email is verified. Waiting for admin approval.",

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        garageId: user.garageId,
        emailVerified: true,
      },

      garage: {
        id: garage._id,
        status: garage.status,
      },
    });
  } catch (error) {
    console.error(
      "Complete registration error:",
      error
    );

    if (
      error &&
      error.code === 11000
    ) {
      return res.status(409).json({
        success: false,
        message:
          "Email or mobile number is already registered",
      });
    }

    return res.status(500).json({
      success: false,
      message:
        "Unable to complete registration",
    });
  }
};

// =====================================================
// DIRECT REGISTER - DISABLED
// =====================================================

const register = async (
  req,
  res
) => {
  return res.status(400).json({
    success: false,
    message:
      "Direct registration is disabled. Please complete email verification first.",
    verificationRequired: true,
    nextStep:
      "/api/auth/register/start",
  });
};

// =====================================================
// LOGIN
// =====================================================

const login = async (
  req,
  res
) => {
  try {
    const {
      email,
      password,
    } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message:
          "Email and password are required",
      });
    }

    const normalizedEmail =
      email.toLowerCase().trim();

    if (
      typeof password !== "string" ||
      password.length > 128
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid email or password",
      });
    }

    const user =
      await User.findOne({
        email:
          normalizedEmail,
      }).select(
        "+password +refreshTokenHash +refreshTokenExpires"
      );

    if (!user) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid email or password",
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message:
          "Account is inactive",
      });
    }

    // Only email verification is required.
   

    const passwordMatch =
      await bcrypt.compare(
        password,
        user.password
      );

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid email or password",
      });
    }

    let garage = null;

    if (user.garageId) {
      garage =
        await Garage.findById(
          user.garageId
        );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message:
            "Garage not found",
        });
      }

      if (
        user.role ===
          "garage_owner" &&
        garage.status ===
          "pending"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Your garage is waiting for admin approval",
        });
      }

      if (
        user.role ===
          "garage_owner" &&
        garage.status ===
          "suspended"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Your garage account has been suspended",
        });
      }

      if (!garage.isActive) {
        return res.status(403).json({
          success: false,
          message:
            "Garage account is inactive",
        });
      }
    }

    const accessToken =
      createAccessToken(user);

    const refreshToken =
      createRefreshToken();

    await saveRefreshToken(
      user,
      refreshToken
    );

    user.lastLogin =
      new Date();

    await user.save();

    return res.json({
      success: true,

      message:
        "Login successful",

      accessToken,

      refreshToken,

      accessTokenExpiresIn:
        ACCESS_TOKEN_EXPIRES_IN,

      refreshTokenExpiresIn:
        "365d",

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        garageId: user.garageId,
      },
    });
  } catch (error) {
    console.error(
      "Login error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Login failed",
    });
  }
};

// =====================================================
// REFRESH ACCESS TOKEN
// =====================================================

const refreshAccessToken = async (
  req,
  res
) => {
  try {
    const {
      refreshToken,
    } = req.body;

    if (
      typeof refreshToken !== "string" ||
      refreshToken.length < 32 ||
      refreshToken.length > 256
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid refresh token",
      });
    }

    const refreshTokenHash =
      hashRefreshToken(
        refreshToken
      );

    const now =
      new Date();

    const newRefreshToken =
      createRefreshToken();

    const newRefreshTokenHash =
      hashRefreshToken(
        newRefreshToken
      );

    const newExpiry =
      new Date(
        Date.now() +
          REFRESH_TOKEN_DURATION_MS
      );

    const user =
      await User.findOneAndUpdate(
        {
          refreshTokenHash,
          refreshTokenExpires: {
            $gt: now,
          },
          isActive: true,
        },
        {
          $set: {
            refreshTokenHash:
              newRefreshTokenHash,

            refreshTokenExpires:
              newExpiry,
          },
        },
        {
          new: true,
        }
      ).select(
        "+refreshTokenHash +refreshTokenExpires"
      );

    if (!user) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid or expired refresh token",
      });
    }

    let garage = null;

    if (user.garageId) {
      garage =
        await Garage.findById(
          user.garageId
        );

      if (!garage) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },
          }
        );

        return res.status(404).json({
          success: false,
          message:
            "Garage not found",
        });
      }

      if (
        user.role ===
          "garage_owner" &&
        garage.status ===
          "pending"
      ) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },
          }
        );

        return res.status(403).json({
          success: false,
          message:
            "Your garage is waiting for admin approval",
        });
      }

      if (
        user.role ===
          "garage_owner" &&
        garage.status ===
          "suspended"
      ) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },
          }
        );

        return res.status(403).json({
          success: false,
          message:
            "Your garage account has been suspended",
        });
      }

      if (!garage.isActive) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },
          }
        );

        return res.status(403).json({
          success: false,
          message:
            "Garage account is inactive",
        });
      }
    }

    const newAccessToken =
      createAccessToken(user);

    return res.json({
      success: true,
      message:
        "Token refreshed successfully",

      accessToken:
        newAccessToken,

      refreshToken:
        newRefreshToken,

      accessTokenExpiresIn:
        ACCESS_TOKEN_EXPIRES_IN,

      refreshTokenExpiresIn:
        "365d",
    });
  } catch (error) {
    console.error(
      "Refresh token error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to refresh session",
    });
  }
};

// =====================================================
// LOGOUT
// =====================================================

const logout = async (
  req,
  res
) => {
  try {
    const {
      refreshToken,
    } = req.body;

    if (
      refreshToken &&
      typeof refreshToken ===
        "string"
    ) {
      const refreshTokenHash =
        hashRefreshToken(
          refreshToken
        );

      const user =
        await User.findOne({
          refreshTokenHash,
        }).select(
          "+refreshTokenHash +refreshTokenExpires"
        );

      if (user) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },

            $inc: {
              sessionVersion: 1,
            },
          }
        );
      }
    }

    if (req.user) {
      const user =
        await User.findById(
          req.user._id
        ).select(
          "+refreshTokenHash +refreshTokenExpires"
        );

      if (user) {
        await User.findByIdAndUpdate(
          user._id,
          {
            $set: {
              refreshTokenHash:
                null,

              refreshTokenExpires:
                null,
            },

            $inc: {
              sessionVersion: 1,
            },
          }
        );
      }
    }

    return res.json({
      success: true,
      message:
        "Logout successful",
    });
  } catch (error) {
    console.error(
      "Logout error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to logout",
    });
  }
};

// =====================================================
// GET CURRENT USER
// =====================================================

const getMe = async (
  req,
  res
) => {
  try {
    let garage = null;

    if (req.user.garageId) {
      garage =
        await Garage.findById(
          req.user.garageId
        );
    }

    return res.json({
      success: true,

      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        phone: req.user.phone,
        role: req.user.role,
        garageId:
          req.user.garageId,
        garage,
      },
    });
  } catch (error) {
    console.error(
      "Get user error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to get user details",
    });
  }
};

// =====================================================
// UPDATE PROFILE
// =====================================================

const updateProfile = async (
  req,
  res
) => {
  try {
    const {
      phone,
      garageName,
      ownerName,
      garagePhone,
      garageEmail,
      garageAddress,
      city,
    } = req.body;

    const user =
      await User.findById(
        req.user._id
      );

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          "User not found",
      });
    }

    let garage = null;

    if (phone !== undefined) {
      user.phone =
        String(phone).trim();
    }

    if (user.garageId) {
      garage =
        await Garage.findById(
          user.garageId
        );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message:
            "Garage not found",
        });
      }

      if (
        garageName !== undefined
      ) {
        garage.name =
          String(
            garageName
          ).trim();
      }

      if (
        ownerName !== undefined
      ) {
        garage.ownerName =
          String(
            ownerName
          ).trim();

        user.name =
          String(
            ownerName
          ).trim();
      }

      if (
        garagePhone !== undefined
      ) {
        garage.phone =
          String(
            garagePhone
          ).trim();
      }

      if (
        garageEmail !== undefined
      ) {
        garage.email =
          String(
            garageEmail
          )
            .trim()
            .toLowerCase();
      }

      if (
        garageAddress !== undefined
      ) {
        garage.address =
          String(
            garageAddress
          ).trim();
      }

      if (city !== undefined) {
        garage.city =
          String(city).trim();
      }

      await garage.save();
    }

    await user.save();

    if (user.garageId) {
      garage =
        await Garage.findById(
          user.garageId
        );
    }

    return res.json({
      success: true,
      message:
        "Profile updated successfully",

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        garageId:
          user.garageId,
        garage,
      },
    });
  } catch (error) {
    console.error(
      "Update profile error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to update profile",
    });
  }
};

// =====================================================
// FORGOT PASSWORD
// =====================================================

const forgotPassword = async (
  req,
  res
) => {
  try {
    const {
      email,
    } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message:
          "Email is required",
      });
    }

    const normalizedEmail =
      email.toLowerCase().trim();

    const user =
      await User.findOne({
        email:
          normalizedEmail,
      });

    if (!user) {
      return res.json({
        success: true,
        message:
          "If an account exists with this email, a password reset email has been sent.",
      });
    }

    const resetToken =
      crypto
        .randomBytes(32)
        .toString("hex");

    const hashedToken =
      crypto
        .createHash("sha256")
        .update(resetToken)
        .digest("hex");

    user.passwordResetToken =
      hashedToken;

    user.passwordResetExpires =
      new Date(
        Date.now() +
          15 * 60 * 1000
      );

    await user.save();

    await sendPasswordResetEmail({
      to: user.email,
      resetToken,
    });

    return res.json({
      success: true,
      message:
        "If an account exists with this email, a password reset email has been sent.",
    });
  } catch (error) {
    console.error(
      "Forgot password error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to send password reset email",
    });
  }
};

// =====================================================
// RESET PASSWORD
// =====================================================

const resetPassword = async (
  req,
  res
) => {
  try {
    const {
      token,
      password,
    } = req.body;

    if (!token || !password) {
      return res.status(400).json({
        success: false,
        message:
          "Token and new password are required",
      });
    }

    if (
      typeof password !== "string" ||
      password.length < 6 ||
      password.length > 128
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Password must be between 6 and 128 characters",
      });
    }

    const hashedToken =
      crypto
        .createHash("sha256")
        .update(token)
        .digest("hex");

    const user =
      await User.findOne({
        passwordResetToken:
          hashedToken,

        passwordResetExpires: {
          $gt: new Date(),
        },
      });

    if (!user) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid or expired password reset token",
      });
    }

    user.password =
      await bcrypt.hash(
        password,
        12
      );

    user.passwordResetToken =
      null;

    user.passwordResetExpires =
      null;

    user.refreshTokenHash =
      null;

    user.refreshTokenExpires =
      null;

    user.sessionVersion =
      Number(
        user.sessionVersion || 0
      ) + 1;

    await user.save();

    return res.json({
      success: true,
      message:
        "Password reset successful. You can now login with your new password.",
    });
  } catch (error) {
    console.error(
      "Reset password error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to reset password",
    });
  }
};

// =====================================================
// SAVE FCM TOKEN
// =====================================================

const saveFcmToken = async (
  req,
  res
) => {
  try {
    const {
      fcmToken,
    } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message:
          "FCM token is required",
      });
    }

    const user =
      await User.findById(
        req.user._id
      );

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          "User not found",
      });
    }

    user.fcmToken =
      fcmToken;

    await user.save();

    return res.json({
      success: true,
      message:
        "FCM token saved successfully",
    });
  } catch (error) {
    console.error(
      "Save FCM token error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to save FCM token",
    });
  }
};

// =====================================================
// EXPORT
// =====================================================

module.exports = {
  register,
  startRegistration,
  verifyRegistrationEmail,
  resendRegistrationEmailOtp,
  completeRegistration,
  login,
  refreshAccessToken,
  logout,
  getMe,
  updateProfile,
  forgotPassword,
  resetPassword,
  saveFcmToken,
};