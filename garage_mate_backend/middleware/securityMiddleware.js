const crypto = require("crypto");

// -----------------------------------------------------------------------------
// GarageMate security middleware
// No external dependency required.
// -----------------------------------------------------------------------------

const BLOCKED_KEYS = new Set([
  "__proto__",
  "prototype",
  "constructor",
]);

const isDangerousKey = (key) => {
  return (
    BLOCKED_KEYS.has(key) ||
    key.startsWith("$") ||
    key.includes(".")
  );
};

const sanitizeObjectInPlace = (value, depth = 0) => {
  // Prevent deeply nested JSON from becoming a CPU/memory abuse vector.
  if (depth > 20 || value === null || typeof value !== "object") {
    return;
  }

  if (Array.isArray(value)) {
    for (let index = value.length - 1; index >= 0; index -= 1) {
      const item = value[index];

      if (item && typeof item === "object") {
        sanitizeObjectInPlace(item, depth + 1);
      }
    }
    return;
  }

  for (const key of Object.keys(value)) {
    if (isDangerousKey(key)) {
      delete value[key];
      continue;
    }

    const child = value[key];
    if (child && typeof child === "object") {
      sanitizeObjectInPlace(child, depth + 1);
    }
  }
};

const sanitizeMongoInput = (req, res, next) => {
  try {
    if (req.body && typeof req.body === "object") {
      sanitizeObjectInPlace(req.body);
    }

    if (req.params && typeof req.params === "object") {
      sanitizeObjectInPlace(req.params);
    }

    if (req.query && typeof req.query === "object") {
      sanitizeObjectInPlace(req.query);
    }

    next();
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: "Invalid request data",
    });
  }
};

// -----------------------------------------------------------------------------
// Simple in-memory rate limiter.
// This is intentionally dependency-free. For a horizontally scaled production
// deployment, replace the store with Redis so all instances share counters.
// -----------------------------------------------------------------------------

const createRateLimiter = ({
  windowMs,
  max,
  message = "Too many requests. Please try again later.",
  keyGenerator = (req) => req.ip || "unknown",
}) => {
  const buckets = new Map();

  const cleanup = () => {
    const now = Date.now();
    for (const [key, entry] of buckets) {
      if (entry.resetAt <= now) {
        buckets.delete(key);
      }
    }
  };

  const interval = setInterval(cleanup, Math.min(windowMs, 60_000));
  interval.unref?.();

  return (req, res, next) => {
    const key = String(keyGenerator(req)).slice(0, 512);
    const now = Date.now();
    let entry = buckets.get(key);

    if (!entry || entry.resetAt <= now) {
      entry = {
        count: 0,
        resetAt: now + windowMs,
      };
      buckets.set(key, entry);
    }

    entry.count += 1;

    res.setHeader("RateLimit-Limit", String(max));
    res.setHeader(
      "RateLimit-Remaining",
      String(Math.max(0, max - entry.count))
    );
    res.setHeader(
      "RateLimit-Reset",
      String(Math.ceil(entry.resetAt / 1000))
    );

    if (entry.count > max) {
      const retryAfter = Math.max(
        1,
        Math.ceil((entry.resetAt - now) / 1000)
      );
      res.setHeader("Retry-After", String(retryAfter));

      return res.status(429).json({
        success: false,
        message,
      });
    }

    next();
  };
};

const normalizeEmailForRateLimit = (value) => {
  if (typeof value !== "string") return "";
  return value.trim().toLowerCase().slice(0, 320);
};

const loginRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: "Too many login attempts. Please try again later.",
  keyGenerator: (req) => {
    const email = normalizeEmailForRateLimit(req.body?.email);
    return `${req.ip || "unknown"}:${email}`;
  },
});

const authRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 60,
  message: "Too many authentication requests. Please try again later.",
});

const forgotPasswordRateLimiter = createRateLimiter({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: "Too many password reset requests. Please try again later.",
  keyGenerator: (req) => {
    const email = normalizeEmailForRateLimit(req.body?.email);
    return `${req.ip || "unknown"}:${email}`;
  },
});

const refreshRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: "Too many token refresh requests. Please try again later.",
});

// -----------------------------------------------------------------------------
// Security headers without relying on an additional package.
// -----------------------------------------------------------------------------

const securityHeaders = (req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Resource-Policy", "same-site");
  res.setHeader(
    "Content-Security-Policy",
    "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"
  );

  if (req.secure) {
    res.setHeader(
      "Strict-Transport-Security",
      "max-age=31536000; includeSubDomains"
    );
  }

  next();
};

const requestId = (req, res, next) => {
  const id = crypto.randomUUID();
  req.requestId = id;
  res.setHeader("X-Request-ID", id);
  next();
};

const limitPasswordLength = (req, res, next) => {
  const password = req.body?.password;

  if (password !== undefined && typeof password === "string" && password.length > 128) {
    return res.status(400).json({
      success: false,
      message: "Password must not exceed 128 characters",
    });
  }

  next();
};

module.exports = {
  sanitizeMongoInput,
  createRateLimiter,
  loginRateLimiter,
  authRateLimiter,
  forgotPasswordRateLimiter,
  refreshRateLimiter,
  securityHeaders,
  requestId,
  limitPasswordLength,
};
