const express = require("express");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");
const { createRateLimiter } = require("../middleware/securityMiddleware");

const webhookRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 120,
  message: "Too many webhook requests",
});

const sendRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 60,
  message: "Too many WhatsApp send requests. Please slow down.",
});

const {
  getIntegration,
  saveIntegration,
  disconnectWhatsApp,
  verifyWebhook,
  receiveWebhook,
  sendTemplateMessage,
  sendTemplateMessageWithPdf,
} = require("../controllers/whatsappController");

const router = express.Router();

// ============================================================
// GARAGE WHATSAPP SETTINGS
// ============================================================

router.get("/integration", protect, getIntegration);
router.put("/integration", protect, saveIntegration);
router.delete("/integration", protect, disconnectWhatsApp);

// ============================================================
// SEND MESSAGES
// ============================================================

router.post(
  "/send",
  protect,
  requireGarage,
  sendRateLimiter,
  sendTemplateMessage
);

router.post(
  "/send-with-pdf",
  protect,
  requireGarage,
  sendRateLimiter,
  sendTemplateMessageWithPdf
);

// ============================================================
// META WHATSAPP WEBHOOK
// ============================================================

router.get("/webhook", verifyWebhook);

router.post("/webhook", webhookRateLimiter, receiveWebhook);

module.exports = router;