const express = require("express");

const Vehicle = require("../models/Vehicle");
const Customer = require("../models/Customer");

const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const router = express.Router();


// ============================================================
// VEHICLE ROUTES
// Base URL: /api/vehicles
// ============================================================


// GET ALL VEHICLES
router.get(
  "/",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const vehicles = await Vehicle.find({
        garageId: req.garageId,
      })
        .populate(
          "customerId",
          "name phone email address"
        )
        .sort({
          createdAt: -1,
        });

      return res.json({
        success: true,
        vehicles,
      });
    } catch (error) {
      console.error(
        "Get vehicles error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to fetch vehicles",
      });
    }
  }
);


// GET SINGLE VEHICLE
router.get(
  "/:id",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const vehicle =
        await Vehicle.findOne({
          _id: req.params.id,
          garageId: req.garageId,
        }).populate(
          "customerId",
          "name phone email address"
        );

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message: "Vehicle not found",
        });
      }

      return res.json({
        success: true,
        vehicle,
      });
    } catch (error) {
      console.error(
        "Get vehicle error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to fetch vehicle",
      });
    }
  }
);


// GET VEHICLES OF A CUSTOMER
router.get(
  "/customer/:customerId",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const customer =
        await Customer.findOne({
          _id: req.params.customerId,
          garageId: req.garageId,
        });

      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found",
        });
      }

      const vehicles =
        await Vehicle.find({
          customerId:
            req.params.customerId,
          garageId: req.garageId,
        }).sort({
          createdAt: -1,
        });

      return res.json({
        success: true,
        vehicles,
      });
    } catch (error) {
      console.error(
        "Get customer vehicles error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to fetch customer vehicles",
      });
    }
  }
);


// CREATE VEHICLE
router.post(
  "/",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const {
        customerId,
        registrationNumber,
        brand,
        model,
        variant,
        manufacturingYear,
        fuelType,
        currentMileage,
        vin,
        engineNumber,
        notes,
        insuranceExpiry,
        pucExpiry,
      } = req.body;

      if (
        !customerId ||
        !registrationNumber ||
        !brand ||
        !model
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Customer, registration number, brand and model are required",
        });
      }

      // Make sure customer belongs
      // to the logged-in garage
      const customer =
        await Customer.findOne({
          _id: customerId,
          garageId: req.garageId,
        });

      if (!customer) {
        return res.status(404).json({
          success: false,
          message:
            "Customer not found",
        });
      }

      const normalizedRegistration =
        registrationNumber
          .trim()
          .toUpperCase();

      const existingVehicle =
        await Vehicle.findOne({
          garageId: req.garageId,
          registrationNumber:
            normalizedRegistration,
        });

      if (existingVehicle) {
        return res.status(409).json({
          success: false,
          message:
            "Vehicle with this registration already exists",
        });
      }

      const vehicle =
        await Vehicle.create({
          garageId: req.garageId,

          customerId,

          registrationNumber:
            normalizedRegistration,

          brand: brand.trim(),

          model: model.trim(),

          variant:
            variant?.trim() || "",

          manufacturingYear,

          fuelType,

          currentMileage,

          vin: vin?.trim() || "",

          engineNumber:
            engineNumber?.trim() || "",

          notes:
            notes?.trim() || "",

          insuranceExpiry:
            insuranceExpiry || null,

          pucExpiry:
            pucExpiry || null,
        });

      return res.status(201).json({
        success: true,
        message:
          "Vehicle created successfully",
        vehicle,
      });
    } catch (error) {
      console.error(
        "Create vehicle error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create vehicle",
      });
    }
  }
);


// UPDATE VEHICLE
router.put(
  "/:id",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      // Explicit allow-list prevents mass assignment of sensitive fields.
      const allowedFields = [
        "customerId",
        "registrationNumber",
        "brand",
        "model",
        "variant",
        "manufacturingYear",
        "fuelType",
        "currentMileage",
        "vin",
        "engineNumber",
        "notes",
        "insuranceExpiry",
        "pucExpiry",
      ];

      const updateData = {};

      for (const field of allowedFields) {
        if (Object.prototype.hasOwnProperty.call(req.body || {}, field)) {
          updateData[field] = req.body[field];
        }
      }

      if (
        updateData.registrationNumber !==
        undefined
      ) {
        updateData.registrationNumber =
          String(
            updateData.registrationNumber
          )
            .trim()
            .toUpperCase();
      }

      if (updateData.brand !== undefined) {
        updateData.brand =
          String(updateData.brand).trim();
      }

      if (updateData.model !== undefined) {
        updateData.model =
          String(updateData.model).trim();
      }

      if (updateData.variant !== undefined) {
        updateData.variant =
          String(updateData.variant).trim();
      }

      if (updateData.vin !== undefined) {
        updateData.vin =
          String(updateData.vin).trim();
      }

      if (
        updateData.engineNumber !==
        undefined
      ) {
        updateData.engineNumber =
          String(
            updateData.engineNumber
          ).trim();
      }

      if (updateData.notes !== undefined) {
        updateData.notes =
          String(updateData.notes).trim();
      }

      // If customerId is being changed,
      // verify that customer belongs
      // to the same garage.
      if (
        updateData.customerId !==
        undefined
      ) {
        const customer =
          await Customer.findOne({
            _id: updateData.customerId,
            garageId: req.garageId,
          });

        if (!customer) {
          return res.status(404).json({
            success: false,
            message:
              "Customer not found",
          });
        }
      }

      // Check duplicate registration
      if (
        updateData.registrationNumber !==
        undefined
      ) {
        const duplicate =
          await Vehicle.findOne({
            _id: {
              $ne: req.params.id,
            },
            garageId: req.garageId,
            registrationNumber:
              updateData.registrationNumber,
          });

        if (duplicate) {
          return res.status(409).json({
            success: false,
            message:
              "Vehicle with this registration already exists",
          });
        }
      }

      const vehicle =
        await Vehicle.findOneAndUpdate(
          {
            _id: req.params.id,
            garageId: req.garageId,
          },
          updateData,
          {
            new: true,
            runValidators: true,
          }
        ).populate(
          "customerId",
          "name phone email address"
        );

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message:
            "Vehicle not found",
        });
      }

      return res.json({
        success: true,
        message:
          "Vehicle updated successfully",
        vehicle,
      });
    } catch (error) {
      console.error(
        "Update vehicle error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to update vehicle",
      });
    }
  }
);


// DELETE VEHICLE
router.delete(
  "/:id",
  protect,
  requireGarage,
  async (req, res) => {
    try {
      const vehicle =
        await Vehicle.findOneAndDelete({
          _id: req.params.id,
          garageId: req.garageId,
        });

      if (!vehicle) {
        return res.status(404).json({
          success: false,
          message:
            "Vehicle not found",
        });
      }

      return res.json({
        success: true,
        message:
          "Vehicle deleted successfully",
      });
    } catch (error) {
      console.error(
        "Delete vehicle error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to delete vehicle",
      });
    }
  }
);


module.exports = router;