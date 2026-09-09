const express = require("express");

const {
  getDashboardStats,
} = require("../controllers/dashboardController");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();

// ============================================================
// DASHBOARD STATS
// GET /api/dashboard/stats
// ============================================================

router.get(
  "/stats",
  protect,
  requireGarage,
  getDashboardStats
);

module.exports = router;