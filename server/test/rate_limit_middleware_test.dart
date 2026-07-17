import 'dart:async';

import 'package:test/test.dart';

import '../lib/auth_runtime_policy.dart';
import '../lib/rate_limit_middleware.dart';

void main() {
  group('RateLimiter', () {
    test('does not trust forwarded IP without an explicit proxy contract', () {
      final clientId = RateLimiter.buildClientIdentifierFromHeaders({
        'X-Forwarded-For': '203.0.113.10, 10.0.0.1',
      });

      expect(clientId, equals('anonymous'));
    });

    test('trusted proxy identity is selected from the right', () {
      final resolution = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': 'spoofed, 203.0.113.10, 10.0.0.1'},
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '2',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
        },
        remoteAddress: '10.0.0.42',
      );

      expect(resolution.identifier, equals('203.0.113.10'));
    });

    test(
      'builds a fingerprint fallback instead of anonymous when headers exist',
      () {
        final clientId = RateLimiter.buildClientIdentifierFromHeaders({
          'User-Agent': 'Mozilla/5.0',
          'Accept-Language': 'pt-BR',
          'Host': 'localhost:8080',
        });

        expect(clientId, startsWith('fingerprint:'));
      },
    );

    test('keeps anonymous only when no identifying headers exist', () {
      final clientId = RateLimiter.buildClientIdentifierFromHeaders(const {});

      expect(clientId, equals('anonymous'));
    });

    test('AI limits authenticated traffic by user instead of shared IP', () {
      expect(
        buildAiRateLimitIdentifier(
          userId: ' user-123 ',
          headers: const {'X-Forwarded-For': '203.0.113.10'},
        ),
        'user:user-123',
      );
      expect(
        buildAiRateLimitIdentifier(
          userId: null,
          headers: const {'X-Forwarded-For': '203.0.113.10'},
        ),
        'anonymous',
      );
    });

    test('allows requests up to limit then blocks', () {
      final limiter = RateLimiter(maxRequests: 2, windowSeconds: 60);

      expect(limiter.isAllowed('client-a'), isTrue);
      expect(limiter.isAllowed('client-a'), isTrue);
      expect(limiter.isAllowed('client-a'), isFalse);
    });

    test('isolates limits by client identifier', () {
      final limiter = RateLimiter(maxRequests: 1, windowSeconds: 60);

      expect(limiter.isAllowed('client-a'), isTrue);
      expect(limiter.isAllowed('client-b'), isTrue);
      expect(limiter.isAllowed('client-a'), isFalse);
      expect(limiter.isAllowed('client-b'), isFalse);
    });

    test('window expiration re-allows requests', () async {
      final limiter = RateLimiter(maxRequests: 1, windowSeconds: 1);

      expect(limiter.isAllowed('client-c'), isTrue);
      expect(limiter.isAllowed('client-c'), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(limiter.isAllowed('client-c'), isTrue);
    });

    test('cleanup removes stale entries from memory', () async {
      final limiter = RateLimiter(maxRequests: 1, windowSeconds: 1);

      expect(limiter.isAllowed('client-d'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 2200));

      limiter.cleanup();

      expect(limiter.isAllowed('client-d'), isTrue);
    });

    test('builds structured 429 body with retry metadata', () {
      final body = buildRateLimitResponseBody(
        error: 'Too Many AI Requests',
        message: 'Aguarde 1 minuto.',
        retryAfterSeconds: 60,
        bucket: 'ai',
        backend: 'in_memory_fallback',
      );

      expect(body['retry_after'], equals(60));
      expect(body['retry_after_seconds'], equals(60));
      expect(body['retry_after_ms'], equals(60000));
      expect(body['rate_limit_bucket'], equals('ai'));
      expect(body['rate_limit_scope'], equals('client'));
      expect(body['rate_limit_backend'], equals('in_memory_fallback'));
    });

    test('can identify an authenticated user rate-limit scope', () {
      final body = buildRateLimitResponseBody(
        error: 'Too Many AI Requests',
        message: 'Aguarde 1 minuto.',
        retryAfterSeconds: 60,
        bucket: 'ai',
        scope: 'user',
      );

      expect(body['rate_limit_scope'], 'user');
    });

    test('exposes a dedicated high-frequency AI polling middleware', () {
      expect(aiPollingRateLimit(), isNotNull);
    });

    test('builds 429 headers with remaining zero and reset', () {
      final headers = buildRateLimitHeaders(
        maxRequests: 10,
        windowSeconds: 60,
        retryAfterSeconds: 45,
      );

      expect(headers['Retry-After'], equals('45'));
      expect(headers['X-RateLimit-Limit'], equals('10'));
      expect(headers['X-RateLimit-Remaining'], equals('0'));
      expect(headers['X-RateLimit-Window'], equals('60'));
      expect(headers['X-RateLimit-Reset'], equals('45'));
    });
  });
}
