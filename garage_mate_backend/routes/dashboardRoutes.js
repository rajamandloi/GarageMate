const express = require("express");

const {
  getDashboardStats,
  getTodayTasks,
} = require("../controllers/dashboardController");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();

// ============================================================
// DASHBOARD ROUTES
// Base URL: /api/dashboard
// ============================================================

// Main dashboard stats
router.get("/", protect, requireGarage, getDashboardStats);

// Today's tasks
router.get(
  "/today-tasks",
  protect,
  requireGarage,
  getTodayTasks
);

module.exports = router;