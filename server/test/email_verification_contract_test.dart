import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/email_verification_policy.dart';

String normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('email verification gate', () {
    final setup = normalize(File('database_setup.sql').readAsStringSync());
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '044',
    );
    final migrationSql = normalize(migration.up);

    test('bootstrap and migration store only a verification token hash', () {
      for (final sql in [setup, migrationSql]) {
        expect(sql, contains('email_verified_at timestamp with time zone'));
        expect(
          sql,
          contains('create table if not exists email_verification_tokens'),
        );
        expect(sql, contains('token_hash char(64) not null unique'));
        expect(sql, contains('expires_at timestamp with time zone not null'));
        expect(sql, contains('consumed_at timestamp with time zone'));
      }
      expect(
        migrate.migrationRollbackPolicy('044'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('production gate cannot be disabled and token exposure stays off', () {
      expect(isVerifiedEmailRequired({'ENVIRONMENT': 'production'}), isTrue);
      expect(
        isVerifiedEmailRequired({
          'ENVIRONMENT': 'development',
          requireVerifiedEmailEnvironment: 'true',
        }),
        isTrue,
      );
      expect(
        mayExposeEmailVerificationTokenForTesting({
          'ENVIRONMENT': 'production',
          emailVerificationTestResponseEnvironment:
              emailVerificationTestResponseApproval,
        }),
        isFalse,
      );
    });

    test('UGC mutation surfaces install the verified-email gate', () {
      for (final path in const [
        'routes/community/_middleware.dart',
        'routes/trades/_middleware.dart',
        'routes/conversations/_middleware.dart',
        'routes/binder/_middleware.dart',
      ]) {
        expect(
          File(path).readAsStringSync(),
          contains('verifiedEmailForMutations()'),
          reason: path,
        );
      }
    });
  });
}
