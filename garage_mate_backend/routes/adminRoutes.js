const express = require("express");

const Garage = require("../models/Garage");
const User = require("../models/User");
const Customer = require("../models/Customer");
const Vehicle = require("../models/Vehicle");
const Service = require("../models/Service");
const Reminder = require("../models/Reminder");
const Invoice = require("../models/Invoice");
const Notification = require("../models/Notification");

const {
  sendGarageApprovalEmail,
} = require("../services/emailService");

const {
  sendPushNotification,
} = require("../services/firebaseNotificationService");

const protect = require("../middleware/authMiddleware");

const router = express.Router();

// ============================================================
// SUPER ADMIN CHECK
// ============================================================

const superAdminOnly = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: "Authentication required",
    });
  }

  if (req.user.role !== "super_admin") {
    return res.status(403).json({
      success: false,
      message: "Super Admin access required",
    });
  }

  next();
};

// ============================================================
// GET ALL GARAGES
// GET /api/admin/garages
// ============================================================

router.get(
  "/garages",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const garages = await Garage.find()
        .sort({ createdAt: -1 })
        .lean();

      return res.status(200).json({
        success: true,
        count: garages.length,
        garages,
      });
    } catch (error) {
      console.error(
        "Get garages error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to fetch garages",
      });
    }
  }
);

// ============================================================
// GET SINGLE GARAGE
// GET /api/admin/garages/:garageId
// ============================================================

router.get(
  "/garages/:garageId",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.params.garageId
      ).lean();

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const owner = await User.findOne({
        garageId: garage._id,
        role: "garage_owner",
      })
        .select("-password")
        .lean();

      return res.status(200).json({
        success: true,
        garage,
        owner: owner || null,
      });
    } catch (error) {
      console.error(
        "Get garage error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to fetch garage",
      });
    }
  }
);

// ============================================================
// APPROVE GARAGE
// PUT /api/admin/garages/:garageId/approve
// ============================================================

router.put(
  "/garages/:garageId/approve",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.params.garageId
      );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const owner = await User.findOne({
        garageId: garage._id,
        role: "garage_owner",
      });

      garage.status = "active";
      garage.isActive = true;

      await garage.save();

      // --------------------------------------------------------
      // PUSH NOTIFICATION TO GARAGE OWNER
      // --------------------------------------------------------

      if (owner?.fcmToken) {
        try {
          await sendPushNotification({
            fcmToken: owner.fcmToken,

            title: "Garage Approved 🎉",

            body:
              "Your GarageMate garage has been approved successfully. You can now access your dashboard.",

            data: {
              type: "garage_approved",
              garageId:
                garage._id.toString(),
            },
          });
        } catch (pushError) {
          console.error(
            "Garage approval push notification error:",
            pushError
          );
        }
      }

      // --------------------------------------------------------
      // APPROVAL EMAIL
      // --------------------------------------------------------

      if (owner) {
        try {
          await sendGarageApprovalEmail({
            to: owner.email,
            ownerName: owner.name,
            garageName: garage.name,
          });
        } catch (emailError) {
          console.error(
            "Garage approval email error:",
            emailError
          );
        }
      }

      return res.status(200).json({
        success: true,
        message:
          "Garage approved successfully",
        garage,
      });
    } catch (error) {
      console.error(
        "Approve garage error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to approve garage",
      });
    }
  }
);

// ============================================================
// SUSPEND GARAGE
// PUT /api/admin/garages/:garageId/suspend
// ============================================================

router.put(
  "/garages/:garageId/suspend",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.params.garageId
      );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      garage.status = "suspended";
      garage.isActive = false;

      await garage.save();

      return res.status(200).json({
        success: true,
        message:
          "Garage suspended successfully",
        garage,
      });
    } catch (error) {
      console.error(
        "Suspend garage error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to suspend garage",
      });
    }
  }
);

// ============================================================
// ACTIVATE GARAGE
// PUT /api/admin/garages/:garageId/activate
// ============================================================

router.put(
  "/garages/:garageId/activate",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.params.garageId
      );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      garage.status = "active";
      garage.isActive = true;

      await garage.save();

      return res.status(200).json({
        success: true,
        message:
          "Garage activated successfully",
        garage,
      });
    } catch (error) {
      console.error(
        "Activate garage error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to activate garage",
      });
    }
  }
);

// ============================================================
// DELETE SINGLE GARAGE + ALL DATA
// DELETE /api/admin/garages/:garageId
// ============================================================

router.delete(
  "/garages/:garageId",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const { garageId } = req.params;

      const confirmation =
        req.body?.confirmation;

      if (
        confirmation !==
        "DELETE GARAGE"
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Confirmation required. Send confirmation as "DELETE GARAGE".',
        });
      }

      const garage =
        await Garage.findById(garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const [
        users,
        customers,
        vehicles,
        services,
        reminders,
        invoices,
        notifications,
      ] = await Promise.all([
        User.deleteMany({
          garageId: garage._id,
          role: {
            $in: [
              "garage_owner",
              "staff",
            ],
          },
        }),

        Customer.deleteMany({
          garageId: garage._id,
        }),

        Vehicle.deleteMany({
          garageId: garage._id,
        }),

        Service.deleteMany({
          garageId: garage._id,
        }),

        Reminder.deleteMany({
          garageId: garage._id,
        }),

        Invoice.deleteMany({
          garageId: garage._id,
        }),

        Notification.deleteMany({
          garageId: garage._id,
        }),
      ]);

      await Garage.findByIdAndDelete(
        garage._id
      );

      return res.status(200).json({
        success: true,

        message:
          "Garage and all associated data deleted successfully",

        deleted: {
          garage: 1,
          users:
            users.deletedCount,
          customers:
            customers.deletedCount,
          vehicles:
            vehicles.deletedCount,
          services:
            services.deletedCount,
          reminders:
            reminders.deletedCount,
          invoices:
            invoices.deletedCount,
          notifications:
            notifications.deletedCount,
        },
      });
    } catch (error) {
      console.error(
        "Delete garage error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete garage and its data",
      });
    }
  }
);

// ============================================================
// ERASE ALL GARAGE DATA
// DELETE /api/admin/garages
// ============================================================

router.delete(
  "/garages",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const confirmation =
        req.body?.confirmation;

      if (
        confirmation !==
        "ERASE ALL GARAGE DATA"
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Confirmation required. Send confirmation as "ERASE ALL GARAGE DATA".',
        });
      }

      const garages =
        await Garage.find()
          .select("_id")
          .lean();

      const garageIds =
        garages.map(
          (garage) => garage._id
        );

      if (garageIds.length === 0) {
        return res.status(200).json({
          success: true,
          message:
            "No garage data found to erase",

          deleted: {
            garages: 0,
            users: 0,
            customers: 0,
            vehicles: 0,
            services: 0,
            reminders: 0,
            invoices: 0,
            notifications: 0,
          },
        });
      }

      const [
        users,
        customers,
        vehicles,
        services,
        reminders,
        invoices,
        notifications,
      ] = await Promise.all([
        User.deleteMany({
          garageId: {
            $in: garageIds,
          },
          role: {
            $in: [
              "garage_owner",
              "staff",
            ],
          },
        }),

        Customer.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),

        Vehicle.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),

        Service.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),

        Reminder.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),

        Invoice.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),

        Notification.deleteMany({
          garageId: {
            $in: garageIds,
          },
        }),
      ]);

      const garagesDeleted =
        await Garage.deleteMany({});

      return res.status(200).json({
        success: true,

        message:
          "All garage data has been erased successfully",

        deleted: {
          garages:
            garagesDeleted.deletedCount,
          users:
            users.deletedCount,
          customers:
            customers.deletedCount,
          vehicles:
            vehicles.deletedCount,
          services:
            services.deletedCount,
          reminders:
            reminders.deletedCount,
          invoices:
            invoices.deletedCount,
          notifications:
            notifications.deletedCount,
        },
      });
    } catch (error) {
      console.error(
        "Erase all garage data error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to erase all garage data",
      });
    }
  }
);

// ============================================================
// GET SUPER ADMIN NOTIFICATIONS
// GET /api/admin/notifications
// ============================================================

router.get(
  "/notifications",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const notifications =
        await Notification.find({
          recipient: req.user._id,
        })
          .populate(
            "garageId",
            "name ownerName phone email city status"
          )
          .sort({
            createdAt: -1,
          })
          .limit(100)
          .lean();

      const unreadCount =
        await Notification.countDocuments({
          recipient: req.user._id,
          isRead: false,
        });

      return res.status(200).json({
        success: true,
        unreadCount,
        count: notifications.length,
        notifications,
      });
    } catch (error) {
      console.error(
        "Get notifications error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to fetch notifications",
      });
    }
  }
);

// ============================================================
// MARK SINGLE NOTIFICATION AS READ
// PUT /api/admin/notifications/:notificationId/read
// ============================================================

router.put(
  "/notifications/:notificationId/read",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const notification =
        await Notification.findOneAndUpdate(
          {
            _id:
              req.params.notificationId,
            recipient:
              req.user._id,
          },
          {
            $set: {
              isRead: true,
            },
          },
          {
            new: true,
          }
        );

      if (!notification) {
        return res.status(404).json({
          success: false,
          message:
            "Notification not found",
        });
      }

      return res.status(200).json({
        success: true,
        message:
          "Notification marked as read",
        notification,
      });
    } catch (error) {
      console.error(
        "Mark notification read error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update notification",
      });
    }
  }
);

// ============================================================
// MARK ALL NOTIFICATIONS AS READ
// PUT /api/admin/notifications/read-all
// ============================================================

router.put(
  "/notifications/read-all",
  protect,
  superAdminOnly,
  async (req, res) => {
    try {
      const result =
        await Notification.updateMany(
          {
            recipient: req.user._id,
            isRead: false,
          },
          {
            $set: {
              isRead: true,
            },
          }
        );

      return res.status(200).json({
        success: true,

        message:
          "All notifications marked as read",

        modifiedCount:
          result.modifiedCount,
      });
    } catch (error) {
      console.error(
        "Mark all notifications read error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to mark all notifications as read",
      });
    }
  }
);

// ============================================================
// EXPORT
// ============================================================

module.exports = router;