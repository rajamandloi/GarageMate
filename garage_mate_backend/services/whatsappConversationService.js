const WhatsAppConversation =
  require("../models/WhatsAppConversation");

const Customer =
  require("../models/Customer");

// ============================================================
// FIND OR CREATE CONVERSATION
// ============================================================

const findOrCreateConversation = async ({
  garageId,
  phoneNumberId,
  customerPhone,
}) => {
  if (!garageId) {
    throw new Error("Garage ID is required");
  }

  if (!phoneNumberId) {
    throw new Error(
      "WhatsApp phone number ID is required"
    );
  }

  if (!customerPhone) {
    throw new Error(
      "Customer phone number is required"
    );
  }

  // ============================================================
  // FIND CUSTOMER
  // ============================================================

  const customer =
    await Customer.findOne({
      garageId,
      phone: customerPhone,
    });

  // ============================================================
  // FIND EXISTING CONVERSATION
  // ============================================================

  let conversation =
    await WhatsAppConversation.findOne({
      garageId,
      customerPhone,
    });

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  if (!conversation) {
    conversation =
      await WhatsAppConversation.create({
        garageId,
        customerId:
          customer?._id || null,
        customerPhone,
        phoneNumberId,
        messages: [],
      });
  } else {
    // Keep customer association updated.
    if (
      customer &&
      (!conversation.customerId ||
        conversation.customerId.toString() !==
          customer._id.toString())
    ) {
      conversation.customerId =
        customer._id;
    }

    // Keep latest phoneNumberId.
    conversation.phoneNumberId =
      phoneNumberId;

    await conversation.save();
  }

  return {
    conversation,
    customer: customer || null,
  };
};


// ============================================================
// ADD MESSAGE
// ============================================================

const addConversationMessage = async ({
  conversation,
  messageId,
  direction,
  type = "text",
  text = "",
  aiGenerated = false,
}) => {
  conversation.messages.push({
    messageId,
    direction,
    type,
    text,
    timestamp: new Date(),
    aiGenerated,
  });

  conversation.lastMessageAt =
    new Date();

  await conversation.save();

  return conversation;
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  findOrCreateConversation,
  addConversationMessage,
};