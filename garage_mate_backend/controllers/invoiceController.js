const Invoice = require("../models/Invoice");
const Service = require("../models/Service");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Garage = require("../models/Garage");

const {
  generateInvoicePDF,
} = require("../services/invoicePdfService");

const {
  sendInvoiceWhatsApp,
} = require("../services/whatsappService");

// ============================================================
// GET GARAGE ID
// ============================================================

const getGarageId = (req) => {
  return (
    req.garageId ||
    req.user?.garageId ||
    null
  );
};


// ============================================================
// GENERATE INVOICE NUMBER
// ============================================================

const generateInvoiceNumber = async (
  garageId
) => {
  const year =
    new Date().getFullYear();

  const lastInvoice =
    await Invoice.findOne({
      garageId,
    }).sort({
      createdAt: -1,
    });

  let nextNumber = 1;

  if (lastInvoice?.invoiceNumber) {
    const match =
      lastInvoice.invoiceNumber.match(
        /(\d+)$/
      );

    if (match) {
      nextNumber =
        Number(match[1]) + 1;
    }
  }

  return `INV-${year}-${String(
    nextNumber
  ).padStart(5, "0")}`;
};


// ============================================================
// CREATE INVOICE FROM SERVICE
// POST /api/invoices
// ============================================================

const createInvoice = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    const {
      serviceId,
    } = req.body;


    // ========================================================
    // VALIDATE GARAGE
    // ========================================================

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }


    // ========================================================
    // VALIDATE SERVICE ID
    // ========================================================

    if (!serviceId) {
      return res.status(400).json({
        success: false,
        message:
          "Service ID is required",
      });
    }


    // ========================================================
    // CHECK GARAGE
    // ========================================================

    const garage =
      await Garage.findById(
        garageId
      );

    if (!garage) {
      return res.status(404).json({
        success: false,
        message:
          "Garage not found",
      });
    }


    // ========================================================
    // CHECK SERVICE
    // ========================================================

    const service =
      await Service.findOne({
        _id: serviceId,
        garageId,
      });

    if (!service) {
      return res.status(404).json({
        success: false,
        message:
          "Service record not found",
      });
    }


    // ========================================================
    // CHECK EXISTING INVOICE
    // ========================================================

    const existingInvoice =
      await Invoice.findOne({
        garageId,
        serviceId,
      });

    if (existingInvoice) {
      return res.status(409).json({
        success: false,
        message:
          "Invoice already exists for this service",
        invoice:
          existingInvoice,
      });
    }


    // ========================================================
    // VERIFY CUSTOMER
    // ========================================================

    const customer =
      await Customer.findOne({
        _id:
          service.customerId,
        garageId,
      });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message:
          "Customer not found",
      });
    }


    // ========================================================
    // VERIFY VEHICLE
    // ========================================================

    const vehicle =
      await Vehicle.findOne({
        _id:
          service.vehicleId,
        garageId,
      });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message:
          "Vehicle not found",
      });
    }


    // ========================================================
    // CALCULATE AMOUNTS
    // ========================================================

    const laborCost =
      Number(service.laborCost) || 0;

    const partsCost =
      Number(service.partsCost) || 0;

    const discount =
      Number(service.discount) || 0;

    const tax =
      Number(service.tax) || 0;

    const subtotal =
      laborCost +
      partsCost;


    let totalAmount =
      Number(service.totalAmount);

    if (
      Number.isNaN(totalAmount)
    ) {
      totalAmount =
        subtotal -
        discount +
        tax;
    }

    totalAmount =
      Math.max(
        0,
        totalAmount
      );


    const paidAmount =
      Math.max(
        0,
        Number(
          service.paidAmount
        ) || 0
      );


    const pendingAmount =
      Math.max(
        0,
        totalAmount -
          paidAmount
      );


    // ========================================================
    // PAYMENT STATUS
    // ========================================================

    let paymentStatus =
      "pending";

    if (
      pendingAmount <= 0 &&
      totalAmount > 0
    ) {
      paymentStatus =
        "paid";
    } else if (
      paidAmount > 0
    ) {
      paymentStatus =
        "partiallyPaid";
    }


    // ========================================================
    // GENERATE INVOICE NUMBER
    // ========================================================

    const invoiceNumber =
      await generateInvoiceNumber(
        garageId
      );


    // ========================================================
    // CREATE INVOICE
    // ========================================================

    const invoice =
      await Invoice.create({
        garageId,

        serviceId,

        customerId:
          service.customerId,

        vehicleId:
          service.vehicleId,

        invoiceNumber,

        invoiceDate:
          service.serviceDate ||
          new Date(),

        subtotal,

        discount,

        tax,

        totalAmount,

        paidAmount,

        pendingAmount,

        paymentStatus,

        paymentMethod:
          service.paymentMethod ||
          "Cash",

        status:
          "issued",

        pdfUrl:
          null,
      });


    // ========================================================
    // POPULATE INVOICE
    // ========================================================

    let populatedInvoice =
      await Invoice.findOne({
        _id:
          invoice._id,
        garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
        )
        .populate(
          "serviceId"
        );


    // ========================================================
    // GENERATE PDF
    // ========================================================

    let pdfResult = null;

    try {
      pdfResult =
        await generateInvoicePDF({
          invoice:
            populatedInvoice,
          garage,
        });

      if (
        !pdfResult ||
        !pdfResult.relativePath
      ) {
        throw new Error(
          "PDF generator did not return a file path"
        );
      }


      // ======================================================
      // CREATE PUBLIC PDF URL
      // ======================================================

      const baseUrl =
        process.env.BACKEND_URL ||
        `${req.protocol}://${req.get(
          "host"
        )}`;

      const cleanBaseUrl =
        baseUrl.replace(
          /\/$/,
          ""
        );

      const pdfUrl =
        `${cleanBaseUrl}${pdfResult.relativePath}`;


      // ======================================================
      // SAVE PDF URL
      // ======================================================

      invoice.pdfUrl =
        pdfUrl;

      await invoice.save();


      // ======================================================
      // UPDATE RESPONSE OBJECT
      // ======================================================

      populatedInvoice =
        await Invoice.findOne({
          _id:
            invoice._id,
          garageId,
        })
          .populate(
            "customerId",
            "name phone email address"
          )
          .populate(
            "vehicleId",
            "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
          )
          .populate(
            "serviceId"
          );


      console.log(
        "================================================"
      );

      console.log(
        "Invoice PDF generated successfully"
      );

      console.log(
        "Invoice:",
        invoice.invoiceNumber
      );

      console.log(
        "PDF:",
        pdfUrl
      );

      console.log(
        "================================================"
      );

    } catch (pdfError) {

      // ======================================================
      // PDF ERROR
      // ======================================================

      console.error(
        "Invoice PDF generation error:",
        pdfError
      );


      // ------------------------------------------------------
      // IMPORTANT:
      // Invoice DB record remains safe.
      // PDF can be generated later.
      // ------------------------------------------------------

      return res.status(201).json({
        success: true,

        message:
          "Invoice created successfully, but PDF generation failed",

        invoice:
          populatedInvoice,

        pdf: {
          generated: false,
          url: null,
        },

        pdfError:
          pdfError.message,
      });
    }


    // ========================================================
    // FINAL RESPONSE
    // ========================================================

    return res.status(201).json({
      success: true,

      message:
        "Invoice created and PDF generated successfully",

      invoice:
        populatedInvoice,

      pdf: {
        generated: true,

        fileName:
          pdfResult.fileName,

        url:
          populatedInvoice.pdfUrl,
      },
    });

  } catch (error) {

    console.error(
      "Create invoice error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        "Unable to create invoice",

      error:
        error.message,
    });
  }
};


// ============================================================
// GET ALL INVOICES
// GET /api/invoices
// ============================================================

const getInvoices = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }


    const invoices =
      await Invoice.find({
        garageId,
      })
        .populate(
          "customerId",
          "name phone email"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant"
        )
        .populate(
          "serviceId",
          "serviceDate serviceType totalAmount paidAmount paymentStatus"
        )
        .sort({
          invoiceDate: -1,
          createdAt: -1,
        });


    return res.status(200).json({
      success: true,

      count:
        invoices.length,

      invoices,
    });

  } catch (error) {

    console.error(
      "Get invoices error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        "Unable to fetch invoices",

      error:
        error.message,
    });
  }
};


// ============================================================
// GET SINGLE INVOICE
// GET /api/invoices/:id
// ============================================================

const getInvoiceById = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }


    const invoice =
      await Invoice.findOne({
        _id:
          req.params.id,

        garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant manufacturingYear fuelType currentMileage"
        )
        .populate(
          "serviceId"
        );


    if (!invoice) {
      return res.status(404).json({
        success: false,

        message:
          "Invoice not found",
      });
    }


    return res.status(200).json({
      success: true,

      invoice,
    });

  } catch (error) {

    console.error(
      "Get invoice error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        "Unable to fetch invoice",

      error:
        error.message,
    });
  }
};


// ============================================================
// GET CUSTOMER INVOICES
// GET /api/invoices/customer/:customerId
// ============================================================

const getCustomerInvoices = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    if (!garageId) {
      return res.status(400).json({
        success: false,

        message:
          "Garage is not associated with this account",
      });
    }


    const customer =
      await Customer.findOne({
        _id:
          req.params.customerId,

        garageId,
      });


    if (!customer) {
      return res.status(404).json({
        success: false,

        message:
          "Customer not found",
      });
    }


    const invoices =
      await Invoice.find({
        garageId,

        customerId:
          req.params.customerId,
      })
        .populate(
          "vehicleId",
          "registrationNumber brand model variant"
        )
        .populate(
          "serviceId",
          "serviceDate serviceType totalAmount paidAmount paymentStatus"
        )
        .sort({
          invoiceDate: -1,

          createdAt: -1,
        });


    return res.status(200).json({
      success: true,

      count:
        invoices.length,

      invoices,
    });

  } catch (error) {

    console.error(
      "Get customer invoices error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        "Unable to fetch customer invoices",

      error:
        error.message,
    });
  }
};


// ============================================================
// CANCEL INVOICE
// PATCH /api/invoices/:id/cancel
// ============================================================

const cancelInvoice = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    if (!garageId) {
      return res.status(400).json({
        success: false,

        message:
          "Garage is not associated with this account",
      });
    }


    const invoice =
      await Invoice.findOne({
        _id:
          req.params.id,

        garageId,
      });


    if (!invoice) {
      return res.status(404).json({
        success: false,

        message:
          "Invoice not found",
      });
    }


    if (
      invoice.status ===
      "cancelled"
    ) {
      return res.status(400).json({
        success: false,

        message:
          "Invoice is already cancelled",
      });
    }


    invoice.status =
      "cancelled";

    await invoice.save();


    return res.status(200).json({
      success: true,

      message:
        "Invoice cancelled successfully",

      invoice,
    });

  } catch (error) {

    console.error(
      "Cancel invoice error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        "Unable to cancel invoice",

      error:
        error.message,
    });
  }
};

// ============================================================
// SEND INVOICE ON WHATSAPP
// POST /api/invoices/:id/send-whatsapp
// ============================================================

const sendInvoiceOnWhatsApp = async (
  req,
  res
) => {
  try {
    const garageId =
      getGarageId(req);

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    // ========================================================
    // FIND INVOICE
    // ========================================================

    const invoice =
      await Invoice.findOne({
        _id: req.params.id,
        garageId,
      })
        .populate(
          "customerId",
          "name phone email"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model variant"
        )
        .populate(
          "serviceId"
        );

    if (!invoice) {
      return res.status(404).json({
        success: false,
        message:
          "Invoice not found",
      });
    }

    // ========================================================
    // CHECK PDF
    // ========================================================

    if (!invoice.pdfUrl) {
      return res.status(400).json({
        success: false,
        message:
          "Invoice PDF is not available",
      });
    }

    // ========================================================
    // CUSTOMER PHONE
    // ========================================================

    const customerPhone =
      invoice.customerId?.phone;

    if (!customerPhone) {
      return res.status(400).json({
        success: false,
        message:
          "Customer WhatsApp number is not available",
      });
    }

    // ========================================================
    // CALCULATE PENDING
    // ========================================================

    const totalAmount =
      Number(invoice.totalAmount) || 0;

    const paidAmount =
      Number(invoice.paidAmount) || 0;

    const pendingAmount =
      Math.max(
        0,
        totalAmount - paidAmount
      );

    // ========================================================
    // SERVICE DATE
    // ========================================================

    const serviceDate =
      invoice.serviceId?.serviceDate
        ? new Date(
            invoice.serviceId.serviceDate
          ).toLocaleDateString("en-IN")
        : "-";

    // ========================================================
    // SEND WHATSAPP
    // ========================================================

    const result =
      await sendInvoiceWhatsApp({
        garageId,

        to: customerPhone,

        customerName:
          invoice.customerId?.name ||
          "Customer",

        vehicleNumber:
          invoice.vehicleId
            ?.registrationNumber ||
          "-",

        serviceDate,

        totalAmount,

        paidAmount,

        pendingAmount,
      });

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,

      message:
        "Invoice sent successfully on WhatsApp",

      invoiceId:
        invoice._id,

      invoiceNumber:
        invoice.invoiceNumber,

      pdfUrl:
        invoice.pdfUrl,

      whatsappMessageId:
        result.messageId || null,
    });

  } catch (error) {

    console.error(
      "Send invoice WhatsApp error:",
      error
    );

    return res.status(500).json({
      success: false,

      message:
        error.message ||
        "Unable to send invoice on WhatsApp",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  createInvoice,
  getInvoices,
  getInvoiceById,
  getCustomerInvoices,
  cancelInvoice,
  sendInvoiceOnWhatsApp,
};