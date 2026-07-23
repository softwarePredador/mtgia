import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/password_reset_delivery_service.dart';

String normalizeSql(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('account security schema and runtime contracts', () {
    final setup = normalizeSql(File('database_setup.sql').readAsStringSync());
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '042',
    );
    final migrationUp = normalizeSql(migration.up);

    test('bootstrap and migration store only a reset token hash', () {
      for (final sql in [setup, migrationUp]) {
        expect(sql, contains('auth_version integer not null default 0'));
        expect(sql, contains('password_changed_at timestamp with time zone'));
        expect(
          sql,
          contains('create table if not exists password_reset_tokens'),
        );
        expect(sql, contains('token_hash char(64) not null unique'));
        expect(sql, contains('expires_at timestamp with time zone not null'));
        expect(sql, contains('consumed_at timestamp with time zone'));
        expect(sql, isNot(contains('password_reset_tokens ( token ')));
      }
    });

    test('migration is guarded as manual rollback', () {
      expect(
        migrate.migrationRollbackPolicy('042'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('raw token exposure is impossible in production', () {
      expect(
        mayExposePasswordResetTokenForTesting({
          'ENVIRONMENT': 'production',
          passwordResetTestResponseEnvironment:
              passwordResetTestResponseApproval,
        }),
        isFalse,
      );
      expect(
        mayExposePasswordResetTokenForTesting({
          'ENVIRONMENT': 'development',
          passwordResetTestResponseEnvironment:
              passwordResetTestResponseApproval,
        }),
        isTrue,
      );
      expect(
        mayExposePasswordResetTokenForTesting({
          'ENVIRONMENT': 'development',
          passwordResetTestResponseEnvironment: 'true',
        }),
        isFalse,
      );
    });
  });
}
