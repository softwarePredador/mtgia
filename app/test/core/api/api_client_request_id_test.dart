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
      final headers = ApiClient.appendRequestIdHeaders(
        const {'Authorization': 'Bearer token'},
        requestId: 'req-123',
      );

      expect(headers['Authorization'], equals('Bearer token'));
      expect(headers['x-request-id'], equals('req-123'));
    });
  });
}
