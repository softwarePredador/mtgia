import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_game_modes_sheet.dart';

class _GameModesHost extends StatelessWidget {
  const _GameModesHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showLifeCounterNativeGameModesSheet(context),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('shows the owned game modes sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _GameModesHost(),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Game Modes'), findsOneWidget);
    expect(find.text('Planechase'), findsOneWidget);
    expect(find.text('Archenemy'), findsOneWidget);
    expect(find.text('Bounty'), findsOneWidget);
    expect(find.text('Lotus runtime'), findsNWidgets(3));
  });
}
