import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/auth_runtime_policy.dart';
import '../lib/rate_limit_middleware.dart';

void main() {
  group('RateLimiter', () {
    test('classifies transport peers without exposing address values', () {
      expect(classifyRateLimitTransportPeer(null), 'missing');
      expect(classifyRateLimitTransportPeer('not-an-ip'), 'invalid');
      expect(classifyRateLimitTransportPeer('10.0.0.42'), 'ipv4');
      expect(classifyRateLimitTransportPeer('2001:db8::1'), 'ipv6');
      expect(
        classifyRateLimitTransportPeer('::ffff:10.0.0.42'),
        'ipv4_mapped_ipv6',
      );
    });

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

    test(
      'GET /auth/me neither consumes nor suffers the credential bucket',
      () async {
        final limiter = RateLimiter(maxRequests: 5, windowSeconds: 60);
        final protectedHandler = authRateLimit(
          limiterOverrideForTesting: limiter,
        )((_) => Response.json(body: const {'ok': true}));
        const client = 'rate-limit-test-auth-me';

        for (var index = 0; index < 12; index++) {
          final response = await protectedHandler(
            _rateLimitContext(HttpMethod.get, '/auth/me', client: client),
          );
          expect(response.statusCode, HttpStatus.ok);
        }

        for (var index = 0; index < 5; index++) {
          final response = await protectedHandler(
            _rateLimitContext(HttpMethod.post, '/auth/login', client: client),
          );
          expect(response.statusCode, HttpStatus.ok);
        }

        final blockedLogin = await protectedHandler(
          _rateLimitContext(HttpMethod.post, '/auth/login', client: client),
        );
        expect(blockedLogin.statusCode, HttpStatus.tooManyRequests);

        final sessionReadAfterBlock = await protectedHandler(
          _rateLimitContext(HttpMethod.get, '/auth/me', client: client),
        );
        expect(sessionReadAfterBlock.statusCode, HttpStatus.ok);
      },
    );

    test('POST /auth/register remains protected by the auth bucket', () async {
      final limiter = RateLimiter(maxRequests: 5, windowSeconds: 60);
      final protectedHandler = authRateLimit(
        limiterOverrideForTesting: limiter,
      )((_) => Response.json(body: const {'ok': true}));
      const client = 'rate-limit-test-register';

      for (var index = 0; index < 5; index++) {
        final response = await protectedHandler(
          _rateLimitContext(HttpMethod.post, '/auth/register', client: client),
        );
        expect(response.statusCode, HttpStatus.ok);
      }

      final blocked = await protectedHandler(
        _rateLimitContext(HttpMethod.post, '/auth/register', client: client),
      );
      final body = jsonDecode(await blocked.body()) as Map<String, dynamic>;

      expect(blocked.statusCode, HttpStatus.tooManyRequests);
      expect(body['rate_limit_bucket'], 'auth');
      expect(body['rate_limit_backend'], 'in_memory_fallback');
    });

    test('account recovery and session rotation share the auth bucket', () {
      for (final path in const [
        '/auth/forgot-password',
        '/auth/reset-password',
        '/auth/change-password',
        '/auth/revoke-sessions',
      ]) {
        expect(
          isAuthCredentialAttempt(
            Request('POST', Uri.parse('http://localhost$path')),
          ),
          isTrue,
          reason: path,
        );
      }
      expect(
        isAuthCredentialAttempt(
          Request('GET', Uri.parse('http://localhost/auth/forgot-password')),
        ),
        isFalse,
      );
    });
  });
}

RequestContext _rateLimitContext(
  HttpMethod method,
  String path, {
  required String client,
}) => _RateLimitRequestContext(
  Request(
    method.name.toUpperCase(),
    Uri.parse('http://localhost$path'),
    headers: {'user-agent': client, 'accept-language': 'pt-BR'},
  ),
);

class _RateLimitRequestContext implements RequestContext {
  const _RateLimitRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() =>
      throw StateError('Distributed limiter is disabled in focused tests.');
}
