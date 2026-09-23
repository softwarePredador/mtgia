import 'dart:io';

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
        'nested': {
          'refresh_token': 'refresh-secret',
          'resend_api_key': 're_test_only_never_real_123456789',
          'input_tokens': 42,
        },
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
      expect(
        (sanitized['nested'] as Map<String, Object?>)['resend_api_key'],
        equals(observedFilteredValue),
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
      // D-23: nenhum evento sai com o usuário, nem só com o ID.
      expect(sanitized.user, isNull);
      expect(sanitized.message!.formatted, isNot(contains('qa@example.com')));
      expect(sanitized.breadcrumbs!.single.message, contains('[Filtered]'));
      expect(
        sanitized.breadcrumbs!.single.data!['fcm_token'],
        equals(observedFilteredValue),
      );
    });

    test('D-23: tira UUIDs de caminho, título, tag, exceção e contexto, mas '
        'mantém o request_id', () {
      const userId = '3f1c2b7a-9d4e-4f6a-8b2c-1d2e3f4a5b6c';
      const deckId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
      const clientRequestId = '0f0e0d0c-0b0a-4908-8706-050403020100';
      final event = SentryEvent(
        request: SentryRequest(url: 'https://api.example.test/users/$userId'),
        message: SentryMessage('HTTP server_error: /users/$userId/follow'),
        transaction: 'GET /decks/$deckId',
        exceptions: [
          SentryException(
            type: 'PgException',
            value: 'Key (user_id)=($userId) is not present',
          ),
        ],
        tags: const {
          'http_path': '/decks/$deckId',
          'endpoint': '/users/$userId',
          'request_id': clientRequestId,
        },
      );
      event.contexts['extras'] = {
        'recipient_user_id': userId,
        'nested': {'deck_id': deckId},
      };

      final sanitized = sanitizeObservedEvent(event);
      final serialized = [
        sanitized.request!.url,
        sanitized.message!.formatted,
        sanitized.transaction,
        sanitized.exceptions!.single.value,
        sanitized.tags!['http_path'],
        sanitized.tags!['endpoint'],
        sanitized.contexts['extras'].toString(),
      ].join(' ');

      expect(serialized, isNot(contains(userId)));
      expect(serialized, isNot(contains(deckId)));
      expect(sanitized.tags!['http_path'], '/decks/:id');
      expect(
        sanitized.message!.formatted,
        'HTTP server_error: /users/:id/follow',
      );
      expect(sanitized.tags!['request_id'], clientRequestId);
      expect(sanitized.user, isNull);
    });

    test('D-23: o servidor não identifica o usuário em nenhum evento', () {
      final source = File('lib/observability.dart').readAsStringSync();
      expect(source, isNot(contains('setUser(')));
      expect(source, isNot(contains('SentryUser(')));
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
