const AutomationSettings = require(
  "../models/AutomationSettings"
);

const {
  getServiceReminderEligible,
  getPaymentReminderEligible,
  getSpecialOfferEligible,
  runAutomationForGarage,
} = require("../services/automationService");

// ============================================================
// GET SETTINGS
// GET /api/automation/settings
// ============================================================

const getSettings = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage is not associated with this account",
      });
    }

    let settings = await AutomationSettings.findOne({
      garageId,
    });

    // Create default settings if not exists
    if (!settings) {
      settings = await AutomationSettings.create({
        garageId,
      });
    }

    // Get eligible counts
    const [
      serviceEligible,
      paymentEligible,
      offerEligible,
    ] = await Promise.all([
      getServiceReminderEligible(garageId),
      getPaymentReminderEligible(garageId),
      getSpecialOfferEligible(garageId),
    ]);

    return res.status(200).json({
      success: true,
      settings,
      counts: {
        serviceReminders: serviceEligible.length,
        paymentReminders: paymentEligible.length,
        specialOffers: offerEligible.length,
      },
    });
  } catch (error) {
    console.error("Get automation settings error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch automation settings",
    });
  }
};

// ============================================================
// UPDATE SETTINGS
// PUT /api/automation/settings
// ============================================================

const updateSettings = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage is not associated with this account",
      });
    }

    const {
      automationEnabled,
      serviceRemindersEnabled,
      specialOffersEnabled,
      paymentRemindersEnabled,
      serviceTemplate,
      offerTemplate,
      paymentTemplate,
    } = req.body;

    let settings = await AutomationSettings.findOne({
      garageId,
    });

    if (!settings) {
      settings = new AutomationSettings({ garageId });
    }

    if (automationEnabled !== undefined) {
      settings.automationEnabled = Boolean(
        automationEnabled
      );
    }

    if (serviceRemindersEnabled !== undefined) {
      settings.serviceRemindersEnabled = Boolean(
        serviceRemindersEnabled
      );
    }

    if (specialOffersEnabled !== undefined) {
      settings.specialOffersEnabled = Boolean(
        specialOffersEnabled
      );
    }

    if (paymentRemindersEnabled !== undefined) {
      settings.paymentRemindersEnabled = Boolean(
        paymentRemindersEnabled
      );
    }

    if (
      serviceTemplate &&
      typeof serviceTemplate === "string"
    ) {
      settings.serviceTemplate = serviceTemplate.trim();
    }

    if (
      offerTemplate &&
      typeof offerTemplate === "string"
    ) {
      settings.offerTemplate = offerTemplate.trim();
    }

    if (
      paymentTemplate &&
      typeof paymentTemplate === "string"
    ) {
      settings.paymentTemplate = paymentTemplate.trim();
    }

    await settings.save();

    return res.status(200).json({
      success: true,
      message: "Automation settings updated successfully",
      settings,
    });
  } catch (error) {
    console.error("Update automation settings error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to update automation settings",
    });
  }
};

// ============================================================
// SEND NOW (Manual Trigger)
// POST /api/automation/send-now
// Body: { category: "service" | "payment" | "offer" | "all" }
// ============================================================

const sendNow = async (req, res) => {
  try {
    const garageId = req.garageId || req.user?.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage is not associated with this account",
      });
    }

    const { category = "all" } = req.body;

    let settings = await AutomationSettings.findOne({
      garageId,
    });

    if (!settings) {
      settings = await AutomationSettings.create({
        garageId,
      });
    }

    const options = {
      skipService: category !== "all" && category !== "service",
      skipPayment: category !== "all" && category !== "payment",
      skipOffer: category !== "all" && category !== "offer",
    };

    const result = await runAutomationForGarage({
      garageId,
      settings,
      options,
    });

    const totalSent =
      result.serviceReminders.sent +
      result.paymentReminders.sent +
      result.specialOffers.sent;

    const totalFailed =
      result.serviceReminders.failed +
      result.paymentReminders.failed +
      result.specialOffers.failed;

    // Update settings state
    settings.lastRunAt = new Date();
    settings.totalSentCount =
      (settings.totalSentCount || 0) + totalSent;

    if (totalFailed === 0) {
      settings.lastRunStatus = "success";
      settings.lastRunMessage = `${totalSent} message(s) sent`;
    } else if (totalSent > 0) {
      settings.lastRunStatus = "partial";
      settings.lastRunMessage = `${totalSent} sent, ${totalFailed} failed`;
    } else {
      settings.lastRunStatus = "failed";
      settings.lastRunMessage = `${totalFailed} failed`;
    }

    await settings.save();

    return res.status(200).json({
      success: true,
      message: settings.lastRunMessage,
      result,
      totalSent,
      totalFailed,
    });
  } catch (error) {
    console.error("Send now error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to send messages now",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getSettings,
  updateSettings,
  sendNow,
};