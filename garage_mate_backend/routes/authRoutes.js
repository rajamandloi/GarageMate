const express = require("express");

const protect = require("../middleware/authMiddleware");

const {
  loginRateLimiter,
  authRateLimiter,
  forgotPasswordRateLimiter,
  refreshRateLimiter,
  limitPasswordLength,
} = require("../middleware/securityMiddleware");

const {
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
} = require("../controllers/authController");

const router = express.Router();

// =====================================================
// LEGACY DIRECT REGISTRATION
// =====================================================

router.post(
  "/register",
  authRateLimiter,
  limitPasswordLength,
  register
);

// =====================================================
// EMAIL VERIFIED REGISTRATION FLOW
// =====================================================

// Step 1:
// Create temporary registration and send email OTP.
router.post(
  "/register/start",
  authRateLimiter,
  limitPasswordLength,
  startRegistration
);

// Step 2:
// Verify email OTP.
router.post(
  "/register/verify-email",
  authRateLimiter,
  verifyRegistrationEmail
);

// Resend email OTP.
router.post(
  "/register/resend-email",
  authRateLimiter,
  resendRegistrationEmailOtp
);

// Step 3:
// Complete registration after email verification.
// Mobile/Firebase verification is no longer required.
router.post(
  "/register/complete",
  authRateLimiter,
  completeRegistration
);

// =====================================================
// LOGIN
// =====================================================

router.post(
  "/login",
  loginRateLimiter,
  limitPasswordLength,
  login
);

// =====================================================
// REFRESH TOKEN
// =====================================================

router.post(
  "/refresh",
  refreshRateLimiter,
  refreshAccessToken
);

// =====================================================
// LOGOUT
// =====================================================

router.post(
  "/logout",
  authRateLimiter,
  logout
);

// =====================================================
// CURRENT USER
// =====================================================

router.get(
  "/me",
  protect,
  getMe
);

// =====================================================
// PROFILE
// =====================================================

router.put(
  "/profile",
  protect,
  authRateLimiter,
  limitPasswordLength,
  updateProfile
);

// =====================================================
// FORGOT PASSWORD
// =====================================================

router.post(
  "/forgot-password",
  forgotPasswordRateLimiter,
  forgotPassword
);

// =====================================================
// RESET PASSWORD
// =====================================================

router.post(
  "/reset-password",
  authRateLimiter,
  limitPasswordLength,
  resetPassword
);

// =====================================================
// FCM TOKEN
// =====================================================

router.post(
  "/fcm-token",
  protect,
  authRateLimiter,
  saveFcmToken
);

module.exports = router;