import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_meter.dart';
import 'package:provider/provider.dart';

class _UsageFixture extends CommercialProvider {
  _UsageFixture(this.snapshot);

  final AiUsageSnapshot snapshot;

  @override
  bool get isLoaded => true;

  @override
  AiUsageSnapshot get usageSnapshot => snapshot;

  @override
  Future<void> load() async {}
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
      ChangeNotifierProvider<CommercialProvider>.value(
        value: provider,
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
}
