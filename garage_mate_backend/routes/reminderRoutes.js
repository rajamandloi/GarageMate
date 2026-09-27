const express = require("express");

const {
  getReminders,
  getCustomerReminders,   // ✅ NAYA
  getVehicleReminders,    // ✅ NAYA
  getReminderById,
  createReminder,
  updateReminder,
  completeReminder,
  cancelReminder,
  deleteReminder,
  bulkDeleteReminders,
  deleteCompletedReminders,
} = require("../controllers/reminderController");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();

// ============================================================
// REMINDER ROUTES
// Base URL: /api/reminders
// ============================================================

// ⚠️ IMPORTANT ORDER:
// 1. Specific string routes pehle
// 2. Dynamic routes baad mein

// Delete all completed / cancelled reminders
router.delete(
  "/completed",
  protect,
  requireGarage,
  deleteCompletedReminders
);

// Bulk delete
router.post(
  "/bulk-delete",
  protect,
  requireGarage,
  bulkDeleteReminders
);

// ✅ Get customer reminders (NEW)
router.get(
  "/customer/:customerId",
  protect,
  requireGarage,
  getCustomerReminders
);

// ✅ Get vehicle reminders (NEW)
router.get(
  "/vehicle/:vehicleId",
  protect,
  requireGarage,
  getVehicleReminders
);

// Get all reminders
router.get("/", protect, requireGarage, getReminders);

// Get single reminder
router.get("/:id", protect, requireGarage, getReminderById);

// Create reminder
router.post("/", protect, requireGarage, createReminder);

// Update reminder
router.put("/:id", protect, requireGarage, updateReminder);

// Complete reminder
router.patch(
  "/:id/complete",
  protect,
  requireGarage,
  completeReminder
);

// Cancel reminder
router.patch(
  "/:id/cancel",
  protect,
  requireGarage,
  cancelReminder
);

// Delete single reminder
router.delete("/:id", protect, requireGarage, deleteReminder);

module.exports = router;