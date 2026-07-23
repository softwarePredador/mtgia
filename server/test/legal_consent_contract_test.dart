import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/legal_policy.dart';

String normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('versioned legal consent', () {
    final setup = normalize(File('database_setup.sql').readAsStringSync());
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '043',
    );
    final migrationSql = normalize(migration.up);

    test('bootstrap and migration keep version/time pairs consistent', () {
      for (final sql in [setup, migrationSql]) {
        for (final column in const [
          'terms_version',
          'terms_accepted_at',
          'privacy_version',
          'privacy_accepted_at',
        ]) {
          expect(sql, contains(column));
        }
      }
      expect(migrationSql, contains('chk_users_terms_acceptance_pair'));
      expect(migrationSql, contains('chk_users_privacy_acceptance_pair'));
      expect(
        migrate.migrationRollbackPolicy('043'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('production always requires the current versions', () {
      expect(
        LegalAcceptancePolicy.isRequired({'ENVIRONMENT': 'production'}),
        isTrue,
      );
      expect(
        () => LegalAcceptancePolicy.parse({}, required: true),
        throwsA(isA<LegalAcceptanceException>()),
      );
      expect(
        () => LegalAcceptancePolicy.parse({
          'legal_accepted': true,
          'terms_version': 'stale',
          'privacy_version': currentPrivacyVersion,
        }, required: true),
        throwsA(isA<LegalAcceptanceException>()),
      );
      final acceptance = LegalAcceptancePolicy.parse({
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      }, required: true);
      expect(acceptance?.termsVersion, currentTermsVersion);
      expect(acceptance?.privacyVersion, currentPrivacyVersion);
    });

    test('local legacy compatibility is explicit and can be gated', () {
      expect(
        LegalAcceptancePolicy.isRequired({'ENVIRONMENT': 'development'}),
        isFalse,
      );
      expect(
        LegalAcceptancePolicy.isRequired({
          'ENVIRONMENT': 'development',
          requireLegalAcceptanceEnvironment: 'true',
        }),
        isTrue,
      );
    });
  });
}
