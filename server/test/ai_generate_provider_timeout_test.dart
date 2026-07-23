import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/ai_generate_performance_support.dart';
import '../routes/ai/generate/index.dart' as generate_route;

void main() {
  group('AI generate provider timeout', () {
    test('enforces the configured provider deadline', () async {
      final pendingResponse = Completer<http.Response>();

      await expectLater(
        generate_route.executeAiGenerateProviderRequest(
          send: () => pendingResponse.future,
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('returns a non-cacheable fail-closed gateway timeout', () async {
      final cacheKey = buildAiGenerateCacheKey(
        prompt: 'provider timeout ${DateTime.now().microsecondsSinceEpoch}',
        format: 'commander',
      );
      expect(readAiGenerateCache(cacheKey), isNull);

      final response = generate_route.buildAiGenerateProviderTimeoutResponse(
        cacheKey: cacheKey,
        timings: const {
          'cache_lookup_ms': 1,
          'openai_ms': 12000,
          'openai_timeout_ms': 12000,
          'total_ms': 12010,
        },
        timeout: const Duration(seconds: 12),
        timeoutKey: 'OPENAI_TIMEOUT_GENERATE_SECONDS',
        referenceGuidanceBudget: false,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final cache = (body['cache'] as Map).cast<String, dynamic>();
      final provider = (body['provider'] as Map).cast<String, dynamic>();

      expect(response.statusCode, HttpStatus.gatewayTimeout);
      expect(response.statusCode, isNot(HttpStatus.ok));
      expect(response.headers['cache-control'], 'no-store');
      expect(body['error_code'], 'provider_timeout');
      expect(body['outcome_code'], 'provider_unavailable');
      expect(body['ai_generation_timed_out'], isTrue);
      expect(body['retryable'], isTrue);
      expect(body['can_save'], isFalse);
      expect(body['learning_eligible'], isFalse);
      expect(body['generated_deck'], isNull);
      expect(body.containsKey('is_mock'), isFalse);
      expect(cache['hit'], isFalse);
      expect(cache['cache_key'], cacheKey);
      expect(cache.containsKey('ttl_seconds'), isFalse);
      expect(provider, {
        'name': 'openai',
        'operation': 'generate',
        'status': 'timeout',
        'timeout_ms': 12000,
        'timeout_key': 'OPENAI_TIMEOUT_GENERATE_SECONDS',
        'reference_guidance_budget': false,
      });
      expect(readAiGenerateCache(cacheKey), isNull);
    });

    test('timeout route branch cannot build or cache a mock success', () {
      final source = File('routes/ai/generate/index.dart').readAsStringSync();
      final timeoutStart = source.indexOf('} on TimeoutException {');
      final timeoutEnd = source.indexOf('} catch (error) {', timeoutStart);

      expect(timeoutStart, isNonNegative);
      expect(timeoutEnd, greaterThan(timeoutStart));

      final timeoutBranch = source.substring(timeoutStart, timeoutEnd);
      expect(
        timeoutBranch,
        contains('return buildAiGenerateProviderTimeoutResponse('),
      );
      expect(timeoutBranch, contains("'provider_timeout'"));
      expect(timeoutBranch, isNot(contains('_buildMockGenerateResponse(')));
      expect(timeoutBranch, isNot(contains('writeAiGenerateCache(')));
      expect(timeoutBranch, isNot(contains('isMock: false')));
      expect(timeoutBranch, isNot(contains('return Response.json(body:')));
    });
  });
}
