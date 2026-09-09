const Service = require("../models/Service");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Reminder = require("../models/Reminder");

const {
  sendInvoiceWhatsApp,
} = require("../services/whatsappService");

// ============================================================
// GET ALL SERVICES
// GET /api/services
// ============================================================

const getServices = async (req, res) => {
  try {
    const services = await Service.find({
      garageId: req.garageId,
    })
      .populate(
        "customerId",
        "name phone email address"
      )
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({
        serviceDate: -1,
        createdAt: -1,
      });

    return res.status(200).json({
      success: true,
      count: services.length,
      services,
    });
  } catch (error) {
    console.error("Get services error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch services",
    });
  }
};

// ============================================================
// GET SINGLE SERVICE
// GET /api/services/:id
// ============================================================

const getServiceById = async (req, res) => {
  try {
    const service = await Service.findOne({
      _id: req.params.id,
      garageId: req.garageId,
    })
      .populate(
        "customerId",
        "name phone email address"
      )
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      );

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service record not found",
      });
    }

    return res.status(200).json({
      success: true,
      service,
    });
  } catch (error) {
    console.error("Get service by ID error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch service",
    });
  }
};

// ============================================================
// GET SERVICES BY CUSTOMER
// GET /api/services/customer/:customerId
// ============================================================

const getCustomerServices = async (req, res) => {
  try {
    const { customerId } = req.params;

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

    const services = await Service.find({
      customerId,
      garageId: req.garageId,
    })
      .populate(
        "customerId",
        "name phone email address"
      )
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({
        serviceDate: -1,
        createdAt: -1,
      });

    return res.status(200).json({
      success: true,
      count: services.length,
      services,
    });
  } catch (error) {
    console.error(
      "Get customer services error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch customer services",
    });
  }
};

// ============================================================
// GET SERVICES BY VEHICLE
// GET /api/services/vehicle/:vehicleId
// ============================================================

const getVehicleServices = async (req, res) => {
  try {
    const { vehicleId } = req.params;

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

    const services = await Service.find({
      vehicleId,
      garageId: req.garageId,
    })
      .populate(
        "customerId",
        "name phone email address"
      )
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({
        serviceDate: -1,
        createdAt: -1,
      });

    return res.status(200).json({
      success: true,
      count: services.length,
      services,
    });
  } catch (error) {
    console.error(
      "Get vehicle services error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch vehicle services",
    });
  }
};

// ============================================================
// CREATE SERVICE
// POST /api/services
// ============================================================

const createService = async (req, res) => {
  try {
    const {
      customerId,
      vehicleId,
      serviceDate,
      serviceType,
      mileage,
      description,
      partsUsed,
      laborCost,
      partsCost,
      discount,
      tax,
      totalAmount,
      paidAmount,
      paymentStatus,
      paymentMethod,
      nextServiceDate,
      nextServiceMileage,
      mechanic,
      notes,
    } = req.body;

    // --------------------------------------------------------
    // Required fields
    // --------------------------------------------------------

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

    if (!serviceDate) {
      return res.status(400).json({
        success: false,
        message: "Service date is required",
      });
    }

    if (!serviceType || !serviceType.trim()) {
      return res.status(400).json({
        success: false,
        message: "Service type is required",
      });
    }

    // --------------------------------------------------------
    // Verify customer belongs to garage
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // Verify vehicle belongs to garage
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // Verify vehicle belongs to customer
    // --------------------------------------------------------

    if (
      vehicle.customerId.toString() !==
      customer._id.toString()
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Selected vehicle does not belong to selected customer",
      });
    }

    // --------------------------------------------------------
    // Calculate amounts
    // --------------------------------------------------------

    const labor = Number(laborCost) || 0;
    const parts = Number(partsCost) || 0;
    const discountValue = Number(discount) || 0;
    const taxValue = Number(tax) || 0;

    let finalTotal = Number(totalAmount);

    if (Number.isNaN(finalTotal)) {
      finalTotal =
        labor +
        parts -
        discountValue +
        taxValue;
    }

    if (finalTotal < 0) {
      finalTotal = 0;
    }

    const finalPaidAmount = Math.max(
      0,
      Number(paidAmount) || 0
    );

    // Never allow paid amount to exceed total.
    const safePaidAmount = Math.min(
      finalPaidAmount,
      finalTotal
    );

    // --------------------------------------------------------
    // Payment status
    // --------------------------------------------------------

    let finalPaymentStatus = paymentStatus;

    if (
      safePaidAmount >= finalTotal &&
      finalTotal > 0
    ) {
      finalPaymentStatus = "paid";
    } else if (safePaidAmount > 0) {
      finalPaymentStatus = "partiallyPaid";
    } else {
      finalPaymentStatus = "pending";
    }

    // --------------------------------------------------------
    // Create service
    // --------------------------------------------------------

    const service = await Service.create({
      garageId: req.user.garageId,

      customerId,
      vehicleId,

      serviceDate,

      serviceType: serviceType.trim(),

      mileage: Number(mileage) || 0,

      description:
        description?.trim() || "",

      partsUsed:
        partsUsed?.trim() || "",

      laborCost: labor,
      partsCost: parts,
      discount: discountValue,
      tax: taxValue,

      totalAmount: finalTotal,
      paidAmount: safePaidAmount,

      paymentStatus: finalPaymentStatus,

      paymentMethod:
        paymentMethod || "Cash",

      nextServiceDate:
        nextServiceDate || null,

      nextServiceMileage:
        nextServiceMileage !== null &&
        nextServiceMileage !== undefined &&
        nextServiceMileage !== ""
          ? Number(nextServiceMileage)
          : null,

      mechanic:
        mechanic?.trim() || "",

      notes:
        notes?.trim() || "",
    });

    // ============================================================
    // SEND BILL ON WHATSAPP
    // ============================================================

    try {
      const pendingAmount = Math.max(
        0,
        finalTotal - safePaidAmount
      );

      await sendInvoiceWhatsApp({
        garageId: req.garageId,

        to: customer.phone,

        customerName: customer.name,

        vehicleNumber:
          vehicle.registrationNumber,

        serviceDate,

        totalAmount: finalTotal,

        paidAmount: safePaidAmount,

        pendingAmount,
      });

      console.log(
        "Service bill sent to customer WhatsApp"
      );
    } catch (whatsappError) {
      console.error(
        "Bill WhatsApp failed:",
        whatsappError.message
      );
    }

    // ============================================================
    // AUTOMATIC PAYMENT REMINDER
    // ============================================================

    if (finalTotal > safePaidAmount) {
      await Reminder.create({
        garageId: req.garageId,

        customerId,

        vehicleId,

        serviceId: service._id,

        type: "payment",

        dueDate: new Date(),

        dueMileage: null,

        title: "Payment Pending",

        message:
          `Payment of ₹${(
            finalTotal - safePaidAmount
          ).toFixed(2)} is pending for your vehicle service.`,

        status: "dueToday",
      });

      console.log(
        "Automatic payment reminder created"
      );
    }

    // ============================================================
    // AUTOMATIC SERVICE REMINDER
    // ============================================================

    if (
      nextServiceDate ||
      nextServiceMileage
    ) {
      await Reminder.create({
        garageId: req.garageId,

        customerId,

        vehicleId,

        // IMPORTANT:
        // Service reminder is now linked to exact service.
        serviceId: service._id,

        type: "service",

        dueDate:
          nextServiceDate || null,

        dueMileage:
          nextServiceMileage !== null &&
          nextServiceMileage !== undefined &&
          nextServiceMileage !== ""
            ? Number(nextServiceMileage)
            : null,

        title: "Service Reminder",

        message:
          "Your vehicle service is due. Please contact the garage to schedule your next service.",

        status: "upcoming",
      });

      console.log(
        "Automatic service reminder created"
      );
    }

    // --------------------------------------------------------
    // Populate response
    // --------------------------------------------------------

    const populatedService =
      await Service.findOne({
        _id: service._id,
        garageId: req.user.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
        );

    return res.status(201).json({
      success: true,
      message: "Service created successfully",
      service: populatedService,
    });
  } catch (error) {
    console.error(
      "Create service error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to create service",
    });
  }
};

// ============================================================
// UPDATE SERVICE
// PUT /api/services/:id
// ============================================================

const updateService = async (req, res) => {
  try {
    const { id } = req.params;

    const {
      customerId,
      vehicleId,
      serviceDate,
      serviceType,
      mileage,
      description,
      partsUsed,
      laborCost,
      partsCost,
      discount,
      tax,
      totalAmount,
      paidAmount,
      paymentStatus,
      paymentMethod,
      nextServiceDate,
      nextServiceMileage,
      mechanic,
      notes,
    } = req.body;

    // --------------------------------------------------------
    // Find service inside current garage
    // --------------------------------------------------------

    const service =
      await Service.findOne({
        _id: id,
        garageId: req.user.garageId,
      });

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service record not found",
      });
    }

    // --------------------------------------------------------
    // Verify customer if changed
    // --------------------------------------------------------

    if (customerId !== undefined) {
      const customer =
        await Customer.findOne({
          _id: customerId,
          garageId: req.user.garageId,
        });

      if (!customer) {
        return res.status(404).json({
          success: false,
          message: "Customer not found",
        });
      }

      service.customerId = customerId;
    }

    // --------------------------------------------------------
    // Verify vehicle if changed
    // --------------------------------------------------------

    if (vehicleId !== undefined) {
      const vehicle =
        await Vehicle.findOne({
          _id: vehicleId,
          garageId: req.user.garageId,
        });

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message: "Vehicle not found",
        });
      }

      const finalCustomerId =
        customerId !== undefined
          ? customerId
          : service.customerId;

      if (
        vehicle.customerId.toString() !==
        finalCustomerId.toString()
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Selected vehicle does not belong to selected customer",
        });
      }

      service.vehicleId = vehicleId;
    }

    // --------------------------------------------------------
    // Update basic fields
    // --------------------------------------------------------

    if (serviceDate !== undefined) {
      service.serviceDate = serviceDate;
    }

    if (serviceType !== undefined) {
      if (!serviceType.trim()) {
        return res.status(400).json({
          success: false,
          message: "Service type is required",
        });
      }

      service.serviceType =
        serviceType.trim();
    }

    if (mileage !== undefined) {
      service.mileage =
        Number(mileage) || 0;
    }

    if (description !== undefined) {
      service.description =
        description?.trim() || "";
    }

    if (partsUsed !== undefined) {
      service.partsUsed =
        partsUsed?.trim() || "";
    }

    // --------------------------------------------------------
    // Amounts
    // --------------------------------------------------------

    const labor =
      laborCost !== undefined
        ? Number(laborCost) || 0
        : Number(service.laborCost) || 0;

    const parts =
      partsCost !== undefined
        ? Number(partsCost) || 0
        : Number(service.partsCost) || 0;

    const discountValue =
      discount !== undefined
        ? Number(discount) || 0
        : Number(service.discount) || 0;

    const taxValue =
      tax !== undefined
        ? Number(tax) || 0
        : Number(service.tax) || 0;

    let finalTotal =
      totalAmount !== undefined
        ? Number(totalAmount)
        : Number(service.totalAmount);

    if (Number.isNaN(finalTotal)) {
      finalTotal =
        labor +
        parts -
        discountValue +
        taxValue;
    }

    if (finalTotal < 0) {
      finalTotal = 0;
    }

    const finalPaidAmount =
      paidAmount !== undefined
        ? Math.max(0, Number(paidAmount) || 0)
        : Math.max(
            0,
            Number(service.paidAmount) || 0
          );

    // Prevent paid amount from exceeding invoice total.
    const safePaidAmount = Math.min(
      finalPaidAmount,
      finalTotal
    );

    // --------------------------------------------------------
    // Payment status
    // --------------------------------------------------------

    let finalPaymentStatus =
      paymentStatus;

    if (
      safePaidAmount >= finalTotal &&
      finalTotal > 0
    ) {
      finalPaymentStatus = "paid";
    } else if (safePaidAmount > 0) {
      finalPaymentStatus =
        "partiallyPaid";
    } else {
      finalPaymentStatus = "pending";
    }

    // --------------------------------------------------------
    // Save service values
    // --------------------------------------------------------

    service.laborCost = labor;
    service.partsCost = parts;
    service.discount = discountValue;
    service.tax = taxValue;

    service.totalAmount = finalTotal;
    service.paidAmount = safePaidAmount;

    service.paymentStatus =
      finalPaymentStatus;

    service.paymentMethod =
      paymentMethod || service.paymentMethod || "Cash";

    service.nextServiceDate =
      nextServiceDate !== undefined
        ? nextServiceDate || null
        : service.nextServiceDate;

    service.nextServiceMileage =
      nextServiceMileage !== undefined
        ? (
            nextServiceMileage !== null &&
            nextServiceMileage !== ""
              ? Number(nextServiceMileage)
              : null
          )
        : service.nextServiceMileage;

    service.mechanic =
      mechanic !== undefined
        ? mechanic?.trim() || ""
        : service.mechanic;

    service.notes =
      notes !== undefined
        ? notes?.trim() || ""
        : service.notes;

    // ============================================================
    // IMPORTANT:
    // Save service FIRST.
    // The Service pre-save hook also recalculates paymentStatus.
    // ============================================================

    await service.save();

    // ============================================================
    // PAYMENT REMINDER SYNCHRONIZATION
    // ============================================================

    const paymentReminders =
      await Reminder.find({
        garageId: req.user.garageId,
        serviceId: service._id,
        type: "payment",
      });

    if (
      service.totalAmount >
      service.paidAmount
    ) {
      const pendingAmount =
        service.totalAmount -
        service.paidAmount;

      // Keep one active payment reminder.
      let activePaymentReminder =
        paymentReminders.find(
          (reminder) =>
            reminder.status !==
              "completed" &&
            reminder.status !==
              "cancelled"
        );

      if (!activePaymentReminder) {
        activePaymentReminder =
          await Reminder.create({
            garageId:
              req.user.garageId,

            customerId:
              service.customerId,

            vehicleId:
              service.vehicleId,

            serviceId:
              service._id,

            type: "payment",

            dueDate: new Date(),

            dueMileage: null,

            title:
              "Payment Pending",

            message:
              `Payment of ₹${pendingAmount.toFixed(
                2
              )} is pending for your vehicle service.`,

            status:
              "dueToday",
          });
      } else {
        activePaymentReminder.customerId =
          service.customerId;

        activePaymentReminder.vehicleId =
          service.vehicleId;

        activePaymentReminder.dueDate =
          new Date();

        activePaymentReminder.title =
          "Payment Pending";

        activePaymentReminder.message =
          `Payment of ₹${pendingAmount.toFixed(
            2
          )} is pending for your vehicle service.`;

        activePaymentReminder.status =
          "dueToday";

        await activePaymentReminder.save();
      }

      // --------------------------------------------------------
      // Clean duplicate/old active payment reminders.
      // --------------------------------------------------------

      if (activePaymentReminder) {
        await Reminder.updateMany(
          {
            garageId:
              req.user.garageId,

            serviceId:
              service._id,

            type: "payment",

            _id: {
              $ne:
                activePaymentReminder._id,
            },

            status: {
              $nin: [
                "completed",
                "cancelled",
              ],
            },
          },
          {
            $set: {
              status: "completed",
            },
          }
        );
      }
    } else {
      // ========================================================
      // PAYMENT FULLY PAID
      // Mark ALL payment reminders for this service completed.
      // This fixes old "Payment Pending" reminders.
      // ========================================================

      await Reminder.updateMany(
        {
          garageId:
            req.user.garageId,

          serviceId:
            service._id,

          type: "payment",

          status: {
            $ne: "cancelled",
          },
        },
        {
          $set: {
            status: "completed",
          },
        }
      );
    }

    // ============================================================
    // SERVICE REMINDER SYNCHRONIZATION
    // ============================================================

    const serviceReminders =
      await Reminder.find({
        garageId: req.user.garageId,
        serviceId: service._id,
        type: "service",
      });

    if (
      service.nextServiceDate ||
      service.nextServiceMileage !== null
    ) {
      let activeServiceReminder =
        serviceReminders.find(
          (reminder) =>
            reminder.status !==
              "completed" &&
            reminder.status !==
              "cancelled"
        );

      if (!activeServiceReminder) {
        await Reminder.create({
          garageId:
            req.user.garageId,

          customerId:
            service.customerId,

          vehicleId:
            service.vehicleId,

          serviceId:
            service._id,

          type: "service",

          dueDate:
            service.nextServiceDate ||
            null,

          dueMileage:
            service.nextServiceMileage ??
            null,

          title:
            "Service Reminder",

          message:
            "Your vehicle service is due. Please contact the garage to schedule your next service.",

          status:
            "upcoming",
        });
      } else {
        activeServiceReminder.customerId =
          service.customerId;

        activeServiceReminder.vehicleId =
          service.vehicleId;

        activeServiceReminder.dueDate =
          service.nextServiceDate ||
          null;

        activeServiceReminder.dueMileage =
          service.nextServiceMileage ??
          null;

        activeServiceReminder.title =
          "Service Reminder";

        activeServiceReminder.message =
          "Your vehicle service is due. Please contact the garage to schedule your next service.";

        activeServiceReminder.status =
          "upcoming";

        await activeServiceReminder.save();
      }

      // Clean duplicate active service reminders.
      await Reminder.updateMany(
        {
          garageId:
            req.user.garageId,

          serviceId:
            service._id,

          type: "service",

          _id: {
            $nin:
              serviceReminders
                .filter(
                  (r) =>
                    r.status !==
                      "completed" &&
                    r.status !==
                      "cancelled"
                )
                .slice(0, 1)
                .map((r) => r._id),
          },

          status: {
            $nin: [
              "completed",
              "cancelled",
            ],
          },
        },
        {
          $set: {
            status: "completed",
          },
        }
      );
    } else {
      // No next service set.
      // Complete old active reminders for this service.
      await Reminder.updateMany(
        {
          garageId:
            req.user.garageId,

          serviceId:
            service._id,

          type: "service",

          status: {
            $nin: [
              "completed",
              "cancelled",
            ],
          },
        },
        {
          $set: {
            status: "completed",
          },
        }
      );
    }

    // --------------------------------------------------------
    // Fresh populated service
    // --------------------------------------------------------

    const updatedService =
      await Service.findOne({
        _id: id,
        garageId: req.user.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
        );

    return res.status(200).json({
      success: true,
      message: "Service updated successfully",
      service: updatedService,
    });
  } catch (error) {
    console.error(
      "Update service error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to update service",
    });
  }
};

// ============================================================
// DELETE SERVICE
// DELETE /api/services/:id
// ============================================================

const deleteService = async (req, res) => {
  try {
    const service =
      await Service.findOneAndDelete({
        _id: req.params.id,
        garageId: req.user.garageId,
      });

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service record not found",
      });
    }

    // Remove reminders belonging to deleted service.
    await Reminder.deleteMany({
      garageId: req.user.garageId,
      serviceId: service._id,
    });

    return res.status(200).json({
      success: true,
      message: "Service deleted successfully",
    });
  } catch (error) {
    console.error(
      "Delete service error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to delete service",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getServices,
  getServiceById,
  getCustomerServices,
  getVehicleServices,
  createService,
  updateService,
  deleteService,
};