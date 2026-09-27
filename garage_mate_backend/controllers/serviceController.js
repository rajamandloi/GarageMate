const Service = require("../models/Service");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Reminder = require("../models/Reminder");
const Garage = require("../models/Garage");
const Invoice = require("../models/Invoice");

const {
  generateInvoicePDF,
} = require("../services/invoicePdfService");

const {
  sendWhatsAppTemplateWithPdf,
} = require("../services/whatsappService");

const {
  notifyServiceComplete,
  notifyPaymentReceived,
} = require("../services/notificationService");

// ============================================================
// GET ALL SERVICES
// GET /api/services
// ============================================================

const getServices = async (req, res) => {
  try {
    const services = await Service.find({
      garageId: req.garageId,
    })
      .populate("customerId", "name phone email address")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({ serviceDate: -1, createdAt: -1 });

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
      .populate("customerId", "name phone email address")
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
      .populate("customerId", "name phone email address")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({ serviceDate: -1, createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: services.length,
      services,
    });
  } catch (error) {
    console.error("Get customer services error:", error);

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
      .populate("customerId", "name phone email address")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .sort({ serviceDate: -1, createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: services.length,
      services,
    });
  } catch (error) {
    console.error("Get vehicle services error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch vehicle services",
    });
  }
};

// ============================================================
// HELPER: GENERATE INVOICE NUMBER
// ============================================================

const generateInvoiceNumber = async (garageId) => {
  const year = new Date().getFullYear();

  const lastInvoice = await Invoice.findOne({
    garageId,
  }).sort({ createdAt: -1 });

  let nextNumber = 1;

  if (lastInvoice?.invoiceNumber) {
    const match = lastInvoice.invoiceNumber.match(/(\d+)$/);

    if (match) {
      nextNumber = Number(match[1]) + 1;
    }
  }

  return `INV-${year}-${String(nextNumber).padStart(5, "0")}`;
};

// ============================================================
// HELPER: FORMAT AMOUNT
// ============================================================

const formatAmount = (value) => {
  const num = Number(value) || 0;
  return num.toFixed(2);
};

// ============================================================
// HELPER: AUTO GENERATE INVOICE FOR SERVICE
// ============================================================

const autoGenerateInvoiceForService = async ({
  service,
  customer,
  vehicle,
  garage,
  req,
}) => {
  try {
    const existingInvoice = await Invoice.findOne({
      garageId: service.garageId,
      serviceId: service._id,
    });

    if (existingInvoice) {
      console.log(
        "Invoice already exists for service:",
        service._id
      );
      return existingInvoice;
    }

    const laborCost = Number(service.laborCost) || 0;
    const partsCost = Number(service.partsCost) || 0;
    const discount = Number(service.discount) || 0;
    const tax = Number(service.tax) || 0;

    const subtotal = laborCost + partsCost;

    let totalAmount = Number(service.totalAmount);
    if (Number.isNaN(totalAmount)) {
      totalAmount = subtotal - discount + tax;
    }
    totalAmount = Math.max(0, totalAmount);

    const paidAmount = Math.max(
      0,
      Number(service.paidAmount) || 0
    );

    const pendingAmount = Math.max(
      0,
      totalAmount - paidAmount
    );

    let paymentStatus = "pending";
    if (pendingAmount <= 0 && totalAmount > 0) {
      paymentStatus = "paid";
    } else if (paidAmount > 0) {
      paymentStatus = "partiallyPaid";
    }

    const invoiceNumber = await generateInvoiceNumber(
      service.garageId
    );

    const invoice = await Invoice.create({
      garageId: service.garageId,
      serviceId: service._id,
      customerId: service.customerId,
      vehicleId: service.vehicleId,
      invoiceNumber,
      invoiceDate: service.serviceDate || new Date(),
      subtotal,
      discount,
      tax,
      totalAmount,
      paidAmount,
      pendingAmount,
      paymentStatus,
      paymentMethod: service.paymentMethod || "Cash",
      status: "issued",
      pdfUrl: null,
    });

    let populatedInvoice = await Invoice.findOne({
      _id: invoice._id,
      garageId: service.garageId,
    })
      .populate("customerId", "name phone email address")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      )
      .populate("serviceId");

    try {
      const pdfResult = await generateInvoicePDF({
        invoice: populatedInvoice,
        garage,
      });

      if (pdfResult && pdfResult.relativePath) {
        const baseUrl =
          process.env.BACKEND_URL ||
          `${req.protocol}://${req.get("host")}`;

        const cleanBaseUrl = baseUrl.replace(/\/$/, "");

        const pdfUrl = `${cleanBaseUrl}${pdfResult.relativePath}`;

        invoice.pdfUrl = pdfUrl;
        await invoice.save();

        populatedInvoice = await Invoice.findOne({
          _id: invoice._id,
          garageId: service.garageId,
        })
          .populate("customerId", "name phone email address")
          .populate(
            "vehicleId",
            "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
          )
          .populate("serviceId");

        console.log(
          "✅ Invoice PDF generated:",
          invoiceNumber,
          pdfUrl
        );
      }
    } catch (pdfError) {
      console.error(
        "Invoice PDF generation error:",
        pdfError.message
      );
    }

    return populatedInvoice;
  } catch (error) {
    console.error(
      "Auto generate invoice error:",
      error.message
    );
    return null;
  }
};

// ============================================================
// HELPER: COMPLETE PAYMENT REMINDERS (when fully paid)
// ============================================================

const completePaymentReminders = async ({
  garageId,
  serviceId,
}) => {
  try {
    const result = await Reminder.updateMany(
      {
        garageId,
        serviceId,
        type: "payment",
        status: { $ne: "cancelled" },
      },
      {
        $set: {
          status: "completed",
          title: "Payment Received",
          message:
            "Payment has been received. Thank you for your business!",
        },
      }
    );

    console.log(
      `✅ ${result.modifiedCount} payment reminder(s) marked as completed`
    );

    return result.modifiedCount;
  } catch (error) {
    console.error(
      "Complete payment reminders error:",
      error.message
    );
    return 0;
  }
};

// ============================================================
// HELPER: SYNC PAYMENT REMINDER
// ============================================================

const syncPaymentReminder = async ({ garageId, service }) => {
  try {
    const pendingAmount = Math.max(
      0,
      Number(service.totalAmount) - Number(service.paidAmount)
    );

    // --------------------------------------------------------
    // FULLY PAID — mark all active reminders complete
    // --------------------------------------------------------
    if (pendingAmount <= 0) {
      await completePaymentReminders({
        garageId,
        serviceId: service._id,
      });
      return;
    }

    // --------------------------------------------------------
    // PENDING — create or update a payment reminder
    // --------------------------------------------------------
    const paymentReminders = await Reminder.find({
      garageId,
      serviceId: service._id,
      type: "payment",
    });

    let activePaymentReminder = paymentReminders.find(
      (reminder) =>
        reminder.status !== "completed" &&
        reminder.status !== "cancelled"
    );

    if (!activePaymentReminder) {
      activePaymentReminder = await Reminder.create({
        garageId,
        customerId: service.customerId,
        vehicleId: service.vehicleId,
        serviceId: service._id,
        type: "payment",
        dueDate: new Date(),
        dueMileage: null,
        title: "Payment Pending",
        message: `Payment of ₹${formatAmount(
          pendingAmount
        )} is pending for your vehicle service.`,
        status: "dueToday",
      });

      console.log("Payment reminder created");
    } else {
      activePaymentReminder.customerId = service.customerId;
      activePaymentReminder.vehicleId = service.vehicleId;
      activePaymentReminder.dueDate = new Date();
      activePaymentReminder.title = "Payment Pending";
      activePaymentReminder.message = `Payment of ₹${formatAmount(
        pendingAmount
      )} is pending for your vehicle service.`;
      activePaymentReminder.status = "dueToday";

      await activePaymentReminder.save();

      console.log("Payment reminder updated");
    }

    // Clean duplicates
    if (activePaymentReminder) {
      await Reminder.updateMany(
        {
          garageId,
          serviceId: service._id,
          type: "payment",
          _id: { $ne: activePaymentReminder._id },
          status: { $nin: ["completed", "cancelled"] },
        },
        {
          $set: {
            status: "completed",
            title: "Payment Received",
            message:
              "Payment has been received. Thank you for your business!",
          },
        }
      );
    }
  } catch (error) {
    console.error(
      "Sync payment reminder error:",
      error.message
    );
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
    // Validate
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
    // Verify customer
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
    // Verify vehicle
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
    // Amounts
    // --------------------------------------------------------

    const labor = Number(laborCost) || 0;
    const parts = Number(partsCost) || 0;
    const discountValue = Number(discount) || 0;
    const taxValue = Number(tax) || 0;

    let finalTotal = Number(totalAmount);

    if (Number.isNaN(finalTotal)) {
      finalTotal = labor + parts - discountValue + taxValue;
    }

    if (finalTotal < 0) {
      finalTotal = 0;
    }

    const finalPaidAmount = Math.max(
      0,
      Number(paidAmount) || 0
    );

    const safePaidAmount = Math.min(
      finalPaidAmount,
      finalTotal
    );

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
      description: description?.trim() || "",
      partsUsed: partsUsed?.trim() || "",
      laborCost: labor,
      partsCost: parts,
      discount: discountValue,
      tax: taxValue,
      totalAmount: finalTotal,
      paidAmount: safePaidAmount,
      paymentStatus: finalPaymentStatus,
      paymentMethod: paymentMethod || "Cash",
      nextServiceDate: nextServiceDate || null,
      nextServiceMileage:
        nextServiceMileage !== null &&
        nextServiceMileage !== undefined &&
        nextServiceMileage !== ""
          ? Number(nextServiceMileage)
          : null,
      mechanic: mechanic?.trim() || "",
      notes: notes?.trim() || "",
    });

    // --------------------------------------------------------
    // Auto invoice
    // --------------------------------------------------------

    const garage = await Garage.findById(req.user.garageId);

    const invoice = await autoGenerateInvoiceForService({
      service,
      customer,
      vehicle,
      garage,
      req,
    });

    // --------------------------------------------------------
    // WhatsApp send
    // --------------------------------------------------------

    let whatsappResult = {
      sent: false,
      messageId: null,
      error: null,
    };

    try {
      if (!customer.phone) {
        throw new Error(
          "Customer phone number is not available"
        );
      }

      if (!invoice || !invoice.pdfUrl) {
        throw new Error(
          "Invoice PDF is not available for sending"
        );
      }

      const serviceDateObj = service.serviceDate
        ? new Date(service.serviceDate)
        : new Date();

      const dateStr =
        `${String(serviceDateObj.getDate()).padStart(2, "0")}/` +
        `${String(serviceDateObj.getMonth() + 1).padStart(2, "0")}/` +
        `${serviceDateObj.getFullYear()}`;

      const vehicleModel =
        [vehicle.brand, vehicle.model]
          .filter(Boolean)
          .join(" ") ||
        vehicle.registrationNumber ||
        "N/A";

      const bodyParameters = [
        customer.name || "Customer",
        vehicleModel,
        dateStr,
      ];

      const result = await sendWhatsAppTemplateWithPdf({
        garageId: req.user.garageId,
        customerId: customer._id,
        vehicleId: vehicle._id,
        to: customer.phone,
        templateName: "garage_service_bill",
        languageCode: "en",
        type: "bill",
        bodyParameters,
        pdfUrl: invoice.pdfUrl,
        pdfFileName: `${invoice.invoiceNumber}.pdf`,
      });

      whatsappResult = {
        sent: true,
        messageId: result.messageId || null,
        error: null,
      };

      console.log(
        "✅ Invoice WhatsApp sent to:",
        customer.phone
      );
    } catch (whatsappError) {
      whatsappResult = {
        sent: false,
        messageId: null,
        error: whatsappError.message,
      };

      console.error(
        "❌ WhatsApp send failed:",
        whatsappError.message
      );
    }

    // --------------------------------------------------------
    // PAYMENT REMINDER
    // --------------------------------------------------------

    await syncPaymentReminder({
      garageId: req.user.garageId,
      service,
    });

    // --------------------------------------------------------
    // Service reminder
    // --------------------------------------------------------

    if (nextServiceDate || nextServiceMileage) {
      await Reminder.create({
        garageId: req.garageId,
        customerId,
        vehicleId,
        serviceId: service._id,
        type: "service",
        dueDate: nextServiceDate || null,
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

      console.log("Automatic service reminder created");
    }

    // --------------------------------------------------------
    // ✅ FCM NOTIFICATION — SERVICE COMPLETE
    // --------------------------------------------------------
    try {
      await notifyServiceComplete({
        garageId: req.user.garageId,
        customerName: customer.name || "Customer",
        vehicleNumber: vehicle.registrationNumber || "-",
        totalAmount: finalTotal,
        invoiceNumber: invoice?.invoiceNumber || null,
      });

      console.log("✅ Service complete notification sent");
    } catch (notifyError) {
      console.error(
        "Service complete notification error:",
        notifyError.message
      );
    }

    // --------------------------------------------------------
    // ✅ FCM NOTIFICATION — PAYMENT RECEIVED
    // (Only if fully paid)
    // --------------------------------------------------------
    if (
      finalPaymentStatus === "paid" &&
      finalTotal > 0
    ) {
      try {
        await notifyPaymentReceived({
          garageId: req.user.garageId,
          customerName: customer.name || "Customer",
          amount: finalTotal,
        });

        console.log(
          "✅ Payment received notification sent"
        );
      } catch (notifyError) {
        console.error(
          "Payment received notification error:",
          notifyError.message
        );
      }
    }

    // --------------------------------------------------------
    // Populate
    // --------------------------------------------------------

    const populatedService = await Service.findOne({
      _id: service._id,
      garageId: req.user.garageId,
    })
      .populate("customerId", "name phone email address")
      .populate(
        "vehicleId",
        "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
      );

    // --------------------------------------------------------
    // Response
    // --------------------------------------------------------

    let message = "Service created successfully";

    if (invoice) {
      message = `Service created & Invoice ${invoice.invoiceNumber} generated`;

      if (whatsappResult.sent) {
        message += " • Sent on WhatsApp";
      } else if (whatsappResult.error) {
        message += " • WhatsApp failed";
      }
    }

    return res.status(201).json({
      success: true,
      message,
      service: populatedService,
      invoice: invoice || null,
      whatsapp: whatsappResult,
    });
  } catch (error) {
    console.error("Create service error:", error);

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

    const service = await Service.findOne({
      _id: id,
      garageId: req.user.garageId,
    });

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service record not found",
      });
    }

    // Track previous state for notification comparison
    const previousPaymentStatus = service.paymentStatus;
    const previousPaidAmount = Number(service.paidAmount) || 0;

    // --------------------------------------------------------
    // Verify customer
    // --------------------------------------------------------

    if (customerId !== undefined) {
      const customer = await Customer.findOne({
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
    // Verify vehicle
    // --------------------------------------------------------

    if (vehicleId !== undefined) {
      const vehicle = await Vehicle.findOne({
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
    // Basic fields
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

      service.serviceType = serviceType.trim();
    }

    if (mileage !== undefined) {
      service.mileage = Number(mileage) || 0;
    }

    if (description !== undefined) {
      service.description = description?.trim() || "";
    }

    if (partsUsed !== undefined) {
      service.partsUsed = partsUsed?.trim() || "";
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
      finalTotal = labor + parts - discountValue + taxValue;
    }

    if (finalTotal < 0) {
      finalTotal = 0;
    }

    const finalPaidAmount =
      paidAmount !== undefined
        ? Math.max(0, Number(paidAmount) || 0)
        : Math.max(0, Number(service.paidAmount) || 0);

    const safePaidAmount = Math.min(
      finalPaidAmount,
      finalTotal
    );

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

    service.laborCost = labor;
    service.partsCost = parts;
    service.discount = discountValue;
    service.tax = taxValue;

    service.totalAmount = finalTotal;
    service.paidAmount = safePaidAmount;

    service.paymentStatus = finalPaymentStatus;

    service.paymentMethod =
      paymentMethod || service.paymentMethod || "Cash";

    service.nextServiceDate =
      nextServiceDate !== undefined
        ? nextServiceDate || null
        : service.nextServiceDate;

    service.nextServiceMileage =
      nextServiceMileage !== undefined
        ? nextServiceMileage !== null &&
          nextServiceMileage !== ""
          ? Number(nextServiceMileage)
          : null
        : service.nextServiceMileage;

    service.mechanic =
      mechanic !== undefined
        ? mechanic?.trim() || ""
        : service.mechanic;

    service.notes =
      notes !== undefined
        ? notes?.trim() || ""
        : service.notes;

    await service.save();

    // --------------------------------------------------------
    // Update invoice
    // --------------------------------------------------------

    try {
      const existingInvoice = await Invoice.findOne({
        garageId: req.user.garageId,
        serviceId: service._id,
      });

      if (existingInvoice) {
        const laborCost = Number(service.laborCost) || 0;
        const partsCost = Number(service.partsCost) || 0;
        const discount = Number(service.discount) || 0;
        const tax = Number(service.tax) || 0;

        const subtotal = laborCost + partsCost;
        const totalAmount = Math.max(
          0,
          Number(service.totalAmount) || subtotal
        );
        const paidAmount = Math.max(
          0,
          Number(service.paidAmount) || 0
        );
        const pendingAmount = Math.max(
          0,
          totalAmount - paidAmount
        );

        let paymentStatus = "pending";
        if (pendingAmount <= 0 && totalAmount > 0) {
          paymentStatus = "paid";
        } else if (paidAmount > 0) {
          paymentStatus = "partiallyPaid";
        }

        existingInvoice.subtotal = subtotal;
        existingInvoice.discount = discount;
        existingInvoice.tax = tax;
        existingInvoice.totalAmount = totalAmount;
        existingInvoice.paidAmount = paidAmount;
        existingInvoice.pendingAmount = pendingAmount;
        existingInvoice.paymentStatus = paymentStatus;
        existingInvoice.paymentMethod =
          service.paymentMethod || "Cash";

        await existingInvoice.save();
      }
    } catch (invoiceUpdateError) {
      console.error(
        "Invoice update error:",
        invoiceUpdateError.message
      );
    }

    // --------------------------------------------------------
    // PAYMENT REMINDER
    // --------------------------------------------------------

    await syncPaymentReminder({
      garageId: req.user.garageId,
      service,
    });

    // --------------------------------------------------------
    // ✅ FCM NOTIFICATION — PAYMENT RECEIVED
    // (Only if payment just became fully paid)
    // --------------------------------------------------------
    try {
      const wasFullyPaid = previousPaymentStatus === "paid";
      const isNowFullyPaid =
        service.paymentStatus === "paid" &&
        Number(service.totalAmount) > 0;

      if (!wasFullyPaid && isNowFullyPaid) {
        const customer = await Customer.findById(
          service.customerId
        ).select("name");

        await notifyPaymentReceived({
          garageId: req.user.garageId,
          customerName: customer?.name || "Customer",
          amount: Number(service.totalAmount),
        });

        console.log(
          "✅ Payment received notification sent (update)"
        );
      }
    } catch (notifyError) {
      console.error(
        "Payment notification error:",
        notifyError.message
      );
    }

    // --------------------------------------------------------
    // Service reminder sync
    // --------------------------------------------------------

    const serviceReminders = await Reminder.find({
      garageId: req.user.garageId,
      serviceId: service._id,
      type: "service",
    });

    if (
      service.nextServiceDate ||
      service.nextServiceMileage !== null
    ) {
      let activeServiceReminder = serviceReminders.find(
        (reminder) =>
          reminder.status !== "completed" &&
          reminder.status !== "cancelled"
      );

      if (!activeServiceReminder) {
        await Reminder.create({
          garageId: req.user.garageId,
          customerId: service.customerId,
          vehicleId: service.vehicleId,
          serviceId: service._id,
          type: "service",
          dueDate: service.nextServiceDate || null,
          dueMileage: service.nextServiceMileage ?? null,
          title: "Service Reminder",
          message:
            "Your vehicle service is due. Please contact the garage to schedule your next service.",
          status: "upcoming",
        });
      } else {
        activeServiceReminder.customerId = service.customerId;
        activeServiceReminder.vehicleId = service.vehicleId;
        activeServiceReminder.dueDate =
          service.nextServiceDate || null;
        activeServiceReminder.dueMileage =
          service.nextServiceMileage ?? null;
        activeServiceReminder.title = "Service Reminder";
        activeServiceReminder.message =
          "Your vehicle service is due. Please contact the garage to schedule your next service.";
        activeServiceReminder.status = "upcoming";

        await activeServiceReminder.save();
      }

      await Reminder.updateMany(
        {
          garageId: req.user.garageId,
          serviceId: service._id,
          type: "service",
          _id: {
            $nin: serviceReminders
              .filter(
                (r) =>
                  r.status !== "completed" &&
                  r.status !== "cancelled"
              )
              .slice(0, 1)
              .map((r) => r._id),
          },
          status: { $nin: ["completed", "cancelled"] },
        },
        { $set: { status: "completed" } }
      );
    } else {
      await Reminder.updateMany(
        {
          garageId: req.user.garageId,
          serviceId: service._id,
          type: "service",
          status: { $nin: ["completed", "cancelled"] },
        },
        { $set: { status: "completed" } }
      );
    }

    const updatedService = await Service.findOne({
      _id: id,
      garageId: req.user.garageId,
    })
      .populate("customerId", "name phone email address")
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
    console.error("Update service error:", error);

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
    const service = await Service.findOneAndDelete({
      _id: req.params.id,
      garageId: req.user.garageId,
    });

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service record not found",
      });
    }

    await Invoice.deleteMany({
      garageId: req.user.garageId,
      serviceId: service._id,
    });

    await Reminder.deleteMany({
      garageId: req.user.garageId,
      serviceId: service._id,
    });

    return res.status(200).json({
      success: true,
      message: "Service deleted successfully",
    });
  } catch (error) {
    console.error("Delete service error:", error);

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