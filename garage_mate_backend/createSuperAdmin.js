require("dotenv").config();

const bcrypt = require("bcryptjs");
const mongoose = require("mongoose");
const readline = require("readline");

const User = require("./models/User");

const MONGODB_URI = process.env.MONGODB_URI;

// ============================================================
// READLINE
// ============================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// ============================================================
// ASK QUESTION
// ============================================================

const ask = (question) => {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.trim());
    });
  });
};

// ============================================================
// ASK PASSWORD
// ============================================================

const askPassword = (question) => {
  return new Promise((resolve) => {
    process.stdout.write(question);

    const stdin = process.stdin;

    stdin.resume();
    stdin.setRawMode(true);
    stdin.setEncoding("utf8");

    let password = "";

    const onData = (key) => {
      // Ctrl + C
      if (key === "\u0003") {
        stdin.setRawMode(false);
        stdin.pause();
        console.log("\n");
        process.exit(1);
      }

      // Enter
      if (key === "\r" || key === "\n") {
        stdin.setRawMode(false);
        stdin.pause();
        stdin.removeListener("data", onData);

        console.log("");
        resolve(password.trim());

        return;
      }

      // Backspace
      if (
        key === "\u0008" ||
        key === "\u007f"
      ) {
        if (password.length > 0) {
          password =
            password.slice(0, -1);

          process.stdout.write(
            "\b \b"
          );
        }

        return;
      }

      // Normal character
      if (key >= " " && key <= "~") {
        password += key;
        process.stdout.write("*");
      }
    };

    stdin.on("data", onData);
  });
};

// ============================================================
// CREATE SUPER ADMIN
// ============================================================

async function createSuperAdmin() {
  try {
    // ========================================================
    // CHECK DATABASE URL
    // ========================================================

    if (!MONGODB_URI) {
      throw new Error(
        "MONGODB_URI is missing from .env"
      );
    }

    console.log("");
    console.log(
      "========================================"
    );
    console.log(
      "     GARAGEMATE SUPER ADMIN SETUP"
    );
    console.log(
      "========================================"
    );
    console.log("");

    // ========================================================
    // CONNECT DATABASE
    // ========================================================

    await mongoose.connect(MONGODB_URI);

    console.log(
      "MongoDB connected successfully."
    );
    console.log("");

    // ========================================================
    // GET ADMIN DETAILS
    // ========================================================

    const name = await ask(
      "Super Admin Name: "
    );

    const emailInput = await ask(
      "Super Admin Email: "
    );

    const phone = await ask(
      "Super Admin Phone (optional): "
    );

    const password =
      await askPassword(
        "Super Admin Password: "
      );

    const confirmPassword =
      await askPassword(
        "Confirm Password: "
      );

    // ========================================================
    // VALIDATION
    // ========================================================

    if (!name) {
      throw new Error(
        "Super Admin name is required."
      );
    }

    if (!emailInput) {
      throw new Error(
        "Super Admin email is required."
      );
    }

    const email =
      emailInput.toLowerCase().trim();

    // Basic email validation
    const emailRegex =
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      throw new Error(
        "Please enter a valid email address."
      );
    }

    if (!password) {
      throw new Error(
        "Password is required."
      );
    }

    if (password.length < 8) {
      throw new Error(
        "Password must be at least 8 characters."
      );
    }

    if (password !== confirmPassword) {
      throw new Error(
        "Passwords do not match."
      );
    }

    // ========================================================
    // CHECK EXISTING EMAIL
    // ========================================================

    const existingUser =
      await User.findOne({
        email,
      });

    if (existingUser) {
      if (
        existingUser.role ===
        "super_admin"
      ) {
        console.log("");
        console.log(
          "A Super Admin with this email already exists."
        );
      } else {
        console.log("");
        console.log(
          "This email is already registered to another account."
        );
      }

      return;
    }

    // ========================================================
    // HASH PASSWORD
    // ========================================================

    const hashedPassword =
      await bcrypt.hash(
        password,
        12
      );

    // ========================================================
    // CREATE SUPER ADMIN
    // ========================================================

    const admin =
      await User.create({
        name,
        email,
        phone,
        password: hashedPassword,
        role: "super_admin",
        garageId: null,
        isActive: true,
      });

    // ========================================================
    // SUCCESS
    // ========================================================

    console.log("");
    console.log(
      "========================================"
    );
    console.log(
      "       SUPER ADMIN CREATED"
    );
    console.log(
      "========================================"
    );
    console.log(
      `Name:  ${admin.name}`
    );
    console.log(
      `Email: ${admin.email}`
    );
    console.log(
      "Role:  super_admin"
    );
    console.log(
      "Status: Active"
    );
    console.log(
      "========================================"
    );
    console.log(
      "Password is stored securely as a hash."
    );
    console.log(
      "========================================"
    );
    console.log("");

  } catch (error) {
    console.error("");
    console.error(
      "Create Super Admin Error:",
      error.message || error
    );
  } finally {
    rl.close();

    if (
      mongoose.connection.readyState === 1
    ) {
      await mongoose.connection.close();
    }
  }
}

// ============================================================
// START
// ============================================================

createSuperAdmin();