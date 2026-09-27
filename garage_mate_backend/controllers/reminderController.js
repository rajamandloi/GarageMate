const Reminder = require("../models/Reminder");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");

// ============================================================
// GET ALL REMINDERS
// GET /api/reminders
// ============================================================

const getReminders = async (req, res) => {
  try {
    const reminders = await Reminder.find({
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      )
      .sort({ dueDate: 1, createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: reminders.length,
      reminders,
    });
  } catch (error) {
    console.error("Get reminders error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch reminders",
    });
  }
};

// ============================================================
// ✅ GET CUSTOMER REMINDERS (NEW)
// GET /api/reminders/customer/:customerId
// ============================================================

const getCustomerReminders = async (req, res) => {
  try {
    const { customerId } = req.params;

    // Verify customer belongs to this garage
    const customer = await Customer.findOne({
      _id: customerId,
      garageId: req.garageId,
    });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: "Customer not found",
      });
    }

    const reminders = await Reminder.find({
      garageId: req.garageId,
      customerId: customerId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      )
      .sort({ dueDate: 1, createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: reminders.length,
      reminders,
    });
  } catch (error) {
    console.error(
      "Get customer reminders error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch customer reminders",
    });
  }
};

// ============================================================
// ✅ GET VEHICLE REMINDERS (NEW)
// GET /api/reminders/vehicle/:vehicleId
// ============================================================

const getVehicleReminders = async (req, res) => {
  try {
    const { vehicleId } = req.params;

    // Verify vehicle belongs to this garage
    const vehicle = await Vehicle.findOne({
      _id: vehicleId,
      garageId: req.garageId,
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: "Vehicle not found",
      });
    }

    const reminders = await Reminder.find({
      garageId: req.garageId,
      vehicleId: vehicleId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      )
      .sort({ dueDate: 1, createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: reminders.length,
      reminders,
    });
  } catch (error) {
    console.error(
      "Get vehicle reminders error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch vehicle reminders",
    });
  }
};

// ============================================================
// GET SINGLE REMINDER
// GET /api/reminders/:id
// ============================================================

const getReminderById = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({
      _id: req.params.id,
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      );

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      reminder,
    });
  } catch (error) {
    console.error("Get reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch reminder",
    });
  }
};

// ============================================================
// CREATE REMINDER
// POST /api/reminders
// ============================================================

const createReminder = async (req, res) => {
  try {
    const {
      customerId,
      vehicleId,
      serviceId,
      type,
      dueDate,
      dueMileage,
      title,
      message,
      status,
    } = req.body;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: "Customer is required",
      });
    }

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: "Vehicle is required",
      });
    }

    if (!title || !title.trim()) {
      return res.status(400).json({
        success: false,
        message: "Reminder title is required",
      });
    }

    const customer = await Customer.findOne({
      _id: customerId,
      garageId: req.garageId,
    });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: "Customer not found",
      });
    }

    const vehicle = await Vehicle.findOne({
      _id: vehicleId,
      garageId: req.garageId,
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: "Vehicle not found",
      });
    }

    const reminder = await Reminder.create({
      garageId: req.garageId,
      customerId,
      vehicleId,
      serviceId: serviceId || null,
      type: type || "service",
      dueDate: dueDate || null,
      dueMileage: dueMileage || null,
      title: title.trim(),
      message: message?.trim() || "",
      status: status || "upcoming",
    });

    const populatedReminder = await Reminder.findOne({
      _id: reminder._id,
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      );

    return res.status(201).json({
      success: true,
      message: "Reminder created successfully",
      reminder: populatedReminder,
    });
  } catch (error) {
    console.error("Create reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to create reminder",
    });
  }
};

// ============================================================
// UPDATE REMINDER
// PUT /api/reminders/:id
// ============================================================

const updateReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({
      _id: req.params.id,
      garageId: req.garageId,
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    const {
      customerId,
      vehicleId,
      type,
      dueDate,
      dueMileage,
      title,
      message,
      status,
    } = req.body;

    if (customerId !== undefined) {
      reminder.customerId = customerId;
    }

    if (vehicleId !== undefined) {
      reminder.vehicleId = vehicleId;
    }

    if (type !== undefined) {
      reminder.type = type;
    }

    if (dueDate !== undefined) {
      reminder.dueDate = dueDate || null;
    }

    if (dueMileage !== undefined) {
      reminder.dueMileage = dueMileage || null;
    }

    if (title !== undefined) {
      reminder.title = title.trim();
    }

    if (message !== undefined) {
      reminder.message = message.trim();
    }

    if (status !== undefined) {
      reminder.status = status;
    }

    await reminder.save();

    const updatedReminder = await Reminder.findOne({
      _id: reminder._id,
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      );

    return res.status(200).json({
      success: true,
      message: "Reminder updated successfully",
      reminder: updatedReminder,
    });
  } catch (error) {
    console.error("Update reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to update reminder",
    });
  }
};

// ============================================================
// COMPLETE REMINDER
// PATCH /api/reminders/:id/complete
// ============================================================

const completeReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({
      _id: req.params.id,
      garageId: req.garageId,
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    if (reminder.status === "completed") {
      return res.status(400).json({
        success: false,
        message: "Reminder is already completed",
      });
    }

    if (reminder.status === "cancelled") {
      return res.status(400).json({
        success: false,
        message: "Cannot complete a cancelled reminder",
      });
    }

    reminder.status = "completed";

    await reminder.save();

    const updatedReminder = await Reminder.findOne({
      _id: reminder._id,
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant"
      );

    return res.status(200).json({
      success: true,
      message: "Reminder marked as completed",
      reminder: updatedReminder,
    });
  } catch (error) {
    console.error("Complete reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to complete reminder",
    });
  }
};

// ============================================================
// CANCEL REMINDER
// PATCH /api/reminders/:id/cancel
// ============================================================

const cancelReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({
      _id: req.params.id,
      garageId: req.garageId,
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    reminder.status = "cancelled";

    await reminder.save();

    return res.status(200).json({
      success: true,
      message: "Reminder cancelled successfully",
      reminder,
    });
  } catch (error) {
    console.error("Cancel reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to cancel reminder",
    });
  }
};

// ============================================================
// DELETE SINGLE REMINDER
// DELETE /api/reminders/:id
// ============================================================

const deleteReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOneAndDelete({
      _id: req.params.id,
      garageId: req.garageId,
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Reminder deleted successfully",
    });
  } catch (error) {
    console.error("Delete reminder error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to delete reminder",
    });
  }
};

// ============================================================
// BULK DELETE REMINDERS
// POST /api/reminders/bulk-delete
// ============================================================

const bulkDeleteReminders = async (req, res) => {
  try {
    const { ids } = req.body;

    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Reminder IDs are required",
      });
    }

    if (ids.length > 500) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete more than 500 reminders at once",
      });
    }

    const result = await Reminder.deleteMany({
      _id: { $in: ids },
      garageId: req.user.garageId,
    });

    return res.status(200).json({
      success: true,
      message: `${result.deletedCount} reminder(s) deleted successfully`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error("Bulk delete reminders error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to delete reminders",
    });
  }
};

// ============================================================
// DELETE ALL COMPLETED REMINDERS
// DELETE /api/reminders/completed
// ============================================================

const deleteCompletedReminders = async (req, res) => {
  try {
    const result = await Reminder.deleteMany({
      garageId: req.user.garageId,
      status: { $in: ["completed", "cancelled"] },
    });

    return res.status(200).json({
      success: true,
      message: `${result.deletedCount} completed reminder(s) deleted`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error("Delete completed reminders error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to delete completed reminders",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
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
};