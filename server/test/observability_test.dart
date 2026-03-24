import 'package:test/test.dart';

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
