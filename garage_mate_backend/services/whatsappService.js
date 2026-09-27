const fs = require("fs");
const path = require("path");
const axios = require("axios");
const FormData = require("form-data");

const WhatsAppIntegration = require(
  "../models/WhatsAppIntegration"
);
const WhatsAppMessage = require("../models/WhatsAppMessage");
const Garage = require("../models/Garage");

const {
  checkWhatsAppLimit,
  incrementWhatsAppCount,
} = require("./subscriptionService");

// ============================================================
// DEFAULT TEMPLATE LANGUAGE
// ============================================================
// Note: Meta template 'payment_reminder' was created with
// language 'English' (code: 'en'), NOT 'en_US'.
// This is why we default to 'en'.

const DEFAULT_TEMPLATE_LANGUAGE = "en";

// ============================================================
// NORMALIZE PHONE NUMBER
// ============================================================

const normalizePhone = (phone) => {
  if (!phone) {
    throw new Error(
      "Recipient WhatsApp number is required"
    );
  }

  let digits = String(phone).replace(/\D/g, "");

  if (!digits) {
    throw new Error(
      "Invalid WhatsApp phone number"
    );
  }

  if (digits.length === 10) {
    digits = "91" + digits;
  } else if (
    digits.length === 11 &&
    digits.startsWith("0")
  ) {
    digits = "91" + digits.substring(1);
  } else if (
    digits.length === 12 &&
    digits.startsWith("91")
  ) {
    // already correct
  } else if (
    digits.length === 12 &&
    digits.startsWith("00")
  ) {
    digits = "91" + digits.substring(2);
  } else if (
    digits.length === 14 &&
    digits.startsWith("0091")
  ) {
    digits = digits.substring(2);
  }

  if (digits.length < 10 || digits.length > 15) {
    throw new Error(
      `Invalid WhatsApp phone number: ${phone}`
    );
  }

  return digits;
};

// ============================================================
// GET GARAGE WHATSAPP INTEGRATION
// ============================================================

const getGarageIntegration = async (garageId) => {
  if (!garageId) {
    throw new Error("Garage ID is required");
  }

  const integration =
    await WhatsAppIntegration.findOne({
      garageId,
      isConnected: true,
      isActive: true,
    }).select("+accessToken");

  if (!integration) {
    throw new Error(
      "WhatsApp integration is not connected for this garage"
    );
  }

  if (!integration.phoneNumberId) {
    throw new Error(
      "WhatsApp phone number ID is missing"
    );
  }

  if (!integration.accessToken) {
    throw new Error(
      "WhatsApp access token is missing"
    );
  }

  console.log("=================================================");
  console.log(
    "Token being used (first 20 chars):",
    integration.accessToken?.substring(0, 20) + "..."
  );
  console.log(
    "Token length:",
    integration.accessToken?.length
  );
  console.log(
    "Phone Number ID:",
    integration.phoneNumberId
  );
  console.log("=================================================");

  return integration;
};

// ============================================================
// GET GARAGE NAME (helper)
// ============================================================

const getGarageName = async (garageId) => {
  try {
    const garage = await Garage.findById(
      garageId
    ).select("name garageName businessName");

    return (
      garage?.name ||
      garage?.garageName ||
      garage?.businessName ||
      "Your Garage"
    );
  } catch (error) {
    console.error(
      "Garage name fetch error:",
      error.message
    );
    return "Your Garage";
  }
};

// ============================================================
// SUBSCRIPTION LIMIT CHECK (before sending)
// ============================================================

const ensureMessageLimit = async (garageId) => {
  const usage = await checkWhatsAppLimit(garageId);

  if (!usage.allowed) {
    const error = new Error(
      usage.reason || "WhatsApp message limit reached"
    );
    error.code = "LIMIT_REACHED";
    error.usage = usage;
    throw error;
  }

  return usage;
};

// ============================================================
// INCREMENT COUNT (after successful send)
// ============================================================

const trackMessageSent = async (garageId) => {
  try {
    await incrementWhatsAppCount(garageId);
  } catch (error) {
    console.error(
      "Track message sent error:",
      error.message
    );
    // Don't throw — message already sent, just log
  }
};

// ============================================================
// ✅ HELPER: READ FILE (LOCAL OR REMOTE)
// ============================================================
// Pehle ye function HTTP fetch karta tha jo timeout ho jata
// tha jab URL local server ka hota (10.x.x.x / 192.168.x.x).
//
// Ab ye:
//   - Local server URL (localhost / 127.0.0.1 / 10.x / 192.168.x
//     / 172.16-31.x) → direct filesystem se read karta hai
//   - External URL → axios se fetch karta hai

const readFileFromUrl = async (fileUrl) => {
  console.log("📁 Reading file from:", fileUrl);

  let urlObj;

  try {
    urlObj = new URL(fileUrl);
  } catch (err) {
    // Agar URL valid nahi hai, to assume local path hai
    console.log("Not a valid URL, treating as local path");
    const absolutePath = path.isAbsolute(fileUrl)
      ? fileUrl
      : path.join(__dirname, "..", fileUrl);

    if (!fs.existsSync(absolutePath)) {
      throw new Error(`File not found: ${absolutePath}`);
    }

    const buffer = fs.readFileSync(absolutePath);
    console.log("✅ Local file read. Size:", buffer.length, "bytes");
    return buffer;
  }

  const hostname = urlObj.hostname;

  // Local server check
  const isLocalServer =
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname === "::1" ||
    hostname.startsWith("10.") ||
    hostname.startsWith("192.168.") ||
    // 172.16.x - 172.31.x
    /^172\.(1[6-9]|2\d|3[01])\./.test(hostname);

  if (isLocalServer) {
    // Server ke apne folder se file read karo
    const relativePath = urlObj.pathname.replace(/^\//, "");

    // Try multiple possible roots
    const candidates = [
      path.join(__dirname, "..", relativePath),
      path.join(__dirname, "..", "public", relativePath),
      path.join(process.cwd(), relativePath),
      path.join(process.cwd(), "public", relativePath),
    ];

    for (const absPath of candidates) {
      if (fs.existsSync(absPath)) {
        const buffer = fs.readFileSync(absPath);
        console.log(
          "✅ Local file read:",
          absPath,
          "- Size:",
          buffer.length,
          "bytes"
        );
        return buffer;
      }
    }

    // Fallback — URL try karo but shorter timeout with localhost
    console.warn(
      "⚠️ Local file not found on disk. Trying localhost HTTP..."
    );

    const fallbackUrl = `http://localhost:${urlObj.port || 5000}${urlObj.pathname}`;

    try {
      const response = await axios.get(fallbackUrl, {
        responseType: "arraybuffer",
        timeout: 15000,
      });
      console.log(
        "✅ Fallback localhost read. Size:",
        response.data.length,
        "bytes"
      );
      return Buffer.from(response.data);
    } catch (err) {
      throw new Error(
        `Cannot read local file. Tried: ${candidates.join(", ")}. Error: ${err.message}`
      );
    }
  }

  // External URL — fetch via axios
  console.log("🌐 External URL detected. Fetching via HTTP...");
  const response = await axios.get(fileUrl, {
    responseType: "arraybuffer",
    timeout: 60000,
  });
  console.log(
    "✅ External file fetched. Size:",
    response.data.length,
    "bytes"
  );
  return Buffer.from(response.data);
};

// ============================================================
// UPLOAD MEDIA TO WHATSAPP
// ============================================================

const uploadMediaToWhatsApp = async ({
  integration,
  fileUrl,
  fileName = "document.pdf",
  mimeType = "application/pdf",
}) => {
  console.log("Downloading file from URL:", fileUrl);

  // ✅ Naya helper — local file read karega, HTTP nahi
  const fileBuffer = await readFileFromUrl(fileUrl);

  console.log(
    "File ready. Size:",
    fileBuffer.length,
    "bytes"
  );

  const formData = new FormData();

  formData.append("messaging_product", "whatsapp");
  formData.append("file", fileBuffer, {
    filename: fileName,
    contentType: mimeType,
  });

  const uploadUrl =
    `https://graph.facebook.com/v23.0/` +
    `${integration.phoneNumberId}/media`;

  console.log("Uploading to WhatsApp...");

  const uploadResponse = await axios.post(
    uploadUrl,
    formData,
    {
      headers: {
        Authorization: `Bearer ${integration.accessToken}`,
        ...formData.getHeaders(),
      },
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
      timeout: 60000,
    }
  );

  const mediaId = uploadResponse.data?.id;

  if (!mediaId) {
    throw new Error(
      "Failed to upload media to WhatsApp"
    );
  }

  console.log("Media uploaded. ID:", mediaId);

  return mediaId;
};

// ============================================================
// SEND GENERIC TEMPLATE MESSAGE (no PDF)
// ============================================================

const sendWhatsAppTemplate = async ({
  garageId,
  customerId = null,
  vehicleId = null,
  reminderId = null,
  to,
  templateName,
  // ✅ DEFAULT LANGUAGE = "en" (NOT "en_US")
  languageCode = DEFAULT_TEMPLATE_LANGUAGE,
  type = "general",
  bodyParameters = [],
}) => {
  let messageLog = null;

  try {
    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!garageId) {
      throw new Error("Garage ID is required");
    }

    if (!to) {
      throw new Error(
        "Recipient WhatsApp number is required"
      );
    }

    if (!templateName) {
      throw new Error("Template name is required");
    }

    if (!Array.isArray(bodyParameters)) {
      throw new Error(
        "bodyParameters must be an array"
      );
    }

    // --------------------------------------------------------
    // CHECK SUBSCRIPTION LIMIT
    // --------------------------------------------------------

    await ensureMessageLimit(garageId);

    // --------------------------------------------------------
    // GET INTEGRATION
    // --------------------------------------------------------

    const integration = await getGarageIntegration(
      garageId
    );

    const recipientPhone = normalizePhone(to);

    // --------------------------------------------------------
    // CREATE LOG
    // --------------------------------------------------------

    messageLog = await WhatsAppMessage.create({
      garageId,
      customerId,
      vehicleId,
      reminderId,
      type,
      phoneNumberId: integration.phoneNumberId,
      recipientPhone,
      templateName,
      templateLanguage: languageCode,
      message: `Template: ${templateName}`,
      provider: "meta",
      status: "sending",
      attempts: 1,
      queuedAt: new Date(),
    });

    // --------------------------------------------------------
    // META API URL
    // --------------------------------------------------------

    const url =
      `https://graph.facebook.com/v23.0/` +
      `${integration.phoneNumberId}/messages`;

    // --------------------------------------------------------
    // BUILD COMPONENTS
    // --------------------------------------------------------

    const components = [];

    if (bodyParameters.length > 0) {
      components.push({
        type: "body",
        parameters: bodyParameters.map((text) => ({
          type: "text",
          text: String(text ?? ""),
        })),
      });
    }

    // --------------------------------------------------------
    // SEND
    // --------------------------------------------------------

    const response = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: recipientPhone,
        type: "template",
        template: {
          name: templateName,
          language: {
            code: languageCode,
          },
          components,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${integration.accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    // --------------------------------------------------------
    // SUCCESS LOG
    // --------------------------------------------------------

    const providerMessageId =
      response.data?.messages?.[0]?.id || null;

    messageLog.status = "sent";
    messageLog.providerMessageId = providerMessageId;
    messageLog.sentAt = new Date();
    messageLog.errorCode = null;
    messageLog.errorMessage = null;
    messageLog.failedAt = null;

    await messageLog.save();

    integration.lastMessageAt = new Date();
    await integration.save();

    // INCREMENT MESSAGE COUNT
    await trackMessageSent(garageId);

    console.log(
      `WhatsApp template '${templateName}' sent successfully`
    );

    return {
      success: true,
      messageId: providerMessageId,
      logId: messageLog._id,
      response: response.data,
    };
  } catch (error) {
    const providerError =
      error.response?.data?.error;
    const errorCode = providerError?.code
      ? String(providerError.code)
      : null;
    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send WhatsApp template";

    console.error(
      "WhatsApp template send error:",
      error.response?.data || error.message
    );

    if (messageLog) {
      try {
        messageLog.status = "failed";
        messageLog.errorCode = errorCode;
        messageLog.errorMessage = errorMessage;
        messageLog.failedAt = new Date();
        messageLog.nextRetryAt = new Date(
          Date.now() + 5 * 60 * 1000
        );
        await messageLog.save();
      } catch (logError) {
        console.error(
          "Log update error:",
          logError
        );
      }
    }

    throw error;
  }
};

// ============================================================
// SEND TEMPLATE + PDF ATTACHMENT
// ============================================================

const sendWhatsAppTemplateWithPdf = async ({
  garageId,
  customerId = null,
  vehicleId = null,
  reminderId = null,
  to,
  templateName,
  // ✅ DEFAULT LANGUAGE = "en" (NOT "en_US")
  languageCode = DEFAULT_TEMPLATE_LANGUAGE,
  type = "general",
  bodyParameters = [],
  pdfUrl,
  pdfFileName = "invoice.pdf",
}) => {
  let messageLog = null;

  try {
    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!garageId) {
      throw new Error("Garage ID is required");
    }

    if (!to) {
      throw new Error(
        "Recipient WhatsApp number is required"
      );
    }

    if (!templateName) {
      throw new Error("Template name is required");
    }

    if (!pdfUrl) {
      throw new Error("PDF URL is required");
    }

    if (!Array.isArray(bodyParameters)) {
      throw new Error(
        "bodyParameters must be an array"
      );
    }

    // --------------------------------------------------------
    // CHECK SUBSCRIPTION LIMIT
    // --------------------------------------------------------

    await ensureMessageLimit(garageId);

    // --------------------------------------------------------
    // GET INTEGRATION
    // --------------------------------------------------------

    const integration = await getGarageIntegration(
      garageId
    );

    const recipientPhone = normalizePhone(to);

    // --------------------------------------------------------
    // UPLOAD PDF
    // --------------------------------------------------------

    const mediaId = await uploadMediaToWhatsApp({
      integration,
      fileUrl: pdfUrl,
      fileName: pdfFileName,
      mimeType: "application/pdf",
    });

    // --------------------------------------------------------
    // CREATE LOG
    // --------------------------------------------------------

    messageLog = await WhatsAppMessage.create({
      garageId,
      customerId,
      vehicleId,
      reminderId,
      type,
      phoneNumberId: integration.phoneNumberId,
      recipientPhone,
      templateName,
      templateLanguage: languageCode,
      message: `Template: ${templateName} + PDF`,
      provider: "meta",
      status: "sending",
      attempts: 1,
      queuedAt: new Date(),
    });

    // --------------------------------------------------------
    // META API
    // --------------------------------------------------------

    const url =
      `https://graph.facebook.com/v23.0/` +
      `${integration.phoneNumberId}/messages`;

    const components = [];

    // PDF as header
    components.push({
      type: "header",
      parameters: [
        {
          type: "document",
          document: {
            id: mediaId,
            filename: pdfFileName,
          },
        },
      ],
    });

    if (bodyParameters.length > 0) {
      components.push({
        type: "body",
        parameters: bodyParameters.map((text) => ({
          type: "text",
          text: String(text ?? ""),
        })),
      });
    }

    const response = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: recipientPhone,
        type: "template",
        template: {
          name: templateName,
          language: { code: languageCode },
          components,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${integration.accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    const providerMessageId =
      response.data?.messages?.[0]?.id || null;

    messageLog.status = "sent";
    messageLog.providerMessageId = providerMessageId;
    messageLog.sentAt = new Date();
    messageLog.errorCode = null;
    messageLog.errorMessage = null;
    messageLog.failedAt = null;

    await messageLog.save();

    integration.lastMessageAt = new Date();
    await integration.save();

    // INCREMENT MESSAGE COUNT
    await trackMessageSent(garageId);

    console.log(
      `WhatsApp template '${templateName}' with PDF sent successfully`
    );

    return {
      success: true,
      messageId: providerMessageId,
      mediaId: mediaId,
      logId: messageLog._id,
      response: response.data,
    };
  } catch (error) {
    const providerError =
      error.response?.data?.error;
    const errorCode = providerError?.code
      ? String(providerError.code)
      : null;
    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send WhatsApp template with PDF";

    console.error(
      "WhatsApp template + PDF error:",
      error.response?.data || error.message
    );

    if (messageLog) {
      try {
        messageLog.status = "failed";
        messageLog.errorCode = errorCode;
        messageLog.errorMessage = errorMessage;
        messageLog.failedAt = new Date();
        messageLog.nextRetryAt = new Date(
          Date.now() + 5 * 60 * 1000
        );
        await messageLog.save();
      } catch (logError) {
        console.error(
          "Log update error:",
          logError
        );
      }
    }

    throw error;
  }
};

// ============================================================
// SEND TEXT WHATSAPP MESSAGE
// ============================================================

const sendWhatsAppMessage = async ({
  garageId,
  customerId = null,
  vehicleId = null,
  reminderId = null,
  to,
  message,
  type = "general",
}) => {
  let messageLog = null;

  try {
    if (!garageId) {
      throw new Error("Garage ID is required");
    }

    if (!message) {
      throw new Error(
        "WhatsApp message is required"
      );
    }

    // CHECK LIMIT
    await ensureMessageLimit(garageId);

    const integration = await getGarageIntegration(
      garageId
    );

    const recipientPhone = normalizePhone(to);

    messageLog = await WhatsAppMessage.create({
      garageId,
      customerId,
      vehicleId,
      reminderId,
      type,
      phoneNumberId: integration.phoneNumberId,
      recipientPhone,
      message,
      provider: "meta",
      status: "sending",
      attempts: 1,
      queuedAt: new Date(),
    });

    const url =
      `https://graph.facebook.com/v23.0/` +
      `${integration.phoneNumberId}/messages`;

    const response = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: recipientPhone,
        type: "text",
        text: {
          preview_url: false,
          body: message,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${integration.accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    const providerMessageId =
      response.data?.messages?.[0]?.id || null;

    messageLog.status = "sent";
    messageLog.providerMessageId = providerMessageId;
    messageLog.sentAt = new Date();
    messageLog.errorCode = null;
    messageLog.errorMessage = null;
    messageLog.failedAt = null;

    await messageLog.save();

    integration.lastMessageAt = new Date();
    await integration.save();

    // INCREMENT
    await trackMessageSent(garageId);

    console.log(
      "WhatsApp message sent successfully"
    );

    return {
      success: true,
      messageId: providerMessageId,
      logId: messageLog._id,
      response: response.data,
    };
  } catch (error) {
    const providerError =
      error.response?.data?.error;
    const errorCode = providerError?.code
      ? String(providerError.code)
      : null;
    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send WhatsApp message";

    console.error(
      "WhatsApp send error:",
      error.response?.data || error.message
    );

    if (messageLog) {
      try {
        messageLog.status = "failed";
        messageLog.errorCode = errorCode;
        messageLog.errorMessage = errorMessage;
        messageLog.failedAt = new Date();
        messageLog.nextRetryAt = new Date(
          Date.now() + 5 * 60 * 1000
        );
        await messageLog.save();
      } catch (logError) {
        console.error(
          "Log update error:",
          logError
        );
      }
    }

    throw error;
  }
};

// ============================================================
// SEND INVOICE / BILL WHATSAPP TEMPLATE (legacy)
// ============================================================

const sendInvoiceWhatsApp = async ({
  garageId,
  customerId = null,
  vehicleId = null,
  to,
  customerName,
  vehicleNumber,
  serviceDate,
  totalAmount,
  paidAmount,
  pendingAmount,
}) => {
  let messageLog = null;

  try {
    if (!garageId) {
      throw new Error("Garage ID is required");
    }

    if (!to) {
      throw new Error(
        "Customer WhatsApp number is required"
      );
    }

    // CHECK LIMIT
    await ensureMessageLimit(garageId);

    const integration = await getGarageIntegration(
      garageId
    );

    const recipientPhone = normalizePhone(to);

    messageLog = await WhatsAppMessage.create({
      garageId,
      customerId,
      vehicleId,
      reminderId: null,
      type: "bill",
      phoneNumberId: integration.phoneNumberId,
      recipientPhone,
      message: `Invoice sent to ${
        customerName || "Customer"
      }`,
      provider: "meta",
      status: "sending",
      attempts: 1,
      queuedAt: new Date(),
    });

    const url =
      `https://graph.facebook.com/v23.0/` +
      `${integration.phoneNumberId}/messages`;

    const response = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: recipientPhone,
        type: "template",
        template: {
          name: "garage_service_bill",
          // ✅ LANGUAGE = "en" (agar ye template bhi English mein hai)
          language: { code: DEFAULT_TEMPLATE_LANGUAGE },
          components: [
            {
              type: "body",
              parameters: [
                {
                  type: "text",
                  text: String(
                    customerName || "Customer"
                  ),
                },
                {
                  type: "text",
                  text: String(vehicleNumber || "-"),
                },
                {
                  type: "text",
                  text: String(serviceDate || "-"),
                },
              ],
            },
          ],
        },
      },
      {
        headers: {
          Authorization: `Bearer ${integration.accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    const providerMessageId =
      response.data?.messages?.[0]?.id || null;

    messageLog.status = "sent";
    messageLog.providerMessageId = providerMessageId;
    messageLog.sentAt = new Date();
    messageLog.errorCode = null;
    messageLog.errorMessage = null;
    messageLog.failedAt = null;

    await messageLog.save();

    integration.lastMessageAt = new Date();
    await integration.save();

    // INCREMENT
    await trackMessageSent(garageId);

    return {
      success: true,
      messageId: providerMessageId,
      logId: messageLog._id,
      response: response.data,
    };
  } catch (error) {
    const providerError =
      error.response?.data?.error;
    const errorCode = providerError?.code
      ? String(providerError.code)
      : null;
    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send invoice on WhatsApp";

    console.error(
      "Invoice WhatsApp error:",
      error.response?.data || error.message
    );

    if (messageLog) {
      try {
        messageLog.status = "failed";
        messageLog.errorCode = errorCode;
        messageLog.errorMessage = errorMessage;
        messageLog.failedAt = new Date();
        messageLog.nextRetryAt = new Date(
          Date.now() + 5 * 60 * 1000
        );
        await messageLog.save();
      } catch (logError) {
        console.error(
          "Log update error:",
          logError
        );
      }
    }

    throw error;
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  sendWhatsAppMessage,
  sendInvoiceWhatsApp,
  sendWhatsAppTemplate,
  sendWhatsAppTemplateWithPdf,
  getGarageIntegration,
  getGarageName,
  normalizePhone,
  uploadMediaToWhatsApp,
  ensureMessageLimit,
  trackMessageSent,
  readFileFromUrl,
  DEFAULT_TEMPLATE_LANGUAGE,
};