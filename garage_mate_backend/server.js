require("dotenv").config();

const express = require("express");
const cors = require("cors");
const path = require("path");

const connectDB = require("./config/db");

const authRoutes = require("./routes/authRoutes");
const adminRoutes = require("./routes/adminRoutes");
const customerRoutes = require("./routes/customerRoutes");
const vehicleRoutes = require("./routes/vehicleRoutes");
const serviceRoutes = require("./routes/serviceRoutes");
const reminderRoutes = require("./routes/reminderRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const garageRoutes = require("./routes/garageRoutes");
const whatsappRoutes = require("./routes/whatsappRoutes");
const invoiceRoutes = require("./routes/invoiceRoutes");

const { startReminderScheduler } = require("./services/reminderScheduler");
const {
  sanitizeMongoInput,
  securityHeaders,
  requestId,
  createRateLimiter,
} = require("./middleware/securityMiddleware");

const app = express();

const isProduction = process.env.NODE_ENV === "production";

// Never trust client-controlled security claims unless explicitly configured.
app.disable("x-powered-by");
app.set("trust proxy", process.env.TRUST_PROXY === "true" ? 1 : false);

// -----------------------------------------------------------------------------
// Startup configuration validation
// -----------------------------------------------------------------------------

const requiredSecrets = ["MONGODB_URI", "JWT_SECRET"];
for (const key of requiredSecrets) {
  if (!process.env[key]) {
    throw new Error(`${key} is required`);
  }
}

if (process.env.JWT_SECRET.length < 32) {
  throw new Error("JWT_SECRET must be at least 32 characters long");
}

// -----------------------------------------------------------------------------
// CORS
// -----------------------------------------------------------------------------

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsOptions = {
  origin(origin, callback) {
    // Native Flutter requests generally have no Origin header.
    if (!origin) return callback(null, true);

    if (!isProduction && allowedOrigins.length === 0) {
      return callback(null, true);
    }

    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error("Origin is not allowed by CORS"));
  },
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: false,
  maxAge: 600,
};

app.use(cors(corsOptions));
app.use(securityHeaders);
app.use(requestId);

app.use((req, res, next) => {
  if (req.originalUrl && req.originalUrl.length > 8192) {
    return res.status(414).json({
      success: false,
      message: "Request URL is too long",
    });
  }
  next();
});

// Reject oversized JSON before it reaches application controllers.
app.use(express.json({
  limit: process.env.JSON_BODY_LIMIT || "256kb",
  strict: true,
  verify: (req, res, buffer) => {
    // Preserve the exact bytes needed to verify Meta webhook signatures.
    if (req.originalUrl === "/api/whatsapp/webhook") {
      req.rawBody = Buffer.from(buffer);
    }
  },
}));
app.use(express.urlencoded({
  extended: false,
  limit: process.env.URLENCODED_BODY_LIMIT || "64kb",
}));

// Protect all application routes from MongoDB operator/prototype injection.
app.use(sanitizeMongoInput);

// General API abuse protection. Login/password-reset have stricter limits below.
app.use(
  "/api",
  createRateLimiter({
    windowMs: 15 * 60 * 1000,
    max: 300,
    message: "Too many API requests. Please try again later.",
  })
);

// Static uploads are read-only and never execute as code.
app.use(
  "/uploads",
  express.static(path.join(process.cwd(), "uploads"), {
    dotfiles: "deny",
    index: false,
    fallthrough: false,
    maxAge: "1d",
  })
);

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/customers", customerRoutes);
app.use("/api/vehicles", vehicleRoutes);
app.use("/api/services", serviceRoutes);
app.use("/api/reminders", reminderRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/garage", garageRoutes);
app.use("/api/whatsapp", whatsappRoutes);
app.use("/api/invoices", invoiceRoutes);

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "GarageMate API is running",
  });
});

// Unknown API routes should not reveal framework details.
app.use("/api", (req, res) => {
  res.status(404).json({
    success: false,
    message: "API endpoint not found",
  });
});

// Central error handler. Do not expose stack traces, DB errors or filesystem
// paths to clients in production.
app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);

  if (error?.message === "Origin is not allowed by CORS") {
    return res.status(403).json({
      success: false,
      message: "Origin is not allowed",
    });
  }

  if (error?.type === "entity.too.large" || error?.status === 413) {
    return res.status(413).json({
      success: false,
      message: "Request payload is too large",
    });
  }

  if (error?.name === "MulterError" || /Only JPG, PNG and WEBP images are allowed|Invalid or unsupported image file/i.test(error?.message || "")) {
    return res.status(400).json({
      success: false,
      message: error?.message || "Invalid uploaded file",
    });
  }

  if (error?.name === "CastError") {
    return res.status(400).json({
      success: false,
      message: "Invalid request identifier",
    });
  }

  if (error?.name === "ValidationError") {
    return res.status(400).json({
      success: false,
      message: "Invalid request data",
    });
  }

  if (error?.code === 11000) {
    return res.status(409).json({
      success: false,
      message: "A record with the same unique value already exists",
    });
  }

  if (!isProduction) {
    console.error("Unhandled API error:", error);
  } else {
    console.error("Unhandled API error:", error?.message || "Unknown error");
  }

  return res.status(error?.status >= 400 && error.status < 500 ? error.status : 500).json({
    success: false,
    message: "An unexpected server error occurred",
    ...(isProduction ? {} : { requestId: req.requestId }),
  });
});

const PORT = Number(process.env.PORT || 5000);

const startServer = async () => {
  await connectDB();

  app.listen(PORT, () => {
    console.log(`GarageMate server running on port ${PORT}`);
    startReminderScheduler();
  });
};

startServer().catch((error) => {
  console.error("GarageMate startup failed:", error?.message || error);
  process.exit(1);
});

module.exports = app;
