# GarageMate Frontend Security + Verified Registration

This package contains the hardened `lib/` source for GarageMate.

## Required dependency

The verified mobile-registration flow uses Firebase Phone Authentication. Make sure the app's existing `pubspec.yaml` contains:

```yaml
dependencies:
  firebase_auth: ^6.1.0
```

Use the Firebase Auth version compatible with the project's current Flutter/Dart SDK rather than blindly replacing an existing version.

The app must already have Firebase configured for Android (`google-services.json`) and Phone sign-in enabled in Firebase Authentication.

## Registration API flow

1. `POST /api/auth/register/start`
2. `POST /api/auth/register/verify-email`
3. Firebase Phone Authentication OTP
4. `POST /api/auth/register/verify-phone` with the Firebase ID token
5. `POST /api/auth/register/complete`
6. Garage remains `pending` until Super Admin approval.

The backend is the final authority. Client-side validation can be bypassed and therefore never replaces backend validation.

## Production transport

`ApiService` permits the current local HTTP address only during development. A release build throws if `baseUrl` is not HTTPS. Before production, change `baseUrl` to the HTTPS API domain.

## Logging

Access tokens, refresh tokens, passwords, OTPs, FCM tokens, notification bodies, and customer data are not printed by the hardened auth/notification services.
