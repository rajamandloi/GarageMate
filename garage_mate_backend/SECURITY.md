# GarageMate Security Hardening

This backend has been hardened around the current GarageMate architecture.

## Included protections

- JWT algorithm restricted to HS256 with issuer/audience validation.
- Access tokens contain a server-side `sessionVersion` and a random JWT ID.
- Database user role and garage ownership are re-checked on every protected request.
- Password length capped at 128 characters to reduce long-password DoS risk.
- Refresh tokens are 64 random bytes, stored only as SHA-256 hashes, and rotated atomically.
- Logout and password reset increment `sessionVersion` to invalidate existing access tokens.
- MongoDB operator/prototype-pollution input keys are removed from body, params and query objects.
- Vehicle updates use an explicit allow-list instead of mass assignment.
- Global API, login, refresh, password-reset and webhook rate limits are enabled.
- JSON and URL-encoded request body limits are enabled.
- Security response headers are enabled.
- Production error responses do not expose stack traces, database errors or filesystem paths.
- CORS is restricted by `ALLOWED_ORIGINS` in production.
- Garage profile uploads use memory storage, MIME checks, magic-byte checks, random filenames and size/part limits.
- WhatsApp webhook requests require an HMAC SHA-256 signature using `WHATSAPP_APP_SECRET`.
- Sensitive WhatsApp message bodies and sender numbers are no longer logged.
- Secrets are excluded from Git by `.gitignore`.

## Important deployment requirements

1. Use HTTPS in production.
2. Set a strong random `JWT_SECRET` of at least 32 characters; preferably 64+ random bytes.
3. Set `WHATSAPP_APP_SECRET` for Meta webhook verification.
4. Configure `ALLOWED_ORIGINS` with only trusted web origins.
5. Restrict MongoDB Atlas network access to the required server/network.
6. Never place AWS, Firebase, MongoDB, JWT, WhatsApp or email secrets inside the Flutter APK.
7. Keep `firebase-service-account.json` outside the repository.
8. If running multiple backend instances, replace the in-memory rate limiter with a shared Redis-backed limiter.
9. Put the Node server behind a properly configured HTTPS reverse proxy in production.
10. Rotate any secret that has ever been committed to Git or exposed in logs.

## Threats that are architecture-specific

- SSTI: this backend does not use a server-side template engine for user-controlled templates. User data is not evaluated as executable template code.
- ReDoS: the backend does not construct `RegExp` objects from user input. Avoid adding dynamic regular expressions in future features.
- AWS S3 key leakage: the current backend does not contain AWS/S3 access keys. If S3 is added later, credentials must remain server-side and uploads should use controlled server/presigned operations.
- Clipboard hijacking: this is primarily a Flutter/device concern. The backend cannot control the OS clipboard; the Flutter client must avoid copying passwords, access tokens or refresh tokens.

No application can honestly be called permanently "100% security-proof". Security must be maintained through dependency updates, server configuration, monitoring and periodic testing.
