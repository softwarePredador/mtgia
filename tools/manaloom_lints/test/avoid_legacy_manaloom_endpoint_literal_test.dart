import 'package:manaloom_lints/src/avoid_legacy_manaloom_endpoint_literal.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidLegacyManaLoomEndpointLiteral', () {
    test('only targets production Dart paths', () {
      expect(
        AvoidLegacyManaLoomEndpointLiteral.isProductionPathForTest(
          '/repo/app/lib/core/api/api_client.dart',
        ),
        isTrue,
      );
      expect(
        AvoidLegacyManaLoomEndpointLiteral.isProductionPathForTest(
          '/repo/app/test/core/api/api_client_test.dart',
        ),
        isFalse,
      );
    });

    test('detects legacy/local ManaLoom endpoints', () {
      expect(
        AvoidLegacyManaLoomEndpointLiteral.containsBlockedFragmentForTest(
          'https://api.8ktevp.easypanel.host',
        ),
        isTrue,
      );
      expect(
        AvoidLegacyManaLoomEndpointLiteral.containsBlockedFragmentForTest(
          'http://127.0.0.1:8080',
        ),
        isTrue,
      );
      expect(
        AvoidLegacyManaLoomEndpointLiteral.containsBlockedFragmentForTest(
          'https://api.scryfall.com',
        ),
        isFalse,
      );
    });
  });
}
