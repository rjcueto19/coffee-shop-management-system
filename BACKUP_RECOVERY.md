# Backup & Recovery

## Implemented behavior
Laravel 12 / PHP 8.3 / MySQL uses the existing admin sidebar, auth, roles and mandatory admin 2FA. Manual/automatic backups, protected downloads, history/filtering, deletion, retention and recovery preparation are implemented directly in the existing module. No replacement authentication or backup package is installed.

New backups are real AES-256 encrypted ZIP archives containing:
- database.sql: mysqldump export of the entire configured MySQL database, including tables, structure, records, triggers, routines and events where present. A single-transaction dump preserves consistency for InnoDB tables; do not run schema migrations during backup. Nontransactional tables require a maintenance backup window.
- files/public/images, files/storage/app/public and files/storage/app/uploads when present: local images and uploaded files. Symlinks, dotfiles, executable scripts and key/config files are excluded.
- manifest.json: encrypted format/version, driver, migration list, table list and each entry's size/SHA-256 checksum.

No .env, APP_KEY, ZIP password, vendor, node_modules, Git, caches, logs or previous backup files are included as application files. The full SQL database includes authentication data, sessions, cache and backup history, so every ZIP entry is encrypted. ZIP filenames/entry names themselves are not secret; contents are encrypted. Legacy .backup files may contain .env/source files from the old implementation: they remain private and downloadable, and must be handled as sensitive historical archives. New ZIP generation does not reproduce those contents.

## Storage, keys and dependencies
Storage: storage/app/private/backups (outside public/). Downloads require authenticated admin routes and mandatory second-factor session verification. Private local serving URLs are disabled. Do not create a public symlink to private backups.

PHP ZIP with AES-256 and Fileinfo are required and have been enabled on this Windows PHP installation. Existing tools/php/extensions.ini no longer loads those extensions twice. Restart an already-running PHP development server/service to load changed php.ini extensions. PDO MySQL, mysqldump and mysql are already available. MySQL binaries are invoked through Symfony Process argument arrays, without a shell or a password argument. A private temporary client options file is removed after export, along with temporary SQL/partial ZIP files.

Optional environment configuration (placeholders only; existing .env credentials were not changed):

    BACKUP_PASSWORD="a-separate-long-random-backup-password"
    BACKUP_RETENTION_DAYS=30
    BACKUP_MYSQLDUMP_PATH="C:/Program Files/MySQL/MySQL Server 8.0/bin/mysqldump.exe"

If BACKUP_PASSWORD is absent, the ZIP password is derived from the existing APP_KEY with a dedicated HMAC label. Obtain it only in your private local console:

    php artisan shop:backup-password

Keep the key separately from downloaded ZIPs and do not share it. Keep the original APP_KEY securely too: restored encrypted 2FA fields require that same key. Rotating a backup key makes existing ZIPs require the original key/configuration. This format intentionally requires the same database driver and migration list for recovery validation.

config/backup.php limits uploaded archives to 10,000 entries and 512 MiB uncompressed contents. HTTP upload validation permits 256 MiB compressed ZIPs, additionally limited by PHP post_max_size/upload_max_filesize. Increase those PHP limits if needed. The module checks entry paths, encryption, symlinks, size limits, manifest and every file hash before accepting a ZIP. Uploaded scripts are never executed.

## Create, download and delete
1. Admin opens Backup & Recovery and clicks Create Backup. Success is shown only after the archive is finalized and fully revalidated.
2. Download retrieves the actual archive through the protected route. Its stored SHA-256 and encrypted entries are checked first. Missing/corrupted files are rejected and reflected in history.
3. Delete requires confirmation and only removes that selected backup file. The catalog row remains as Deleted. Active operations share a lock; the latest actually validated known-good backup cannot be deleted, even if a newer file is corrupted.
4. A daily automatic backup applies retention after successful creation: expired regular backups are removed while preserving at least two validated regular backups and the latest valid backup. Safety backups are not automatically pruned. Keep off-device copies: same-disk backups do not protect against disk loss.

History includes filename, ID, type, date/time, file size, table/file counts, status and actor. Statuses include In Progress, Completed, Failed, Recovery Ready, Deleted, Missing and Corrupted. Creation, failure, download, deletion and recovery preparation events are written to activity_logs without passwords, SQL contents or customer records.

## Daily scheduler
Laravel schedules shop:backup --automatic at 00:00 in config('app.timezone'), currently Asia/Manila. Both scheduler non-overlap protection and a shared operation lock are enabled; a validated automatic backup is deduplicated per local date.

Windows: tools/install-backup-task.ps1 installs/updates DailyGrind-AutomaticBackup to run tools/run-backup-scheduler.ps1 every minute in a hidden PowerShell window. The wrapper invokes Laravel schedule:run. The current user must be logged in, computer on and MySQL running. This is a local-development task, not an always-on service. If the computer is off at midnight, the missed Laravel due time is not replayed automatically; create a manual backup when needed.

Reinstall after moving the project:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/install-backup-task.ps1

Inspect actual execution:

    Get-ScheduledTaskInfo -TaskName DailyGrind-AutomaticBackup
    php artisan schedule:list

Check storage/logs/backup-scheduler.log and the latest Automatic history row. A defined schedule alone does not prove a backup ran. The Windows runner was exercised successfully, but a real midnight execution must still be observed in history.

Production: configure a cron entry every minute (use the actual project path), or use your hosting scheduler/service:

    * * * * * cd /path/to/coffee-shop && php artisan schedule:run >> /dev/null 2>&1

Keep production online with the proper timezone, file permissions, MySQL access and mysqldump path. Do not run multiple independent scheduler setups unless they share the same lock store.

## Safe recovery: validation and staging first
Web Restore deliberately PREPARES recovery; it does not replace live data. This is the safe manual recovery workflow permitted by the task. It avoids assuming that MySQL DDL can roll back in one transaction.

1. Select an existing ZIP or upload one. Review the history filename, date and size. Confirm your current admin password, a fresh authenticator/recovery code when 2FA is enabled, and the explicit recovery checkbox.
2. The server validates the archive, creates and validates a fresh Safety ZIP, then preserves a separate encrypted Recovery ZIP. Any failure leaves live shop records and uploaded files untouched. Safety backups remain available if later preparation fails.
3. Download both the recovery package and its safety backup to private off-device storage. Review Recovery Prepared activity logs for the source filename/date and safety backup ID.
4. Extract on a private machine to a NEW folder; the command does not execute SQL or overwrite an existing directory:

       php artisan shop:backup-extract "C:/private/saved.zip" "C:/private/new-recovery-folder"

5. Review database.sql. It must not contain unexpected CREATE/DROP DATABASE, USE statements pointing at live data, cross-database references, stored routines, triggers or events. Do not execute untrusted SQL. Genuine exports include table replacement statements intended ONLY for the selected restore target.
6. Create a NEW empty MySQL staging database using a different name. Import using MySQL Workbench's Data Import or a MySQL client signed into that new database. For example, supply your configured host/port/user and type the password at the prompt:

       mysql --default-character-set=utf8mb4 -h HOST -P PORT -u USER -p NEW_STAGING_DATABASE

   Inside that staging-only client, use source C:/private/new-recovery-folder/database.sql. Never select the live database for a staging test.
7. Verify required tables, row data, foreign keys, user roles/verification/2FA fields, order items/totals, payments, inventory and settings. Compare representative uploaded-file checksums. Test a separate private application copy using the staging DB with outbound email, scheduler and public access disabled.
8. Record successful staging verification from the local admin console, supplying only the ZIP filename:

       php artisan shop:recovery-record staging_verified coffee_shop_backup_FILENAME.zip

   This records an operator report; it is not itself a validation or restore command.

The module's current MySQL export was also imported into a separate randomly named temporary MySQL validation database by tools/verify-backup-staging.php. Required tables and all 13 foreign-key relationships were verified; only the generated temporary database and extraction folder were removed. The source database was never imported into or replaced. This helper accepts no uploaded archive or target database name; it tests only the latest locally created, validated manual ZIP and rejects SQL needing additional database/routine review. Invoke it only from the local CLI when intentionally performing that isolated integration test.

## Administrator-approved activation and rollback
These steps are manual and were NOT performed during implementation:

1. Obtain explicit administrator approval after successful staging checks. Record the current database name, application version and upload locations. Preserve the original APP_KEY and backup key outside archives.
2. Put the application into maintenance mode with php artisan down --retry=60. Stop/pause scheduler and queue workers and any other external writers. Do not let business writes continue while switching databases/files.
3. Create a FINAL safety ZIP with php -d memory_limit=512M artisan shop:backup. Validate/download it and preserve it. Keep the existing original live database intact.
4. Import the reviewed SQL into another NEW empty database intended for recovery activation; do not overwrite the original live database. Review/disable restored scheduled database events. Preserve the current upload directories and copy only the validated files/ tree into the matching uploaded-file locations. Never copy archive contents over .env, application code or APP_KEY.
5. After verification, change only the configured DB_DATABASE to that recovered database and run php artisan config:clear. Keep the original database name available for rollback. In the RECOVERED database, clear restored sessions/reset tokens and cache/lock state before opening access so old sessions cannot resume and copied locks do not remain active. Do not remove business tables or the original database.
6. Run php artisan migrate:status, inspect required tables and relationships, and perform login/role/ordering/payment checks while normal access is still blocked. Confirm the matching application version and APP_KEY can read encrypted 2FA data. Reconcile backup catalog paths against physical files after a database switch.
7. If any check fails, keep maintenance mode on; point DB_DATABASE back to the untouched original database, restore the preserved original upload directories and clear config. Recheck before resuming. The final Safety ZIP is an additional fallback, not a substitute for keeping the original database.
8. After successful activation checks, record shop:recovery-record activated SOURCE_FILENAME.zip; on rollback, record rolled_back instead. Then php artisan up and resume workers/scheduler. Review logs and the next automatic backup.

No live database is dropped, truncated or overwritten by web validation, automated tests or the recovery-preparation action. There is no one-click live restore endpoint. Operators must retain maintenance mode until manual recovery checks succeed.

## Verification and file inventory
Automated suite: 115 tests / 1,027 assertions passed, using isolated SQLite for automated business/recovery tests. Recovery tests import SQL into a separate in-memory database and check relationships/files. Additional actual MySQL backup and temporary-MySQL restore validation passed. Windows scheduler execution returned task result 0; midnight job execution is still a scheduled future observation. No real live restore was performed.

Created:
- config/backup.php
- app/Services/BackupArchive.php
- app/Services/BackupManager.php
- database/migrations/2026_11_23_000002_expand_backup_metadata.php
- resources/views/shop/backup-guide.blade.php
- public/backup-ui.js
- tools/run-backup-scheduler.ps1
- tools/verify-backup-staging.php
- tests/Feature/BackupValidationTest.php
- BACKUP_RECOVERY.md

Updated:
- app/Http/Controllers/BackupController.php
- app/Services/FullBackupService.php (new creation delegates to ZIP service; legacy offline readers retained)
- resources/views/shop/backups.blade.php
- routes/web.php and routes/console.php
- config/filesystems.php (private serving disabled)
- tools/install-backup-task.ps1 and tools/php/extensions.ini
- tests/Feature/BackupHistoryTest.php, AutomaticBackupTest.php and ModulesTest.php
- README.md
- Local PHP php.ini: ZIP and Fileinfo enabled; Windows task updated.

The migration adds only SHA-256, file-count, error-code and completion-time fields to the existing backup_runs table. No user or business tables are recreated. No third-party Composer package was added; existing Symfony Process, MySQL tools and PHP ZipArchive are used.

References: https://www.php.net/manual/en/ziparchive.setencryptionname.php and https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html .