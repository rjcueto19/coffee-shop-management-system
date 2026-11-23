# Email verification and password reset

Laravel 12 built-in signed verification notifications and Password broker are enabled. Admin two-factor authentication is mandatory; customer enrollment is optional. See TWO_FACTOR_SETUP.md. No database migration is necessary: users.email_verified_at and password_reset_tokens already exist. Existing accounts, passwords and roles are preserved. New public registrations are unverified customers; admin-provisioned accounts retain their trusted provisioning flow.

## Configure real Gmail delivery
The current .env is intentionally left unchanged. MAIL_MAILER=log writes email locally and DOES NOT send to an inbox. Set the following in .env locally using your own credentials; .env.gmail.example contains placeholders only:

```dotenv
APP_URL=http://127.0.0.1:8000
EMAIL_FEATURES_ENABLED=true
MAIL_MAILER=smtp
MAIL_SCHEME=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-address@gmail.com
MAIL_PASSWORD="your-16-character-app-password"
MAIL_FROM_ADDRESS=your-address@gmail.com
MAIL_FROM_NAME="Your Coffee Shop Name"
```

Use your actual HTTPS origin for APP_URL when deployed. Do not leave an old MAIL_URL overriding these settings. Port 587 uses STARTTLS with scheme smtp; port 465 uses smtps. Security messages use the coffee shop name from shop_settings for the sender display name and email body; the sender address always comes from mail configuration.

1. Enable 2-Step Verification on the sending Google Account. This Google Account setting is independent of the app's authenticator 2FA.
2. Open https://myaccount.google.com/apppasswords and create an App Password for this application. Use the generated 16-character password, without spaces, as MAIL_PASSWORD. Use a new App Password if one has been shared or revoked.
3. Use the same Gmail address for MAIL_USERNAME and MAIL_FROM_ADDRESS. Never put the App Password in an email address field.
4. Run php artisan config:clear. Restart any long-running application/queue processes after configuration changes.
5. Test with a real address you control. Never share or commit .env credentials.

Google documentation: https://support.google.com/accounts/answer/185833 . Organization policy or Advanced Protection may restrict App Password availability.

## Test verification
1. Register a new customer using a real inbox; registration sends a verification notification and opens /verify-email.
2. Check the inbox and spam folder. The email includes your shop name, greeting and Verify Email Address button.
3. Before verifying, /menu and POST /orders redirect to the notice page. Account Settings and logout remain accessible.
4. Open the link while signed in as that customer. A valid signed link verifies the email and redirects to /dashboard (customers then go to /menu).
5. A repeated valid link reports already verified. Invalid, expired, altered, or other-account links are rejected. Links expire in 60 minutes. After an email change, old verification links do not match the new email.
6. Resend Verification Email is limited to 3 requests per minute per signed-in account. Account creation is limited to 5 requests per minute per IP.

## Test password reset
1. Sign out, open Forgot password? and submit the registered real email.
2. The same generic response is shown for known and unknown addresses, including SMTP transport failures, to avoid revealing account existence. Administrator logs contain a credential-free warning if sending fails.
3. Open the Reset Password email link; enter email, a new password of at least 12 characters, and matching confirmation.
4. A successful reset redirects to login. Sign in with the new password; old sessions and remember-me credentials are revoked.
5. Reuse the token or use it after 60 minutes: it must fail. Password reset never marks an unverified email as verified or changes a role/2FA setting.
6. Reset requests are limited to 3 per minute per IP, with the built-in broker also limiting tokens per address to one per minute. Reset submissions are limited to 5 per minute per IP.

Local .test seeded admin addresses cannot receive real email. Keep the trusted seeded admin for local access; use a real registered customer for inbox tests. No real delivery is claimed until a verification and reset email have both been received and opened. Automated tests use fake/array notifications and isolated SQLite; they do not send real mail or modify MySQL records.
## Implementation file list
Created:
- resources/views/emails/account-action.blade.php: branded verification/reset email template.
- resources/views/shop/security/invalid-verification.blade.php: invalid/expired/other-account verification screen.
- public/auth-forms.js: loading states and duplicate submission prevention.
- tests/Feature/EmailAuthenticationTest.php: end-to-end registration, verification, resend, reset and login tests.

Updated:
- config/security.php: email authentication enabled by default, optional EMAIL_FEATURES_ENABLED environment flag; admin 2FA is now mandatory by default.
- app/Providers/AppServiceProvider.php: Laravel notification customization with shop name and configured sender address.
- app/Http/Controllers/SecurityController.php: safe reset-request responses, invalid reset messages, already-verified handling.
- app/Services/VerificationMail.php: credential-free error handling for SMTP and malformed email configuration.
- bootstrap/app.php: friendly verification link error handling.
- resources/views/shop/login.blade.php and register.blade.php: shared form loading behavior and login reset link.
- resources/views/components/security-layout.blade.php: shared form loading behavior.
- resources/views/shop/security/forgot.blade.php, reset.blade.php and verify.blade.php: reset and verification instructions/forms.
- tests/Feature/ForgotPasswordTest.php and ModulesTest.php: privacy-safe reset response and verification-first registration expectations.
- .env.gmail.example: placeholders and email feature flag.
- GMAIL_SETUP.md and README.md: configuration, behavior and testing instructions.

No new dependencies, migrations or user/table recreation. .env credentials are not modified.