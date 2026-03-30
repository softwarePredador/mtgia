import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opens the ManaLoom-owned native card search on the live WebView path',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-card-search","source":"card_search_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Search'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-native-card-search-input')),
        findsOneWidget,
      );
      expect(find.text('SOL RING'), findsOneWidget);
    },
  );
}
