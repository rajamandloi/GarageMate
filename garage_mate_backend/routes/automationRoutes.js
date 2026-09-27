const express = require("express");

const protect = require("../middleware/authMiddleware");
const requireGarage = require(
  "../middleware/garageMiddleware"
);
const {
  createRateLimiter,
} = require("../middleware/securityMiddleware");

const sendRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 5,
  message:
    "Too many send requests. Please wait before trying again.",
});

const {
  getSettings,
  updateSettings,
  sendNow,
} = require("../controllers/automationController");

const router = express.Router();

// ============================================================
// AUTOMATION ROUTES
// Base URL: /api/automation
// ============================================================

router.get(
  "/settings",
  protect,
  requireGarage,
  getSettings
);

router.put(
  "/settings",
  protect,
  requireGarage,
  updateSettings
);

router.post(
  "/send-now",
  protect,
  requireGarage,
  sendRateLimiter,
  sendNow
);

module.exports = router;