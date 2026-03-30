import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_quick_actions_sheet.dart';

class _QuickActionsHost extends StatelessWidget {
  const _QuickActionsHost({required this.onResult});

  final ValueChanged<LifeCounterQuickAction?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showLifeCounterNativeQuickActionsSheet(
              context,
            );
            onResult(result);
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('returns the selected action from the quick actions sheet', (
    tester,
  ) async {
    LifeCounterQuickAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _QuickActionsHost(onResult: (value) => result = value),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('life-counter-native-quick-actions-dice')),
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterQuickAction.dice);
  });
}
