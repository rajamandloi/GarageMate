const express = require("express");

const Customer = require("../models/Customer");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();


// ============================================================
// CUSTOMER ROUTES
// Base URL: /api/customers
// ============================================================


// GET ALL CUSTOMERS
router.get(
  "/",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const customers =
        await Customer.find({
          garageId: req.garageId,
        }).sort({
          createdAt: -1,
        });

      return res.json({
        success: true,
        customers,
      });
    } catch (error) {
      console.error(
        "Get customers error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to fetch customers",
      });
    }
  }
);


// CREATE CUSTOMER
router.post(
  "/",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const {
        name,
        phone,
        email,
        address,
      } = req.body;

      if (!name || !phone) {
        return res.status(400).json({
          success: false,
          message:
            "Name and phone are required",
        });
      }

      const customer =
        await Customer.create({
          garageId: req.garageId,
          name: name.trim(),
          phone: phone.trim(),
          email: email
            ? email.trim().toLowerCase()
            : "",
          address: address
            ? address.trim()
            : "",
        });

      return res.status(201).json({
        success: true,
        message:
          "Customer created successfully",
        customer,
      });
    } catch (error) {
      console.error(
        "Create customer error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create customer",
      });
    }
  }
);


// UPDATE CUSTOMER
router.put(
  "/:id",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const updateData = {};

      if (req.body.name !== undefined) {
        updateData.name =
          String(req.body.name).trim();
      }

      if (req.body.phone !== undefined) {
        updateData.phone =
          String(req.body.phone).trim();
      }

      if (req.body.email !== undefined) {
        updateData.email =
          String(req.body.email)
            .trim()
            .toLowerCase();
      }

      if (req.body.address !== undefined) {
        updateData.address =
          String(req.body.address).trim();
      }

      const customer =
        await Customer.findOneAndUpdate(
          {
            _id: req.params.id,
            garageId: req.garageId,
          },
          updateData,
          {
            new: true,
            runValidators: true,
          }
        );

      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found",
        });
      }

      return res.json({
        success: true,
        message:
          "Customer updated successfully",
        customer,
      });
    } catch (error) {
      console.error(
        "Update customer error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update customer",
      });
    }
  }
);


// DELETE CUSTOMER
router.delete(
  "/:id",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const customer =
        await Customer.findOneAndDelete({
          _id: req.params.id,
          garageId: req.garageId,
        });

      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found",
        });
      }

      return res.json({
        success: true,
        message:
          "Customer deleted successfully",
      });
    } catch (error) {
      console.error(
        "Delete customer error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete customer",
      });
    }
  }
);


module.exports = router;