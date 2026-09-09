
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

const router = express.Router();


// ============================================================
// SERVICE ROUTES
// Base URL: /api/services
// ============================================================


// Get all services
router.get(
  "/",
  protect,
  requireGarage,
  getServices
);


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
router.get(
  "/:id",
  protect,
  requireGarage,
  getServiceById
);


// Create service
router.post(
  "/",
  protect,
  requireGarage,
  createService
);


// Update service
router.put(
  "/:id",
  protect,
  requireGarage,
  updateService
);


// Delete service
router.delete(
  "/:id",
  protect,
  requireGarage,
  deleteService
);


module.exports = router;