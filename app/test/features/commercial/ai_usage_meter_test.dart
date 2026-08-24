import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_meter.dart';
import 'package:provider/provider.dart';

class _UsageFixture extends CommercialProvider {
  _UsageFixture(this.snapshot, {this.loaded = true});

  final AiUsageSnapshot snapshot;
  final bool loaded;
  int loadCalls = 0;

  @override
  bool get isLoaded => loaded;

  @override
  AiUsageSnapshot get usageSnapshot => snapshot;

  @override
  Future<void> load() async => loadCalls += 1;
}

void main() {
  testWidgets('AI quota consistently presents the used-actions model', (
    tester,
  ) async {
    final provider = _UsageFixture(
      const AiUsageSnapshot(
        plan: ManaLoomPlan.free,
        periodKey: '2026-08',
        used: 118,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReleaseCapabilitiesProvider>(
            create: (_) => ReleaseCapabilitiesProvider.seeded(const {
              ReleaseCapability.aiAnalyzeOptimizeAdvisory,
            }),
          ),
          ChangeNotifierProvider<CommercialProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: AiUsageMeter()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ações usadas'), findsOneWidget);
    expect(
      find.text('118 de 120 usadas · 2 disponíveis em 2026-08.'),
      findsOneWidget,
    );
    expect(find.textContaining('restantes'), findsNothing);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('ai-usage-progress')),
    );
    expect(progress.value, closeTo(118 / 120, 0.0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all-off policy hides the AI balance without loading it', (
    tester,
  ) async {
    final provider = _UsageFixture(
      const AiUsageSnapshot(
        plan: ManaLoomPlan.free,
        periodKey: '2026-08',
        used: 0,
      ),
      loaded: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReleaseCapabilitiesProvider>(
            create: (_) => ReleaseCapabilitiesProvider.seeded(const {}),
          ),
          ChangeNotifierProvider<CommercialProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: Scaffold(body: AiUsageMeter())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-usage-meter')), findsNothing);
    expect(find.textContaining('disponíveis'), findsNothing);
    expect(provider.loadCalls, 0);
  });
}
