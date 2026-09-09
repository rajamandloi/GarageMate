const Service = require("../models/Service");
const Reminder = require("../models/Reminder");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");

// ============================================================
// CREATE / UPDATE SERVICE REMINDER
// ============================================================

const createServiceReminder = async ({
  garageId,
  customerId,
  vehicleId,
  nextServiceDate = null,
  nextServiceMileage = null,
}) => {
  if (!garageId) {
    throw new Error("Garage ID is required");
  }

  if (!customerId) {
    throw new Error("Customer ID is required");
  }

  if (!vehicleId) {
    throw new Error("Vehicle ID is required");
  }

  // ============================================================
  // VERIFY CUSTOMER
  // ============================================================

  const customer = await Customer.findOne({
    _id: customerId,
    garageId,
  });

  if (!customer) {
    throw new Error("Customer not found");
  }

  // ============================================================
  // VERIFY VEHICLE
  // ============================================================

  const vehicle = await Vehicle.findOne({
    _id: vehicleId,
    customerId,
    garageId,
  });

  if (!vehicle) {
    throw new Error("Vehicle not found");
  }

  // ============================================================
  // NO REMINDER DATA
  // ============================================================

  if (!nextServiceDate && !nextServiceMileage) {
    return null;
  }

  // ============================================================
  // FIND EXISTING UPCOMING SERVICE REMINDER
  // ============================================================

  let reminder = await Reminder.findOne({
    garageId,
    customerId,
    vehicleId,
    type: "service",
    status: {
      $in: [
        "upcoming",
        "dueSoon",
        "dueToday",
        "overdue",
      ],
    },
  }).sort({
    createdAt: -1,
  });

  // ============================================================
  // CREATE
  // ============================================================

  if (!reminder) {
    reminder = new Reminder({
      garageId,
      customerId,
      vehicleId,

      type: "service",

      dueDate: nextServiceDate
        ? new Date(nextServiceDate)
        : null,

      dueMileage:
        nextServiceMileage !== null &&
        nextServiceMileage !== undefined
          ? Number(nextServiceMileage)
          : null,

      title:
        "Vehicle service reminder",

      message:
        `Your vehicle ${vehicle.registrationNumber} ` +
        `is due for its next service.`,

      status: "upcoming",
    });
  } else {
    // ========================================================
    // UPDATE EXISTING REMINDER
    // ========================================================

    reminder.dueDate = nextServiceDate
      ? new Date(nextServiceDate)
      : null;

    reminder.dueMileage =
      nextServiceMileage !== null &&
      nextServiceMileage !== undefined
        ? Number(nextServiceMileage)
        : null;

    reminder.status = "upcoming";

    reminder.title =
      "Vehicle service reminder";

    reminder.message =
      `Your vehicle ${vehicle.registrationNumber} ` +
      `is due for its next service.`;
  }

  await reminder.save();

  return reminder;
};


// ============================================================
// CREATE REMINDER FROM SERVICE
// ============================================================

const createReminderFromService = async (
  serviceId
) => {
  if (!serviceId) {
    throw new Error("Service ID is required");
  }

  const service = await Service.findById(
    serviceId
  );

  if (!service) {
    throw new Error("Service not found");
  }

  return createServiceReminder({
    garageId: service.garageId,
    customerId: service.customerId,
    vehicleId: service.vehicleId,
    nextServiceDate:
      service.nextServiceDate,
    nextServiceMileage:
      service.nextServiceMileage,
  });
};


// ============================================================
// UPDATE REMINDER STATUS
// ============================================================

const updateServiceReminderStatuses =
  async () => {
    const now = new Date();

    const todayStart =
      new Date(now);

    todayStart.setHours(
      0,
      0,
      0,
      0
    );

    const todayEnd =
      new Date(now);

    todayEnd.setHours(
      23,
      59,
      59,
      999
    );

    // ========================================================
    // OVERDUE
    // ========================================================

    await Reminder.updateMany(
      {
        type: "service",

        status: {
          $in: [
            "upcoming",
            "dueSoon",
            "dueToday",
          ],
        },

        dueDate: {
          $lt: todayStart,
        },
      },
      {
        $set: {
          status: "overdue",
        },
      }
    );

    // ========================================================
    // DUE TODAY
    // ========================================================

    await Reminder.updateMany(
      {
        type: "service",

        status: {
          $in: [
            "upcoming",
            "dueSoon",
          ],
        },

        dueDate: {
          $gte: todayStart,
          $lte: todayEnd,
        },
      },
      {
        $set: {
          status: "dueToday",
        },
      }
    );

    // ========================================================
    // DUE SOON
    // ========================================================

    const dueSoonLimit =
      new Date(
        todayEnd.getTime() +
          7 * 24 * 60 * 60 * 1000
      );

    await Reminder.updateMany(
      {
        type: "service",

        status: "upcoming",

        dueDate: {
          $gt: todayEnd,
          $lte: dueSoonLimit,
        },
      },
      {
        $set: {
          status: "dueSoon",
        },
      }
    );
  };


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  createServiceReminder,
  createReminderFromService,
  updateServiceReminderStatuses,
};