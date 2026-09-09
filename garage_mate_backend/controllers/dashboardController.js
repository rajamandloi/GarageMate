const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Service = require("../models/Service");
const Reminder = require("../models/Reminder");

const getDashboardStats = async (req, res) => {
  try {
    // ============================================================
    // GARAGE ID
    // ============================================================

    const garageId = req.garageId;

    // Super Admin ke liye garage-specific dashboard
    // abhi required nahi hai.
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
      // Customers
      Customer.countDocuments({
        garageId,
      }),

      // Vehicles
      Vehicle.countDocuments({
        garageId,
      }),

      // Services
      Service.countDocuments({
        garageId,
      }),

      // Pending / upcoming reminders
      Reminder.countDocuments({
        garageId,
        status: {
          $in: [
            "upcoming",
            "dueSoon",
            "dueToday",
          ],
        },
      }),

      // Overdue reminders
      Reminder.countDocuments({
        garageId,
        status: "overdue",
      }),

      // Completed reminders
      Reminder.countDocuments({
        garageId,
        status: "completed",
      }),
    ]);

    // ============================================================
    // PAYMENT SUMMARY
    // ============================================================

    const paymentSummary = await Service.aggregate([
      {
        $match: {
          garageId,
        },
      },

      {
        $group: {
          _id: null,

          totalAmount: {
            $sum: "$totalAmount",
          },

          paidAmount: {
            $sum: "$paidAmount",
          },
        },
      },
    ]);

    const totalAmount =
      paymentSummary[0]?.totalAmount || 0;

    const paidAmount =
      paymentSummary[0]?.paidAmount || 0;

    const pendingAmount = Math.max(
      0,
      totalAmount - paidAmount
    );

    // ============================================================
    // RECENT SERVICES
    // ============================================================

    const recentServices =
      await Service.find({
        garageId,
      })
        .populate(
          "customerId",
          "name phone"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model"
        )
        .sort({
          serviceDate: -1,
          createdAt: -1,
        })
        .limit(5);

    // ============================================================
    // RECENT REMINDERS
    // ============================================================

    const recentReminders =
      await Reminder.find({
        garageId,
      })
        .populate(
          "customerId",
          "name phone"
        )
        .populate(
          "vehicleId",
          "registrationNumber brand model"
        )
        .sort({
          dueDate: 1,
          createdAt: -1,
        })
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
    console.error(
      "Dashboard stats error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch dashboard stats",
      error: error.message,
    });
  }
};

module.exports = {
  getDashboardStats,
};