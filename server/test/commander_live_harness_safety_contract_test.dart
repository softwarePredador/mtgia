import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Commander live harness safety contract', () {
    test('real-provider lifecycle pins target and proves Commander', () {
      final source =
          File(
            'test/commander_ai_real_provider_lifecycle_live_test.dart',
          ).readAsStringSync();

      expect(source, isNot(contains("'format': 'Standard'")));
      expect(source, contains("'format': 'Commander'"));
      expect(source, contains("'format': 'commander'"));
      expect(source, contains("'commander_name': commanderName"));
      expect(source, contains("'bracket': commanderBracket"));
      expect(source, contains('expect(generatedQuantity, 100)'));
      expect(source, contains("generation['deckbuilding_contract']"));
      expect(source, contains("Uri.parse('\$baseUrl/users/me')"));
      expect(source, contains("'account_deleted'"));
      expect(source, contains("Platform.environment['TEST_API_BASE_URL']"));
      expect(source, contains('MANALOOM_EXPECTED_API_GIT_SHA'));
      expect(source, contains("target.scheme == 'https'"));
      expect(source, contains("target.scheme == 'http' && targetIsLoopback"));
      expect(source, contains("RegExp(r'^[0-9a-f]{40}\$')"));
      expect(source, contains("Uri.parse('\$baseUrl/health')"));
      expect(source, contains("health['git_sha']"));
      expect(source, contains("'prefer_collection': true"));
      expect(source, contains("'ai_generate'"));
      expect(source, contains("'provider_validated_repair'"));
      expect(source, isNot(contains('package:postgres/postgres.dart')));
      expect(source, isNot(contains('Pool openPool')));
      expect(source, contains("'legal_accepted': true"));
      expect(source, contains('currentTermsVersion'));
      expect(source, contains('currentPrivacyVersion'));
    });

    test('reference-profile probe requires explicit target and cleans up', () {
      final source =
          File(
            'test/commander_reference_profile_generate_live_test.dart',
          ).readAsStringSync();

      expect(
        source,
        contains("@Tags(['live', 'live_backend', 'live_db_write'"),
      );
      expect(source, contains("Platform.environment['TEST_API_BASE_URL']"));
      expect(source, contains('targetConfigured'));
      expect(source, contains('MANALOOM_EXPECTED_API_GIT_SHA'));
      expect(source, contains("target.scheme == 'https'"));
      expect(source, contains("target.scheme == 'http' && targetIsLoopback"));
      expect(source, contains("Uri.parse('\$baseUrl/health')"));
      expect(source, isNot(contains('evolution-cartinhas.2ta7qx')));
      expect(source, isNot(contains('MANALOOM_CONFIRM_POSTGRES_WRITES')));
      expect(source, contains('expect(response.statusCode, 200'));
      expect(source, contains('expect(otherResponse.statusCode, 200'));
      expect(source, contains('expect(mainQuantity, 99)'));
      expect(source, contains("body['deckbuilding_contract']"));
      expect(source, contains("Uri.parse('\$baseUrl/users/me')"));
      expect(source, contains("'account_deleted'"));
      expect(source, contains("'legal_accepted': true"));
      expect(source, contains('currentTermsVersion'));
      expect(source, contains('currentPrivacyVersion'));
    });
  });
}
