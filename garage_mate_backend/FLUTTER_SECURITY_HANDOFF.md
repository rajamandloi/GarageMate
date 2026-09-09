# GarageMate Flutter Security Handoff

Backend hardening cannot control the Android device itself. Before production, the Flutter app must also enforce these rules:

- Store access/refresh tokens only in Android Keystore-backed secure storage; never SharedPreferences/plaintext files.
- Never copy passwords, access tokens, refresh tokens, OTPs or API secrets to the clipboard.
- Never ship MongoDB URI, JWT secret, SMTP password, AWS/S3 keys, Firebase Admin private key, WhatsApp App Secret or OpenAI server key in the APK.
- Use HTTPS only for production API traffic.
- Do not disable TLS certificate validation or use insecure HTTP clients in release builds.
- Clear sensitive in-memory/session state on logout.
- Treat all API responses as untrusted input.
- Do not expose server stack traces or raw backend errors in UI.
- Do not log Authorization headers, tokens, passwords, customer private data or WhatsApp message contents.
- Use release builds with debugging disabled and avoid verbose production logging.
- Prevent screenshots/screen capture on screens displaying especially sensitive credentials if the product requirements justify it.
- Use Android App Links/deep-link validation carefully for password-reset or authentication links.
- Refresh tokens only through the backend refresh endpoint; never attempt to generate JWTs on-device.
- On `SESSION_REVOKED`, `ACCESS_TOKEN_EXPIRED` or invalid refresh token responses, clear the local session and require authentication again.
