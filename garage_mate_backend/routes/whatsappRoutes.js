const express = require("express");

const protect = require("../middleware/authMiddleware");
const { createRateLimiter } = require("../middleware/securityMiddleware");

const webhookRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 120,
  message: "Too many webhook requests",
});

const {
  getIntegration,
  saveIntegration,
  disconnectWhatsApp,
  verifyWebhook,
  receiveWebhook,
} = require("../controllers/whatsappController");

const router = express.Router();

// ============================================================
// GARAGE WHATSAPP SETTINGS
// ============================================================

// Get current garage WhatsApp configuration
router.get(
  "/integration",
  protect,
  getIntegration
);

// Save / update current garage WhatsApp configuration
router.put(
  "/integration",
  protect,
  saveIntegration
);

// Disconnect current garage WhatsApp
router.delete(
  "/integration",
  protect,
  disconnectWhatsApp
);


// ============================================================
// META WHATSAPP WEBHOOK
// ============================================================

// Meta webhook verification
router.get(
  "/webhook",
  verifyWebhook
);

// Meta webhook events
router.post(
  "/webhook",
  webhookRateLimiter,
  receiveWebhook
);


module.exports = router;