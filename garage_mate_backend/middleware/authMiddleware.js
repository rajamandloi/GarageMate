const jwt = require("jsonwebtoken");

const User = require("../models/User");
const Garage = require("../models/Garage");

const protect = async (
  req,
  res,
  next
) => {
  try {
    // =================================================
    // AUTHORIZATION HEADER
    // =================================================

    const authHeader =
      req.headers.authorization;

    if (
      !authHeader ||
      !authHeader.startsWith(
        "Bearer "
      )
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Authentication required",
      });
    }

    // =================================================
    // EXTRACT ACCESS TOKEN
    // =================================================

    const token =
      authHeader
        .split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message:
          "Authentication token missing",
      });
    }

    // =================================================
    // VERIFY ACCESS TOKEN
    // =================================================

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET,
      {
        algorithms: ["HS256"],
        issuer: process.env.JWT_ISSUER || "garagemate-api",
        audience: process.env.JWT_AUDIENCE || "garagemate-app",
      }
    );

    if (!decoded.userId || decoded.sessionVersion === undefined) {
      return res.status(401).json({
        success: false,
        message: "Invalid authentication token",
      });
    }

    // =================================================
    // FIND USER
    // =================================================

    const user =
      await User.findById(
        decoded.userId
      ).select(
        "-password"
      );

    if (!user) {
      return res.status(401).json({
        success: false,
        message:
          "User not found",
      });
    }

    // A session-version mismatch immediately invalidates old access tokens.
    if (Number(decoded.sessionVersion) !== Number(user.sessionVersion || 0)) {
      return res.status(401).json({
        success: false,
        message: "Session expired. Please login again.",
        code: "SESSION_REVOKED",
      });
    }

    // JWT claims are not trusted for authorization. Always compare them with
    // current database state so role/tenant changes take effect immediately.
    if (String(decoded.role) !== String(user.role)) {
      return res.status(401).json({
        success: false,
        message: "Session is no longer valid",
        code: "SESSION_REVOKED",
      });
    }

    const tokenGarageId = decoded.garageId ? String(decoded.garageId) : null;
    const userGarageId = user.garageId ? String(user.garageId) : null;

    if (tokenGarageId !== userGarageId) {
      return res.status(401).json({
        success: false,
        message: "Session is no longer valid",
        code: "SESSION_REVOKED",
      });
    }

    // =================================================
    // USER ACTIVE CHECK
    // =================================================

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message:
          "Account is inactive",
      });
    }

    // =================================================
    // GARAGE STATUS CHECK
    // =================================================

    if (
      user.role === "garage_owner" &&
      user.garageId
    ) {
      const garage =
        await Garage.findById(
          user.garageId
        );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message:
            "Garage not found",
        });
      }

      // -------------------------------------------------
      // PENDING
      // -------------------------------------------------

      if (
        garage.status ===
        "pending"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Your garage is waiting for admin approval",
        });
      }

      // -------------------------------------------------
      // SUSPENDED
      // -------------------------------------------------

      if (
        garage.status ===
        "suspended"
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Your garage account has been suspended",
        });
      }

      // -------------------------------------------------
      // INACTIVE
      // -------------------------------------------------

      if (!garage.isActive) {
        return res.status(403).json({
          success: false,
          message:
            "Garage account is inactive",
        });
      }
    }

    // =================================================
    // ATTACH USER
    // =================================================

    req.user = user;

    next();
  } catch (error) {
    // =================================================
    // EXPIRED / INVALID ACCESS TOKEN
    // =================================================

    if (
      error.name ===
      "TokenExpiredError"
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Access token expired",
        code:
          "ACCESS_TOKEN_EXPIRED",
      });
    }

    console.error(
      "Auth middleware error:",
      error.message
    );

    return res.status(401).json({
      success: false,
      message:
        "Invalid authentication token",
    });
  }
};

module.exports = protect;