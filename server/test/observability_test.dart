import 'package:test/test.dart';

import '../lib/log_sanitizer.dart';
import '../lib/observability.dart';

void main() {
  group('observability', () {
    test('sanitizes authorization and cookie headers', () {
      final sanitized = sanitizeObservedHeaders(const {
        'Authorization': 'Bearer secret',
        'Cookie': 'session=abc',
        'X-Request-Id': 'req-1',
      });

      expect(sanitized['Authorization'], equals('[Filtered]'));
      expect(sanitized['Cookie'], equals('[Filtered]'));
      expect(sanitized['X-Request-Id'], equals('req-1'));
    });

    test('redacts email and FCM token from log messages', () {
      final sanitized = sanitizeLogMessage(
        'email=qa@example.com fcm_token=abc123xyz other=ok',
      );

      expect(sanitized, isNot(contains('qa@example.com')));
      expect(sanitized, isNot(contains('abc123xyz')));
      expect(sanitized, contains('[REDACTED_EMAIL]'));
      expect(sanitized, contains('fcm_token=[REDACTED]'));
      expect(sanitized, contains('other=ok'));
    });

    test('parses valid trace sample rate', () {
      expect(resolveSentryTracesSampleRate('0.35'), equals(0.35));
    });

    test('falls back on invalid trace sample rate', () {
      expect(
        resolveSentryTracesSampleRate('oops', fallback: 0.1),
        equals(0.1),
      );
    });
  });
}
