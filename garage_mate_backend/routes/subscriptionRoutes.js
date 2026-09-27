const express = require("express");

const protect = require("../middleware/authMiddleware");
const requireGarage = require(
  "../middleware/garageMiddleware"
);

const {
  getCurrentSubscription,
  getPlans,
  startFreeTrial,
  adminUpgradePlan,
  getFounderSlots,
  adminListSubscriptions,
  requestUpgrade,
} = require("../controllers/subscriptionController");

const router = express.Router();

// ============================================================
// PUBLIC / USER ROUTES
// ============================================================

// Get all plans (public — anyone can see)
router.get("/plans", getPlans);

// Get founder slots (public — shows availability)
router.get("/founder-slots", getFounderSlots);

// Get current subscription + usage (protected)
router.get(
  "/current",
  protect,
  requireGarage,
  getCurrentSubscription
);

// Start free trial
router.post(
  "/start-trial",
  protect,
  requireGarage,
  startFreeTrial
);

// Request manual upgrade (user submits request)
router.post(
  "/request-upgrade",
  protect,
  requireGarage,
  requestUpgrade
);

// ============================================================
// ADMIN ROUTES
// (In production, add admin middleware here)
// ============================================================

// Admin: manually upgrade a garage's plan
router.post(
  "/admin/upgrade",
  protect,
  adminUpgradePlan
);

// Admin: list all subscriptions
router.get(
  "/admin/all",
  protect,
  adminListSubscriptions
);

// ============================================================
// EXPORT
// ============================================================

module.exports = router;