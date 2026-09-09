const crypto = require("crypto");

const WhatsAppIntegration = require("../models/WhatsAppIntegration");
const Garage = require("../models/Garage");

const {
  findOrCreateConversation,
  addConversationMessage,
} = require("../services/whatsappConversationService");

const { generateAIResponse } =
  require("../services/aiService");

const {
  sendWhatsAppMessage,
} = require("../services/whatsappService");

// ============================================================
// GET WHATSAPP INTEGRATION
// GET /api/whatsapp/integration
// ============================================================

const getIntegration = async (req, res) => {
  try {
    const garageId = req.user.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const integration =
      await WhatsAppIntegration.findOne({
        garageId,
      }).select("-accessToken");

    return res.status(200).json({
      success: true,
      integration: integration || null,
    });
  } catch (error) {
    console.error(
      "Get WhatsApp integration error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch WhatsApp integration",
    });
  }
};

// ============================================================
// SAVE / UPDATE WHATSAPP CONFIGURATION
// PUT /api/whatsapp/integration
// ============================================================

const saveIntegration = async (req, res) => {
  try {
    const garageId = req.user.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const garage = await Garage.findById(garageId);

    if (!garage) {
      return res.status(404).json({
        success: false,
        message: "Garage not found",
      });
    }

    const {
      businessAccountId,
      phoneNumberId,
      displayPhoneNumber,
      accessToken,
      aiEnabled,
      aiName,
      greeting,
      aiInstructions,
      businessHours,
    } = req.body;

    let integration =
      await WhatsAppIntegration.findOne({
        garageId,
      });

    if (!integration) {
      integration =
        new WhatsAppIntegration({
          garageId,
        });
    }

    if (businessAccountId !== undefined) {
      integration.businessAccountId =
        String(businessAccountId).trim();
    }

    if (phoneNumberId !== undefined) {
      integration.phoneNumberId =
        String(phoneNumberId).trim();
    }

    if (displayPhoneNumber !== undefined) {
      integration.displayPhoneNumber =
        String(displayPhoneNumber).trim();
    }

    if (accessToken !== undefined) {
      integration.accessToken =
        String(accessToken).trim();
    }

    if (aiEnabled !== undefined) {
      integration.aiEnabled =
        Boolean(aiEnabled);
    }

    if (aiName !== undefined) {
      integration.aiName =
        String(aiName).trim();
    }

    if (greeting !== undefined) {
      integration.greeting =
        String(greeting).trim();
    }

    if (aiInstructions !== undefined) {
      integration.aiInstructions =
        String(aiInstructions).trim();
    }

    if (businessHours !== undefined) {
      integration.businessHours =
        String(businessHours).trim();
    }

    integration.isConnected = true;
    integration.lastConnectedAt = new Date();

    await integration.save();

    return res.status(200).json({
      success: true,
      message:
        "WhatsApp integration saved successfully",
      integration:
        integration.toObject({
          transform: (doc, ret) => {
            delete ret.accessToken;
            return ret;
          },
        }),
    });
  } catch (error) {
    console.error(
      "Save WhatsApp integration error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to save WhatsApp integration",
    });
  }
};

// ============================================================
// DISCONNECT WHATSAPP
// DELETE /api/whatsapp/integration
// ============================================================

const disconnectWhatsApp = async (req, res) => {
  try {
    const garageId = req.user.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message:
          "Garage is not associated with this account",
      });
    }

    const integration =
      await WhatsAppIntegration.findOne({
        garageId,
      });

    if (!integration) {
      return res.status(404).json({
        success: false,
        message:
          "WhatsApp integration not found",
      });
    }

    integration.isConnected = false;
    integration.webhookVerified = false;
    integration.accessToken = null;
    integration.phoneNumberId = null;
    integration.businessAccountId = null;
    integration.displayPhoneNumber = null;
    integration.lastConnectedAt = null;

    await integration.save();

    return res.status(200).json({
      success: true,
      message:
        "WhatsApp disconnected successfully",
    });
  } catch (error) {
    console.error(
      "Disconnect WhatsApp error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to disconnect WhatsApp",
    });
  }
};

// ============================================================
// WEBHOOK VERIFICATION
// GET /api/whatsapp/webhook
// ============================================================

const verifyWebhook = async (req, res) => {
  try {
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge =
      req.query["hub.challenge"];

    const verifyToken =
      process.env.WHATSAPP_VERIFY_TOKEN;

    if (
      mode !== "subscribe" ||
      !token ||
      !verifyToken
    ) {
      return res.status(403).send("Forbidden");
    }

    const tokenBuffer =
      Buffer.from(String(token));

    const verifyTokenBuffer =
      Buffer.from(String(verifyToken));

    if (
      tokenBuffer.length !==
      verifyTokenBuffer.length
    ) {
      return res.status(403).send("Forbidden");
    }

    if (
      !crypto.timingSafeEqual(
        tokenBuffer,
        verifyTokenBuffer
      )
    ) {
      return res.status(403).send("Forbidden");
    }

    console.log(
      "WhatsApp webhook verified successfully"
    );

    return res.status(200).send(challenge);
  } catch (error) {
    console.error(
      "WhatsApp webhook verification error:",
      error
    );

    return res.status(403).send("Forbidden");
  }
};

// ============================================================
// RECEIVE WHATSAPP WEBHOOK
// POST /api/whatsapp/webhook
// ============================================================

const receiveWebhook = async (req, res) => {
  try {
    const appSecret = process.env.WHATSAPP_APP_SECRET;
    const signature = req.headers["x-hub-signature-256"];

    // Meta signs webhook bodies with the WhatsApp/Facebook app secret.
    // Never process an unsigned webhook in production.
    if (!appSecret || typeof signature !== "string" || !signature.startsWith("sha256=")) {
      return res.sendStatus(403);
    }

    const expected = crypto
      .createHmac("sha256", appSecret)
      .update(req.rawBody || Buffer.from(JSON.stringify(req.body)))
      .digest("hex");

    const received = signature.slice("sha256=".length);
    const expectedBuffer = Buffer.from(expected, "hex");
    const receivedBuffer = Buffer.from(received, "hex");

    if (
      expectedBuffer.length !== receivedBuffer.length ||
      !crypto.timingSafeEqual(expectedBuffer, receivedBuffer)
    ) {
      return res.sendStatus(403);
    }

    const body = req.body;

    // ==========================================================
    // BASIC META WEBHOOK VALIDATION
    // ==========================================================

    if (
      body?.object !==
      "whatsapp_business_account"
    ) {
      return res.sendStatus(200);
    }

    const entries = body.entry || [];

    for (const entry of entries) {
      const changes = entry.changes || [];

      for (const change of changes) {
        const value = change.value;

        if (!value) {
          continue;
        }

        // ======================================================
        // PHONE NUMBER ID
        // ======================================================

        const phoneNumberId =
          value.metadata?.phone_number_id;

        if (!phoneNumberId) {
          console.log(
            "WhatsApp phone number ID not found"
          );

          continue;
        }

        console.log(
          "WhatsApp Phone Number ID:",
          phoneNumberId
        );

        // ======================================================
        // FIND GARAGE INTEGRATION
        // ======================================================

        const integration =
          await WhatsAppIntegration.findOne({
            phoneNumberId,
            isConnected: true,
            isActive: true,
          });

        if (!integration) {
          console.log(
            "No connected garage found for Phone Number ID:",
            phoneNumberId
          );

          continue;
        }

        // ======================================================
        // FIND GARAGE
        // ======================================================

        const garage =
          await Garage.findById(
            integration.garageId
          );

        if (!garage) {
          console.log(
            "Garage not found:",
            integration.garageId
          );

          continue;
        }

        console.log(
          "WhatsApp message belongs to garage:",
          garage.name
        );

        // ======================================================
        // INCOMING MESSAGES
        // ======================================================

        const messages =
          value.messages || [];

        for (const message of messages) {
          const senderPhone =
            message.from;

          const messageType =
            message.type;

          let messageText = "";

          // ====================================================
          // TEXT MESSAGE
          // ====================================================

          if (messageType === "text") {
            messageText =
              message.text?.body || "";
          }



          // ====================================================
          // NORMALIZE PHONE
          // ====================================================

          const normalizedPhone =
            String(senderPhone)
              .replace(/\D/g, "");

          if (!normalizedPhone) {
            console.log(
              "Invalid sender phone number"
            );

            continue;
          }

          // ====================================================
          // FIND OR CREATE CONVERSATION
          // ====================================================

          const {
            conversation,
            customer,
          } =
            await findOrCreateConversation({
              garageId: garage._id,
              phoneNumberId,
              customerPhone:
                normalizedPhone,
            });

          console.log(
            "Conversation ID:",
            conversation._id.toString()
          );

          console.log(
            "Customer:",
            customer
              ? customer.name
              : "Not registered"
          );

          // ====================================================
          // IGNORE UNSUPPORTED MESSAGE TYPES
          // ====================================================

          if (!messageText) {
            console.log(
              "Unsupported WhatsApp message type:",
              messageType
            );

            continue;
          }

          // ====================================================
          // SAVE INCOMING MESSAGE
          // ====================================================

          await addConversationMessage({
            conversation,
            messageId:
              message.id || null,
            direction: "incoming",
            type: messageType,
            text: messageText,
            aiGenerated: false,
          });

          console.log(
            "Incoming WhatsApp message saved"
          );

          // ====================================================
          // AI RESPONSE
          // ====================================================

          if (!integration.aiEnabled) {
            console.log(
              "AI is disabled for this garage"
            );

            continue;
          }

          try {
            const aiResponse =
              await generateAIResponse({
                integration,
                customer,
                conversation,
                message: messageText,
              });

            console.log(
              "AI RESPONSE:",
              aiResponse
            );

            // ==================================================
            // SEND AI RESPONSE TO WHATSAPP
            // ==================================================

            await sendWhatsAppMessage({
              garageId: garage._id,
              to: senderPhone,
              message: aiResponse,
            });

            console.log(
              "AI response sent successfully"
            );

          } catch (error) {
            console.error(
              "AI WhatsApp processing error:",
              error.message
            );
          }
        }
      }
    }

    // ==========================================================
    // ACKNOWLEDGE META
    // ==========================================================

    return res.sendStatus(200);

  } catch (error) {
    console.error(
      "WhatsApp webhook error:",
      error
    );

    // Always acknowledge Meta webhook
    return res.sendStatus(200);
  }
};

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  getIntegration,
  saveIntegration,
  disconnectWhatsApp,
  verifyWebhook,
  receiveWebhook,
};