# Authenticator two-factor authentication

## What is enabled
Laravel 12 keeps its existing login, email verification and password broker. The existing pragmarx/google2fa TOTP implementation is reused; Fortify is not added because this application already has its own tested authentication routes and enrollment/challenge logic. Adding another authentication route provider would duplicate that integration. bacon/bacon-qr-code supplies local SVG QR rendering, with dasprid/enum as its dependency. No setup secret is sent to a remote QR service.

- Admin: enrollment is mandatory before administrator/account features; each new login requires a second factor after the password. Admin cannot disable 2FA through Account Settings or the disable endpoint.
- Customer: enrollment is optional in Account Settings > Security > Two-Factor Authentication. Once confirmed, subsequent logins require a second factor.
- Cashier and Staff/Barista: existing email/password login and role-based access remain unchanged; authenticator enrollment is not offered.
- Unverified customers must still verify their email before ordering. Password resets retain 2FA; an old incomplete challenge cannot authenticate after a password reset, secret change or auth-version change.

## Configuration and database
config/security.php enables enforcement by default with ADMIN_TWO_FACTOR_ENABLED=true. No .env credential or existing account is overwritten. Domain tests explicitly disable this flag in phpunit.xml; SecurityTest and TwoFactorFlowTest explicitly enable it to exercise enforcement.

The live MySQL database already contains users.two_factor_secret, two_factor_recovery_codes, two_factor_confirmed_at, two_factor_last_counter and auth_version. These fields were added by 2026_11_14_000005_add_security_fields.php. No additional migration or user-data change is needed.

Run composer install when copying this project to a different machine, then php artisan config:clear. QR rendering needs PHP XMLWriter, provided by the current PHP installation. Keep the existing APP_KEY: secrets and recovery data depend on it. Use HTTPS for deployment; browser clipboard copying normally requires HTTPS or localhost.

## Set up Google Authenticator
1. Sign in normally. An admin without 2FA is directed to setup; a customer opens Account Settings > Security > Two-Factor Authentication. Setup, QR display, code confirmation and recovery controls are available directly in Account Settings. An unenrolled admin may open this read-only account page to enroll; account changes and other administrator functions stay blocked until enrollment.
2. Click Enable Two-Factor Authentication and confirm the current account password.
3. Open Google Authenticator, tap + and choose Scan a QR code. Scan the QR displayed on this account's setup page. A compatible TOTP app can also be used.
4. If scanning is unavailable, expand Cannot scan? Enter a setup key. Enter the account email and key, and choose time-based/TOTP. The app uses SHA-1, six digits and a 30-second interval.
5. Enter the six-digit code and click Verify and enable 2FA. Setup is activated only after a valid code. Pending setup expires after ten minutes and is bound to the current user and password fingerprint.
6. Copy or download the eight recovery codes shown after confirmation. The original codes cannot be revealed again later; use regeneration to get a replacement set.

## Sign in and recover
After entering the password, enter the current authenticator code. An incomplete challenge expires after five minutes. Codes are rate limited and previously accepted TOTP counters cannot be replayed. If you just confirmed setup or used a code, wait for the next code before using another authenticator challenge.

Without your authenticator, click Use Recovery Code Instead and enter one saved code. Each recovery code works once. To replace the set, open Manage recovery codes and confirm the current password plus a valid authenticator or unused recovery code. All previous recovery codes are invalidated immediately. Copy/download is performed locally by the browser and does not call a third-party service.

Customers can disable protection by confirming their password and a valid second factor in the Disable section. This clears the stored secret, recovery codes, confirmation and replay counter, and invalidates older sessions. Admins cannot use this action.

## Security and testing
Secrets use Laravel encryption at rest. Recovery codes are hashed individually and the resulting array is encrypted. Pending setup secrets and the one-time recovery-code flash payload are also encrypted in session storage. Setup/recovery pages use Cache-Control: no-store and all forms require CSRF protection. Every sensitive management action requires the current password (confirmation may follow setup within its ten-minute window). Codes and secrets are excluded from user serialization, request flashing and audit values.

Automated tests cover customer and mandatory admin setup, local QR rendering, secret encryption, invalid codes, login challenge, protected route denial, replay prevention, single-use recovery, regeneration, customer disable, admin disable denial, setup/challenge expiry, account binding, stale/password-reset challenges, email verification integration and cashier/barista redirects. Full regression tests also cover ordering, user management and backup/recovery.

Run:

    php -d extension=fileinfo -d extension=pdo_sqlite -d memory_limit=512M vendor/phpunit/phpunit/phpunit --colors=never

The tests use isolated SQLite and generated secrets. They do not enroll or change live MySQL accounts. Actual Google/Microsoft Authenticator scanning on a physical phone, clipboard behavior and browser downloads require a manual device/browser check; these are not claimed as verified.

## Files changed
Created:
- app/Http/Controllers/TwoFactorController.php
- public/two-factor.js
- tests/Feature/TwoFactorFlowTest.php
- TWO_FACTOR_SETUP.md

Updated:
- app/Http/Controllers/SecurityController.php: existing password login hands off to the second-factor challenge.
- app/Services/TwoFactor.php: TOTP/recovery verification, session/pending bindings and local QR rendering.
- app/Http/Middleware/EnsureAdminTwoFactor.php: mandatory admin and enabled-customer enforcement.
- app/Models/User.php: hidden replay counter; encrypted secret/recovery casts retained.
- routes/web.php: existing 2FA routes point to the dedicated controller; customer disable route added.
- config/security.php: 2FA enabled by default.
- resources/views/shop/account.blade.php: Security status/management entry.
- resources/views/shop/security/two-factor.blade.php: QR setup, recovery copy/download, regeneration and customer disable.
- resources/views/shop/security/challenge.blade.php: authenticator/recovery selection.
- public/coffee-theme.css: responsive 2FA styling matching existing security pages.
- composer.json and composer.lock: QR renderer dependency.
- phpunit.xml and tests/Feature/SecurityTest.php: explicit domain-test configuration and encrypted setup/pending test data.
- .env.example, .env.gmail.example, README.md, SECURITY.md and GMAIL_SETUP.md: current configuration and behavior documentation.

References: https://github.com/Bacon/BaconQrCode and https://github.com/antonioribeiro/google2fa .