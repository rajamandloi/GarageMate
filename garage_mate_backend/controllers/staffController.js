const {
  createStaff,
  getStaffList,
  getStaffLimitsInfo,
  updateStaffRole,
  toggleStaffActive,
  resetStaffPassword,
  deleteStaff,
} = require("../services/staffService");

const {
  logActivity,
} = require("../services/activityLogService");

const ActivityLog = require("../models/ActivityLog");

// ============================================================
// CREATE STAFF
// POST /api/staff
// ============================================================

const addStaff = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage is not associated",
      });
    }

    const {
      name,
      phone,
      staffRole,
      password = null,
    } = req.body;

    const result = await createStaff({
      garageId,
      ownerUser: req.user,
      name,
      phone,
      staffRole,
      customPassword: password,
    });

    // Log activity
    await logActivity({
      garageId,
      user: req.user,
      action: "staff.create",
      entity: "staff",
      entityId: result.staff._id,
      description: `Added ${result.staff.name} as ${result.staff.staffRole}`,
      metadata: {
        staffName: result.staff.name,
        staffRole: result.staff.staffRole,
        whatsappSent: result.whatsappSent,
      },
    });

    return res.status(201).json({
      success: true,
      message: result.whatsappSent
        ? "Staff added successfully & WhatsApp invite sent"
        : "Staff added successfully (WhatsApp invite failed)",
      staff: result.staff,
      whatsappSent: result.whatsappSent,
      whatsappError: result.whatsappError,
      // Note: Only return password if WhatsApp failed
      ...(result.whatsappSent
        ? {}
        : { plainPassword: result.plainPassword }),
    });
  } catch (error) {
    console.error("Add staff error:", error.message);

    return res.status(400).json({
      success: false,
      message: error.message || "Unable to add staff",
    });
  }
};

// ============================================================
// LIST STAFF
// GET /api/staff
// ============================================================

const listStaff = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage is not associated",
      });
    }

    const [staff, limits] = await Promise.all([
      getStaffList(garageId),
      getStaffLimitsInfo(garageId),
    ]);

    return res.status(200).json({
      success: true,
      count: staff.length,
      staff,
      limits,
    });
  } catch (error) {
    console.error("List staff error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch staff",
    });
  }
};

// ============================================================
// UPDATE STAFF ROLE
// PUT /api/staff/:id/role
// ============================================================

const changeStaffRole = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;
    const { id } = req.params;
    const { staffRole } = req.body;

    if (!staffRole) {
      return res.status(400).json({
        success: false,
        message: "staffRole is required",
      });
    }

    const staff = await updateStaffRole({
      garageId,
      staffId: id,
      newRole: staffRole,
    });

    await logActivity({
      garageId,
      user: req.user,
      action: "staff.updateRole",
      entity: "staff",
      entityId: staff._id,
      description: `Changed ${staff.name} role to ${staffRole}`,
      metadata: { newRole: staffRole },
    });

    return res.status(200).json({
      success: true,
      message: "Staff role updated successfully",
      staff: {
        _id: staff._id,
        name: staff.name,
        phone: staff.phone,
        staffRole: staff.staffRole,
      },
    });
  } catch (error) {
    console.error("Change role error:", error.message);

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// TOGGLE STAFF ACTIVE
// PATCH /api/staff/:id/toggle
// ============================================================

const toggleStaffStatus = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;
    const { id } = req.params;

    const staff = await toggleStaffActive({
      garageId,
      staffId: id,
    });

    await logActivity({
      garageId,
      user: req.user,
      action: staff.isActive
        ? "staff.activate"
        : "staff.deactivate",
      entity: "staff",
      entityId: staff._id,
      description: `${staff.name} ${
        staff.isActive ? "activated" : "deactivated"
      }`,
    });

    return res.status(200).json({
      success: true,
      message: staff.isActive
        ? "Staff activated successfully"
        : "Staff deactivated successfully",
      isActive: staff.isActive,
    });
  } catch (error) {
    console.error("Toggle staff error:", error.message);

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// RESET STAFF PASSWORD
// PUT /api/staff/:id/password
// ============================================================

const changeStaffPassword = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;
    const { id } = req.params;
    const { newPassword } = req.body;

    const staff = await resetStaffPassword({
      garageId,
      staffId: id,
      newPassword,
    });

    await logActivity({
      garageId,
      user: req.user,
      action: "staff.resetPassword",
      entity: "staff",
      entityId: staff._id,
      description: `Reset password for ${staff.name}`,
    });

    return res.status(200).json({
      success: true,
      message: "Password reset successfully",
    });
  } catch (error) {
    console.error("Reset password error:", error.message);

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// DELETE STAFF
// DELETE /api/staff/:id
// ============================================================

const removeStaff = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;
    const { id } = req.params;

    const staff = await deleteStaff({
      garageId,
      staffId: id,
    });

    await logActivity({
      garageId,
      user: req.user,
      action: "staff.delete",
      entity: "staff",
      entityId: staff._id,
      description: `Removed ${staff.name}`,
      metadata: {
        staffName: staff.name,
        staffRole: staff.staffRole,
      },
    });

    return res.status(200).json({
      success: true,
      message: "Staff removed successfully",
    });
  } catch (error) {
    console.error("Delete staff error:", error.message);

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================
// GET ACTIVITY LOG
// GET /api/staff/activity
// Query: ?limit=50&userId=xxx
// ============================================================

const getActivityLog = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;
    const {
      limit = 50,
      userId,
      action,
    } = req.query;

    const query = { garageId };

    if (userId) query.userId = userId;
    if (action) query.action = action;

    const logs = await ActivityLog.find(query)
      .sort({ createdAt: -1 })
      .limit(Math.min(Number(limit), 200));

    return res.status(200).json({
      success: true,
      count: logs.length,
      logs,
    });
  } catch (error) {
    console.error("Activity log error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch activity log",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  addStaff,
  listStaff,
  changeStaffRole,
  toggleStaffStatus,
  changeStaffPassword,
  removeStaff,
  getActivityLog,
};