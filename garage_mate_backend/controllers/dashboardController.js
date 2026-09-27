const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Service = require("../models/Service");
const Reminder = require("../models/Reminder");
const Invoice = require("../models/Invoice");

// ============================================================
// GET DASHBOARD STATS
// GET /api/dashboard
// ============================================================

const getDashboardStats = async (req, res) => {
  try {
    const garageId = req.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage ID is required",
      });
    }

    // ============================================================
    // BASIC COUNTS
    // ============================================================

    const [
      totalCustomers,
      totalVehicles,
      totalServices,
      pendingReminders,
      overdueReminders,
      completedReminders,
    ] = await Promise.all([
      Customer.countDocuments({ garageId }),
      Vehicle.countDocuments({ garageId }),
      Service.countDocuments({ garageId }),

      Reminder.countDocuments({
        garageId,
        status: {
          $in: ["upcoming", "dueSoon", "dueToday"],
        },
      }),

      Reminder.countDocuments({
        garageId,
        status: "overdue",
      }),

      Reminder.countDocuments({
        garageId,
        status: "completed",
      }),
    ]);

    // ============================================================
    // PAYMENT SUMMARY
    // ============================================================

    const paymentSummary = await Service.aggregate([
      { $match: { garageId } },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: "$totalAmount" },
          paidAmount: { $sum: "$paidAmount" },
        },
      },
    ]);

    const totalAmount = paymentSummary[0]?.totalAmount || 0;
    const paidAmount = paymentSummary[0]?.paidAmount || 0;
    const pendingAmount = Math.max(0, totalAmount - paidAmount);

    // ============================================================
    // RECENT SERVICES
    // ============================================================

    const recentServices = await Service.find({ garageId })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ serviceDate: -1, createdAt: -1 })
      .limit(5);

    // ============================================================
    // RECENT REMINDERS
    // ============================================================

    const recentReminders = await Reminder.find({
      garageId,
      status: { $nin: ["completed", "cancelled"] },
    })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ dueDate: 1, createdAt: -1 })
      .limit(5);

    // ============================================================
    // RESPONSE
    // ============================================================

    return res.status(200).json({
      success: true,
      stats: {
        totalCustomers,
        totalVehicles,
        totalServices,
        pendingReminders,
        overdueReminders,
        completedReminders,
        totalAmount,
        paidAmount,
        pendingAmount,
      },
      recentServices,
      recentReminders,
    });
  } catch (error) {
    console.error("Dashboard stats error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to fetch dashboard stats",
      error: error.message,
    });
  }
};

// ============================================================
// GET TODAY'S TASKS
// GET /api/dashboard/today-tasks
// ============================================================

const getTodayTasks = async (req, res) => {
  try {
    const garageId = req.garageId;

    if (!garageId) {
      return res.status(400).json({
        success: false,
        message: "Garage ID is required",
      });
    }

    // --------------------------------------------------------
    // Date range: today 00:00 to tomorrow 00:00
    // --------------------------------------------------------
    const now = new Date();

    const startOfToday = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0,
      0
    );

    const startOfTomorrow = new Date(
      startOfToday.getTime() +
        24 * 60 * 60 * 1000
    );

    const endOfNext7Days = new Date(
      startOfToday.getTime() +
        7 * 24 * 60 * 60 * 1000
    );

    // --------------------------------------------------------
    // 1. SERVICES DUE TODAY
    // (Services whose nextServiceDate is today or before today)
    // --------------------------------------------------------
    const servicesDueToday = await Service.find({
      garageId,
      nextServiceDate: {
        $ne: null,
        $lte: startOfTomorrow,
      },
    })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ nextServiceDate: 1 })
      .limit(20);

    // --------------------------------------------------------
    // 2. PAYMENTS PENDING
    // (Services with paymentStatus pending/partiallyPaid,
    //  service date older than 7 days)
    // --------------------------------------------------------
    const sevenDaysAgo = new Date(
      startOfToday.getTime() -
        7 * 24 * 60 * 60 * 1000
    );

    const paymentsPending = await Service.find({
      garageId,
      paymentStatus: {
        $in: ["pending", "partiallyPaid"],
      },
      serviceDate: { $lte: sevenDaysAgo },
    })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ serviceDate: 1 })
      .limit(20);

    // --------------------------------------------------------
    // 3. REMINDERS DUE TODAY
    // --------------------------------------------------------
    const remindersDueToday = await Reminder.find({
      garageId,
      status: {
        $in: ["dueToday", "overdue"],
      },
    })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ dueDate: 1 })
      .limit(20);

    // --------------------------------------------------------
    // 4. SERVICES DUE IN NEXT 7 DAYS (upcoming)
    // --------------------------------------------------------
    const servicesUpcoming = await Service.find({
      garageId,
      nextServiceDate: {
        $gt: startOfTomorrow,
        $lte: endOfNext7Days,
      },
    })
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ nextServiceDate: 1 })
      .limit(10);

    // --------------------------------------------------------
    // Total tasks count
    // --------------------------------------------------------
    const totalTasksCount =
      servicesDueToday.length +
      paymentsPending.length +
      remindersDueToday.length;

    return res.status(200).json({
      success: true,
      tasks: {
        servicesDueToday,
        paymentsPending,
        remindersDueToday,
        servicesUpcoming,
        totalTasksCount,
      },
    });
  } catch (error) {
    console.error("Today tasks error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to fetch today's tasks",
      error: error.message,
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getDashboardStats,
  getTodayTasks,
};