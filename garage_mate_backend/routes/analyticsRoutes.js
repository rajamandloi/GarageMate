const express = require("express");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const {
  getAnalyticsDashboard,
  getAnalyticsSummary,
} = require("../controllers/analyticsController");

const router = express.Router();

// ============================================================
// ANALYTICS ROUTES
// Base URL: /api/analytics
// ============================================================

// Full analytics dashboard
// Query params:
//   range: today | week | month | year | custom
//   startDate: YYYY-MM-DD (if range=custom)
//   endDate: YYYY-MM-DD (if range=custom)
router.get(
  "/dashboard",
  protect,
  requireGarage,
  getAnalyticsDashboard
);

// Quick summary
router.get(
  "/summary",
  protect,
  requireGarage,
  getAnalyticsSummary
);

module.exports = router;