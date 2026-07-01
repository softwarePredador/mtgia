import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';

void main() {
  group('ApiClient request id', () {
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
  });
}
