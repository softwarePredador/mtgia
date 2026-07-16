import 'dart:io';

import 'package:server/ai_provider_runtime_support.dart';
import 'package:test/test.dart';

void main() {
  group('AI provider runtime support', () {
    test('hashes user identifiers before sending provider safety metadata', () {
      final first = aiSafetyIdentifierPayload(' user-123 ');
      final repeated = aiSafetyIdentifierPayload('user-123');
      final other = aiSafetyIdentifierPayload('user-456');

      expect(first, repeated);
      expect(first, isNot(other));
      expect(first['safety_identifier'], startsWith('manaloom_'));
      expect(first.toString(), isNot(contains('user-123')));
      expect(aiSafetyIdentifierPayload(null), isEmpty);
      expect(aiSafetyIdentifierPayload('  '), isEmpty);
    });

    test('does not expose provider authentication as user authentication', () {
      expect(
        mapAiProviderHttpStatus(HttpStatus.unauthorized),
        HttpStatus.serviceUnavailable,
      );
      expect(
        mapAiProviderHttpStatus(HttpStatus.forbidden),
        HttpStatus.serviceUnavailable,
      );
    });

    test(
      'maps provider throttling and failures to stable gateway statuses',
      () {
        expect(
          mapAiProviderHttpStatus(HttpStatus.requestTimeout),
          HttpStatus.gatewayTimeout,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.tooManyRequests),
          HttpStatus.serviceUnavailable,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.internalServerError),
          HttpStatus.serviceUnavailable,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.badRequest),
          HttpStatus.badGateway,
        );
      },
    );
  });
}
