const express = require("express");

const {
  getReminders,
  getCustomerReminders,
  getVehicleReminders,
  createReminder,
  updateReminder,
  completeReminder,
  cancelReminder,
  deleteReminder,
} = require("../controllers/reminderController");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();

router.get(
  "/",
  protect,
  requireGarage,
  getReminders
);

router.get(
  "/customer/:customerId",
  protect,
  requireGarage,
  getCustomerReminders
);

router.get(
  "/vehicle/:vehicleId",
  protect,
  requireGarage,
  getVehicleReminders
);

router.post(
  "/",
  protect,
  requireGarage,
  createReminder
);

router.put(
  "/:id",
  protect,
  requireGarage,
  updateReminder
);

router.patch(
  "/:id/complete",
  protect,
  requireGarage,
  completeReminder
);

router.patch(
  "/:id/cancel",
  protect,
  requireGarage,
  cancelReminder
);

router.delete(
  "/:id",
  protect,
  requireGarage,
  deleteReminder
);

module.exports = router;