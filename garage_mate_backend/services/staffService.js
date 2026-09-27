// ============================================================
// STAFF SERVICE — Garage Mate Backend
// ============================================================
// Staff ko User collection mein hi rakhte hain (role: "staff")
// Alag Staff model nahi chahiye.
// ============================================================

const bcrypt = require("bcryptjs");
const crypto = require("crypto");

const User = require("../models/User");
const Garage = require("../models/Garage");
const Subscription = require("../models/Subscription");

const {
  sendWhatsAppMessage,
  sendWhatsAppTemplate,
} = require("./whatsappService");

// ============================================================
// CONSTANTS
// ============================================================

const VALID_STAFF_ROLES = ["manager", "mechanic", "accountant"];

const ROLE_LABELS = {
  manager: "Manager",
  mechanic: "Mechanic",
  accountant: "Accountant",
};

// Plan limits
const PLAN_LIMITS = {
  free: 1,
  trial: 3,
  basic: 5,
  pro: 15,
  premium: 50,
  enterprise: 999,
};

// ============================================================
// HELPERS
// ============================================================

const generatePassword = (length = 10) => {
  const chars =
    "ABCDEFGHJKMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
  let password = "";
  for (let i = 0; i < length; i++) {
    password += chars.charAt(crypto.randomInt(0, chars.length));
  }
  return password;
};

const normalizePhone = (phone) => {
  if (!phone) return "";
  return String(phone).replace(/[\s\-\(\)]/g, "").trim();
};

const isValidRole = (role) => VALID_STAFF_ROLES.includes(role);

// ============================================================
// GET STAFF LIMITS
// ============================================================

const getStaffLimits = async (garageId) => {
  try {
    const garage = await Garage.findById(garageId);
    if (!garage) throw new Error("Garage not found");

    const subscription = await Subscription.findOne({
      garageId,
      status: { $in: ["active", "trial"] },
    }).sort({ createdAt: -1 });

    const plan = subscription?.plan || "free";
    const limit = PLAN_LIMITS[plan] || 1;

    // Count staff users for this garage
    const used = await User.countDocuments({
      garageId,
      role: "staff",
      isActive: true,
    });

    return {
      plan,
      limit,
      used,
      remaining: Math.max(0, limit - used),
    };
  } catch (error) {
    console.error("getStaffLimits error:", error.message);
    throw error;
  }
};

// ============================================================
// CAN ADD STAFF
// ============================================================

const canAddStaff = async (garageId) => {
  const limits = await getStaffLimits(garageId);
  return limits.remaining > 0;
};

// ============================================================
// CREATE STAFF (as User)
// ============================================================

const createStaff = async ({
  garageId,
  ownerId,
  name,
  phone,
  email,
  staffRole,
  password,
  sendWhatsApp = true,
}) => {
  console.log("=================================================");
  console.log("👤 CREATE STAFF");
  console.log("Garage:", garageId);
  console.log("Name:", name);
  console.log("Phone:", phone);
  console.log("Role:", staffRole);
  console.log("=================================================");

  try {
    // ---------- VALIDATE ----------
    if (!name || !name.trim()) {
      throw new Error("Name is required");
    }

    if (!phone || !phone.trim()) {
      throw new Error("Phone is required");
    }

    if (!isValidRole(staffRole)) {
      throw new Error(
        `Invalid role. Allowed: ${VALID_STAFF_ROLES.join(", ")}`
      );
    }

    const cleanPhone = normalizePhone(phone);

    // ---------- CHECK LIMITS ----------
    const limits = await getStaffLimits(garageId);

    if (limits.remaining <= 0) {
      const err = new Error(
        `Staff limit reached for ${limits.plan} plan (${limits.limit})`
      );
      err.code = "LIMIT_REACHED";
      err.limits = limits;
      throw err;
    }

    // ---------- CHECK DUPLICATE PHONE ----------
    const existing = await User.findOne({ phone: cleanPhone });
    if (existing) {
      throw new Error(
        "This phone number is already registered. Please use a different number."
      );
    }

    // ---------- GET GARAGE + OWNER ----------
    const garage = await Garage.findById(garageId);
    if (!garage) throw new Error("Garage not found");

    const owner = await User.findById(ownerId);

    // ---------- GENERATE PASSWORD ----------
    const plainPassword = password || generatePassword(10);
    const passwordHash = await bcrypt.hash(plainPassword, 10);

    // ---------- CREATE USER (as staff) ----------
    const user = await User.create({
      name: name.trim(),
      phone: cleanPhone,
      email:
        email && email.trim()
          ? email.trim().toLowerCase()
          : `${cleanPhone}@staff.garagemate.app`, // fallback unique email
      password: passwordHash,
      role: "staff",
      staffRole,
      garageId,
      invitedBy: ownerId,
      isActive: true,
    });

    console.log("✅ Staff created:", user._id);

    // ---------- SEND WHATSAPP INVITE ----------
    let whatsappResult = null;
    let whatsappError = null;

    if (sendWhatsApp) {
      try {
        whatsappResult = await sendStaffInviteWhatsApp({
          garageId,
          to: cleanPhone,
          staffName: name.trim(),
          staffRole,
          phone: cleanPhone,
          password: plainPassword,
          garageName: garage.name || "Garage",
          ownerName: owner?.name || "Garage Owner",
        });

        console.log(
          "✅ WhatsApp invite sent:",
          whatsappResult?.messageId
        );
      } catch (err) {
        whatsappError = err.message;
        console.error("❌ WhatsApp invite failed:", err.message);
      }
    }

    // ---------- RESPONSE ----------
    return {
      success: true,
      staff: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        staffRole: user.staffRole,
        isActive: user.isActive,
        createdAt: user.createdAt,
      },
      credentials: {
        phone: cleanPhone,
        password: plainPassword,
      },
      whatsapp: {
        sent: !!whatsappResult,
        messageId: whatsappResult?.messageId || null,
        error: whatsappError,
      },
      limits: {
        ...limits,
        used: limits.used + 1,
        remaining: Math.max(0, limits.remaining - 1),
      },
    };
  } catch (error) {
    console.error("createStaff error:", error.message);
    throw error;
  }
};

// ============================================================
// SEND WHATSAPP INVITE
// ============================================================

const sendStaffInviteWhatsApp = async ({
  garageId,
  to,
  staffName,
  staffRole,
  phone,
  password,
  garageName,
  ownerName,
}) => {
  const roleLabel = ROLE_LABELS[staffRole] || "Staff";

  console.log("=================================================");
  console.log("📤 SENDING STAFF INVITE");
  console.log("Garage ID:", garageId);
  console.log("To:", to);
  console.log("Staff:", staffName);
  console.log("Role:", roleLabel);
  console.log("=================================================");

  // ---------- TRY TEMPLATE FIRST ----------
  try {
    const result = await sendWhatsAppTemplate({
      garageId,
      to,
      templateName: "staff_onboarding_v2", // ← Naya utility template
      languageCode: "en",
      type: "general",
      bodyParameters: [
        staffName,   // {{1}}
        roleLabel,   // {{2}}
        garageName,  // {{3}}
        phone,       // {{4}}
        password,    // {{5}}
      ],
    });

    console.log("✅ Template invite sent:", result.messageId);
    return result;
  } catch (templateError) {
    console.warn(
      "⚠️ Template failed, trying text message:",
      templateError.message
    );
  }

  // ---------- FALLBACK: FREE-FORM TEXT ----------
  const message =
    `Hi ${staffName}, you have been added as a ${roleLabel} at ${garageName}.\n\n` +
    `Login details:\n` +
    `Phone: ${phone}\n` +
    `Password: ${password}`;

  const result = await sendWhatsAppMessage({
    garageId,
    to,
    message,
    type: "general",
  });

  console.log("✅ Text invite sent:", result.messageId);
  return result;
};

// ============================================================
// GET ALL STAFF
// ============================================================

const getAllStaff = async (garageId, { includeInactive = false } = {}) => {
  try {
    const query = {
      garageId,
      role: "staff",
    };
    if (!includeInactive) query.isActive = true;

    const staffList = await User.find(query)
      .select("-password -refreshTokenHash -passwordResetToken")
      .sort({ createdAt: -1 })
      .lean();

    // Map to expected shape
    return staffList.map((u) => ({
      _id: u._id,
      id: u._id,
      name: u.name,
      phone: u.phone,
      email: u.email,
      staffRole: u.staffRole,
      isActive: u.isActive,
      createdAt: u.createdAt,
      lastActiveAt: u.lastActiveAt,
    }));
  } catch (error) {
    console.error("getAllStaff error:", error.message);
    throw error;
  }
};

// ============================================================
// GET STAFF BY ID
// ============================================================

const getStaffById = async (garageId, staffId) => {
  try {
    const user = await User.findOne({
      _id: staffId,
      garageId,
      role: "staff",
    })
      .select("-password -refreshTokenHash -passwordResetToken")
      .lean();

    if (!user) throw new Error("Staff not found");

    return {
      _id: user._id,
      id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      staffRole: user.staffRole,
      isActive: user.isActive,
      createdAt: user.createdAt,
      lastActiveAt: user.lastActiveAt,
    };
  } catch (error) {
    console.error("getStaffById error:", error.message);
    throw error;
  }
};

// ============================================================
// UPDATE STAFF
// ============================================================

const updateStaff = async (
  garageId,
  staffId,
  { name, phone, email, staffRole, isActive }
) => {
  console.log("=================================================");
  console.log("✏️ UPDATE STAFF");
  console.log("Garage:", garageId);
  console.log("Staff:", staffId);
  console.log("=================================================");

  try {
    const user = await User.findOne({
      _id: staffId,
      garageId,
      role: "staff",
    });

    if (!user) throw new Error("Staff not found");

    if (name !== undefined) {
      if (!name.trim()) throw new Error("Name cannot be empty");
      user.name = name.trim();
    }

    if (phone !== undefined) {
      const cleanPhone = normalizePhone(phone);

      const duplicate = await User.findOne({
        phone: cleanPhone,
        _id: { $ne: staffId },
      });

      if (duplicate) {
        throw new Error(
          "This phone number is already used by another user"
        );
      }

      user.phone = cleanPhone;
    }

    if (email !== undefined) {
      user.email = email ? email.trim().toLowerCase() : user.email;
    }

    if (staffRole !== undefined) {
      if (!isValidRole(staffRole)) {
        throw new Error(
          `Invalid role. Allowed: ${VALID_STAFF_ROLES.join(", ")}`
        );
      }
      user.staffRole = staffRole;
    }

    if (isActive !== undefined) {
      user.isActive = isActive;
    }

    await user.save();

    console.log("✅ Staff updated");

    return {
      _id: user._id,
      id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      staffRole: user.staffRole,
      isActive: user.isActive,
      createdAt: user.createdAt,
    };
  } catch (error) {
    console.error("updateStaff error:", error.message);
    throw error;
  }
};

// ============================================================
// DELETE STAFF (Soft delete)
// ============================================================

const deleteStaff = async (garageId, staffId) => {
  console.log("=================================================");
  console.log("🗑️ DELETE STAFF");
  console.log("Garage:", garageId);
  console.log("Staff:", staffId);
  console.log("=================================================");

  try {
    const user = await User.findOne({
      _id: staffId,
      garageId,
      role: "staff",
    });

    if (!user) throw new Error("Staff not found");

    user.isActive = false;
    user.sessionVersion = (user.sessionVersion || 0) + 1; // force logout
    await user.save();

    console.log("✅ Staff deleted (soft)");

    return { success: true, id: staffId };
  } catch (error) {
    console.error("deleteStaff error:", error.message);
    throw error;
  }
};

// ============================================================
// RESET STAFF PASSWORD
// ============================================================

const resetStaffPassword = async (garageId, staffId) => {
  try {
    const user = await User.findOne({
      _id: staffId,
      garageId,
      role: "staff",
    });

    if (!user) throw new Error("Staff not found");

    const newPassword = generatePassword(10);
    user.password = await bcrypt.hash(newPassword, 10);
    user.sessionVersion = (user.sessionVersion || 0) + 1; // force re-login
    await user.save();

    console.log("✅ Password reset for staff:", staffId);

    return {
      success: true,
      credentials: {
        phone: user.phone,
        password: newPassword,
      },
    };
  } catch (error) {
    console.error("resetStaffPassword error:", error.message);
    throw error;
  }
};

// ============================================================
// RESEND WHATSAPP INVITE
// ============================================================

const resendWhatsAppInvite = async (garageId, staffId) => {
  try {
    const user = await User.findOne({
      _id: staffId,
      garageId,
      role: "staff",
    });

    if (!user) throw new Error("Staff not found");

    const garage = await Garage.findById(garageId);
    const owner = user.invitedBy
      ? await User.findById(user.invitedBy)
      : null;

    // Generate new password
    const newPassword = generatePassword(10);
    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    const result = await sendStaffInviteWhatsApp({
      garageId,
      to: user.phone,
      staffName: user.name,
      staffRole: user.staffRole,
      phone: user.phone,
      password: newPassword,
      garageName: garage?.name || "Garage",
      ownerName: owner?.name || "Garage Owner",
    });

    return {
      success: true,
      whatsapp: {
        sent: true,
        messageId: result.messageId,
      },
      credentials: {
        phone: user.phone,
        password: newPassword,
      },
    };
  } catch (error) {
    console.error("resendWhatsAppInvite error:", error.message);
    throw error;
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // Limits
  getStaffLimits,
  canAddStaff,

  // CRUD
  createStaff,
  getAllStaff,
  getStaffById,
  updateStaff,
  deleteStaff,

  // Actions
  resetStaffPassword,
  resendWhatsAppInvite,

  // Internal (testing)
  sendStaffInviteWhatsApp,
  generatePassword,
  normalizePhone,
  isValidRole,

  // Constants
  VALID_STAFF_ROLES,
  ROLE_LABELS,
};