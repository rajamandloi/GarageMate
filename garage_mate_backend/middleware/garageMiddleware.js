const Garage = require("../models/Garage");


// =====================================================
// REQUIRE GARAGE ACCESS
// =====================================================

const requireGarage = async (req, res, next) => {
  try {
    // protect middleware pehle run hona chahiye
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required",
      });
    }

    // Super Admin ko garage-specific restriction nahi
    if (req.user.role === "super_admin") {
      req.garageId = null;
      return next();
    }

    // Garage owner / staff ke paas garageId hona mandatory
    if (!req.user.garageId) {
      return res.status(403).json({
        success: false,
        message: "Garage access not assigned",
      });
    }

    const garage = await Garage.findById(req.user.garageId);

    if (!garage) {
      return res.status(404).json({
        success: false,
        message: "Garage not found",
      });
    }

    // Garage status check
    if (garage.status === "suspended") {
      return res.status(403).json({
        success: false,
        message: "Garage account has been suspended",
      });
    }

    if (garage.status === "pending") {
      return res.status(403).json({
        success: false,
        message: "Garage is waiting for admin approval",
      });
    }

    if (!garage.isActive) {
      return res.status(403).json({
        success: false,
        message: "Garage account is inactive",
      });
    }

    // Controller ke liye trusted garageId
    req.garageId = req.user.garageId;

    // Garage object bhi available rahega
    req.garage = garage;

    next();
  } catch (error) {
    console.error(
      "Garage middleware error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Unable to verify garage access",
    });
  }
};


module.exports = requireGarage;