import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_gate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final kind in AiUsageKind.values) {
    testWidgets('shows paywall when ${kind.name} quota is exhausted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
      await provider.load();
      for (var i = 0; i < ManaLoomPlan.free.monthlyAiLimit; i += 1) {
        expect(
          await provider.consumeAiAction(AiUsageKind.deckGeneration),
          true,
        );
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<CommercialProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () =>
                              reserveAiActionOrShowPaywall(context, kind: kind),
                      child: const Text('run'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-paywall-dialog')), findsOneWidget);
      expect(find.text('${kind.label} precisa do Pro'), findsOneWidget);
      expect(
        find.byKey(const Key('ai-paywall-upgrade-button')),
        findsOneWidget,
      );
    });
  }
}
