# GarageMate Verified Registration Flow

Registration no longer creates a GarageMate account from an unverified email/mobile number.

## Flow

1. `POST /api/auth/register/start`
   - Validates required fields.
   - Validates email syntax.
   - Performs DNS MX lookup for the email domain.
   - Normalizes Indian mobile numbers to `+91XXXXXXXXXX`.
   - Checks that email/mobile are not already registered.
   - Stores only a temporary registration record with a hashed email OTP.
   - Sends the email OTP.

2. `POST /api/auth/register/verify-email`
   - Accepts `registrationId` + 6-digit OTP.
   - OTP expires after 10 minutes.
   - Maximum 5 incorrect attempts.

3. `POST /api/auth/register/resend-email`
   - Resends a fresh OTP.
   - Enforces a 60-second resend interval.

4. Flutter verifies the mobile number with Firebase Phone Authentication.

5. `POST /api/auth/register/verify-phone`
   - Accepts `registrationId` + Firebase ID token.
   - Backend verifies the token with Firebase Admin.
   - Backend compares the verified Firebase phone number with the registration phone number.

6. `POST /api/auth/register/complete`
   - Creates the Garage and User only after both verifications succeed.
   - Garage remains `pending` until Super Admin approval.
   - Super Admin notification is sent only for a fully verified registration.

## Firebase requirement

Firebase Phone Authentication must be enabled in the Firebase project used by the Flutter application.
The Flutter app must obtain a Firebase ID token after successful phone OTP verification and send that token to `/api/auth/register/verify-phone`.

## Important

Email DNS/MX validation can reject domains that technically exist but are temporarily misconfigured. The actual mailbox is confirmed by the email OTP.

The backend does not attempt to guess whether a phone number is real from its digits alone. The Firebase phone OTP is the proof of control of that number.
