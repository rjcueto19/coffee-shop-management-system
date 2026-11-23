# Security controls
Authenticator 2FA is mandatory for administrators and optional for customers.
Cashier and staff login behavior is preserved. See TWO_FACTOR_SETUP.md for enrollment, recovery, security details and test instructions.

Enabled security features:
- Server-side role restrictions: Admin, Cashier, Staff/Barista, Customer.
- Verified email required for operational pages. Unverified users can access
  Account Settings to change an incorrect email and request a verification link.
- Hashed passwords, current-password confirmation for email/password changes,
  session regeneration and invalidation of tracked sessions after credential changes.
- Login, verification and reset rate limiting.
- Expiring single-use password reset tokens with generic reset-request responses.
- Actor/time/IP audit logs; product and role edits log before/after values in
  the same transaction as the change. Passwords, tokens and secrets are excluded.
- Encrypted private backups, admin-only downloads and password-confirmed restores.

## Email setup required for real delivery
Set MAIL_MAILER=smtp plus your provider's MAIL_HOST, MAIL_PORT, MAIL_USERNAME,
MAIL_PASSWORD and authorized MAIL_FROM_ADDRESS in .env. Use the transport scheme
specified by the provider in config/mail.php. Do not share credentials in chat.
Set APP_URL to your actual application origin, e.g. http://127.0.0.1:8000 locally.
Run php artisan config:clear after changing .env.
The log mailer is for development only and does not deliver to inboxes.
Use a real email address in Account Settings; .test addresses cannot receive mail.
AdminSeeder provisions a trusted verified admin; rerunning it preserves the existing password. Accounts created by an authenticated admin or shop:admin are trusted and verified. Public registrations remain unverified until they open their email link.

## Production
Use HTTPS, APP_ENV=production, APP_DEBUG=false and SESSION_SECURE_COOKIE=true.
Expose only public/, keep .env/storage private, restrict database access, and
keep APP_KEY with your encrypted off-device backups.
No live restore is run during installation. Audit history is read-only in the
app, but a database administrator or privileged restore can change historical
records; this is not a cryptographically immutable audit log.

## Verification
SecurityTest and TwoFactorFlowTest explicitly enable 2FA enforcement. Domain suites isolate business rules by disabling enforcement in phpunit.xml. Integration tests cover mandatory admin setup, customer enrollment, QR rendering, recovery, disable, email verification, password reset and role restrictions.
