const express = require("express");

const protect = require("../middleware/authMiddleware");
const {
  sendTestNotification,
  debugFcmInfo,
  sendToSpecificToken,
} = require("../controllers/notificationController");

const router = express.Router();

// ============================================================
// NOTIFICATION ROUTES
// Base URL: /api/notifications
// ============================================================

// Get current user's FCM token info
router.get("/debug/fcm", protect, debugFcmInfo);

// Send test notification to logged-in user
router.post("/test", protect, sendTestNotification);

// Send to specific FCM token (admin)
router.post("/test-token", protect, sendToSpecificToken);

module.exports = router;