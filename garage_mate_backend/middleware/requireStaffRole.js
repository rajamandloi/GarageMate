// ============================================================
// REQUIRE STAFF ROLE
// Allows access only to specific staff roles
// Owners always allowed
// ============================================================

const requireStaffRole = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required",
      });
    }

    // Owner and super_admin always allowed
    if (
      req.user.role === "garage_owner" ||
      req.user.role === "super_admin"
    ) {
      return next();
    }

    // Must be staff
    if (req.user.role !== "staff") {
      return res.status(403).json({
        success: false,
        message: "Access denied",
      });
    }

    // Check staff role
    const staffRole = req.user.staffRole;

    if (!allowedRoles.includes(staffRole)) {
      return res.status(403).json({
        success: false,
        message:
          "Aapko ye action karne ki permission nahi hai",
      });
    }

    next();
  };
};

module.exports = requireStaffRole;