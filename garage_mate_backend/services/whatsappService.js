const axios = require("axios");

const WhatsAppIntegration = require("../models/WhatsAppIntegration");
const WhatsAppMessage = require("../models/WhatsAppMessage");


// ============================================================
// NORMALIZE PHONE NUMBER
// ============================================================

const normalizePhone = (phone) => {
  if (!phone) {
    throw new Error(
      "Recipient WhatsApp number is required"
    );
  }

  const normalized =
    String(phone).replace(/\D/g, "");

  if (!normalized) {
    throw new Error(
      "Invalid WhatsApp phone number"
    );
  }

  return normalized;
};


// ============================================================
// GET GARAGE WHATSAPP INTEGRATION
// ============================================================

const getGarageIntegration = async (
  garageId
) => {
  if (!garageId) {
    throw new Error(
      "Garage ID is required"
    );
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

  return integration;
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
    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!garageId) {
      throw new Error(
        "Garage ID is required"
      );
    }

    if (!message) {
      throw new Error(
        "WhatsApp message is required"
      );
    }

    // --------------------------------------------------------
    // GET INTEGRATION
    // --------------------------------------------------------

    const integration =
      await getGarageIntegration(
        garageId
      );

    // --------------------------------------------------------
    // NORMALIZE PHONE
    // --------------------------------------------------------

    const recipientPhone =
      normalizePhone(to);

    // --------------------------------------------------------
    // CREATE MESSAGE LOG
    // --------------------------------------------------------

    messageLog =
      await WhatsAppMessage.create({
        garageId,

        customerId,

        vehicleId,

        reminderId,

        type,

        phoneNumberId:
          integration.phoneNumberId,

        recipientPhone,

        message,

        provider: "meta",

        status: "sending",

        attempts: 1,

        queuedAt: new Date(),
      });

    // --------------------------------------------------------
    // META WHATSAPP CLOUD API
    // --------------------------------------------------------

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

          type: "text",

          text: {
            preview_url: false,
            body: message,
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

    // --------------------------------------------------------
    // PROVIDER MESSAGE ID
    // --------------------------------------------------------

    const providerMessageId =
      response.data?.messages?.[0]?.id ||
      null;

    // --------------------------------------------------------
    // UPDATE MESSAGE LOG
    // --------------------------------------------------------

    messageLog.status = "sent";

    messageLog.providerMessageId =
      providerMessageId;

    messageLog.sentAt =
      new Date();

    messageLog.errorCode = null;

    messageLog.errorMessage = null;

    messageLog.failedAt = null;

    await messageLog.save();

    // --------------------------------------------------------
    // UPDATE INTEGRATION
    // --------------------------------------------------------

    integration.lastMessageAt =
      new Date();

    await integration.save();

    // --------------------------------------------------------
    // LOG
    // --------------------------------------------------------

    console.log(
      "WhatsApp message sent successfully"
    );



    // --------------------------------------------------------
    // RETURN
    // --------------------------------------------------------

    return {
      success: true,

      messageId:
        providerMessageId,

      logId:
        messageLog._id,

      response:
        response.data,
    };

  } catch (error) {

    // --------------------------------------------------------
    // PROVIDER ERROR
    // --------------------------------------------------------

    const providerError =
      error.response?.data?.error;

    const errorCode =
      providerError?.code
        ? String(
            providerError.code
          )
        : null;

    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send WhatsApp message";

    console.error(
      "WhatsApp send error:",
      error.response?.data ||
        error.message
    );

    // --------------------------------------------------------
    // UPDATE FAILED MESSAGE LOG
    // --------------------------------------------------------

    if (messageLog) {
      try {
        messageLog.status =
          "failed";

        messageLog.errorCode =
          errorCode;

        messageLog.errorMessage =
          errorMessage;

        messageLog.failedAt =
          new Date();

        messageLog.nextRetryAt =
          new Date(
            Date.now() +
              5 * 60 * 1000
          );

        await messageLog.save();

      } catch (logError) {
        console.error(
          "WhatsApp message log update error:",
          logError
        );
      }
    }

    throw new Error(
      errorMessage
    );
  }
};


// ============================================================
// SEND INVOICE / BILL WHATSAPP TEMPLATE
// ============================================================
//
// Meta Template:
// garage_service_bill
//
// Body parameters:
// 1. Customer Name
// 2. Vehicle Number
// 3. Service Date
// 4. Total Amount
// 5. Paid Amount
// 6. Pending Amount
//
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

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!garageId) {
      throw new Error(
        "Garage ID is required"
      );
    }

    if (!to) {
      throw new Error(
        "Customer WhatsApp number is required"
      );
    }

    // --------------------------------------------------------
    // GET INTEGRATION
    // --------------------------------------------------------

    const integration =
      await getGarageIntegration(
        garageId
      );

    // --------------------------------------------------------
    // NORMALIZE PHONE
    // --------------------------------------------------------

    const recipientPhone =
      normalizePhone(to);

    // --------------------------------------------------------
    // CREATE MESSAGE LOG
    // --------------------------------------------------------

    messageLog =
      await WhatsAppMessage.create({
        garageId,

        customerId,

        vehicleId,

        reminderId: null,

        type: "invoice",

        phoneNumberId:
          integration.phoneNumberId,

        recipientPhone,

        message:
          `Invoice sent to ${customerName || "Customer"} | ` +
          `Vehicle: ${vehicleNumber || "-"}`,

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
    // SEND TEMPLATE
    // --------------------------------------------------------

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
            name:
              "garage_service_bill",

            language: {
              code: "en_US",
            },

            components: [
              {
                type: "body",

                parameters: [
                  {
                    type: "text",

                    text:
                      String(
                        customerName ||
                        "Customer"
                      ),
                  },

                  {
                    type: "text",

                    text:
                      String(
                        vehicleNumber ||
                        "-"
                      ),
                  },

                  {
                    type: "text",

                    text:
                      String(
                        serviceDate ||
                        "-"
                      ),
                  },

                  {
                    type: "text",

                    text:
                      `₹${Number(
                        totalAmount || 0
                      ).toFixed(2)}`,
                  },

                  {
                    type: "text",

                    text:
                      `₹${Number(
                        paidAmount || 0
                      ).toFixed(2)}`,
                  },

                  {
                    type: "text",

                    text:
                      `₹${Number(
                        pendingAmount || 0
                      ).toFixed(2)}`,
                  },
                ],
              },
            ],
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

    // --------------------------------------------------------
    // PROVIDER MESSAGE ID
    // --------------------------------------------------------

    const providerMessageId =
      response.data?.messages?.[0]?.id ||
      null;

    // --------------------------------------------------------
    // UPDATE LOG SUCCESS
    // --------------------------------------------------------

    messageLog.status =
      "sent";

    messageLog.providerMessageId =
      providerMessageId;

    messageLog.sentAt =
      new Date();

    messageLog.errorCode =
      null;

    messageLog.errorMessage =
      null;

    messageLog.failedAt =
      null;

    await messageLog.save();

    // --------------------------------------------------------
    // UPDATE INTEGRATION
    // --------------------------------------------------------

    integration.lastMessageAt =
      new Date();

    await integration.save();

    // --------------------------------------------------------
    // LOG
    // --------------------------------------------------------

    console.log(
      "Invoice WhatsApp sent successfully"
    );



    // --------------------------------------------------------
    // RETURN
    // --------------------------------------------------------

    return {
      success: true,

      messageId:
        providerMessageId,

      logId:
        messageLog._id,

      response:
        response.data,
    };

  } catch (error) {

    // --------------------------------------------------------
    // PROVIDER ERROR
    // --------------------------------------------------------

    const providerError =
      error.response?.data?.error;

    const errorCode =
      providerError?.code
        ? String(
            providerError.code
          )
        : null;

    const errorMessage =
      providerError?.message ||
      error.message ||
      "Unable to send invoice on WhatsApp";

    console.error(
      "Invoice WhatsApp error:",
      error.response?.data ||
        error.message
    );

    // --------------------------------------------------------
    // UPDATE FAILED LOG
    // --------------------------------------------------------

    if (messageLog) {
      try {

        messageLog.status =
          "failed";

        messageLog.errorCode =
          errorCode;

        messageLog.errorMessage =
          errorMessage;

        messageLog.failedAt =
          new Date();

        messageLog.nextRetryAt =
          new Date(
            Date.now() +
              5 * 60 * 1000
          );

        await messageLog.save();

      } catch (logError) {

        console.error(
          "Invoice message log update error:",
          logError
        );
      }
    }

    throw new Error(
      errorMessage
    );
  }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  sendWhatsAppMessage,
  sendInvoiceWhatsApp,
  getGarageIntegration,
  normalizePhone,
};