import 'dart:io';

import 'package:test/test.dart';

import '../routes/_middleware.dart';

void main() {
  test('process liveness paths do not require PostgreSQL', () {
    expect(isDatabaseIndependentHealthPath('/health'), isTrue);
    expect(isDatabaseIndependentHealthPath('/health/'), isTrue);
    expect(isDatabaseIndependentHealthPath('/health/live'), isTrue);
    expect(isDatabaseIndependentHealthPath('/health/live/'), isTrue);
    expect(isDatabaseIndependentHealthPath('/health/ready'), isFalse);
    expect(isDatabaseIndependentHealthPath('/ready'), isFalse);
    expect(isDatabaseIndependentHealthPath('/health/metrics'), isFalse);
  });

  test('root middleware only initializes dependencies outside liveness', () {
    final source = File('routes/_middleware.dart').readAsStringSync();

    expect(source, contains('if (!processLiveness)'));
    expect(source, contains('await ensureObservabilityInitialized();'));
    expect(source, contains('await _db.connect();'));
    expect(source, contains('processLiveness\n              ? await handler'));
  });
}
