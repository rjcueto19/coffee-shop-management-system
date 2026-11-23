# Daily Grind — Coffee Shop Management
Laravel 12 / PHP 8.2+ / MySQL 8+. Blade + vanilla JavaScript, no Node build required.

## Setup
1. Install Composer dependencies: composer install
2. Copy .env.example to .env if missing and run: php artisan key:generate
3. Create a MySQL database named coffee_shop and configure DB_* in .env.
4. Enable PHP pdo_mysql, fileinfo, zip, mbstring, curl, openssl and XML extensions.
5. Run: php artisan migrate --seed
6. Run: php artisan shop:admin
7. Run: php artisan serve
8. Visit http://127.0.0.1:8000/login

On this Windows installation, pdo_mysql is enabled globally. For the additional
extensions supplied with PHP, use:
    powershell -ExecutionPolicy Bypass -File .\artisan.ps1 migrate --seed
    powershell -ExecutionPolicy Bypass -File .\artisan.ps1 shop:admin
    powershell -ExecutionPolicy Bypass -File .\artisan.ps1 serve
    powershell -ExecutionPolicy Bypass -File .\artisan.ps1 test

Keep passwords only in .env, not source control. No default admin password is
shipped. Existing user accounts remain unchanged by the module expansion.

## Roles
- Admin: dashboard, users/roles, products, ingredients/recipes, POS/orders, customer
  profiles/history, reservations/tables, reports, settings, logs, backup/recovery.
- Cashier: POS, payments, receipts, order tracking and handover.
- Staff / Barista (stored as staff): paid preparation queue, customizations,
  mark preparing orders ready. Cannot collect payment or complete handover.
- Customer: register, browse menu, place orders, see only their own orders,
  update their profile, view points/history, make/cancel their own reservations.
- New public registrations always become customers, regardless of submitted role.
- Users & roles lets admins create accounts for all roles. The last admin is protected.

## Modules
1. Dashboard: today's orders/paid sales, total paid revenue, weekly chart,
   sellable-unit and ingredient low-stock alerts.
2. User management: four role types, account creation and role changes.
3. Product management: add/edit/delete. Used products are archived on deletion
   so historical sales and receipts remain available.
4. Ordering: dine-in/takeout, per-item preparation customization and order notes.
5. POS: integer-cent server prices, percentage discount, loyalty redemption,
   cash payment, change and printable receipts.
6. Inventory: ingredients in whole g/ml/pcs, stock-in/out, movement history,
   low thresholds, and per-product recipes deducted automatically.
7. Sales: daily/weekly/monthly shortcuts and custom date ranges, paid sales only.
8. Customers: profiles, phone, points and linked order history.
9. Loyalty: earn after payment; redeem at cashier checkout. Default is one point
   per PHP100 paid, with PHP1 value per point. Admin can configure rates.
10. Reservations: tables/seats, date availability schedule, capacity checks,
    overlap prevention, maximum four-hour booking, cancellation.
11. Tracking: customer Pending (unpaid) -> Preparing (after payment) -> Ready ->
    Completed (cashier/admin handover). Counter sales start paid and Preparing.
12. Analytics: best-selling products (gross line sales), net revenue chart,
    ingredient stock balances and date-filtered stock movement totals.
13. Notifications: persistent in-app order updates and admin low-ingredient alerts.
14. Activity: signed-in mutation routes, actor and timestamp, no request contents.
15. Backup/recovery: encrypted application data snapshots and admin-only restore.

## Operational rules
- Payments are cash at the counter. Customer orders do not claim payment.
- Stock is reserved/deducted when an order is placed, including unpaid online
  orders. This version has no cancellation/refund workflow for orders.
- Add real ingredient stock and recipes from Ingredients & recipes. Products
  without recipes only consume their menu-unit stock.
- Preparation customizations are instructions, not priced options or recipe
  overrides. Baristas see these instructions in order details.
- Reward points cannot exceed the account balance or remaining order value.
  They are redeemed on new cashier orders linked to a customer account.
- Add your real tables and seating capacities before accepting reservations.
- Availability shows occupied intervals; unlisted intervals are available.
- Notification updates appear when the page is refreshed, without email or SMS.
- Timezone is Asia/Manila. No external payment, tax, SMS, or email provider is configured.

## Backup and recovery
Use Admin > Backup & Recovery for validated AES-256 ZIP backups, protected downloads, history, deletion and safe recovery preparation. Daily backups are scheduled for 12:00 AM in the application timezone. See [Backup and recovery guide](BACKUP_RECOVERY.md) for keys, scheduler setup, staging tests and manual activation/rollback. Web recovery never replaces live records.

## Verification
Feature tests use in-memory SQLite and never erase the configured MySQL database.
    powershell -ExecutionPolicy Bypass -File .\artisan.ps1 test
Coverage includes all role boundaries, server prices, failed-checkout rollback,
ingredients, reward earning/redemption, unpaid-order isolation, reservations,
notifications, history preservation, and encrypted backup integrity/round-trip.
MySQL migration and runtime smoke checks are performed separately.

## Production
Use HTTPS, APP_ENV=production and APP_DEBUG=false. Web root must be public/.
Keep .env and storage private, use a dedicated database user, and back up APP_KEY
and the database. The app is intended for a small single-location coffee shop.
## Manual and automatic backups
The current module uses encrypted ZIPs, not new .backup snapshots. Refer to [BACKUP_RECOVERY.md](BACKUP_RECOVERY.md) for the midnight schedule, private storage, retention, recovery preparation and legacy archive limitations.

## Email authentication
Email verification for customer registrations and Forgot Password / Reset Password are enabled. The existing .env mailer remains unchanged; log mail does not deliver to inboxes. See [Gmail setup and testing](GMAIL_SETUP.md) for placeholder SMTP configuration, App Password instructions and the implementation file list. Existing database tables are reused; no migration is required. Admin 2FA is mandatory; customers can opt in. See [Authenticator setup](TWO_FACTOR_SETUP.md) for instructions.
