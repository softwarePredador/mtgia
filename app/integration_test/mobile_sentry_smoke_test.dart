import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/observability/app_observability.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures a controlled Sentry smoke event', (tester) async {
    final smokeId =
        'mtgia-mobile-smoke-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

    await AppObservability.instance.bootstrap(() async {
      runApp(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('mobile-sentry-smoke'))),
        ),
      );
    });

    await tester.pumpAndSettle();
    expect(find.text('mobile-sentry-smoke'), findsOneWidget);
    expect(AppObservability.instance.isEnabled, isTrue);
    expect(await _waitForSentryReady(tester), isTrue);

    final eventId = await AppObservability.instance.captureException(
      Exception('MTGIA mobile sentry smoke'),
      tags: {'source': 'mobile_smoke', 'smoke_id': smokeId},
      extras: {
        'smoke_id': smokeId,
        'runner': 'app/integration_test/mobile_sentry_smoke_test.dart',
      },
    );

    // Dá tempo para o client despachar buffers assíncronos.
    await Future<void>.delayed(const Duration(seconds: 2));

    // O próprio teste não consegue consultar o Sentry; o script externo usa o smoke_id.
    // Mantemos o id no log da execução para o runbook.
    expect(eventId, isNotNull);
    // ignore: avoid_print
    print('SENTRY_MOBILE_EVENT_ID=$eventId');
    // ignore: avoid_print
    print('SENTRY_MOBILE_SMOKE_TAG=smoke_id:$smokeId');
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
