const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});



// ============================================================
// REGISTRATION EMAIL OTP
// ============================================================

const sendRegistrationOtpEmail = async ({
  to,
  ownerName,
  otp,
}) => {
  await transporter.sendMail({
    from: `"GarageMate" <${process.env.EMAIL_USER}>`,
    to,
    subject: "Verify your GarageMate email address",
    text: `
Hello ${ownerName},

Your GarageMate email verification code is: ${otp}

This code expires in 10 minutes.

If you did not start a GarageMate registration, you can ignore this email.

GarageMate Team
`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background:#f5f7fa;font-family:Arial,Helvetica,sans-serif;">
  <div style="max-width:600px;margin:40px auto;padding:20px;">
    <div style="background:#ffffff;border-radius:20px;padding:36px 28px;box-shadow:0 4px 20px rgba(0,0,0,0.06);">
      <h1 style="margin:0 0 8px;color:#222222;">GarageMate</h1>
      <p style="margin:0 0 28px;color:#777777;">Garage Management Platform</p>
      <h2 style="color:#222222;">Verify your email</h2>
      <p style="color:#555555;line-height:1.6;">Hello <strong>${ownerName}</strong>,</p>
      <p style="color:#555555;line-height:1.6;">Use the verification code below to confirm your GarageMate email address.</p>
      <div style="margin:30px 0;text-align:center;">
        <span style="display:inline-block;padding:16px 28px;border-radius:12px;background:#eff6ff;color:#1d4ed8;font-size:30px;letter-spacing:8px;font-weight:700;">${otp}</span>
      </div>
      <p style="color:#777777;font-size:14px;line-height:1.6;">This code expires in <strong>10 minutes</strong>.</p>
      <p style="color:#777777;font-size:14px;line-height:1.6;">GarageMate will never ask you to share this code with anyone.</p>
      <hr style="border:0;border-top:1px solid #eeeeee;margin:28px 0;">
      <p style="color:#999999;font-size:13px;margin:0;">GarageMate Team</p>
    </div>
  </div>
</body>
</html>
`,
  });
};

// ============================================================
// PASSWORD RESET EMAIL
// ============================================================

const sendPasswordResetEmail = async ({
  to,
  resetToken,
}) => {
  const resetUrl =
    `garagemate://reset-password?token=${encodeURIComponent(
      resetToken
    )}`;

  await transporter.sendMail({
    from: `"GarageMate" <${process.env.EMAIL_USER}>`,
    to,

    subject: "Reset your GarageMate password",

    text: `
Hello,

We received a request to reset your GarageMate password.

Open this link to create a new password:

${resetUrl}

This password reset link will expire in 15 minutes.

If you did not request this, you can safely ignore this email.

GarageMate Team
`,

    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0">
</head>

<body style="
  margin:0;
  padding:0;
  background:#f5f7fa;
  font-family:Arial,Helvetica,sans-serif;
">

  <div style="
    max-width:600px;
    margin:40px auto;
    padding:20px;
  ">

    <div style="
      background:#ffffff;
      border-radius:20px;
      padding:36px 28px;
      box-shadow:0 4px 20px rgba(0,0,0,0.06);
    ">

      <h1 style="
        margin:0 0 8px;
        font-size:28px;
        color:#222222;
      ">
        GarageMate
      </h1>

      <p style="
        margin:0 0 28px;
        color:#777777;
      ">
        Garage Management Platform
      </p>

      <h2 style="
        color:#222222;
        margin-bottom:12px;
      ">
        Reset Your Password
      </h2>

      <p style="
        color:#555555;
        line-height:1.6;
      ">
        We received a request to reset your GarageMate
        account password.
      </p>

      <p style="
        color:#555555;
        line-height:1.6;
      ">
        Click the button below to create a new password.
      </p>

      <div style="
        text-align:center;
        margin:32px 0;
      ">

        <a
          href="${resetUrl}"
          style="
            display:inline-block;
            padding:15px 28px;
            background:#2563eb;
            color:#ffffff;
            text-decoration:none;
            border-radius:10px;
            font-weight:bold;
          "
        >
          Reset Password
        </a>

      </div>

      <p style="
        color:#777777;
        font-size:14px;
        line-height:1.6;
      ">
        This password reset link will expire in
        <strong>15 minutes</strong>.
      </p>

      <p style="
        color:#777777;
        font-size:14px;
        line-height:1.6;
      ">
        If you did not request a password reset,
        you can safely ignore this email.
      </p>

      <hr style="
        border:0;
        border-top:1px solid #eeeeee;
        margin:28px 0;
      ">

      <p style="
        color:#999999;
        font-size:13px;
        margin:0;
      ">
        GarageMate Team
      </p>

    </div>

  </div>

</body>
</html>
`,
  });
};


// ============================================================
// GARAGE APPROVAL EMAIL
// ============================================================

const sendGarageApprovalEmail = async ({
  to,
  ownerName,
  garageName,
}) => {
  await transporter.sendMail({
    from: `"GarageMate" <${process.env.EMAIL_USER}>`,
    to,

    subject: "Your GarageMate garage has been approved 🎉",

    text: `
Hello ${ownerName},

Great news!

Your GarageMate garage "${garageName}" has been approved successfully by the GarageMate Super Admin.

You can now log in to your GarageMate account and start managing your garage, customers, vehicles, services and reminders.

Your garage is now active.

Welcome to GarageMate!

GarageMate Team
`,

    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0">
</head>

<body style="
  margin:0;
  padding:0;
  background:#f5f7fa;
  font-family:Arial,Helvetica,sans-serif;
">

  <div style="
    max-width:600px;
    margin:40px auto;
    padding:20px;
  ">

    <div style="
      background:#ffffff;
      border-radius:20px;
      padding:36px 28px;
      box-shadow:0 4px 20px rgba(0,0,0,0.06);
    ">

      <h1 style="
        margin:0 0 8px;
        font-size:28px;
        color:#222222;
      ">
        GarageMate
      </h1>

      <p style="
        margin:0 0 28px;
        color:#777777;
      ">
        Garage Management Platform
      </p>

      <div style="
        text-align:center;
        margin-bottom:25px;
      ">

        <div style="
          width:70px;
          height:70px;
          margin:0 auto;
          border-radius:50%;
          background:#ecfdf5;
          display:flex;
          align-items:center;
          justify-content:center;
          font-size:38px;
        ">
          ✓
        </div>

      </div>

      <h2 style="
        color:#222222;
        text-align:center;
        margin-bottom:15px;
      ">
        Garage Approved!
      </h2>

      <p style="
        color:#555555;
        line-height:1.6;
      ">
        Hello <strong>${ownerName}</strong>,
      </p>

      <p style="
        color:#555555;
        line-height:1.6;
      ">
        Great news! Your GarageMate garage has been
        <strong>approved successfully</strong> by the
        GarageMate Super Admin.
      </p>

      <div style="
        background:#f8fafc;
        border-radius:12px;
        padding:18px;
        margin:24px 0;
      ">

        <p style="
          margin:0 0 8px;
          color:#777777;
          font-size:14px;
        ">
          Garage
        </p>

        <p style="
          margin:0;
          color:#222222;
          font-size:18px;
          font-weight:bold;
        ">
          ${garageName}
        </p>

        <p style="
          margin:12px 0 0;
          color:#16a34a;
          font-weight:bold;
        ">
          ● Active
        </p>

      </div>

      <p style="
        color:#555555;
        line-height:1.6;
      ">
        You can now log in to your GarageMate account
        and start managing your garage, customers,
        vehicles, services and reminders.
      </p>

      <div style="
        background:#eff6ff;
        border-radius:12px;
        padding:18px;
        margin:24px 0;
      ">

        <p style="
          margin:0;
          color:#1e40af;
          line-height:1.6;
        ">
          Your garage account is now active.
          Welcome to GarageMate!
        </p>

      </div>

      <hr style="
        border:0;
        border-top:1px solid #eeeeee;
        margin:28px 0;
      ">

      <p style="
        color:#999999;
        font-size:13px;
        margin:0;
      ">
        GarageMate Team
      </p>

    </div>

  </div>

</body>
</html>
`,
  });
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
  sendRegistrationOtpEmail,
  sendPasswordResetEmail,
  sendGarageApprovalEmail,
};