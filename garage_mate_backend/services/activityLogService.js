const ActivityLog = require("../models/ActivityLog");

// ============================================================
// LOG ACTIVITY
// ============================================================

const logActivity = async ({
  garageId,
  user,
  action,
  entity = "",
  entityId = null,
  description = "",
  metadata = {},
}) => {
  try {
    if (!garageId || !user || !action) {
      return null;
    }

    const log = await ActivityLog.create({
      garageId,
      userId: user._id || user.id,
      userName: user.name || "",
      userRole: user.role || "",
      action,
      entity,
      entityId,
      description,
      metadata,
    });

    return log;
  } catch (error) {
    console.error(
      "Log activity error:",
      error.message
    );
    return null;
  }
};

module.exports = {
  logActivity,
};