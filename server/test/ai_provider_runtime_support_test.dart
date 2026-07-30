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
      for (final status in const [
        HttpStatus.unauthorized,
        HttpStatus.forbidden,
      ]) {
        final contract = classifyAiProviderHttpFailure(status);
        expect(contract.httpStatus, HttpStatus.serviceUnavailable);
        expect(contract.errorCode, 'provider_unavailable');
        expect(contract.retryable, isFalse);
      }
    });

    test(
      'maps provider throttling and failures to stable gateway statuses',
      () {
        final timeout = classifyAiProviderHttpFailure(
          HttpStatus.requestTimeout,
        );
        expect(timeout.httpStatus, HttpStatus.gatewayTimeout);
        expect(timeout.errorCode, 'provider_timeout');
        expect(timeout.providerStatus, 'timeout');
        expect(timeout.retryable, isTrue);

        final throttled = classifyAiProviderHttpFailure(
          HttpStatus.tooManyRequests,
        );
        expect(throttled.httpStatus, HttpStatus.serviceUnavailable);
        expect(throttled.errorCode, 'provider_rate_limited');
        expect(throttled.providerStatus, 'rate_limited');
        expect(throttled.retryable, isTrue);

        final unavailable = classifyAiProviderHttpFailure(
          HttpStatus.internalServerError,
        );
        expect(unavailable.httpStatus, HttpStatus.serviceUnavailable);
        expect(unavailable.errorCode, 'provider_unavailable');
        expect(unavailable.providerStatus, 'unavailable');
        expect(unavailable.retryable, isTrue);

        final rejected = classifyAiProviderHttpFailure(HttpStatus.badRequest);
        expect(rejected.httpStatus, HttpStatus.badGateway);
        expect(rejected.errorCode, 'provider_rejected');
        expect(rejected.providerStatus, 'rejected');
        expect(rejected.retryable, isFalse);

        expect(
          mapAiProviderHttpStatus(HttpStatus.requestTimeout),
          timeout.httpStatus,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.tooManyRequests),
          throttled.httpStatus,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.internalServerError),
          unavailable.httpStatus,
        );
        expect(
          mapAiProviderHttpStatus(HttpStatus.badRequest),
          rejected.httpStatus,
        );
      },
    );

    test('transport failures use a retryable sanitized contract', () {
      expect(
        aiProviderTransportFailureContract.category,
        AiProviderFailureCategory.transport,
      );
      expect(
        aiProviderTransportFailureContract.httpStatus,
        HttpStatus.serviceUnavailable,
      );
      expect(
        aiProviderTransportFailureContract.errorCode,
        'provider_transport_error',
      );
      expect(aiProviderTransportFailureContract.providerStatus, 'unavailable');
      expect(aiProviderTransportFailureContract.retryable, isTrue);
    });

    test('sanitizes and bounds provider retry-after guidance', () {
      expect(parseAiProviderRetryAfterSeconds('12'), 12);
      expect(parseAiProviderRetryAfterSeconds('9999'), 3600);
      expect(parseAiProviderRetryAfterSeconds('-1'), isNull);
      expect(parseAiProviderRetryAfterSeconds('invalid'), isNull);
      expect(
        parseAiProviderRetryAfterSeconds(
          'Wed, 29 Jul 2026 12:00:03 GMT',
          now: DateTime.utc(2026, 7, 29, 12),
        ),
        3,
      );
    });
  });
}
