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

    test('starts a game from the next active player when requested seat is out', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [40, 0, 40, 40],
      );

      final next = LifeCounterTurnTrackerEngine.startGame(
        session,
        startingPlayerIndex: 1,
      );

      expect(next.turnTrackerActive, isTrue);
      expect(next.firstPlayerIndex, 2);
      expect(next.currentTurnPlayerIndex, 2);
    });

    test('does not start a tracked game when no active players remain', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [0, 0, 0, 0],
      );

      final next = LifeCounterTurnTrackerEngine.startGame(
        session,
        startingPlayerIndex: 2,
        autoHighRoll: true,
        turnTimerActive: true,
      );

      expect(next.turnTrackerActive, isFalse);
      expect(next.turnTrackerOngoingGame, isFalse);
      expect(next.firstPlayerIndex, isNull);
      expect(next.currentTurnPlayerIndex, isNull);
      expect(next.currentTurnNumber, 1);
      expect(next.turnTimerActive, isFalse);
      expect(next.turnTimerSeconds, 0);
      expect(next.turnTrackerAutoHighRoll, isTrue);
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

    test('skips lethal players even before a manual special state is set', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        lives: const [40, 0, 40, 40],
        poison: const [0, 0, 10, 0],
      );

      final next = LifeCounterTurnTrackerEngine.nextTurn(session);

      expect(next.currentTurnPlayerIndex, 3);
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

    test('setStartingPlayer skips out players and picks the next active one', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [40, 0, 40, 40],
      );

      final updated = LifeCounterTurnTrackerEngine.setStartingPlayer(
        session,
        playerIndex: 1,
      );

      expect(updated.turnTrackerActive, isTrue);
      expect(updated.firstPlayerIndex, 2);
      expect(updated.currentTurnPlayerIndex, 2);
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

    test('sanitizes current and starting players when they are out', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 1,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 3,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        lives: const [40, 0, 0, 40],
      );

      final sanitized = LifeCounterTurnTrackerEngine
          .sanitizeTrackerPointersForActivePlayers(session);

      expect(sanitized.firstPlayerIndex, 3);
      expect(sanitized.currentTurnPlayerIndex, 3);
      expect(sanitized.currentTurnNumber, 3);
    });

    test('clears tracker pointers when no active players remain', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        firstPlayerIndex: 2,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 5,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        lives: const [0, 0, 0, 0],
      );

      final sanitized = LifeCounterTurnTrackerEngine
          .sanitizeTrackerPointersForActivePlayers(session);

      expect(sanitized.firstPlayerIndex, isNull);
      expect(sanitized.currentTurnPlayerIndex, isNull);
      expect(sanitized.turnTrackerActive, isTrue);
      expect(sanitized.currentTurnNumber, 5);
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
