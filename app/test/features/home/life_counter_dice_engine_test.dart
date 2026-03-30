import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_dice_engine.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

void main() {
  group('LifeCounterDiceEngine', () {
    test('runs coin flip and updates the last table event', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterDiceEngine.runCoinFlip(
        session,
        random: Random(1),
      );

      expect(updated.lastTableEvent, anyOf('Moeda: Cara', 'Moeda: Coroa'));
    });

    test('runs table d20 and updates the last table event', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterDiceEngine.runTableD20(
        session,
        random: Random(2),
      );

      expect(updated.lastTableEvent, startsWith('D20: '));
    });

    test('runs player d20 and updates player roll state', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterDiceEngine.runPlayerD20(
        session,
        2,
        random: Random(6),
      );

      expect(updated.lastPlayerRolls[2], isNotNull);
      expect(updated.lastTableEvent, startsWith('Player 3 rolou D20: '));
    });

    test('runs first player roll and persists the chosen player', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterDiceEngine.runFirstPlayerRoll(
        session,
        random: Random(3),
      );

      expect(updated.firstPlayerIndex, inInclusiveRange(0, 3));
      expect(updated.lastTableEvent, startsWith('Primeiro jogador: Player '));
    });

    test('runs high roll for all players when there is no pending tie', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterDiceEngine.runHighRoll(
        session,
        random: Random(4),
      );

      expect(updated.lastHighRolls.whereType<int>().length, 4);
      expect(updated.lastTableEvent, startsWith('High Roll'));
    });

    test('rerolls only tied players when a tie is pending', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lastHighRolls: const [19, null, 19, null],
      );

      final updated = LifeCounterDiceEngine.runHighRoll(
        session,
        random: Random(5),
      );

      expect(updated.lastHighRolls[1], isNull);
      expect(updated.lastHighRolls[3], isNull);
      expect(updated.lastHighRolls[0], isNotNull);
      expect(updated.lastHighRolls[2], isNotNull);
      expect(updated.lastTableEvent, contains('Desempate do High Roll'));
    });
  });
}
