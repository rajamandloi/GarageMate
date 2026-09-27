const express = require("express");

const protect =
  require("../middleware/authMiddleware");

const requireGarage =
  require("../middleware/garageMiddleware");

  const requireStaffRole = require("../middleware/requireStaffRole");

const {
  createInvoice,
  getInvoices,
  getInvoiceById,
  getCustomerInvoices,
  cancelInvoice,
  sendInvoiceOnWhatsApp,
} = require(
  "../controllers/invoiceController"
);

const router =
  express.Router();

router.get(
  "/",
  protect,
  requireGarage,
  getInvoices
);

router.get(
  "/customer/:customerId",
  protect,
  requireGarage,
  getCustomerInvoices
);

router.get(
  "/:id",
  protect,
  requireGarage,
  getInvoiceById
);

router.post(
  "/",
  protect,
  requireGarage,
  createInvoice
);

router.patch(
  "/:id/cancel",
  protect,
  requireGarage,
  cancelInvoice
);

router.post(
  "/:id/send-whatsapp",
  protect,
  requireGarage,
  sendInvoiceOnWhatsApp
);



// Create invoice — owner, manager, accountant
router.post(
  "/",
  protect,
  requireGarage,
  requireStaffRole(["manager", "accountant"]),
  createInvoice
);

// Send on WhatsApp — owner, manager, accountant
router.post(
  "/:id/send-whatsapp",
  protect,
  requireGarage,
  requireStaffRole(["manager", "accountant"]),
  sendInvoiceOnWhatsApp
);

module.exports = router;