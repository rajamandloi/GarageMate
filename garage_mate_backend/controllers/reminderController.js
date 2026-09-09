const Reminder = require("../models/Reminder");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");


// ============================================================
// CALCULATE REMINDER STATUS
// ============================================================

const calculateStatus = ({
  dueDate,
  dueMileage,
  currentMileage,
}) => {
  const now = new Date();

  let dateStatus = null;
  let mileageStatus = null;

  // -----------------------------
  // DATE STATUS
  // -----------------------------

  if (dueDate) {
    const due = new Date(dueDate);

    const today = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate()
    );

    const dueDay = new Date(
      due.getFullYear(),
      due.getMonth(),
      due.getDate()
    );

    const diffMs = dueDay - today;

    const diffDays = Math.ceil(
      diffMs / (1000 * 60 * 60 * 24)
    );

    if (diffDays < 0) {
      dateStatus = "overdue";
    } else if (diffDays === 0) {
      dateStatus = "dueToday";
    } else if (diffDays <= 3) {
      dateStatus = "dueSoon";
    } else {
      dateStatus = "upcoming";
    }
  }

  // -----------------------------
  // MILEAGE STATUS
  // -----------------------------

  if (
    dueMileage !== null &&
    dueMileage !== undefined &&
    currentMileage !== null &&
    currentMileage !== undefined
  ) {
    const difference =
      Number(dueMileage) -
      Number(currentMileage);

    if (difference <= 0) {
      mileageStatus = "overdue";
    } else if (difference <= 500) {
      mileageStatus = "dueSoon";
    } else {
      mileageStatus = "upcoming";
    }
  }

  // -----------------------------
  // FINAL STATUS
  // -----------------------------

  if (
    dateStatus === "overdue" ||
    mileageStatus === "overdue"
  ) {
    return "overdue";
  }

  if (
    dateStatus === "dueToday" &&
    !mileageStatus
  ) {
    return "dueToday";
  }

  if (
    dateStatus === "dueSoon" ||
    mileageStatus === "dueSoon"
  ) {
    return "dueSoon";
  }

  return "upcoming";
};


// ============================================================
// GET ALL REMINDERS
// GET /api/reminders
// ============================================================

const getReminders = async (req, res) => {
  try {
    const reminders =
      await Reminder.find({
        garageId: req.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        )
        .sort({
          dueDate: 1,
          createdAt: -1,
        });

    const updatedReminders =
      reminders.map((reminder) => {
        if (
          reminder.status === "completed" ||
          reminder.status === "cancelled"
        ) {
          return reminder;
        }

        const currentMileage =
          reminder.vehicleId?.currentMileage;

        const status =
          calculateStatus({
            dueDate:
              reminder.dueDate,
            dueMileage:
              reminder.dueMileage,
            currentMileage,
          });

        reminder.status = status;

        return reminder;
      });

    await Promise.all(
      updatedReminders.map(
        (reminder) =>
          reminder.save()
      )
    );

    return res.status(200).json({
      success: true,
      reminders: updatedReminders,
    });
  } catch (error) {
    console.error(
      "Get reminders error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to fetch reminders",
      error: error.message,
    });
  }
};


// ============================================================
// GET CUSTOMER REMINDERS
// GET /api/reminders/customer/:customerId
// ============================================================

const getCustomerReminders = async (
  req,
  res
) => {
  try {
    const {
      customerId,
    } = req.params;

    // Make sure customer belongs
    // to current garage
    const customer =
      await Customer.findOne({
        _id: customerId,
        garageId: req.garageId,
      });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message:
          "Customer not found",
      });
    }

    const reminders =
      await Reminder.find({
        customerId,
        garageId: req.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        )
        .sort({
          dueDate: 1,
          createdAt: -1,
        });

    return res.status(200).json({
      success: true,
      reminders,
    });
  } catch (error) {
    console.error(
      "Get customer reminders error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to fetch customer reminders",
      error: error.message,
    });
  }
};


// ============================================================
// GET VEHICLE REMINDERS
// GET /api/reminders/vehicle/:vehicleId
// ============================================================

const getVehicleReminders = async (
  req,
  res
) => {
  try {
    const {
      vehicleId,
    } = req.params;

    // Make sure vehicle belongs
    // to current garage
    const vehicle =
      await Vehicle.findOne({
        _id: vehicleId,
        garageId: req.garageId,
      });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message:
          "Vehicle not found",
      });
    }

    const reminders =
      await Reminder.find({
        vehicleId,
        garageId: req.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        )
        .sort({
          dueDate: 1,
          createdAt: -1,
        });

    return res.status(200).json({
      success: true,
      reminders,
    });
  } catch (error) {
    console.error(
      "Get vehicle reminders error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to fetch vehicle reminders",
      error: error.message,
    });
  }
};


// ============================================================
// CREATE REMINDER
// POST /api/reminders
// ============================================================

const createReminder = async (
  req,
  res
) => {
  try {
    const {
      customerId,
      vehicleId,
      type,
      dueDate,
      dueMileage,
      title,
      message,
    } = req.body;

    if (
      !customerId ||
      !vehicleId ||
      !type ||
      !title ||
      !message
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Customer, vehicle, type, title and message are required",
      });
    }

    // -----------------------------
    // Verify customer
    // -----------------------------

    const customer =
      await Customer.findOne({
        _id: customerId,
        garageId: req.garageId,
      });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message:
          "Customer not found",
      });
    }

    // -----------------------------
    // Verify vehicle
    // -----------------------------

    const vehicle =
      await Vehicle.findOne({
        _id: vehicleId,
        garageId: req.garageId,
        customerId,
      });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message:
          "Vehicle not found for this customer",
      });
    }

    // -----------------------------
    // Calculate initial status
    // -----------------------------

    const status =
      calculateStatus({
        dueDate:
          dueDate || null,
        dueMileage:
          dueMileage !== null &&
          dueMileage !== undefined &&
          dueMileage !== ""
            ? Number(dueMileage)
            : null,
        currentMileage:
          vehicle.currentMileage,
      });

    // -----------------------------
    // Create reminder
    // -----------------------------

    const reminder =
      await Reminder.create({
        garageId: req.garageId,

        customerId,

        vehicleId,

        type,

        dueDate:
          dueDate || null,

        dueMileage:
          dueMileage !== null &&
          dueMileage !== undefined &&
          dueMileage !== ""
            ? Number(dueMileage)
            : null,

        title: title.trim(),

        message: message.trim(),

        status,
      });

    const populatedReminder =
      await Reminder.findById(
        reminder._id
      )
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        );

    return res.status(201).json({
      success: true,
      message:
        "Reminder created successfully",
      reminder:
        populatedReminder,
    });
  } catch (error) {
    console.error(
      "Create reminder error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to create reminder",
      error: error.message,
    });
  }
};


// ============================================================
// UPDATE REMINDER
// PUT /api/reminders/:id
// ============================================================

const updateReminder = async (
  req,
  res
) => {
  try {
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

    const reminder =
      await Reminder.findOne({
        _id: req.params.id,
        garageId: req.garageId,
      });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message:
          "Reminder not found",
      });
    }

    // -----------------------------
    // Validate new customer
    // -----------------------------

    if (
      customerId !== undefined
    ) {
      const customer =
        await Customer.findOne({
          _id: customerId,
          garageId: req.garageId,
        });

      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found",
        });
      }

      reminder.customerId =
        customerId;
    }

    // -----------------------------
    // Validate new vehicle
    // -----------------------------

    if (
      vehicleId !== undefined
    ) {
      const finalCustomerId =
        customerId ||
        reminder.customerId;

      const vehicle =
        await Vehicle.findOne({
          _id: vehicleId,
          garageId: req.garageId,
          customerId:
            finalCustomerId,
        });

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message:
            "Vehicle not found for this customer",
        });
      }

      reminder.vehicleId =
        vehicleId;
    }

    if (type !== undefined) {
      reminder.type = type;
    }

    if (dueDate !== undefined) {
      reminder.dueDate =
        dueDate || null;
    }

    if (dueMileage !== undefined) {
      reminder.dueMileage =
        dueMileage === null ||
        dueMileage === ""
          ? null
          : Number(dueMileage);
    }

    if (title !== undefined) {
      reminder.title =
        String(title).trim();
    }

    if (message !== undefined) {
      reminder.message =
        String(message).trim();
    }

    if (status !== undefined) {
      reminder.status = status;
    }

    // -----------------------------
    // Recalculate status
    // -----------------------------

    if (
      reminder.status !==
        "completed" &&
      reminder.status !==
        "cancelled"
    ) {
      const vehicle =
        await Vehicle.findOne({
          _id:
            reminder.vehicleId,
          garageId:
            req.garageId,
        });

      if (vehicle) {
        reminder.status =
          calculateStatus({
            dueDate:
              reminder.dueDate,
            dueMileage:
              reminder.dueMileage,
            currentMileage:
              vehicle.currentMileage,
          });
      }
    }

    await reminder.save();

    const updatedReminder =
      await Reminder.findById(
        reminder._id
      )
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        );

    return res.status(200).json({
      success: true,
      message:
        "Reminder updated successfully",
      reminder:
        updatedReminder,
    });
  } catch (error) {
    console.error(
      "Update reminder error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to update reminder",
      error: error.message,
    });
  }
};


// ============================================================
// COMPLETE REMINDER
// PATCH /api/reminders/:id/complete
// ============================================================

const completeReminder = async (
  req,
  res
) => {
  try {
    const reminder =
      await Reminder.findOneAndUpdate(
        {
          _id: req.params.id,
          garageId: req.garageId,
        },
        {
          status: "completed",
        },
        {
          new: true,
        }
      )
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        );

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message:
          "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        "Reminder marked as completed",
      reminder,
    });
  } catch (error) {
    console.error(
      "Complete reminder error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to complete reminder",
      error: error.message,
    });
  }
};


// ============================================================
// CANCEL REMINDER
// PATCH /api/reminders/:id/cancel
// ============================================================

const cancelReminder = async (
  req,
  res
) => {
  try {
    const reminder =
      await Reminder.findOneAndUpdate(
        {
          _id: req.params.id,
          garageId: req.garageId,
        },
        {
          status: "cancelled",
        },
        {
          new: true,
        }
      )
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant currentMileage"
        );

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message:
          "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        "Reminder cancelled successfully",
      reminder,
    });
  } catch (error) {
    console.error(
      "Cancel reminder error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to cancel reminder",
      error: error.message,
    });
  }
};


// ============================================================
// DELETE REMINDER
// DELETE /api/reminders/:id
// ============================================================

const deleteReminder = async (
  req,
  res
) => {
  try {
    const reminder =
      await Reminder.findOneAndDelete({
        _id: req.params.id,
        garageId: req.garageId,
      });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message:
          "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        "Reminder deleted successfully",
    });
  } catch (error) {
    console.error(
      "Delete reminder error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to delete reminder",
      error: error.message,
    });
  }
};


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getReminders,
  getCustomerReminders,
  getVehicleReminders,
  createReminder,
  updateReminder,
  completeReminder,
  cancelReminder,
  deleteReminder,
};