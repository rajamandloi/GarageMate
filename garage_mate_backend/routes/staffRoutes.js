const express = require("express");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const {
  addStaff,
  listStaff,
  changeStaffRole,
  toggleStaffStatus,
  changeStaffPassword,
  removeStaff,
  getActivityLog,
} = require("../controllers/staffController");

const router = express.Router();

// ============================================================
// STAFF ROUTES
// Base URL: /api/staff
// ============================================================

// List staff
router.get(
  "/",
  protect,
  requireGarage,
  listStaff
);

// Activity log
router.get(
  "/activity",
  protect,
  requireGarage,
  getActivityLog
);

// Add staff
router.post(
  "/",
  protect,
  requireGarage,
  addStaff
);

// Update staff role
router.put(
  "/:id/role",
  protect,
  requireGarage,
  changeStaffRole
);

// Toggle staff active
router.patch(
  "/:id/toggle",
  protect,
  requireGarage,
  toggleStaffStatus
);

// Reset password
router.put(
  "/:id/password",
  protect,
  requireGarage,
  changeStaffPassword
);

// Delete staff
router.delete(
  "/:id",
  protect,
  requireGarage,
  removeStaff
);

module.exports = router;