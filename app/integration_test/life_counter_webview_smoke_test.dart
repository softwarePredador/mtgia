import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots the embedded life counter without host error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );

    await tester.pump();

    expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
    expect(find.text('Life counter unavailable'), findsNothing);

    await tester.pump(const Duration(seconds: 8));

    expect(find.text('Life counter unavailable'), findsNothing);
  });
}
