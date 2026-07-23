import 'dart:math';

import 'package:test/test.dart';

import '../lib/request_trace.dart';

void main() {
  group('request_trace', () {
    test('reuses inbound x-request-id when present', () {
      final requestId = resolveRequestId(const {'x-request-id': 'abc-123'});

      expect(requestId, equals('abc-123'));
    });

    test('generates request id when header is absent', () {
      final requestId = resolveRequestId(
        const {},
        now: DateTime.fromMillisecondsSinceEpoch(42),
        random: Random(7),
      );

      expect(requestId, startsWith('srv-'));
      expect(requestId, contains('-'));
    });

    test('matches headers case-insensitively', () {
      final requestId = resolveRequestId(const {'X-Request-Id': 'upper-case'});

      expect(requestId, equals('upper-case'));
    });

    test('rejects request ids that can inject log or response headers', () {
      final requestId = resolveRequestId(
        const {'x-request-id': 'trusted\r\nx-forged: value'},
        now: DateTime.fromMillisecondsSinceEpoch(42),
        random: Random(7),
      );

      expect(requestId, startsWith('srv-'));
      expect(requestId, isNot(contains('forged')));
    });

    test('rejects oversized and non-ASCII request ids', () {
      expect(isValidRequestId('a' * requestIdMaxLength), isTrue);
      expect(isValidRequestId('a' * (requestIdMaxLength + 1)), isFalse);
      expect(isValidRequestId('requisição-1'), isFalse);
    });

    test('normalizes an invalid generated prefix', () {
      final requestId = generateRequestId(
        prefix: 'bad prefix',
        now: DateTime.fromMillisecondsSinceEpoch(42),
        random: Random(7),
      );

      expect(requestId, startsWith('srv-'));
    });
  });
}
