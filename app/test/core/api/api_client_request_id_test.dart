import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';

class _MaxRecordingRandom implements Random {
  final calls = <int>[];

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) {
    calls.add(max);
    return max - 1;
  }
}

void main() {
  group('ApiClient request id', () {
    tearDown(() {
      ApiClient.resetForTesting(performanceUnavailable: true);
    });

    test('generates prefixed request ids', () {
      final requestId = ApiClient.generateRequestId(
        now: DateTime.fromMillisecondsSinceEpoch(42),
        random: Random(7),
      );

      expect(requestId, startsWith('mob-'));
      expect(requestId, contains('-'));
    });

    test('uses web-safe entropy chunks for request ids', () {
      final random = _MaxRecordingRandom();

      final requestId = ApiClient.generateRequestId(
        now: DateTime.fromMillisecondsSinceEpoch(42),
        random: random,
      );

      expect(random.calls, equals([0x10000, 0x10000]));
      expect(requestId, endsWith('-ffffffff'));
    });

    test('appends x-request-id without dropping headers', () {
      final headers = ApiClient.appendRequestIdHeaders(const {
        'Authorization': 'Bearer token',
      }, requestId: 'req-123');

      expect(headers['Authorization'], equals('Bearer token'));
      expect(headers['x-request-id'], equals('req-123'));
    });

    test('classifies 4xx and 5xx as reportable HTTP errors', () {
      expect(ApiClient.isReportableHttpStatus(200), isFalse);
      expect(ApiClient.isReportableHttpStatus(399), isFalse);
      expect(ApiClient.isReportableHttpStatus(400), isTrue);
      expect(ApiClient.isReportableHttpStatus(500), isTrue);
    });

    test('retries only transient GET server statuses', () {
      expect(ApiClient.isTransientGetStatus(500), isTrue);
      expect(ApiClient.isTransientGetStatus(502), isTrue);
      expect(ApiClient.isTransientGetStatus(503), isTrue);
      expect(ApiClient.isTransientGetStatus(504), isTrue);
      expect(ApiClient.isTransientGetStatus(400), isFalse);
      expect(ApiClient.isTransientGetStatus(501), isFalse);
    });

    test('uses longer timeout for AI endpoints', () {
      expect(
        ApiClient.timeoutForEndpoint('/ai/generate/jobs/job-1'),
        equals(const Duration(minutes: 2)),
      );
      expect(
        ApiClient.timeoutForEndpoint('/decks/1/analysis'),
        equals(const Duration(seconds: 15)),
      );
      expect(
        ApiClient.timeoutForEndpoint('/decks/1/ai-analysis'),
        equals(const Duration(minutes: 2)),
      );
      expect(
        ApiClient.timeoutForEndpoint('/decks/1/recommendations?force=true'),
        equals(const Duration(minutes: 2)),
      );
      expect(
        ApiClient.timeoutForEndpoint(
          '/ai/optimize',
          override: const Duration(seconds: 3),
        ),
        equals(const Duration(seconds: 3)),
      );
    });

    test('defaults to the public server when API_BASE_URL is absent', () {
      expect(
        ApiClient.baseUrl,
        equals('https://evolution-cartinhas.2ta7qx.easypanel.host'),
      );
      expect(ApiClient.baseUrl, isNot(contains('127.0.0.1')));
      expect(ApiClient.baseUrl, isNot(contains('10.0.2.2')));
    });

    test('sends x-request-id and stores the backend echo on GET', () async {
      String? outboundRequestId;
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        httpClient: MockClient((request) async {
          outboundRequestId = request.headers['x-request-id'];
          expect(outboundRequestId, isNotNull);
          expect(outboundRequestId, startsWith('mob-'));

          return http.Response(
            '{"status":"ready"}',
            200,
            headers: {
              'content-type': 'application/json',
              'x-request-id': outboundRequestId!,
            },
          );
        }),
      );

      final response = await ApiClient().get('/ready');

      expect(response.statusCode, 200);
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.requestId, outboundRequestId);
      expect(response.responseRequestId, outboundRequestId);
    });

    test('request logs use endpoint path instead of public host', () async {
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"status":"ready"}',
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      try {
        await ApiClient().get('/ready');
      } finally {
        debugPrint = previousDebugPrint;
      }

      final joined = logs.join('\n');
      expect(joined, contains('GET /ready'));
      expect(
        joined,
        isNot(contains('https://evolution-cartinhas.2ta7qx.easypanel.host')),
      );
    });

    test('keeps request correlation available on HTTP errors', () async {
      var attempts = 0;
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        httpClient: MockClient((request) async {
          attempts++;
          expect(request.headers['x-request-id'], startsWith('mob-'));
          if (attempts == 2) {
            expect(request.headers['x-retry-attempt'], '1');
          }
          return http.Response(
            '{"error":"maintenance"}',
            503,
            headers: const {
              'content-type': 'application/json',
              'x-request-id': 'backend-request-503',
            },
          );
        }),
      );

      final response = await ApiClient().get('/ready');

      expect(response.statusCode, 503);
      expect(response.requestId, startsWith('mob-'));
      expect(response.responseRequestId, 'backend-request-503');
      expect(response.data, containsPair('error', 'maintenance'));
      expect(attempts, 2);
    });

    test('recovers when a transient GET succeeds on retry', () async {
      var attempts = 0;
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        httpClient: MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            return http.Response('{"error":"temporary"}', 500);
          }
          expect(request.headers['x-retry-attempt'], '1');
          return http.Response(
            '{"status":"ready"}',
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      final response = await ApiClient().get('/ready');

      expect(response.statusCode, 200);
      expect(response.data, containsPair('status', 'ready'));
      expect(attempts, 2);
    });
  });
}
