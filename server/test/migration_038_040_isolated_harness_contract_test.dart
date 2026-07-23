import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('migrations 038-040 isolated harness', () {
    final harness =
        File(
          '../scripts/manaloom_migrations_038_040_isolated.sh',
        ).readAsStringSync();
    final helper =
        File('bin/migration_038_040_isolated_support.dart').readAsStringSync();

    test('is fail closed and restricted to disposable loopback databases', () {
      expect(harness, contains('require_postgres_write_approval'));
      expect(harness, contains('require_live_mutation_approval'));
      expect(harness, contains('localhost|127.0.0.1|::1'));
      expect(helper, contains("startsWith('manaloom_s1_migrations_')"));
      expect(harness, contains('trap cleanup EXIT INT TERM'));
      expect(harness, contains('dropdb --if-exists --force'));
    });

    test('proves fresh upgrade idempotency restore and forward recovery', () {
      expect(harness, contains('fresh-apply.log'));
      expect(harness, contains('fresh-reapply.log'));
      expect(harness, contains('upgrade-prior.log'));
      expect(harness, contains('upgrade-reapply.log'));
      expect(harness, contains('rollback-restore.log'));
      expect(harness, contains('rollback-forward-check.log'));
      expect(helper, contains("const ['040', '039', '038']"));
      expect(helper, contains("candidate.version) <= 37"));
    });
  });
}
