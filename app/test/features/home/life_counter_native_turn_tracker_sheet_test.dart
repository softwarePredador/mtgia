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

      expect(find.text('Controle de turnos'), findsOneWidget);
      expect(find.text('O controle de turnos está parado.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Jogador 3'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Jogador 3'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Iniciar partida'),
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

      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Jogador 3'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Avançar'),
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
        find.text('Encerrar'),
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

    testWidgets('sanitizes invalid tracked players when opening the sheet', (
      tester,
    ) async {
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
        lives: const [40, 0, 0, 40],
        playerEliminationReasons: const [
          LifeCounterPlayerEliminationReason.none,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.none,
        ],
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

      expect(find.text('Jogador 4'), findsWidgets);

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.firstPlayerIndex, 3);
      expect(result!.currentTurnPlayerIndex, 3);
      expect(result!.currentTurnNumber, 3);
    });

    testWidgets(
      'disables starting a tracked game when no active players remain',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        LifeCounterSession? result;

        final initialSession = LifeCounterSession.initial(
          playerCount: 4,
        ).copyWith(
          lives: const [0, 0, 0, 0],
          playerEliminationReasons:
              List<LifeCounterPlayerEliminationReason>.filled(
                4,
                LifeCounterPlayerEliminationReason.life,
              ),
          turnTrackerActive: false,
          turnTrackerOngoingGame: false,
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

        expect(find.text('Nenhum jogador ativo'), findsWidgets);

        final startButton = tester.widget<FilledButton>(
          find.byKey(const Key('life-counter-native-turn-tracker-start')),
        );
        expect(startButton.onPressed, isNull);

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-apply')),
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.firstPlayerIndex, isNull);
        expect(result!.currentTurnPlayerIndex, isNull);
        expect(result!.turnTrackerActive, isFalse);
      },
    );
  });
}
