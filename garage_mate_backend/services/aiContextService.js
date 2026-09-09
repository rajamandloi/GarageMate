const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Service = require("../models/Service");
const Reminder = require("../models/Reminder");

// ============================================================
// BUILD GARAGE AI CONTEXT
// ============================================================

const buildAIContext = async ({
  garageId,
  customerId,
}) => {
  if (!garageId) {
    throw new Error("Garage ID is required");
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  let customer = null;

  if (customerId) {
    customer = await Customer.findOne({
      _id: customerId,
      garageId,
    }).lean();
  }

  // ============================================================
  // VEHICLES
  // ============================================================

  let vehicles = [];

  if (customer) {
    vehicles = await Vehicle.find({
      garageId,
      customerId: customer._id,
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .lean();
  }

  // ============================================================
  // SERVICE HISTORY
  // ============================================================

  let services = [];

  if (customer) {
    services = await Service.find({
      garageId,
      customerId: customer._id,
    })
      .sort({ serviceDate: -1 })
      .limit(20)
      .lean();
  }

  // ============================================================
  // REMINDERS
  // ============================================================

  let reminders = [];

  if (customer) {
    reminders = await Reminder.find({
      garageId,
      customerId: customer._id,
    })
      .sort({ dueDate: 1 })
      .limit(20)
      .lean();
  }

  // ============================================================
  // SAFE CUSTOMER DATA
  // ============================================================

  const customerData = customer
    ? {
        id: customer._id.toString(),
        name: customer.name,
        phone: customer.phone,
        email: customer.email || "",
        address: customer.address || "",
      }
    : null;

  // ============================================================
  // SAFE VEHICLE DATA
  // ============================================================

  const vehicleData = vehicles.map(
    (vehicle) => ({
      id: vehicle._id.toString(),

      registrationNumber:
        vehicle.registrationNumber,

      brand: vehicle.brand,

      model: vehicle.model,

      variant:
        vehicle.variant || "",

      manufacturingYear:
        vehicle.manufacturingYear || "",

      fuelType:
        vehicle.fuelType,

      currentMileage:
        vehicle.currentMileage || 0,

      insuranceExpiry:
        vehicle.insuranceExpiry || null,

      pucExpiry:
        vehicle.pucExpiry || null,

      notes:
        vehicle.notes || "",
    })
  );

  // ============================================================
  // SAFE SERVICE DATA
  // ============================================================

  const serviceData = services.map(
    (service) => ({
      id: service._id.toString(),

      vehicleId:
        service.vehicleId?.toString(),

      serviceDate:
        service.serviceDate,

      serviceType:
        service.serviceType,

      mileage:
        service.mileage,

      description:
        service.description || "",

      partsUsed:
        service.partsUsed || "",

      totalAmount:
        service.totalAmount,

      paidAmount:
        service.paidAmount,

      paymentStatus:
        service.paymentStatus,

      paymentMethod:
        service.paymentMethod,

      nextServiceDate:
        service.nextServiceDate,

      nextServiceMileage:
        service.nextServiceMileage,

      mechanic:
        service.mechanic || "",

      notes:
        service.notes || "",
    })
  );

  // ============================================================
  // SAFE REMINDER DATA
  // ============================================================

  const reminderData = reminders.map(
    (reminder) => ({
      id: reminder._id.toString(),

      vehicleId:
        reminder.vehicleId?.toString(),

      type:
        reminder.type,

      dueDate:
        reminder.dueDate,

      dueMileage:
        reminder.dueMileage,

      title:
        reminder.title,

      message:
        reminder.message,

      status:
        reminder.status,
    })
  );

  // ============================================================
  // RETURN CONTEXT
  // ============================================================

  return {
    customer: customerData,

    vehicles: vehicleData,

    serviceHistory: serviceData,

    reminders: reminderData,
  };
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  buildAIContext,
};