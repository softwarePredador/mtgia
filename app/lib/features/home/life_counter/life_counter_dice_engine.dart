import 'dart:math';

import 'life_counter_session.dart';

class LifeCounterDiceEngine {
  LifeCounterDiceEngine._();

  static LifeCounterSession runCoinFlip(
    LifeCounterSession session, {
    Random? random,
  }) {
    final result = (random ?? Random()).nextBool() ? 'Cara' : 'Coroa';
    return session.copyWith(lastTableEvent: 'Moeda: $result');
  }

  static LifeCounterSession runTableD20(
    LifeCounterSession session, {
    Random? random,
  }) {
    final value = (random ?? Random()).nextInt(20) + 1;
    return session.copyWith(lastTableEvent: 'D20: $value');
  }

  static LifeCounterSession runPlayerD20(
    LifeCounterSession session,
    int playerIndex, {
    Random? random,
  }) {
    final value = (random ?? Random()).nextInt(20) + 1;
    final nextRolls = List<int?>.from(session.lastPlayerRolls);
    nextRolls[playerIndex] = value;
    return session.copyWith(
      lastPlayerRolls: nextRolls,
      lastTableEvent: '${_playerLabel(playerIndex)} rolou D20: $value',
    );
  }

  static LifeCounterSession runFirstPlayerRoll(
    LifeCounterSession session, {
    Random? random,
  }) {
    final chosen = (random ?? Random()).nextInt(session.playerCount);
    return session.copyWith(
      firstPlayerIndex: chosen,
      lastTableEvent: 'Primeiro jogador: ${_playerLabel(chosen)}',
    );
  }

  static LifeCounterSession runHighRoll(
    LifeCounterSession session, {
    Random? random,
  }) {
    final participants = _resolveHighRollParticipants(session);
    final nextRandom = random ?? Random();
    final nextHighRolls = List<int?>.filled(session.playerCount, null);

    for (final playerIndex in participants) {
      nextHighRolls[playerIndex] = nextRandom.nextInt(20) + 1;
    }

    final winners = deriveHighRollWinners(nextHighRolls);
    final isTieBreaker = participants.length != session.playerCount;

    if (winners.length == 1) {
      final winner = winners.first;
      final value = nextHighRolls[winner]!;
      return session.copyWith(
        lastHighRolls: nextHighRolls,
        firstPlayerIndex: winner,
        lastTableEvent:
            '${isTieBreaker ? 'Desempate do High Roll' : 'High Roll'}: ${_playerLabel(winner)} venceu com $value',
      );
    }

    final highest = winners
        .map((index) => nextHighRolls[index]!)
        .fold<int>(0, max);
    final tiedPlayers = winners.map(_playerLabel).join(', ');
    return session.copyWith(
      lastHighRolls: nextHighRolls,
      lastTableEvent:
          '${isTieBreaker ? 'Desempate do High Roll' : 'High Roll'} empatado em $highest entre $tiedPlayers',
    );
  }

  static Set<int> deriveHighRollWinners(List<int?> values) {
    final available = values.whereType<int>().toList(growable: false);
    if (available.isEmpty) {
      return const <int>{};
    }

    final highest = available.reduce(max);
    return <int>{
      for (var index = 0; index < values.length; index += 1)
        if (values[index] == highest) index,
    };
  }

  static Set<int> _resolveHighRollParticipants(LifeCounterSession session) {
    final persistedWinners = deriveHighRollWinners(session.lastHighRolls);
    if (persistedWinners.length > 1) {
      return persistedWinners;
    }

    return <int>{for (var index = 0; index < session.playerCount; index += 1) index};
  }

  static String _playerLabel(int playerIndex) => 'Player ${playerIndex + 1}';
}
