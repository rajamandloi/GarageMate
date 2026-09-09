
const PDFDocument = require("pdfkit");
const fs = require("fs");
const path = require("path");

// ============================================================
// FORMAT DATE
// Always DD/MM/YYYY
// Example: 21/08/2026
// ============================================================

const formatDate = (date) => {
  if (!date) {
    return "-";
  }

  const d = new Date(date);

  if (Number.isNaN(d.getTime())) {
    return "-";
  }

  const day = String(
    d.getDate()
  ).padStart(2, "0");

  const month = String(
    d.getMonth() + 1
  ).padStart(2, "0");

  const year =
    d.getFullYear();

  return `${day}/${month}/${year}`;
};


// ============================================================
// FORMAT AMOUNT
// IMPORTANT:
// Do NOT use ₹ with PDFKit default Helvetica font.
// "Rs." avoids Unicode/font corruption.
// ============================================================

const formatAmount = (amount) => {
  const value =
    Number(amount) || 0;

  return `Rs. ${value.toFixed(2)}`;
};


// ============================================================
// GENERATE INVOICE PDF
// ============================================================

const generateInvoicePDF = async ({
  invoice,
  garage,
}) => {
  if (!invoice) {
    throw new Error(
      "Invoice data is required"
    );
  }

  if (!garage) {
    throw new Error(
      "Garage data is required"
    );
  }

  // ============================================================
  // PDF DIRECTORY
  // ============================================================

  const uploadDirectory =
    path.join(
      process.cwd(),
      "uploads",
      "invoices"
    );

  if (
    !fs.existsSync(
      uploadDirectory
    )
  ) {
    fs.mkdirSync(
      uploadDirectory,
      {
        recursive: true,
      }
    );
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  const invoiceNumber =
    invoice.invoiceNumber ||
    `invoice-${invoice._id}`;

  const safeInvoiceNumber =
    String(
      invoiceNumber
    ).replace(
      /[^a-zA-Z0-9-_]/g,
      "-"
    );

  const fileName =
    `${safeInvoiceNumber}.pdf`;

  const filePath =
    path.join(
      uploadDirectory,
      fileName
    );

  // ============================================================
  // CREATE PDF
  // ============================================================

  return new Promise(
    (resolve, reject) => {
      try {
        const doc =
          new PDFDocument({
            size: "A4",
            margin: 50,
          });

        const stream =
          fs.createWriteStream(
            filePath
          );

        doc.pipe(stream);

        // ======================================================
        // GARAGE HEADER
        // ======================================================

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(22)
          .text(
            garage.name ||
              "GarageMate Garage",
            {
              align: "center",
            }
          );

        doc.moveDown(0.5);

        doc
          .font("Helvetica")
          .fontSize(10)
          .text(
            garage.address || "",
            {
              align: "center",
            }
          );

        if (garage.phone) {
          doc.text(
            `Phone: ${garage.phone}`,
            {
              align: "center",
            }
          );
        }

        if (garage.email) {
          doc.text(
            `Email: ${garage.email}`,
            {
              align: "center",
            }
          );
        }

        // ======================================================
        // DIVIDER
        // ======================================================

        doc
          .moveDown()
          .moveTo(
            50,
            doc.y
          )
          .lineTo(
            545,
            doc.y
          )
          .stroke();

        // ======================================================
        // INVOICE TITLE
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(20)
          .text(
            "SERVICE INVOICE",
            {
              align: "center",
            }
          );

        doc.moveDown();

        // ======================================================
        // INVOICE INFORMATION
        // ======================================================

        const invoiceDate =
          formatDate(
            invoice.invoiceDate
          );

        doc
          .font("Helvetica")
          .fontSize(11);

        doc.text(
          `Invoice No: ${
            invoice.invoiceNumber ||
            "-"
          }`
        );

        doc.text(
          `Invoice Date: ${invoiceDate}`
        );

        // ======================================================
        // CUSTOMER DETAILS
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(13)
          .text(
            "Customer Details"
          );

        doc.moveDown(0.3);

        doc
          .font("Helvetica")
          .fontSize(10);

        doc.text(
          `Name: ${
            invoice.customerId
              ?.name ||
            invoice.customerName ||
            "-"
          }`
        );

        doc.text(
          `Phone: ${
            invoice.customerId
              ?.phone ||
            invoice.customerPhone ||
            "-"
          }`
        );

        if (
          invoice.customerId
            ?.email ||
          invoice.customerEmail
        ) {
          doc.text(
            `Email: ${
              invoice.customerId
                ?.email ||
              invoice.customerEmail
            }`
          );
        }

        if (
          invoice.customerId
            ?.address
        ) {
          doc.text(
            `Address: ${
              invoice.customerId
                .address
            }`
          );
        }

        // ======================================================
        // VEHICLE DETAILS
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(13)
          .text(
            "Vehicle Details"
          );

        doc.moveDown(0.3);

        doc
          .font("Helvetica")
          .fontSize(10);

        doc.text(
          `Registration No: ${
            invoice.vehicleId
              ?.registrationNumber ||
            invoice.vehicleNumber ||
            "-"
          }`
        );

        const vehicleBrand =
          invoice.vehicleId
            ?.brand ||
          "";

        const vehicleModel =
          invoice.vehicleId
            ?.model ||
          "";

        const vehicleName =
          `${vehicleBrand} ${vehicleModel}`
            .trim();

        doc.text(
          `Vehicle: ${
            vehicleName ||
            "-"
          }`
        );

        if (
          invoice.vehicleId
            ?.variant
        ) {
          doc.text(
            `Variant: ${
              invoice.vehicleId
                .variant
            }`
          );
        }

        if (
          invoice.vehicleId
            ?.currentMileage !==
            undefined &&
          invoice.vehicleId
            ?.currentMileage !==
            null
        ) {
          doc.text(
            `Mileage: ${
              invoice.vehicleId
                .currentMileage
            } km`
          );
        }

        if (
          invoice.vehicleId
            ?.fuelType
        ) {
          doc.text(
            `Fuel Type: ${
              invoice.vehicleId
                .fuelType
            }`
          );
        }

        // ======================================================
        // SERVICE DETAILS
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(13)
          .text(
            "Service Details"
          );

        doc.moveDown(0.5);

        doc
          .font("Helvetica")
          .fontSize(10);

        doc.text(
          `Service: ${
            invoice.serviceId
              ?.serviceType ||
            invoice.serviceType ||
            "-"
          }`
        );

        const serviceDate =
          invoice.serviceId
            ?.serviceDate ||
          invoice.serviceDate;

        if (serviceDate) {
          doc.text(
            `Service Date: ${formatDate(
              serviceDate
            )}`
          );
        }

        if (
          invoice.serviceId
            ?.description
        ) {
          doc.text(
            `Description: ${
              invoice.serviceId
                .description
            }`
          );
        }

        // ======================================================
        // AMOUNT CALCULATION
        // ======================================================

        const laborCost =
          Number(
            invoice.serviceId
              ?.laborCost ??
            invoice.laborCost ??
            0
          );

        const partsCost =
          Number(
            invoice.serviceId
              ?.partsCost ??
            invoice.partsCost ??
            0
          );

        const discount =
          Number(
            invoice.serviceId
              ?.discount ??
            invoice.discount ??
            0
          );

        const tax =
          Number(
            invoice.serviceId
              ?.tax ??
            invoice.tax ??
            0
          );

        const totalAmount =
          Number(
            invoice.totalAmount
          ) || 0;

        const paidAmount =
          Number(
            invoice.paidAmount
          ) || 0;

        const pendingAmount =
          Math.max(
            0,
            totalAmount -
              paidAmount
          );

        // ======================================================
        // PAYMENT DETAILS
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(13)
          .text(
            "Payment Details"
          );

        doc.moveDown(0.5);

        doc
          .font("Helvetica")
          .fontSize(10);

        doc.text(
          `Labour Charges: ${formatAmount(
            laborCost
          )}`
        );

        doc.text(
          `Parts Charges: ${formatAmount(
            partsCost
          )}`
        );

        doc.text(
          `Discount: ${formatAmount(
            discount
          )}`
        );

        doc.text(
          `Tax: ${formatAmount(
            tax
          )}`
        );

        // ======================================================
        // TOTAL SECTION
        // ======================================================

        doc.moveDown();

        doc
          .moveTo(
            50,
            doc.y
          )
          .lineTo(
            545,
            doc.y
          )
          .stroke();

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(13);

        doc.text(
          `Total Amount: ${formatAmount(
            totalAmount
          )}`
        );

        doc.text(
          `Paid Amount: ${formatAmount(
            paidAmount
          )}`
        );

        doc.text(
          `Pending Amount: ${formatAmount(
            pendingAmount
          )}`
        );

        // ======================================================
        // PAYMENT STATUS
        // ======================================================

        doc.moveDown();

        doc
          .font(
            "Helvetica-Bold"
          )
          .fontSize(11)
          .text(
            `Payment Status: ${
              invoice.paymentStatus ||
              "pending"
            }`
          );

        if (
          invoice.paymentMethod
        ) {
          doc
            .font("Helvetica")
            .text(
              `Payment Method: ${
                invoice.paymentMethod
              }`
            );
        }

        // ======================================================
        // FOOTER
        // ======================================================

        doc.moveDown(2);

        doc
          .font("Helvetica")
          .fontSize(9)
          .text(
            "Thank you for choosing our garage.",
            {
              align: "center",
            }
          );

        doc.moveDown(0.3);

        doc.text(
          "Powered by GarageMate",
          {
            align: "center",
          }
        );

        // ======================================================
        // FINALIZE
        // ======================================================

        doc.end();

        stream.on(
          "finish",
          () => {
            resolve({
              fileName,
              filePath,
              relativePath:
                `/uploads/invoices/${fileName}`,
            });
          }
        );

        stream.on(
          "error",
          (error) => {
            reject(error);
          }
        );
      } catch (error) {
        reject(error);
      }
    }
  );
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  generateInvoicePDF,
};

