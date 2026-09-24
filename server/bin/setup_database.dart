import 'dart:io';

/// Historical schema setup entrypoint (D-48, BT-DB-004).
///
/// It applied the whole `database_setup.sql` to the database in `.env`, with
/// no approval, no loopback restriction and exit code 0 even after a partial
/// failure. A fresh schema is born only in the disposable schema gate
/// (`database_setup.sql` plus `bin/migrate.dart`), and an existing database
/// changes only through migrations. Keeping this filename as a fail-closed
/// tombstone stops old runbooks or shell history from reapplying the baseline.
void main() {
  stderr.writeln(
    'BLOCKED: server/bin/setup_database.dart is a retired destructive schema '
    'reset entrypoint. Use bin/migrate.dart and the governed schema gate.',
  );
  exitCode = 2;
}
