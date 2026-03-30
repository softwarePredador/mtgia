import 'life_counter_session.dart';

class LifeCounterTurnTrackerEngine {
  LifeCounterTurnTrackerEngine._();

  static LifeCounterSession startGame(
    LifeCounterSession session, {
    required int startingPlayerIndex,
    bool autoHighRoll = false,
    bool turnTimerActive = false,
  }) {
    final normalizedStartingPlayer = _normalizePlayerIndex(
      session,
      startingPlayerIndex,
    );

    return session.copyWith(
      firstPlayerIndex: normalizedStartingPlayer,
      currentTurnPlayerIndex: normalizedStartingPlayer,
      currentTurnNumber: 1,
      turnTrackerActive: true,
      turnTrackerOngoingGame: true,
      turnTrackerAutoHighRoll: autoHighRoll,
      turnTimerActive: turnTimerActive,
      turnTimerSeconds: 0,
    );
  }

  static LifeCounterSession stopGame(LifeCounterSession session) {
    return session.copyWith(
      clearFirstPlayerIndex: true,
      clearCurrentTurnPlayerIndex: true,
      currentTurnNumber: 1,
      turnTrackerActive: false,
      turnTrackerOngoingGame: false,
      turnTimerSeconds: 0,
    );
  }

  static LifeCounterSession nextTurn(LifeCounterSession session) {
    if (!session.turnTrackerActive) {
      return session;
    }

    final currentIndex = _resolveActivePlayerIndex(session);
    final nextIndex = _findNextAlivePlayer(session, currentIndex);
    final startingIndex = _resolveStartingPlayerIndex(session);
    final wrapped = nextIndex == startingIndex && nextIndex != currentIndex;

    return session.copyWith(
      currentTurnPlayerIndex: nextIndex,
      currentTurnNumber:
          wrapped ? session.currentTurnNumber + 1 : session.currentTurnNumber,
      turnTrackerOngoingGame: true,
      turnTimerSeconds: 0,
    );
  }

  static LifeCounterSession previousTurn(LifeCounterSession session) {
    if (!session.turnTrackerActive) {
      return session;
    }

    final currentIndex = _resolveActivePlayerIndex(session);
    final previousIndex = _findPreviousAlivePlayer(session, currentIndex);
    final startingIndex = _resolveStartingPlayerIndex(session);

    if (session.currentTurnNumber <= 1 && currentIndex == startingIndex) {
      return session.copyWith(
        firstPlayerIndex: previousIndex,
        currentTurnPlayerIndex: previousIndex,
        currentTurnNumber: 1,
        turnTrackerOngoingGame: true,
        turnTimerSeconds: 0,
      );
    }

    final crossedStartingPlayer = currentIndex == startingIndex;
    return session.copyWith(
      currentTurnPlayerIndex: previousIndex,
      currentTurnNumber:
          crossedStartingPlayer
              ? (session.currentTurnNumber - 1).clamp(1, 9999)
              : session.currentTurnNumber,
      turnTrackerOngoingGame: true,
      turnTimerSeconds: 0,
    );
  }

  static LifeCounterSession setStartingPlayer(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final normalizedIndex = _normalizePlayerIndex(session, playerIndex);
    return session.copyWith(
      firstPlayerIndex: normalizedIndex,
      currentTurnPlayerIndex: normalizedIndex,
      currentTurnNumber: 1,
      turnTrackerActive: true,
      turnTrackerOngoingGame: true,
      turnTimerSeconds: 0,
    );
  }

  static LifeCounterSession setTurnTimerActive(
    LifeCounterSession session, {
    required bool isActive,
  }) {
    return session.copyWith(
      turnTimerActive: isActive,
      turnTimerSeconds: isActive ? session.turnTimerSeconds : 0,
    );
  }

  static LifeCounterSession tickTurnTimer(
    LifeCounterSession session, {
    int deltaSeconds = 1,
  }) {
    if (!session.turnTrackerActive || !session.turnTimerActive) {
      return session;
    }

    final safeDelta = deltaSeconds.clamp(0, 864000);
    if (safeDelta == 0) {
      return session;
    }

    return session.copyWith(
      turnTimerSeconds: (session.turnTimerSeconds + safeDelta).clamp(0, 864000),
    );
  }

  static int _resolveActivePlayerIndex(LifeCounterSession session) {
    final current = session.currentTurnPlayerIndex;
    if (current != null) {
      return _normalizePlayerIndex(session, current);
    }

    return _resolveStartingPlayerIndex(session);
  }

  static int _resolveStartingPlayerIndex(LifeCounterSession session) {
    final starting = session.firstPlayerIndex;
    if (starting != null) {
      return _normalizePlayerIndex(session, starting);
    }

    return _findNextAlivePlayer(session, 0, includeCurrent: true);
  }

  static int _findNextAlivePlayer(
    LifeCounterSession session,
    int startIndex, {
    bool includeCurrent = false,
  }) {
    final playerCount = session.playerCount;
    var candidate =
        includeCurrent ? startIndex : (startIndex + 1) % playerCount;
    for (var steps = 0; steps < playerCount; steps += 1) {
      if (_isAlive(session, candidate)) {
        return candidate;
      }
      candidate = (candidate + 1) % playerCount;
    }

    return _normalizePlayerIndex(session, startIndex);
  }

  static int _findPreviousAlivePlayer(
    LifeCounterSession session,
    int startIndex,
  ) {
    final playerCount = session.playerCount;
    var candidate = (startIndex - 1 + playerCount) % playerCount;
    for (var steps = 0; steps < playerCount; steps += 1) {
      if (_isAlive(session, candidate)) {
        return candidate;
      }
      candidate = (candidate - 1 + playerCount) % playerCount;
    }

    return _normalizePlayerIndex(session, startIndex);
  }

  static bool _isAlive(LifeCounterSession session, int playerIndex) {
    return session.playerSpecialStates[playerIndex] ==
        LifeCounterPlayerSpecialState.none;
  }

  static int _normalizePlayerIndex(
    LifeCounterSession session,
    int playerIndex,
  ) {
    if (session.playerCount <= 0) {
      return 0;
    }
    return playerIndex.clamp(0, session.playerCount - 1);
  }
}
