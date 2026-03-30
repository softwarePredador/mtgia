import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

void main() {
  group('LifeCounterNativeTurnTrackerSheet', () {
    testWidgets('starts a tracked game and advances the draft turn', (
      tester,
    ) async {
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
                      result = await showLifeCounterNativeTurnTrackerSheet(
                        context,
                        initialSession: LifeCounterSession.initial(
                          playerCount: 4,
                        ),
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

      expect(find.text('Turn Tracker'), findsOneWidget);
      expect(find.text('Tracker is currently stopped.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Player 3'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Player 3'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Start Game'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-turn-tracker-start')),
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-start')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Player 3'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Next'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-turn-tracker-next')),
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-next')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.turnTrackerActive, isTrue);
      expect(result!.firstPlayerIndex, 2);
      expect(result!.currentTurnPlayerIndex, 3);
      expect(result!.currentTurnNumber, 1);
    });

    testWidgets('stops an active tracked game before applying', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      LifeCounterSession? result;

      final initialSession = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(
        firstPlayerIndex: 1,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 3,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTimerActive: true,
        turnTimerSeconds: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showLifeCounterNativeTurnTrackerSheet(
                        context,
                        initialSession: initialSession,
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

      await tester.scrollUntilVisible(
        find.text('Stop'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-turn-tracker-stop')),
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-stop')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.turnTrackerActive, isFalse);
      expect(result!.currentTurnPlayerIndex, isNull);
      expect(result!.firstPlayerIndex, isNull);
      expect(result!.currentTurnNumber, 1);
      expect(result!.turnTimerSeconds, 0);
    });
  });
}
