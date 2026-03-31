import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_dice_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

void main() {
  group('LifeCounterNativeDiceSheet', () {
    testWidgets('runs high roll and applies the updated session', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      LifeCounterSession? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showLifeCounterNativeDiceSheet(
                        context,
                        initialSession: LifeCounterSession.initial(
                          playerCount: 4,
                        ),
                        random: Random(7),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Dice Tools'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-dice-high-roll')),
      );
      await tester.pumpAndSettle();

      expect(find.text('High Roll Board'), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-native-dice-apply')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.lastHighRolls.whereType<int>().length, 4);
      expect(result!.lastTableEvent, startsWith('High Roll'));
    });

    testWidgets(
      'disables player-selecting dice actions when no active players remain',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        LifeCounterSession? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        result = await showLifeCounterNativeDiceSheet(
                          context,
                          initialSession: LifeCounterSession.initial(
                            playerCount: 4,
                          ).copyWith(lives: const [0, 0, 0, 0]),
                          random: Random(7),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.textContaining('No active players remain on the table.'), findsOneWidget);

        final highRollButton = tester.widget<FilledButton>(
          find.byKey(const Key('life-counter-native-dice-high-roll')),
        );
        final firstPlayerButton = tester.widget<OutlinedButton>(
          find.byKey(const Key('life-counter-native-dice-first-player')),
        );
        expect(highRollButton.onPressed, isNull);
        expect(firstPlayerButton.onPressed, isNull);

        await tester.tap(find.byKey(const Key('life-counter-native-dice-apply')));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.firstPlayerIndex, isNull);
        expect(result!.lastHighRolls.whereType<int>(), isEmpty);
      },
    );
  });
}
