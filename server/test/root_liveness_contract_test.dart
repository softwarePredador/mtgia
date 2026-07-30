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

  test('basic health proves an explicitly isolated E2E process', () {
    final source = File('routes/health/index.dart').readAsStringSync();

    expect(source, contains("import '../../lib/e2e_validation_policy.dart'"));
    expect(source, contains("'service': 'mtgia-server'"));
    expect(
      source,
      contains("'e2e_isolated_runtime': isManaloomE2eIsolatedRuntime()"),
    );
  });
}
