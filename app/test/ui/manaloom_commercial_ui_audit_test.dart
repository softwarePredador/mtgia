import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/screens/checkout_screen.dart';
import 'package:manaloom/features/commercial/screens/plan_screen.dart';
import 'package:manaloom/features/commercial/screens/upgrade_screen.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_gate.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_meter.dart';
import 'package:provider/provider.dart';

import 'support/manaloom_ui_audit_harness.dart';

void main() {
  runManaLoomUiGoldenConfig(
    run: () {
      goldenTest(
        'commercial AI usage states keep the ManaLoom visual contract',
        fileName: 'manaloom_commercial_ai_usage_states',
        constraints: manaloomGoldenViewport,
        builder:
            () => GoldenTestGroup(
              columns: 1,
              scenarioConstraints: manaloomGoldenScenarioConstraints,
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

      goldenTest(
        'free beta plans screen keeps the ManaLoom visual contract',
        fileName: 'manaloom_commercial_beta_plans',
        constraints: manaloomFullScreenGoldenConstraints,
        builder:
            () => _commercialScreenShell(
              provider: _freeNearLimitProvider(),
              child: const PlanScreen(),
            ),
      );

      goldenTest(
        'free beta upgrade fallback keeps the ManaLoom visual contract',
        fileName: 'manaloom_commercial_beta_upgrade',
        constraints: manaloomFullScreenGoldenConstraints,
        builder:
            () => _commercialScreenShell(
              provider: _freeNearLimitProvider(),
              child: const UpgradeScreen(),
            ),
      );

      goldenTest(
        'free beta checkout fallback keeps the ManaLoom visual contract',
        fileName: 'manaloom_commercial_beta_checkout',
        constraints: manaloomFullScreenGoldenConstraints,
        builder:
            () => _commercialScreenShell(
              provider: _freeNearLimitProvider(),
              child: const CheckoutScreen(),
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
      setManaLoomMobileViewport(tester);

      await tester.pumpWidget(
        manaloomAccessibilityShell(
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
      await expectManaLoomBaselineAccessibility(tester);
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
    child: manaloomDecoratedAuditSurface(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Widget _commercialScreenShell({
  required CommercialProvider provider,
  required Widget child,
}) {
  return ChangeNotifierProvider<CommercialProvider>.value(
    value: provider,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: child,
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
