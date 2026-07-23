import 'package:test/test.dart';
import 'package:sentry/sentry.dart';

import '../lib/log_sanitizer.dart';
import '../lib/observability.dart';

void main() {
  group('observability', () {
    test('sanitizes sensitive headers while preserving request id', () {
      final sanitized = sanitizeObservedHeaders(const {
        'Authorization': 'Bearer secret',
        'Cookie': 'session=abc',
        'X-ManaLoom-Ops-Key': 'ops-secret',
        'X-Fcm-Token': 'fcm-secret',
        'X-Request-Id': 'req-1',
      });

      expect(sanitized['Authorization'], equals('[Filtered]'));
      expect(sanitized['Cookie'], equals('[Filtered]'));
      expect(sanitized['X-ManaLoom-Ops-Key'], equals('[Filtered]'));
      expect(sanitized['X-Fcm-Token'], equals('[Filtered]'));
      expect(sanitized['X-Request-Id'], equals('req-1'));
    });

    test('redacts nested values without hiding token counters', () {
      final sanitized = sanitizeObservedMap({
        'email': 'qa@example.com',
        'safe': 'ok',
        'nested': {'refresh_token': 'refresh-secret', 'input_tokens': 42},
      });

      expect(sanitized['email'], equals('[REDACTED_EMAIL]'));
      expect(sanitized['safe'], equals('ok'));
      expect(
        (sanitized['nested'] as Map<String, Object?>)['refresh_token'],
        equals(observedFilteredValue),
      );
      expect(
        (sanitized['nested'] as Map<String, Object?>)['input_tokens'],
        equals(42),
      );
    });

    test('removes request values, cookies and PII from Sentry events', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.example.test/decks?email=qa@example.com#private',
          queryString: 'email=qa@example.com&token=secret',
          cookies: 'session=secret',
          headers: const {
            'Authorization': 'Bearer secret',
            'X-Request-Id': 'mob-123',
          },
          data: const {'password': 'secret', 'safe': true},
        ),
        user: SentryUser(
          id: 'user-1',
          username: 'qa@example.com',
          email: 'qa@example.com',
        ),
        message: SentryMessage('failed for qa@example.com'),
        breadcrumbs: [
          Breadcrumb(
            message: 'token=secret',
            data: const {'fcm_token': 'secret', 'status': 503},
          ),
        ],
      );

      final sanitized = sanitizeObservedEvent(event);

      expect(sanitized.request!.url, equals('https://api.example.test/decks'));
      expect(
        sanitized.request!.queryString,
        equals('email=[Filtered]&token=[Filtered]'),
      );
      expect(sanitized.request!.cookies, isNull);
      expect(sanitized.request!.headers['Authorization'], equals('[Filtered]'));
      expect(sanitized.request!.headers['X-Request-Id'], equals('mob-123'));
      expect(sanitized.user!.id, equals('user-1'));
      expect(sanitized.user!.username, isNull);
      expect(sanitized.user!.email, isNull);
      expect(sanitized.message!.formatted, isNot(contains('qa@example.com')));
      expect(sanitized.breadcrumbs!.single.message, contains('[Filtered]'));
      expect(
        sanitized.breadcrumbs!.single.data!['fcm_token'],
        equals(observedFilteredValue),
      );
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
      expect(resolveSentryTracesSampleRate('oops', fallback: 0.1), equals(0.1));
    });
  });
}
