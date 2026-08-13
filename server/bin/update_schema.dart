import 'dart:io';

/// Historical schema reset entrypoint.
///
/// Product schema changes must use the versioned migration runner and the
/// disposable loopback schema gate. Keeping this filename as a fail-closed
/// tombstone prevents old runbooks or shell history from dropping product
/// tables.
void main() {
  stderr.writeln(
    'BLOCKED: server/bin/update_schema.dart is a retired destructive schema '
    'reset entrypoint. Use bin/migrate.dart and the governed schema gate.',
  );
  exitCode = 2;
}
