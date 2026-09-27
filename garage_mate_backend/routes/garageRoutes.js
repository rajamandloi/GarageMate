const express = require("express");
const Garage = require("../models/Garage");
const User = require("../models/User");
const protect = require("../middleware/authMiddleware");
const requireGarage = require("../middleware/garageMiddleware");

const multer = require("multer");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");

const router = express.Router();

// ==================================================
// UPLOAD DIRECTORIES
// ==================================================

const profileUploadDir = path.join(
  __dirname,
  "../uploads/garage"
);

const logoUploadDir = path.join(
  __dirname,
  "../uploads/garage/logos"
);

for (const dir of [profileUploadDir, logoUploadDir]) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// ==================================================
// MULTER CONFIG
// ==================================================

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 1,
    fields: 10,
    parts: 12,
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      "image/jpeg",
      "image/png",
      "image/webp",
    ];

    if (!allowedTypes.includes(file.mimetype)) {
      return cb(
        new Error(
          "Only JPG, PNG and WEBP images are allowed"
        )
      );
    }

    cb(null, true);
  },
});

// ==================================================
// IMAGE TYPE DETECTION
// ==================================================

const detectImageType = (buffer) => {
  if (!Buffer.isBuffer(buffer)) return null;

  // JPEG
  if (
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
    return { extension: ".jpg", mime: "image/jpeg" };
  }

  // PNG
  if (
    buffer.length >= 8 &&
    buffer
      .subarray(0, 8)
      .equals(
        Buffer.from([
          0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
        ])
      )
  ) {
    return { extension: ".png", mime: "image/png" };
  }

  // WEBP
  if (
    buffer.length >= 12 &&
    buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
    buffer.subarray(8, 12).toString("ascii") === "WEBP"
  ) {
    return { extension: ".webp", mime: "image/webp" };
  }

  return null;
};

// ==================================================
// HEX COLOR VALIDATION
// ==================================================

const isValidHexColor = (value) => {
  if (typeof value !== "string") return false;
  return /^#([0-9A-Fa-f]{6})$/.test(value);
};

// ==================================================
// UPLOAD GARAGE PROFILE IMAGE
// POST /api/garage/profile/image
// ==================================================

router.post(
  "/profile/image",
  protect,
  requireGarage,
  upload.single("profileImage"),

  async (req, res) => {
    try {
      if (!req.garageId) {
        return res.status(403).json({
          success: false,
          message: "Garage access is required",
        });
      }

      if (!req.file || !req.file.buffer) {
        return res.status(400).json({
          success: false,
          message: "Profile image is required",
        });
      }

      const detected = detectImageType(req.file.buffer);

      if (!detected || detected.mime !== req.file.mimetype) {
        return res.status(400).json({
          success: false,
          message: "Invalid or unsupported image file",
        });
      }

      const garage = await Garage.findById(req.garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const filename = `garage-${crypto.randomUUID()}${detected.extension}`;
      const targetPath = path.join(profileUploadDir, filename);

      await fs.promises.writeFile(targetPath, req.file.buffer, {
        flag: "wx",
        mode: 0o600,
      });

      const imageUrl = `/uploads/garage/${filename}`;
      const previousImage = garage.profileImage;

      garage.profileImage = imageUrl;
      await garage.save();

      // Delete old image
      if (
        typeof previousImage === "string" &&
        previousImage.startsWith("/uploads/garage/") &&
        !previousImage.includes("/logos/")
      ) {
        const previousFilename = path.basename(previousImage);
        const previousPath = path.join(
          profileUploadDir,
          previousFilename
        );

        try {
          await fs.promises.unlink(previousPath);
        } catch (error) {
          if (error.code !== "ENOENT") {
            console.warn("Unable to remove previous garage image");
          }
        }
      }

      return res.json({
        success: true,
        message: "Garage profile image uploaded successfully",
        profileImage: imageUrl,
      });
    } catch (error) {
      console.error(
        "Garage profile image upload error:",
        error.message
      );

      return res.status(500).json({
        success: false,
        message: "Unable to upload profile image",
      });
    }
  }
);

// ==================================================
// UPLOAD INVOICE LOGO
// POST /api/garage/invoice-logo
// ==================================================

router.post(
  "/invoice-logo",
  protect,
  requireGarage,
  upload.single("logo"),

  async (req, res) => {
    try {
      if (!req.garageId) {
        return res.status(403).json({
          success: false,
          message: "Garage access is required",
        });
      }

      if (!req.file || !req.file.buffer) {
        return res.status(400).json({
          success: false,
          message: "Logo image is required",
        });
      }

      const detected = detectImageType(req.file.buffer);

      if (!detected || detected.mime !== req.file.mimetype) {
        return res.status(400).json({
          success: false,
          message: "Invalid or unsupported image file",
        });
      }

      const garage = await Garage.findById(req.garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const filename = `logo-${crypto.randomUUID()}${detected.extension}`;
      const targetPath = path.join(logoUploadDir, filename);

      await fs.promises.writeFile(targetPath, req.file.buffer, {
        flag: "wx",
        mode: 0o600,
      });

      const logoUrl = `/uploads/garage/logos/${filename}`;
      const previousLogo = garage.invoiceSettings?.logo || "";

      if (!garage.invoiceSettings) {
        garage.invoiceSettings = {};
      }

      garage.invoiceSettings.logo = logoUrl;
      await garage.save();

      // Delete old logo
      if (
        typeof previousLogo === "string" &&
        previousLogo.startsWith("/uploads/garage/logos/")
      ) {
        const previousFilename = path.basename(previousLogo);
        const previousPath = path.join(
          logoUploadDir,
          previousFilename
        );

        try {
          await fs.promises.unlink(previousPath);
        } catch (error) {
          if (error.code !== "ENOENT") {
            console.warn("Unable to remove previous logo");
          }
        }
      }

      return res.json({
        success: true,
        message: "Invoice logo uploaded successfully",
        logo: logoUrl,
      });
    } catch (error) {
      console.error(
        "Invoice logo upload error:",
        error.message
      );

      return res.status(500).json({
        success: false,
        message: "Unable to upload logo",
      });
    }
  }
);

// ==================================================
// GET GARAGE PROFILE
// GET /api/garage/profile
// ==================================================

router.get(
  "/profile",
  protect,
  requireGarage,

  async (req, res) => {
    try {
      const garage = await Garage.findById(req.garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      return res.json({
        success: true,
        garage,
      });
    } catch (error) {
      console.error(
        "Get garage profile error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to fetch garage profile",
      });
    }
  }
);

// ==================================================
// UPDATE GARAGE PROFILE
// PUT /api/garage/profile
// ==================================================

router.put(
  "/profile",
  protect,
  requireGarage,

  async (req, res) => {
    try {
      const {
        name,
        ownerName,
        phone,
        ownerPhone,
        garagePhone,
        email,
        garageEmail,
        address,
        city,
      } = req.body;

      const garage = await Garage.findById(req.garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const user = await User.findById(req.user._id);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      if (name !== undefined) {
        if (!String(name).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage name is required",
          });
        }
        garage.name = String(name).trim();
      }

      if (ownerName !== undefined) {
        if (!String(ownerName).trim()) {
          return res.status(400).json({
            success: false,
            message: "Owner name is required",
          });
        }
        garage.ownerName = String(ownerName).trim();
        user.name = String(ownerName).trim();
      }

      if (ownerPhone !== undefined) {
        if (!String(ownerPhone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Owner phone is required",
          });
        }
        user.phone = String(ownerPhone).trim();
      }

      if (garagePhone !== undefined) {
        if (!String(garagePhone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage phone is required",
          });
        }
        garage.phone = String(garagePhone).trim();
      }

      if (garageEmail !== undefined) {
        if (!String(garageEmail).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage email is required",
          });
        }
        garage.email = String(garageEmail)
          .trim()
          .toLowerCase();
      }

      if (address !== undefined) {
        garage.address = String(address).trim();
      }

      if (city !== undefined) {
        garage.city = String(city).trim();
      }

      // Backward compatibility
      if (phone !== undefined) {
        if (!String(phone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Phone is required",
          });
        }
        garage.phone = String(phone).trim();
      }

      if (email !== undefined) {
        if (!String(email).trim()) {
          return res.status(400).json({
            success: false,
            message: "Email is required",
          });
        }
        garage.email = String(email)
          .trim()
          .toLowerCase();
      }

      await garage.save();
      await user.save();

      return res.json({
        success: true,
        message: "Garage profile updated successfully",
        garage,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          garageId: user.garageId,
        },
      });
    } catch (error) {
      console.error(
        "Update garage profile error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to update garage profile",
      });
    }
  }
);

// ==================================================
// GET INVOICE SETTINGS
// GET /api/garage/invoice-settings
// ==================================================

router.get(
  "/invoice-settings",
  protect,
  requireGarage,

  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.garageId
      ).select("name invoiceSettings");

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      return res.json({
        success: true,
        garageName: garage.name,
        settings: garage.invoiceSettings || {},
      });
    } catch (error) {
      console.error(
        "Get invoice settings error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to fetch invoice settings",
      });
    }
  }
);

// ==================================================
// UPDATE INVOICE SETTINGS
// PUT /api/garage/invoice-settings
// ==================================================

router.put(
  "/invoice-settings",
  protect,
  requireGarage,

  async (req, res) => {
    try {
      const {
        primaryColor,
        secondaryColor,
        footerMessage,
        termsAndConditions,
        upiId,
      } = req.body;

      const garage = await Garage.findById(req.garageId);

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      if (!garage.invoiceSettings) {
        garage.invoiceSettings = {};
      }

      // Validate & update colors
      if (primaryColor !== undefined) {
        if (!isValidHexColor(primaryColor)) {
          return res.status(400).json({
            success: false,
            message:
              "Primary color must be a valid hex color (e.g. #4A6CF7)",
          });
        }
        garage.invoiceSettings.primaryColor = primaryColor;
      }

      if (secondaryColor !== undefined) {
        if (!isValidHexColor(secondaryColor)) {
          return res.status(400).json({
            success: false,
            message:
              "Secondary color must be a valid hex color (e.g. #25D366)",
          });
        }
        garage.invoiceSettings.secondaryColor = secondaryColor;
      }

      // Footer
      if (footerMessage !== undefined) {
        if (String(footerMessage).length > 200) {
          return res.status(400).json({
            success: false,
            message:
              "Footer message cannot exceed 200 characters",
          });
        }
        garage.invoiceSettings.footerMessage =
          String(footerMessage).trim();
      }

      // Terms
      if (termsAndConditions !== undefined) {
        if (String(termsAndConditions).length > 500) {
          return res.status(400).json({
            success: false,
            message:
              "Terms cannot exceed 500 characters",
          });
        }
        garage.invoiceSettings.termsAndConditions =
          String(termsAndConditions).trim();
      }

      // UPI ID (basic format check)
      if (upiId !== undefined) {
        const cleaned = String(upiId).trim();

        if (cleaned && !cleaned.includes("@")) {
          return res.status(400).json({
            success: false,
            message: "UPI ID must contain @ (e.g. name@upi)",
          });
        }

        garage.invoiceSettings.upiId = cleaned;
      }

      await garage.save();

      return res.json({
        success: true,
        message: "Invoice settings updated successfully",
        settings: garage.invoiceSettings,
      });
    } catch (error) {
      console.error(
        "Update invoice settings error:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Unable to update invoice settings",
      });
    }
  }
);

module.exports = router;