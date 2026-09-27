const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
const fs = require("fs");
const path = require("path");

// ============================================================
// DEFAULT BRAND COLORS
// ============================================================

const DEFAULT_PRIMARY = "#4A6CF7";
const DEFAULT_SECONDARY = "#25D366";

// ============================================================
// FORMAT DATE
// ============================================================

const formatDate = (date) => {
  if (!date) return "-";

  const d = new Date(date);
  if (Number.isNaN(d.getTime())) return "-";

  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();

  return `${day}/${month}/${year}`;
};

// ============================================================
// FORMAT AMOUNT
// ============================================================

const formatAmount = (amount) => {
  const value = Number(amount) || 0;
  return `Rs. ${value.toFixed(2)}`;
};

// ============================================================
// HEX → RGB
// ============================================================

const hexToRgb = (hex) => {
  try {
    const clean = String(hex).replace("#", "");
    if (clean.length !== 6) throw new Error("bad");

    const r = parseInt(clean.substring(0, 2), 16);
    const g = parseInt(clean.substring(2, 4), 16);
    const b = parseInt(clean.substring(4, 6), 16);

    return { r, g, b };
  } catch {
    return { r: 74, g: 108, b: 247 };
  }
};

// ============================================================
// GET CONTRASTING TEXT COLOR
// Returns "#000000" (black) or "#FFFFFF" (white)
// based on background luminance
// ============================================================

const getContrastColor = (backgroundHex) => {
  try {
    const { r, g, b } = hexToRgb(backgroundHex);

    // W3C luminance formula (perceptual brightness)
    const luminance =
      (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    // If background is light → black text
    // If background is dark → white text
    return luminance > 0.5 ? "#000000" : "#FFFFFF";
  } catch {
    return "#FFFFFF";
  }
};

// ============================================================
// GENERATE INVOICE PDF
// ============================================================

const generateInvoicePDF = async ({ invoice, garage }) => {
  if (!invoice) throw new Error("Invoice data is required");
  if (!garage) throw new Error("Garage data is required");

  // ============================================================
  // PATHS
  // ============================================================

  const uploadDirectory = path.join(
    process.cwd(),
    "uploads",
    "invoices"
  );

  if (!fs.existsSync(uploadDirectory)) {
    fs.mkdirSync(uploadDirectory, { recursive: true });
  }

  const invoiceNumber =
    invoice.invoiceNumber || `invoice-${invoice._id}`;

  const safeInvoiceNumber = String(invoiceNumber).replace(
    /[^a-zA-Z0-9-_]/g,
    "-"
  );

  const fileName = `${safeInvoiceNumber}.pdf`;
  const filePath = path.join(uploadDirectory, fileName);

  // ============================================================
  // SETTINGS
  // ============================================================

  const settings = garage.invoiceSettings || {};

  const primaryHex = settings.primaryColor || DEFAULT_PRIMARY;
  const secondaryHex =
    settings.secondaryColor || DEFAULT_SECONDARY;

  const primaryRgb = hexToRgb(primaryHex);
  const secondaryRgb = hexToRgb(secondaryHex);

  // ✅ SMART TEXT COLORS
  const headerTextColor = getContrastColor(primaryHex);
  const totalTextColor = getContrastColor(secondaryHex);

  const footerMessage =
    settings.footerMessage ||
    "Thank you for choosing our garage!";

  const terms = settings.termsAndConditions || "";
  const upiId = settings.upiId || "";

  // ============================================================
  // QR CODE (if UPI ID present)
  // ============================================================

  let qrBuffer = null;

  if (upiId && upiId.includes("@")) {
    try {
      const totalAmount = Number(invoice.totalAmount) || 0;
      const paidAmount = Number(invoice.paidAmount) || 0;
      const pending = Math.max(0, totalAmount - paidAmount);

      // UPI deep-link (NPCI spec)
      const upiUrl =
        `upi://pay?pa=${encodeURIComponent(upiId)}` +
        `&pn=${encodeURIComponent(garage.name || "Garage")}` +
        `&am=${pending > 0 ? pending : totalAmount}` +
        `&cu=INR` +
        `&tn=${encodeURIComponent(`Invoice ${invoiceNumber}`)}`;

      qrBuffer = await QRCode.toBuffer(upiUrl, {
        type: "png",
        width: 300,
        margin: 1,
        color: {
          dark: "#000000",
          light: "#FFFFFF",
        },
      });
    } catch (qrError) {
      console.warn(
        "QR code generation failed:",
        qrError.message
      );
      qrBuffer = null;
    }
  }

  // ============================================================
  // LOGO BUFFER
  // ============================================================

  let logoBuffer = null;

  if (settings.logo) {
    try {
      const logoPath = path.join(
        process.cwd(),
        settings.logo.replace(/^\//, "")
      );

      if (fs.existsSync(logoPath)) {
        logoBuffer = fs.readFileSync(logoPath);
      }
    } catch (logoError) {
      console.warn("Logo load failed:", logoError.message);
      logoBuffer = null;
    }
  }

  // ============================================================
  // CREATE PDF
  // ============================================================

  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        size: "A4",
        margin: 40,
      });

      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      const pageWidth = doc.page.width;
      const pageMargin = 40;
      const contentWidth = pageWidth - pageMargin * 2;

      // ========================================================
      // HEADER BACKGROUND
      // ========================================================

      doc
        .rect(0, 0, pageWidth, 130)
        .fill(primaryHex);

      // ========================================================
      // LOGO
      // ========================================================

      let headerTextX = pageMargin;

      if (logoBuffer) {
        try {
          // White background box for logo
          doc
            .rect(pageMargin, 25, 70, 70)
            .fill("#FFFFFF");

          doc.image(logoBuffer, pageMargin + 5, 30, {
            fit: [60, 60],
            align: "center",
            valign: "center",
          });

          headerTextX = pageMargin + 90;
        } catch {
          headerTextX = pageMargin;
        }
      }

      // ========================================================
      // GARAGE NAME + DETAILS
      // ========================================================

      doc
        .fillColor(headerTextColor)
        .font("Helvetica-Bold")
        .fontSize(20)
        .text(
          garage.name || "GarageMate Garage",
          headerTextX,
          25
        );

      doc
        .font("Helvetica")
        .fontSize(9)
        .fillColor(headerTextColor);

      let headerY = 52;

      if (garage.address) {
        doc.text(
          `${garage.address}${
            garage.city ? `, ${garage.city}` : ""
          }`,
          headerTextX,
          headerY
        );
        headerY += 13;
      }

      if (garage.phone) {
        doc.text(
          `Phone: ${garage.phone}`,
          headerTextX,
          headerY
        );
        headerY += 13;
      }

      if (garage.email) {
        doc.text(
          `Email: ${garage.email}`,
          headerTextX,
          headerY
        );
        headerY += 13;
      }

      // ========================================================
      // INVOICE NUMBER + DATE (top-right)
      // ========================================================

      doc
        .font("Helvetica-Bold")
        .fontSize(11)
        .fillColor(headerTextColor)
        .text(`INVOICE`, pageMargin, 95, {
          width: contentWidth,
          align: "right",
        });

      doc
        .font("Helvetica")
        .fontSize(9)
        .fillColor(headerTextColor)
        .text(`#${invoiceNumber}`, pageMargin, 110, {
          width: contentWidth,
          align: "right",
        });

      // ========================================================
      // INVOICE DATE BAR
      // ========================================================

      doc
        .fillColor("#111827")
        .font("Helvetica-Bold")
        .fontSize(10);

      let yPos = 150;

      doc.text(
        `Invoice Date: ${formatDate(invoice.invoiceDate)}`,
        pageMargin,
        yPos
      );

      doc.text(
        `Payment Status: ${String(
          invoice.paymentStatus || "pending"
        ).toUpperCase()}`,
        pageMargin,
        yPos,
        {
          width: contentWidth,
          align: "right",
        }
      );

      yPos += 25;

      // ========================================================
      // BILL TO + VEHICLE (two columns)
      // ========================================================

      const colWidth = contentWidth / 2 - 10;

      // Left column — BILL TO
      doc
        .fillColor(primaryHex)
        .font("Helvetica-Bold")
        .fontSize(11)
        .text("BILL TO", pageMargin, yPos);

      doc
        .fillColor("#111827")
        .font("Helvetica-Bold")
        .fontSize(10)
        .text(
          invoice.customerId?.name ||
            invoice.customerName ||
            "-",
          pageMargin,
          yPos + 18
        );

      doc.font("Helvetica").fontSize(9);

      if (
        invoice.customerId?.phone ||
        invoice.customerPhone
      ) {
        doc
          .fillColor("#374151")
          .text(
            `Phone: ${
              invoice.customerId?.phone ||
              invoice.customerPhone
            }`,
            pageMargin,
            yPos + 32
          );
      }

      if (invoice.customerId?.address) {
        doc
          .fillColor("#374151")
          .text(
            `Address: ${invoice.customerId.address}`,
            pageMargin,
            yPos + 46,
            { width: colWidth }
          );
      }

      // Right column — VEHICLE
      const rightColX = pageMargin + colWidth + 20;

      doc
        .fillColor(primaryHex)
        .font("Helvetica-Bold")
        .fontSize(11)
        .text("VEHICLE", rightColX, yPos);

      doc
        .fillColor("#111827")
        .font("Helvetica-Bold")
        .fontSize(10)
        .text(
          `Reg: ${
            invoice.vehicleId?.registrationNumber ||
            invoice.vehicleNumber ||
            "-"
          }`,
          rightColX,
          yPos + 18
        );

      const vBrand = invoice.vehicleId?.brand || "";
      const vModel = invoice.vehicleId?.model || "";
      const vName = `${vBrand} ${vModel}`.trim();

      doc.font("Helvetica").fontSize(9);

      if (vName) {
        doc
          .fillColor("#374151")
          .text(
            `Vehicle: ${vName}`,
            rightColX,
            yPos + 32
          );
      }

      if (
        invoice.vehicleId?.currentMileage !== undefined &&
        invoice.vehicleId?.currentMileage !== null
      ) {
        doc
          .fillColor("#374151")
          .text(
            `Mileage: ${invoice.vehicleId.currentMileage} km`,
            rightColX,
            yPos + 46
          );
      }

      yPos += 80;

      // ========================================================
      // SERVICE DETAILS
      // ========================================================

      doc
        .fillColor(primaryHex)
        .font("Helvetica-Bold")
        .fontSize(11)
        .text("SERVICE DETAILS", pageMargin, yPos);

      yPos += 18;

      doc
        .fillColor("#111827")
        .font("Helvetica-Bold")
        .fontSize(10);

      doc.text(
        `Service: ${
          invoice.serviceId?.serviceType ||
          invoice.serviceType ||
          "-"
        }`,
        pageMargin,
        yPos
      );

      const serviceDate =
        invoice.serviceId?.serviceDate ||
        invoice.serviceDate;

      doc.font("Helvetica").fontSize(9);

      if (serviceDate) {
        doc
          .fillColor("#374151")
          .text(
            `Date: ${formatDate(serviceDate)}`,
            pageMargin,
            yPos,
            {
              width: contentWidth,
              align: "right",
            }
          );
      }

      yPos += 25;

      // ========================================================
      // AMOUNTS TABLE
      // ========================================================

      const laborCost = Number(
        invoice.serviceId?.laborCost ??
          invoice.laborCost ??
          0
      );
      const partsCost = Number(
        invoice.serviceId?.partsCost ??
          invoice.partsCost ??
          0
      );
      const discount = Number(
        invoice.serviceId?.discount ??
          invoice.discount ??
          0
      );
      const tax = Number(
        invoice.serviceId?.tax ?? invoice.tax ?? 0
      );

      const totalAmount = Number(invoice.totalAmount) || 0;
      const paidAmount = Number(invoice.paidAmount) || 0;
      const pendingAmount = Math.max(
        0,
        totalAmount - paidAmount
      );

      // Table header
      doc
        .rect(pageMargin, yPos, contentWidth, 24)
        .fill(primaryHex);

      doc
        .fillColor(headerTextColor)
        .font("Helvetica-Bold")
        .fontSize(10)
        .text("Description", pageMargin + 10, yPos + 7)
        .text("Amount", pageMargin, yPos + 7, {
          width: contentWidth - 10,
          align: "right",
        });

      yPos += 24;

      // Row helper
      const addRow = (label, amount, isTotal = false) => {
        if (isTotal) {
          doc
            .rect(pageMargin, yPos, contentWidth, 26)
            .fill(secondaryHex);

          doc
            .fillColor(totalTextColor)
            .font("Helvetica-Bold")
            .fontSize(11)
            .text(label, pageMargin + 10, yPos + 8)
            .text(
              formatAmount(amount),
              pageMargin,
              yPos + 8,
              {
                width: contentWidth - 10,
                align: "right",
              }
            );

          yPos += 26;
        } else {
          doc
            .fillColor("#111827")
            .font("Helvetica-Bold")
            .fontSize(10)
            .text(label, pageMargin + 10, yPos + 6)
            .text(
              formatAmount(amount),
              pageMargin,
              yPos + 6,
              {
                width: contentWidth - 10,
                align: "right",
              }
            );

          // Divider
          doc
            .moveTo(pageMargin, yPos + 24)
            .lineTo(
              pageMargin + contentWidth,
              yPos + 24
            )
            .strokeColor("#E5E7EB")
            .lineWidth(0.5)
            .stroke();

          yPos += 24;
        }
      };

      addRow("Labour Charges", laborCost);
      addRow("Parts Charges", partsCost);

      if (discount > 0) {
        addRow("Discount", -discount);
      }

      if (tax > 0) {
        addRow("Tax", tax);
      }

      addRow("TOTAL", totalAmount, true);
      addRow("Paid", paidAmount);
      addRow("Pending", pendingAmount);

      yPos += 20;

      // ========================================================
      // PAYMENT QR CODE
      // ========================================================

      if (qrBuffer) {
        doc
          .fillColor(primaryHex)
          .font("Helvetica-Bold")
          .fontSize(11)
          .text("PAYMENT", pageMargin, yPos);

        yPos += 16;

        try {
          doc.image(qrBuffer, pageMargin, yPos, {
            fit: [90, 90],
          });

          doc
            .fillColor("#111827")
            .font("Helvetica-Bold")
            .fontSize(9)
            .text("Scan to Pay", pageMargin, yPos + 95, {
              width: 90,
              align: "center",
            });

          const textX = pageMargin + 110;

          doc
            .fillColor("#374151")
            .font("Helvetica")
            .fontSize(10)
            .text("UPI ID:", textX, yPos + 5);

          doc
            .fillColor("#111827")
            .font("Helvetica-Bold")
            .fontSize(11)
            .text(upiId, textX, yPos + 20);

          doc
            .font("Helvetica")
            .fontSize(9)
            .fillColor("#6B7280")
            .text(
              "Pay via any UPI app\n(GPay, PhonePe, Paytm, etc.)",
              textX,
              yPos + 40,
              { width: contentWidth - 110 }
            );

          yPos += 110;
        } catch {
          yPos += 10;
        }
      }

      // ========================================================
      // TERMS & CONDITIONS
      // ========================================================

      if (terms) {
        yPos += 10;

        doc
          .fillColor(primaryHex)
          .font("Helvetica-Bold")
          .fontSize(10)
          .text("TERMS & CONDITIONS", pageMargin, yPos);

        yPos += 14;

        doc
          .fillColor("#374151")
          .font("Helvetica")
          .fontSize(9)
          .text(terms, pageMargin, yPos, {
            width: contentWidth,
            align: "left",
          });

        yPos +=
          doc.heightOfString(terms, {
            width: contentWidth,
          }) + 10;
      }

      // ========================================================
      // FOOTER
      // ========================================================

      const footerY = doc.page.height - 70;

      doc
        .rect(0, footerY - 10, pageWidth, 80)
        .fill("#F9FAFB");

      doc
        .fillColor("#111827")
        .font("Helvetica-Bold")
        .fontSize(11)
        .text(footerMessage, pageMargin, footerY, {
          width: contentWidth,
          align: "center",
        });

      doc
        .fillColor("#6B7280")
        .font("Helvetica")
        .fontSize(8)
        .text(
          `Powered by GarageMate  •  ${
            garage.phone || ""
          }  •  ${garage.email || ""}`,
          pageMargin,
          footerY + 18,
          {
            width: contentWidth,
            align: "center",
          }
        );

      // ========================================================
      // FINALIZE
      // ========================================================

      doc.end();

      stream.on("finish", () => {
        resolve({
          fileName,
          filePath,
          relativePath: `/uploads/invoices/${fileName}`,
        });
      });

      stream.on("error", reject);
    } catch (error) {
      reject(error);
    }
  });
};

module.exports = {
  generateInvoicePDF,
};