import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_turn_tracker_engine.dart';

void main() {
  group('LifeCounterTurnTrackerEngine', () {
    test('starts a game with the requested starting player', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final next = LifeCounterTurnTrackerEngine.startGame(
        session,
        startingPlayerIndex: 2,
        autoHighRoll: true,
        turnTimerActive: true,
      );

      expect(next.turnTrackerActive, isTrue);
      expect(next.turnTrackerOngoingGame, isTrue);
      expect(next.turnTrackerAutoHighRoll, isTrue);
      expect(next.firstPlayerIndex, 2);
      expect(next.currentTurnPlayerIndex, 2);
      expect(next.currentTurnNumber, 1);
      expect(next.turnTimerActive, isTrue);
      expect(next.turnTimerSeconds, 0);
    });

    test('advances to the next alive player and wraps on starting player', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 1,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 4,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
      );

      final next = LifeCounterTurnTrackerEngine.nextTurn(session);

      expect(next.currentTurnPlayerIndex, 1);
      expect(next.currentTurnNumber, 5);
      expect(next.turnTimerSeconds, 0);
    });

    test('skips dead players when advancing', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        playerSpecialStates: const [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.deckedOut,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
        ],
      );

      final next = LifeCounterTurnTrackerEngine.nextTurn(session);

      expect(next.currentTurnPlayerIndex, 2);
      expect(next.currentTurnNumber, 1);
    });

    test(
      'moves back and decrements turn when crossing the starting player',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          firstPlayerIndex: 1,
          currentTurnPlayerIndex: 1,
          currentTurnNumber: 3,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
        );

        final previous = LifeCounterTurnTrackerEngine.previousTurn(session);

        expect(previous.currentTurnPlayerIndex, 0);
        expect(previous.currentTurnNumber, 2);
        expect(previous.turnTimerSeconds, 0);
      },
    );

    test('reassigns starting player when rewinding on turn one', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 2,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
      );

      final previous = LifeCounterTurnTrackerEngine.previousTurn(session);

      expect(previous.firstPlayerIndex, 1);
      expect(previous.currentTurnPlayerIndex, 1);
      expect(previous.currentTurnNumber, 1);
    });

    test('ticks timer only when tracker and timer are active', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        turnTrackerActive: true,
        turnTimerActive: true,
        turnTimerSeconds: 15,
      );

      final next = LifeCounterTurnTrackerEngine.tickTurnTimer(
        session,
        deltaSeconds: 5,
      );

      expect(next.turnTimerSeconds, 20);

      final inactive = LifeCounterTurnTrackerEngine.tickTurnTimer(
        session.copyWith(turnTimerActive: false),
        deltaSeconds: 5,
      );
      expect(inactive.turnTimerSeconds, 15);
    });

    test('stops game and clears active turn pointers', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 2,
        currentTurnPlayerIndex: 3,
        currentTurnNumber: 7,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTimerSeconds: 45,
      );

      final stopped = LifeCounterTurnTrackerEngine.stopGame(session);

      expect(stopped.turnTrackerActive, isFalse);
      expect(stopped.turnTrackerOngoingGame, isFalse);
      expect(stopped.firstPlayerIndex, isNull);
      expect(stopped.currentTurnPlayerIndex, isNull);
      expect(stopped.currentTurnNumber, 1);
      expect(stopped.turnTimerSeconds, 0);
    });
  });
}
