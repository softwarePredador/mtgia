import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/observability/app_observability_sanitizer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('app observability sanitizer', () {
    test('redacts nested secrets, email and token values', () {
      final sanitized = sanitizeAppObservedMap({
        'email': 'qa@example.com',
        'safe': 'ok',
        'nested': {'access_token': 'token-value', 'input_tokens': 42},
      });

      expect(sanitized['email'], equals('[Filtered_EMAIL]'));
      expect(sanitized['safe'], equals('ok'));
      expect(
        (sanitized['nested'] as Map<String, Object?>)['access_token'],
        equals(appObservedFilteredValue),
      );
      expect(
        (sanitized['nested'] as Map<String, Object?>)['input_tokens'],
        equals(42),
      );
    });

    test('removes query values, cookies and PII from Sentry events', () {
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

      final sanitized = sanitizeAppObservedEvent(event);

      expect(sanitized.request!.url, equals('https://api.example.test/decks'));
      expect(
        sanitized.request!.queryString,
        equals('email=[Filtered]&token=[Filtered]'),
      );
      expect(sanitized.request!.cookies, isNull);
      expect(
        sanitized.request!.headers['Authorization'],
        equals(appObservedFilteredValue),
      );
      expect(sanitized.request!.headers['X-Request-Id'], equals('mob-123'));
      expect(sanitized.user!.id, equals('user-1'));
      expect(sanitized.user!.username, isNull);
      expect(sanitized.user!.email, isNull);
      expect(sanitized.message!.formatted, isNot(contains('qa@example.com')));
      expect(sanitized.breadcrumbs!.single.message, contains('[Filtered]'));
      expect(
        sanitized.breadcrumbs!.single.data!['fcm_token'],
        equals(appObservedFilteredValue),
      );
    });
  });
}
