import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/observability/app_observability.dart';
import 'package:manaloom/core/services/performance_service.dart';
import 'package:manaloom/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checks Sentry and Firebase Performance release readiness', (
    tester,
  ) async {
    final smokeId =
        'release-observability-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

    await AppObservability.instance.bootstrap(() async {
      runApp(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('release-observability'))),
        ),
      );
    });

    await tester.pumpAndSettle();
    expect(find.text('release-observability'), findsOneWidget);
    final sentryDsnConfigured = AppObservability.instance.isEnabled;
    final sentryReady =
        sentryDsnConfigured ? await _waitForSentryReady(tester) : false;

    final eventId = await AppObservability.instance.captureException(
      Exception('MTGIA release observability smoke'),
      tags: {'source': 'release_observability_smoke', 'smoke_id': smokeId},
      extras: const {
        'runner': 'app/integration_test/release_observability_smoke_test.dart',
      },
    );
    await Future<void>.delayed(const Duration(seconds: 2));

    // ignore: avoid_print
    print(
      'SENTRY_RELEASE_SMOKE_RESULT='
      '${sentryDsnConfigured && sentryReady && eventId != null ? 'captured' : 'not_configured'}',
    );
    // ignore: avoid_print
    print('SENTRY_RELEASE_DSN_CONFIGURED=$sentryDsnConfigured');
    // ignore: avoid_print
    print('SENTRY_RELEASE_READY=$sentryReady');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PerformanceService.instance.init();
    await PerformanceService.instance.traceAsync(
      'release_observability_smoke',
      () async => Future<void>.delayed(const Duration(milliseconds: 25)),
    );

    // ignore: avoid_print
    print(
      'FIREBASE_PERFORMANCE_SMOKE_RESULT='
      '${PerformanceService.instance.isInitializedForTesting ? 'initialized' : 'not_initialized'}',
    );
    // ignore: avoid_print
    print(
      'FIREBASE_PERFORMANCE_COLLECTION_ENABLED='
      '${PerformanceService.instance.isEnabledForTesting}',
    );
  });
}

Future<bool> _waitForSentryReady(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (AppObservability.instance.isReadyForTesting) {
      return true;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  return AppObservability.instance.isReadyForTesting;
}
