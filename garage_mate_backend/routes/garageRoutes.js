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
// GARAGE PROFILE IMAGE UPLOAD SECURITY
// ==================================================

const uploadDir = path.join(
  __dirname,
  "../uploads/garage"
);

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, {
    recursive: true,
  });
}

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
      return cb(new Error("Only JPG, PNG and WEBP images are allowed"));
    }

    cb(null, true);
  },
});

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
    buffer.subarray(0, 8).equals(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    )
  ) {
    return { extension: ".png", mime: "image/png" };
  }

  // WEBP (RIFF....WEBP)
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

      // Do not trust the multipart MIME type or original filename alone.
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
      const targetPath = path.join(uploadDir, filename);

      await fs.promises.writeFile(targetPath, req.file.buffer, {
        flag: "wx",
        mode: 0o600,
      });

      const imageUrl = `/uploads/garage/${filename}`;
      const previousImage = garage.profileImage;

      garage.profileImage = imageUrl;
      await garage.save();

      // Remove the previous image only when it is one of GarageMate's own
      // generated profile paths. Never delete arbitrary user-controlled paths.
      if (
        typeof previousImage === "string" &&
        previousImage.startsWith("/uploads/garage/")
      ) {
        const previousFilename = path.basename(previousImage);
        const previousPath = path.join(uploadDir, previousFilename);

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
// GET GARAGE PROFILE
// GET /api/garage/profile
// ==================================================

router.get(
  "/profile",
  protect,
  requireGarage,

  async (req, res) => {
    try {
      const garage = await Garage.findById(
        req.garageId
      );

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
        message:
          "Unable to fetch garage profile",
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

      const garage = await Garage.findById(
        req.garageId
      );

      if (!garage) {
        return res.status(404).json({
          success: false,
          message: "Garage not found",
        });
      }

      const user = await User.findById(
        req.user._id
      );

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }


      // ==================================================
      // GARAGE NAME
      // ==================================================

      if (name !== undefined) {
        if (!String(name).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage name is required",
          });
        }

        garage.name = String(name).trim();
      }


      // ==================================================
      // OWNER NAME
      // ==================================================

      if (ownerName !== undefined) {
        if (!String(ownerName).trim()) {
          return res.status(400).json({
            success: false,
            message: "Owner name is required",
          });
        }

        garage.ownerName =
          String(ownerName).trim();

        user.name =
          String(ownerName).trim();
      }


      // ==================================================
      // OWNER PHONE
      // ==================================================

      if (ownerPhone !== undefined) {
        if (!String(ownerPhone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Owner phone is required",
          });
        }

        user.phone =
          String(ownerPhone).trim();
      }


      // ==================================================
      // GARAGE PHONE
      // ==================================================

      if (garagePhone !== undefined) {
        if (!String(garagePhone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage phone is required",
          });
        }

        garage.phone =
          String(garagePhone).trim();
      }


      // ==================================================
      // GARAGE EMAIL
      // ==================================================

      if (garageEmail !== undefined) {
        if (!String(garageEmail).trim()) {
          return res.status(400).json({
            success: false,
            message: "Garage email is required",
          });
        }

        garage.email =
          String(garageEmail)
            .trim()
            .toLowerCase();
      }


      // ==================================================
      // ADDRESS
      // ==================================================

      if (address !== undefined) {
        garage.address =
          String(address).trim();
      }


      // ==================================================
      // CITY
      // ==================================================

      if (city !== undefined) {
        garage.city =
          String(city).trim();
      }


      // ==================================================
      // BACKWARD COMPATIBILITY
      // ==================================================

      if (phone !== undefined) {
        if (!String(phone).trim()) {
          return res.status(400).json({
            success: false,
            message: "Phone is required",
          });
        }

        garage.phone =
          String(phone).trim();
      }

      if (email !== undefined) {
        if (!String(email).trim()) {
          return res.status(400).json({
            success: false,
            message: "Email is required",
          });
        }

        garage.email =
          String(email)
            .trim()
            .toLowerCase();
      }


      // ==================================================
      // SAVE
      // ==================================================

      await garage.save();
      await user.save();


      // ==================================================
      // RESPONSE
      // ==================================================

      return res.json({
        success: true,
        message:
          "Garage profile updated successfully",

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
        message:
          "Unable to update garage profile",
      });
    }
  }
);


module.exports = router;