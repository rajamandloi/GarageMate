const axios = require("axios");

const WhatsAppIntegration = require(
  "../models/WhatsAppIntegration"
);

const WhatsAppNotificationLog =
  require(
    "../models/WhatsAppNotificationLog"
  );


// ============================================================
// NORMALIZE PHONE
// ============================================================

const normalizePhone = (phone) => {
  return String(phone || "").replace(/\D/g, "");
};


// ============================================================
// SEND WHATSAPP TEMPLATE
// ============================================================

const sendWhatsAppTemplate = async ({
  garageId,
  customerId,
  vehicleId = null,
  reminderId = null,

  to,

  templateName,
  language = "en",

  parameters = [],

  type = "general",
}) => {
  let notificationLog = null;

  try {
    if (!garageId) {
      throw new Error(
        "Garage ID is required"
      );
    }

    if (!to) {
      throw new Error(
        "Recipient phone number is required"
      );
    }

    if (!templateName) {
      throw new Error(
        "WhatsApp template name is required"
      );
    }

    // ========================================================
    // GET GARAGE WHATSAPP CONNECTION
    // ========================================================

    const integration =
      await WhatsAppIntegration.findOne({
        garageId,
        isConnected: true,
        isActive: true,
      }).select("+accessToken");

    if (!integration) {
      throw new Error(
        "WhatsApp is not connected for this garage"
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

    // ========================================================
    // PHONE
    // ========================================================

    const recipientPhone =
      normalizePhone(to);

    if (!recipientPhone) {
      throw new Error(
        "Invalid recipient phone number"
      );
    }

    // ========================================================
    // CREATE LOG
    // ========================================================

    notificationLog =
      await WhatsAppNotificationLog.create({
        garageId,
        customerId,
        vehicleId,
        reminderId,
        type,
        templateName,
        recipientPhone,
        status: "pending",
      });

    // ========================================================
    // TEMPLATE COMPONENTS
    // ========================================================

    const components = [];

    if (
      Array.isArray(parameters) &&
      parameters.length > 0
    ) {
      components.push({
        type: "body",

        parameters:
          parameters.map((value) => ({
            type: "text",
            text: String(value),
          })),
      });
    }

    // ========================================================
    // META API
    // ========================================================

    const url =
      `https://graph.facebook.com/v23.0/` +
      `${integration.phoneNumberId}/messages`;

    const response =
      await axios.post(
        url,
        {
          messaging_product:
            "whatsapp",

          recipient_type:
            "individual",

          to: recipientPhone,

          type: "template",

          template: {
            name: templateName,

            language: {
              code: language,
            },

            ...(components.length > 0
              ? { components }
              : {}),
          },
        },
        {
          headers: {
            Authorization:
              `Bearer ${integration.accessToken}`,

            "Content-Type":
              "application/json",
          },
        }
      );

    // ========================================================
    // SUCCESS
    // ========================================================

    const messageId =
      response.data?.messages?.[0]?.id ||
      null;

    notificationLog.status = "sent";

    notificationLog.whatsappMessageId =
      messageId;

    notificationLog.sentAt =
      new Date();

    await notificationLog.save();

    integration.lastMessageAt =
      new Date();

    await integration.save();

    console.log(
      "WhatsApp template sent:",
      templateName
    );

    return {
      success: true,
      messageId,
      response: response.data,
    };
  } catch (error) {
    console.error(
      "WhatsApp template error:",
      error.response?.data ||
        error.message
    );

    if (notificationLog) {
      notificationLog.status =
        "failed";

      notificationLog.errorMessage =
        error.response?.data?.error
          ?.message ||
        error.message;

      await notificationLog.save();
    }

    throw new Error(
      error.response?.data?.error
        ?.message ||
        "Unable to send WhatsApp template"
    );
  }
};


module.exports = {
  sendWhatsAppTemplate,
};