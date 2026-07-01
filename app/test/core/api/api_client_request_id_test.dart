import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';

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
        ApiClient.timeoutForEndpoint(
          '/ai/optimize',
          override: const Duration(seconds: 3),
        ),
        equals(const Duration(seconds: 3)),
      );
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

    test('keeps request correlation available on HTTP errors', () async {
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        httpClient: MockClient((request) async {
          expect(request.headers['x-request-id'], startsWith('mob-'));
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
    });
  });
}
