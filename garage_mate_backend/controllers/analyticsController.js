const mongoose = require("mongoose");

const Invoice = require("../models/Invoice");
const Service = require("../models/Service");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");

// ============================================================
// HELPER: DATE RANGE
// ============================================================

const getDateRange = (range, startDate, endDate) => {
  const now = new Date();
  let start;
  let end = new Date();

  switch (range) {
    case "today":
      start = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate()
      );
      break;

    case "week":
      start = new Date(now);
      start.setDate(now.getDate() - 7);
      break;

    case "month":
      start = new Date(
        now.getFullYear(),
        now.getMonth(),
        1
      );
      break;

    case "year":
      start = new Date(now.getFullYear(), 0, 1);
      break;

    case "custom":
      start = startDate ? new Date(startDate) : new Date(0);
      end = endDate ? new Date(endDate) : new Date();
      // Include entire end day
      end.setHours(23, 59, 59, 999);
      break;

    default:
      // Default: this month
      start = new Date(
        now.getFullYear(),
        now.getMonth(),
        1
      );
  }

  return { start, end };
};

// ============================================================
// GET ANALYTICS DASHBOARD
// GET /api/analytics/dashboard
// Query: ?range=today|week|month|year|custom
//        &startDate=2025-01-01&endDate=2025-12-31
// ============================================================

const getAnalyticsDashboard = async (req, res) => {
  try {
    const garageId = new mongoose.Types.ObjectId(
      req.garageId
    );

    const {
      range = "month",
      startDate,
      endDate,
    } = req.query;

    const { start, end } = getDateRange(
      range,
      startDate,
      endDate
    );

    const matchStage = {
      garageId,
      status: { $ne: "cancelled" },
      invoiceDate: {
        $gte: start,
        $lte: end,
      },
    };

    // ========================================================
    // 1. SUMMARY STATS
    // ========================================================
    const summaryAgg = await Invoice.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: "$paidAmount" },
          totalBilled: { $sum: "$totalAmount" },
          pendingAmount: { $sum: "$pendingAmount" },
          totalInvoices: { $sum: 1 },
          avgServiceValue: { $avg: "$totalAmount" },
        },
      },
    ]);

    const summary = summaryAgg[0] || {
      totalRevenue: 0,
      totalBilled: 0,
      pendingAmount: 0,
      totalInvoices: 0,
      avgServiceValue: 0,
    };

    // ========================================================
    // 2. MONTHLY REVENUE (Last 12 months)
    // ========================================================
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(
      twelveMonthsAgo.getMonth() - 11
    );
    twelveMonthsAgo.setDate(1);
    twelveMonthsAgo.setHours(0, 0, 0, 0);

    const monthlyRevenueAgg = await Invoice.aggregate([
      {
        $match: {
          garageId,
          status: { $ne: "cancelled" },
          invoiceDate: { $gte: twelveMonthsAgo },
        },
      },
      {
        $group: {
          _id: {
            year: { $year: "$invoiceDate" },
            month: { $month: "$invoiceDate" },
          },
          revenue: { $sum: "$paidAmount" },
          billed: { $sum: "$totalAmount" },
          invoices: { $sum: 1 },
        },
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } },
    ]);

    // Fill missing months with 0
    const monthlyRevenue = [];
    const monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];

    for (let i = 0; i < 12; i++) {
      const d = new Date();
      d.setMonth(d.getMonth() - (11 - i));
      const year = d.getFullYear();
      const month = d.getMonth() + 1;

      const found = monthlyRevenueAgg.find(
        (m) =>
          m._id.year === year && m._id.month === month
      );

      monthlyRevenue.push({
        year,
        month,
        monthName: monthNames[month - 1],
        label: `${monthNames[month - 1]} ${year}`,
        revenue: found?.revenue || 0,
        billed: found?.billed || 0,
        invoices: found?.invoices || 0,
      });
    }

    // ========================================================
    // 3. TOP 10 CUSTOMERS
    // ========================================================
    const topCustomersAgg = await Invoice.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: "$customerId",
          totalRevenue: { $sum: "$paidAmount" },
          totalBilled: { $sum: "$totalAmount" },
          pendingAmount: { $sum: "$pendingAmount" },
          invoiceCount: { $sum: 1 },
        },
      },
      { $sort: { totalRevenue: -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: "customers",
          localField: "_id",
          foreignField: "_id",
          as: "customer",
        },
      },
      {
        $unwind: {
          path: "$customer",
          preserveNullAndEmptyArrays: true,
        },
      },
      {
        $project: {
          _id: 1,
          customerName: {
            $ifNull: ["$customer.name", "Unknown"],
          },
          customerPhone: "$customer.phone",
          totalRevenue: 1,
          totalBilled: 1,
          pendingAmount: 1,
          invoiceCount: 1,
        },
      },
    ]);

    // ========================================================
    // 4. SERVICE TYPE BREAKDOWN
    // ========================================================
    const serviceTypeAgg = await Service.aggregate([
      {
        $match: {
          garageId,
          serviceDate: { $gte: start, $lte: end },
        },
      },
      {
        $group: {
          _id: "$serviceType",
          count: { $sum: 1 },
          revenue: { $sum: "$paidAmount" },
          totalBilled: { $sum: "$totalAmount" },
        },
      },
      { $sort: { count: -1 } },
    ]);

    const serviceTypes = serviceTypeAgg.map((s) => ({
      serviceType: s._id || "Other",
      count: s.count,
      revenue: s.revenue,
      totalBilled: s.totalBilled,
    }));

    // ========================================================
    // 5. PAYMENT COLLECTION RATE
    // ========================================================
    const collectionAgg = await Invoice.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalBilled: { $sum: "$totalAmount" },
          totalPaid: { $sum: "$paidAmount" },
          fullyPaidCount: {
            $sum: {
              $cond: [
                { $eq: ["$paymentStatus", "paid"] },
                1,
                0,
              ],
            },
          },
          pendingCount: {
            $sum: {
              $cond: [
                {
                  $in: [
                    "$paymentStatus",
                    ["pending", "partiallyPaid"],
                  ],
                },
                1,
                0,
              ],
            },
          },
          totalCount: { $sum: 1 },
        },
      },
    ]);

    const collectionData = collectionAgg[0] || {
      totalBilled: 0,
      totalPaid: 0,
      fullyPaidCount: 0,
      pendingCount: 0,
      totalCount: 0,
    };

    const collectionRate =
      collectionData.totalBilled > 0
        ? (collectionData.totalPaid /
            collectionData.totalBilled) *
          100
        : 0;

    // ========================================================
    // 6. BUSY DAYS ANALYSIS
    // ========================================================
    const busyDaysAgg = await Service.aggregate([
      {
        $match: {
          garageId,
          serviceDate: { $gte: start, $lte: end },
        },
      },
      {
        $group: {
          _id: { $dayOfWeek: "$serviceDate" },
          count: { $sum: 1 },
          revenue: { $sum: "$paidAmount" },
        },
      },
      { $sort: { count: -1 } },
    ]);

    const dayNames = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    const busyDays = dayNames.map((name, idx) => {
      const found = busyDaysAgg.find(
        (b) => b._id === idx + 1
      );
      return {
        day: name,
        dayIndex: idx,
        count: found?.count || 0,
        revenue: found?.revenue || 0,
      };
    });

    // ========================================================
    // 7. RECENT INVOICES
    // ========================================================
    const recentInvoices = await Invoice.find(
      matchStage
    )
      .populate("customerId", "name phone")
      .populate(
        "vehicleId",
        "registrationNumber brand model"
      )
      .sort({ invoiceDate: -1 })
      .limit(5)
      .lean();

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,

      range: {
        type: range,
        startDate: start,
        endDate: end,
      },

      summary: {
        totalRevenue: summary.totalRevenue || 0,
        totalBilled: summary.totalBilled || 0,
        pendingAmount: summary.pendingAmount || 0,
        totalInvoices: summary.totalInvoices || 0,
        avgServiceValue:
          summary.avgServiceValue || 0,
      },

      monthlyRevenue,

      topCustomers: topCustomersAgg,

      serviceTypes,

      collection: {
        totalBilled: collectionData.totalBilled,
        totalPaid: collectionData.totalPaid,
        collectionRate: Number(
          collectionRate.toFixed(1)
        ),
        fullyPaidCount:
          collectionData.fullyPaidCount,
        pendingCount: collectionData.pendingCount,
        totalCount: collectionData.totalCount,
      },

      busyDays,

      recentInvoices,
    });
  } catch (error) {
    console.error(
      "Analytics dashboard error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch analytics",
      error:
        process.env.NODE_ENV !== "production"
          ? error.message
          : undefined,
    });
  }
};

// ============================================================
// GET QUICK SUMMARY (for dashboard card)
// GET /api/analytics/summary
// ============================================================

const getAnalyticsSummary = async (req, res) => {
  try {
    const garageId = new mongoose.Types.ObjectId(
      req.garageId
    );

    const now = new Date();
    const startOfMonth = new Date(
      now.getFullYear(),
      now.getMonth(),
      1
    );

    const [thisMonth, allTime] = await Promise.all([
      Invoice.aggregate([
        {
          $match: {
            garageId,
            status: { $ne: "cancelled" },
            invoiceDate: { $gte: startOfMonth },
          },
        },
        {
          $group: {
            _id: null,
            revenue: { $sum: "$paidAmount" },
            billed: { $sum: "$totalAmount" },
            invoices: { $sum: 1 },
          },
        },
      ]),
      Invoice.aggregate([
        {
          $match: {
            garageId,
            status: { $ne: "cancelled" },
          },
        },
        {
          $group: {
            _id: null,
            revenue: { $sum: "$paidAmount" },
            billed: { $sum: "$totalAmount" },
            pending: { $sum: "$pendingAmount" },
            invoices: { $sum: 1 },
          },
        },
      ]),
    ]);

    return res.status(200).json({
      success: true,
      thisMonth: thisMonth[0] || {
        revenue: 0,
        billed: 0,
        invoices: 0,
      },
      allTime: allTime[0] || {
        revenue: 0,
        billed: 0,
        pending: 0,
        invoices: 0,
      },
    });
  } catch (error) {
    console.error(
      "Analytics summary error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Unable to fetch summary",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getAnalyticsDashboard,
  getAnalyticsSummary,
};