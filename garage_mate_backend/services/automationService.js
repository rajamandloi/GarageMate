const Customer = require("../models/Customer");
const Service = require("../models/Service");
const Vehicle = require("../models/Vehicle");

const {
  sendWhatsAppTemplate,
} = require("./whatsappService");

// ============================================================
// ELIGIBLE CUSTOMERS — SERVICE REMINDERS
// (Customers whose next service date is within 7 days
//  OR already overdue — based on their last service)
// ============================================================

const getServiceReminderEligible = async (garageId) => {
  const now = new Date();
  const limit = new Date(
    now.getTime() + 7 * 24 * 60 * 60 * 1000
  );

  // Get all services with nextServiceDate set
  const services = await Service.find({
    garageId,
    nextServiceDate: { $ne: null, $lte: limit },
  })
    .populate("customerId", "name phone")
    .populate(
      "vehicleId",
      "registrationNumber brand model"
    );

  // De-duplicate by customer (only latest service per customer)
  const map = new Map();

  for (const s of services) {
    if (!s.customerId || !s.customerId.phone) continue;

    const key = s.customerId._id.toString();

    if (
      !map.has(key) ||
      new Date(s.nextServiceDate) <
        new Date(map.get(key).nextServiceDate)
    ) {
      map.set(key, s);
    }
  }

  return Array.from(map.values());
};

// ============================================================
// ELIGIBLE CUSTOMERS — PAYMENT REMINDERS
// (Services with pendingAmount > 0, not cancelled)
// ============================================================

const getPaymentReminderEligible = async (garageId) => {
  const services = await Service.find({
    garageId,
    paymentStatus: {
      $in: ["pending", "partiallyPaid"],
    },
  })
    .populate("customerId", "name phone")
    .populate(
      "vehicleId",
      "registrationNumber brand model"
    );

  return services.filter((s) => {
    if (!s.customerId || !s.customerId.phone) {
      return false;
    }

    const pending = Math.max(
      0,
      Number(s.totalAmount) - Number(s.paidAmount)
    );

    return pending > 0;
  });
};

// ============================================================
// ELIGIBLE CUSTOMERS — SPECIAL OFFERS
// (All customers with valid phone)
// ============================================================

const getSpecialOfferEligible = async (garageId) => {
  const customers = await Customer.find({
    garageId,
  });

  return customers.filter(
    (c) => c.phone && c.phone.trim().length >= 10
  );
};

// ============================================================
// FORMAT HELPERS
// ============================================================

const formatDate = (date) => {
  if (!date) return "-";

  const d = new Date(date);

  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();

  return `${day}/${month}/${year}`;
};

const formatAmount = (value) => {
  const num = Number(value) || 0;
  return num.toFixed(2);
};

const getVehicleModel = (vehicle) => {
  if (!vehicle) return "N/A";

  const parts = [
    vehicle.brand,
    vehicle.model,
  ].filter(Boolean);

  if (parts.length > 0) return parts.join(" ");

  return vehicle.registrationNumber || "N/A";
};

// ============================================================
// SEND SERVICE REMINDER
// ============================================================

const sendServiceReminder = async ({
  garageId,
  service,
  templateName,
}) => {
  const customer = service.customerId;
  const vehicle = service.vehicleId;

  const bodyParameters = [
    customer.name || "Customer",
    getVehicleModel(vehicle),
    formatDate(service.nextServiceDate),
  ];

  return await sendWhatsAppTemplate({
    garageId,
    customerId: customer._id,
    vehicleId: vehicle?._id,
    to: customer.phone,
    templateName,
    languageCode: "en",
    type: "service_reminder",
    bodyParameters,
  });
};

// ============================================================
// SEND PAYMENT REMINDER
// ============================================================

const sendPaymentReminder = async ({
  garageId,
  service,
  templateName,
}) => {
  const customer = service.customerId;
  const vehicle = service.vehicleId;

  const pendingAmount = Math.max(
    0,
    Number(service.totalAmount) - Number(service.paidAmount)
  );

  const bodyParameters = [
    customer.name || "Customer",
    formatAmount(pendingAmount),
    formatDate(service.serviceDate || new Date()),
  ];

  return await sendWhatsAppTemplate({
    garageId,
    customerId: customer._id,
    vehicleId: vehicle?._id,
    to: customer.phone,
    templateName,
    languageCode: "en",
    type: "payment_reminder",
    bodyParameters,
  });
};

// ============================================================
// SEND SPECIAL OFFER
// ============================================================

const sendSpecialOffer = async ({
  garageId,
  customer,
  templateName,
}) => {
  const bodyParameters = [
    customer.name || "Customer",
    "Special Offer",
    "Visit us for exclusive deals!",
  ];

  return await sendWhatsAppTemplate({
    garageId,
    customerId: customer._id,
    to: customer.phone,
    templateName,
    languageCode: "en",
    type: "offer",
    bodyParameters,
  });
};

// ============================================================
// RUN AUTOMATION FOR ONE GARAGE
// options: { skipService, skipOffer, skipPayment }
// ============================================================

const runAutomationForGarage = async ({
  garageId,
  settings,
  options = {},
}) => {
  const result = {
    serviceReminders: { sent: 0, failed: 0, errors: [] },
    paymentReminders: { sent: 0, failed: 0, errors: [] },
    specialOffers: { sent: 0, failed: 0, errors: [] },
  };

  // ----------------------------------------------------------
  // SERVICE REMINDERS
  // ----------------------------------------------------------
  if (
    settings.automationEnabled &&
    settings.serviceRemindersEnabled &&
    !options.skipService
  ) {
    try {
      const eligible =
        await getServiceReminderEligible(garageId);

      for (const service of eligible) {
        try {
          await sendServiceReminder({
            garageId,
            service,
            templateName: settings.serviceTemplate,
          });
          result.serviceReminders.sent++;
        } catch (e) {
          result.serviceReminders.failed++;
          result.serviceReminders.errors.push(
            e.message
          );
        }
      }
    } catch (e) {
      result.serviceReminders.errors.push(e.message);
    }
  }

  // ----------------------------------------------------------
  // PAYMENT REMINDERS
  // ----------------------------------------------------------
  if (
    settings.automationEnabled &&
    settings.paymentRemindersEnabled &&
    !options.skipPayment
  ) {
    try {
      const eligible =
        await getPaymentReminderEligible(garageId);

      for (const service of eligible) {
        try {
          await sendPaymentReminder({
            garageId,
            service,
            templateName: settings.paymentTemplate,
          });
          result.paymentReminders.sent++;
        } catch (e) {
          result.paymentReminders.failed++;
          result.paymentReminders.errors.push(e.message);
        }
      }
    } catch (e) {
      result.paymentReminders.errors.push(e.message);
    }
  }

  // ----------------------------------------------------------
  // SPECIAL OFFERS
  // ----------------------------------------------------------
  if (
    settings.automationEnabled &&
    settings.specialOffersEnabled &&
    !options.skipOffer
  ) {
    try {
      const eligible =
        await getSpecialOfferEligible(garageId);

      for (const customer of eligible) {
        try {
          await sendSpecialOffer({
            garageId,
            customer,
            templateName: settings.offerTemplate,
          });
          result.specialOffers.sent++;
        } catch (e) {
          result.specialOffers.failed++;
          result.specialOffers.errors.push(e.message);
        }
      }
    } catch (e) {
      result.specialOffers.errors.push(e.message);
    }
  }

  return result;
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getServiceReminderEligible,
  getPaymentReminderEligible,
  getSpecialOfferEligible,
  sendServiceReminder,
  sendPaymentReminder,
  sendSpecialOffer,
  runAutomationForGarage,
};