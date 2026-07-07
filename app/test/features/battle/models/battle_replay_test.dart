import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';

void main() {
  group('BattleReplayDetail', () {
    test('parses saved battle replay with events and decision trace', () {
      final detail = BattleReplayDetail.fromJson({
        'replay': {
          'id': 'sim-1',
          'deck_id': 'deck-1',
          'type': 'battle',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 6,
          'created_at': '2026-07-06T12:00:00Z',
          'game_log': [
            {
              'turn': 1,
              'player': 'Player A',
              'phase': 'main',
              'action': 'casts',
              'card': 'Sol Ring',
            },
          ],
          'decision_trace': [
            {
              'turn': 1,
              'choice': 'Cast Sol Ring',
              'reason': 'Accelerates commander turn.',
              'score': 0.91,
            },
          ],
        },
      }, fallbackDeckId: 'deck-1');

      expect(detail.summary.id, 'sim-1');
      expect(detail.summary.title, 'Battle contra Atraxa Superfriends');
      expect(detail.summary.resultLabel, 'Vencedor: Player A');
      expect(detail.summary.turnLabel, '6 turnos');
      expect(detail.events, hasLength(1));
      expect(detail.events.single.turnLabel, 'T1');
      expect(detail.events.single.message, 'Player A casts Sol Ring');
      expect(detail.decisions, hasLength(1));
      expect(detail.decisions.single.reason, 'Accelerates commander turn.');
      expect(detail.decisions.single.score, 0.91);
    });

    test('accepts immediate simulate response shape', () {
      final detail = BattleReplayDetail.fromJson(
        {
          'type': 'goldfish',
          'deck_id': 'deck-2',
          'simulations': 1000,
          'consistency_score': 0.74,
          'mana_analysis': {'keepable_rate': 0.82},
          'recommendations': ['Deck bem balanceado.'],
        },
        fallbackDeckId: 'deck-2',
        fallbackId: 'goldfish-latest',
        source: 'immediate_simulation',
      );

      expect(detail.summary.id, 'goldfish-latest');
      expect(detail.summary.typeLabel, 'Goldfish');
      expect(detail.summary.sourceLabel, 'Simulacao recem-gerada');
      expect(detail.summary.simulations, 1000);
      expect(detail.hasReplayBody, isFalse);
    });
  });
}
