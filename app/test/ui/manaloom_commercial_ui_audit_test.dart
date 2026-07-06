import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_gate.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_meter.dart';
import 'package:provider/provider.dart';

void main() {
  final goldenConfig = AlchemistConfig.current().merge(
    AlchemistConfig(
      theme: AppTheme.darkTheme,
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(
        obscureText: true,
        renderShadows: false,
        diffThreshold: 0.001,
      ),
    ),
  );

  AlchemistConfig.runWithConfig(
    config: goldenConfig,
    run: () {
      goldenTest(
        'commercial AI usage states keep the ManaLoom visual contract',
        fileName: 'manaloom_commercial_ai_usage_states',
        constraints: const BoxConstraints(maxWidth: 430),
        builder:
            () => GoldenTestGroup(
              columns: 1,
              scenarioConstraints: const BoxConstraints(maxWidth: 390),
              children: [
                GoldenTestScenario(
                  name: 'Free near limit',
                  child: _meterScenario(_freeNearLimitProvider()),
                ),
                GoldenTestScenario(
                  name: 'Free exhausted paywall',
                  child: _paywallScenario(_freeExhaustedProvider()),
                ),
                GoldenTestScenario(
                  name: 'Pro active usage',
                  child: _meterScenario(_proActiveProvider()),
                ),
              ],
            ),
      );
    },
  );

  testWidgets('commercial AI usage surface passes baseline accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => AccessibilityTools.debugRunCheckersInTests = false);
    AccessibilityTools.debugRunCheckersInTests = true;

    try {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _accessibilityShell(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _meterScenario(_freeNearLimitProvider()),
              const SizedBox(height: 16),
              _paywallScenario(_freeExhaustedProvider()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-usage-meter')), findsOneWidget);
      expect(find.byKey(const Key('ai-paywall-dialog')), findsOneWidget);
      expect(find.byIcon(Icons.accessibility_new), findsNothing);
      expect(find.byIcon(Icons.build), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

Widget _meterScenario(CommercialProvider provider) {
  return _commercialShell(provider: provider, child: const AiUsageMeter());
}

Widget _paywallScenario(CommercialProvider provider) {
  return _commercialShell(
    provider: provider,
    child: AiPaywallDialog(
      kind: AiUsageKind.deckOptimization,
      provider: provider,
    ),
  );
}

Widget _commercialShell({
  required CommercialProvider provider,
  required Widget child,
}) {
  return ChangeNotifierProvider<CommercialProvider>.value(
    value: provider,
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Widget _accessibilityShell({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    builder:
        (context, appChild) => AccessibilityTools(
          logLevel: LogLevel.none,
          checkFontOverflows: true,
          enableButtonsDrag: false,
          testingToolsConfiguration: const TestingToolsConfiguration(
            enabled: false,
          ),
          child: appChild,
        ),
    home: Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: child,
      ),
    ),
  );
}

_CommercialProviderFixture _freeNearLimitProvider() {
  return _CommercialProviderFixture(
    snapshot: const AiUsageSnapshot(
      plan: ManaLoomPlan.free,
      periodKey: '2026-07',
      used: 118,
    ),
  );
}

_CommercialProviderFixture _freeExhaustedProvider() {
  return _CommercialProviderFixture(
    snapshot: const AiUsageSnapshot(
      plan: ManaLoomPlan.free,
      periodKey: '2026-07',
      used: 120,
    ),
  );
}

_CommercialProviderFixture _proActiveProvider() {
  return _CommercialProviderFixture(
    snapshot: const AiUsageSnapshot(
      plan: ManaLoomPlan.pro,
      periodKey: '2026-07',
      used: 1120,
    ),
  );
}

class _CommercialProviderFixture extends CommercialProvider {
  _CommercialProviderFixture({required AiUsageSnapshot snapshot})
    : _snapshot = snapshot,
      super(now: () => DateTime(2026, 7, 1));

  final AiUsageSnapshot _snapshot;

  @override
  bool get isLoaded => true;

  @override
  AiUsageSnapshot get usageSnapshot => _snapshot;

  @override
  ManaLoomPlanTier get tier => _snapshot.plan.tier;

  @override
  ManaLoomPlan get plan => _snapshot.plan;

  @override
  int get monthlyAiLimit => _snapshot.limit;

  @override
  int get remainingAiActions => _snapshot.remaining;

  @override
  Future<void> load() async {}
}
