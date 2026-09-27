const express = require("express");

const {
  getServices,
  getServiceById,
  getCustomerServices,
  getVehicleServices,
  createService,
  updateService,
  deleteService,
} = require("../controllers/serviceController");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");
const requireStaffRole = require("../middleware/requireStaffRole");

const router = express.Router();

// ============================================================
// SERVICE ROUTES
// Base URL: /api/services
// ============================================================

// Get all services
router.get("/", protect, requireGarage, getServices);

// Get services for a specific customer
router.get(
  "/customer/:customerId",
  protect,
  requireGarage,
  getCustomerServices
);

// Get service history for a specific vehicle
router.get(
  "/vehicle/:vehicleId",
  protect,
  requireGarage,
  getVehicleServices
);

// Get single service
router.get("/:id", protect, requireGarage, getServiceById);

// Create service (auto-generates invoice + PDF)
router.post("/", protect, requireGarage, createService);

// Update service (updates existing invoice if exists)
router.put("/:id", protect, requireGarage, updateService);

// Delete service (also deletes invoice + reminders)
router.delete("/:id", protect, requireGarage, deleteService);


// Create service — only owner, manager, mechanic
router.post(
  "/",
  protect,
  requireGarage,
  requireStaffRole(["manager", "mechanic"]),
  createService
);

// Update service — only owner, manager, mechanic
router.put(
  "/:id",
  protect,
  requireGarage,
  requireStaffRole(["manager", "mechanic"]),
  updateService
);

// Delete service — only owner, manager
router.delete(
  "/:id",
  protect,
  requireGarage,
  requireStaffRole(["manager"]),
  deleteService
);

module.exports = router;