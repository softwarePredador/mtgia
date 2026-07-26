import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';

void main() {
  group('BattleReplayDetail', () {
    test('preserves the observable XMage snapshot contract', () {
      final detail = BattleReplayDetail.fromJson({
        'replay': {
          'id': 'sim-1',
          'deck_id': 'deck-1',
          'type': 'battle',
          'engine': 'xmage',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 6,
          'created_at': '2026-07-06T12:00:00Z',
          'learning_contract': {
            'schema_version': 'external_battle_learning_v1',
            'ai_decision_rationale_available': false,
          },
          'game_log': [
            {
              'turn': 1,
              'player': 'Player A',
              'phase': 'main',
              'action': 'casts',
              'card': 'Sol Ring',
            },
          ],
          'decision_trace': [],
          'visual_snapshots': [
            {
              'index': 7,
              'turn': 1,
              'phase': 'COMBAT',
              'step': 'DECLARE_ATTACKERS',
              'action': 'attacker_declared',
              'active_player': 'deck_a',
              'priority_player': 'deck_b',
              'event': {
                'turn': 1,
                'player': 'deck_a',
                'phase': 'COMBAT',
                'step': 'DECLARE_ATTACKERS',
                'action': 'attacker_declared',
                'card': 'Goblin Token',
              },
              'players': [
                {
                  'name': 'deck_a',
                  'life': 40,
                  'hand_size': 6,
                  'library_size': 91,
                  'battlefield': [
                    {
                      'id': 'goblin-1',
                      'name': 'Goblin Token',
                      'tapped': true,
                      'damage': 1,
                    },
                  ],
                  'graveyard': [],
                  'exile': [
                    {'id': 'exiled-1', 'name': 'Faithless Looting'},
                  ],
                  'command': [
                    {'id': 'commander-1', 'name': 'Krenko, Mob Boss'},
                  ],
                  'has_left': false,
                },
              ],
              'stack': [
                {
                  'id': 'stack-1',
                  'name': 'Lightning Bolt',
                  'object_type': 'SPELL',
                },
              ],
              'combat': [
                {
                  'defender_id': 'deck_b',
                  'defender_name': 'deck_b',
                  'blocked': false,
                  'attackers': [
                    {'id': 'goblin-1', 'name': 'Goblin Token'},
                  ],
                  'blockers': [],
                },
              ],
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
      expect(detail.decisions, isEmpty);
      expect(detail.nativeDecisionTraceAvailable, isFalse);
      expect(detail.visualSnapshots, hasLength(1));
      final snapshot = detail.visualSnapshots.single;
      expect(snapshot.index, 7);
      expect(snapshot.phase, 'COMBAT');
      expect(snapshot.step, 'DECLARE_ATTACKERS');
      expect(snapshot.phaseLabel, 'COMBAT · DECLARE_ATTACKERS');
      expect(snapshot.activePlayer, 'deck_a');
      expect(snapshot.priorityPlayer, 'deck_b');
      expect(snapshot.stack.single.name, 'Lightning Bolt');
      expect(snapshot.combat.single.defenderName, 'deck_b');
      expect(snapshot.combat.single.blocked, isFalse);
      expect(snapshot.combat.single.attackers.single.name, 'Goblin Token');

      final player = snapshot.players.single;
      expect(player.life, 40);
      expect(player.mana, isNull);
      expect(player.hand, isEmpty);
      expect(player.handSize, 6);
      expect(player.librarySize, 91);
      expect(player.lands, isNull);
      expect(player.graveyardSize, 0);
      expect(player.exile.single.name, 'Faithless Looting');
      expect(player.command.single.name, 'Krenko, Mob Boss');
      expect(player.hasLeft, isFalse);
      expect(player.battlefield.single.isTapped, isTrue);
      expect(player.battlefield.single.damage, 1);
    });

    test('interprets Forge player maps and keeps unobserved fields null', () {
      final detail = BattleReplayDetail.fromJson({
        'id': 'forge-1',
        'deck_id': 'deck-1',
        'engine': 'forge',
        'learning_contract': {
          'schema_version': 'external_battle_learning_v1',
          'combat_activity_available': false,
          'ai_decision_rationale_available': false,
        },
        'visual_snapshots': [
          {
            'turn': 3,
            'players': {
              'deck_a': {'life': 40},
              'deck_b': {'life': 34},
            },
          },
          {
            'final': true,
            'players': {
              'deck_a': {'life': 40},
              'deck_b': {'life': 0},
            },
          },
        ],
      });

      expect(detail.visualSnapshots, hasLength(2));
      final first = detail.visualSnapshots.first;
      expect(first.turnLabel, 'T3');
      expect(first.phase, isNull);
      expect(first.step, isNull);
      expect(first.stack, isEmpty);
      expect(first.combat, isEmpty);
      expect(first.players.map((player) => player.name), ['deck_a', 'deck_b']);
      expect(first.players.map((player) => player.deckKey), [
        'deck_a',
        'deck_b',
      ]);
      expect(first.players.first.life, 40);
      expect(first.players.first.mana, isNull);
      expect(first.players.first.handSize, isNull);
      expect(first.players.first.librarySize, isNull);
      expect(first.players.first.graveyardSize, isNull);
      expect(detail.visualSnapshots.last.turn, isNull);
      expect(detail.visualSnapshots.last.turnLabel, 'Turno nao disponivel');
      expect(detail.visualSnapshots.last.players.last.life, 0);
    });

    test('maps reviewed native heuristic decisions only with its contract', () {
      final detail = BattleReplayDetail.fromJson({
        'id': 'native-1',
        'deck_id': 'deck-1',
        'engine': 'manaloom_native_reviewed',
        'engine_contract': 'native_reviewed_rules_execution',
        'learning_contract': {
          'schema_version': 'native_battle_learning_v1',
          'decision_trace_available': true,
        },
        'decision_trace': [
          {
            'schema_version': 'decision_trace_v1',
            'decision_id': 'decision-000001',
            'turn': 2,
            'phase': 'main',
            'player': 'Deck A',
            'decision_type': 'cast_spell',
            'chosen_option': {
              'card': 'Sol Ring',
              'action': 'cast',
              'score': 0.91,
            },
            'alternatives_considered': [
              {'card': 'Arcane Signet', 'action': 'cast', 'score': 0.73},
              {'action': 'pass', 'score': 0},
            ],
            'score_components': {'mana_efficiency': 0.95, 'curve_plan': 0.87},
            'reason': 'Accelerates the commander turn.',
            'heuristic_version': 'battle_decision_strategy_v1',
            'rule_source': 'battle_heuristic',
            'rule_status': 'heuristic',
            'confidence': 'high',
            'chosen_option_score': 0.91,
          },
        ],
      });

      expect(detail.nativeDecisionTraceAvailable, isTrue);
      expect(detail.decisions, hasLength(1));
      final decision = detail.decisions.single;
      expect(decision.isNativeHeuristic, isTrue);
      expect(decision.decisionType, 'cast_spell');
      expect(decision.choice, 'cast · Sol Ring');
      expect(decision.reason, 'Accelerates the commander turn.');
      expect(decision.phase, 'main');
      expect(decision.actor, 'Deck A');
      expect(decision.score, 0.91);
      expect(decision.chosenOption['card'], 'Sol Ring');
      expect(decision.alternatives, hasLength(2));
      expect(decision.alternatives.first['card'], 'Arcane Signet');
      expect(decision.scoreComponents['mana_efficiency'], 0.95);
      expect(decision.heuristicVersion, 'battle_decision_strategy_v1');
      expect(decision.ruleSource, 'battle_heuristic');
      expect(decision.ruleStatus, 'heuristic');
      expect(decision.confidence, 'high');
    });

    test('does not relabel external or undeclared traces as heuristics', () {
      final external = BattleReplayDetail.fromJson({
        'engine': 'xmage',
        'learning_contract': {
          'schema_version': 'external_battle_learning_v1',
          'ai_decision_rationale_available': false,
        },
        'decision_trace': [
          {
            'decision_id': 'unstable-debug-row',
            'chosen_option': {'card': 'Hidden Card'},
            'reason': 'Internal engine debug output.',
          },
        ],
      });
      final incompleteNative = BattleReplayDetail.fromJson({
        'engine': 'manaloom_native_reviewed',
        'learning_contract': {'schema_version': 'native_battle_learning_v1'},
        'decision_trace': [
          {
            'decision_id': 'legacy-native-row',
            'chosen_option': {'card': 'Sol Ring'},
          },
        ],
      });

      expect(external.nativeDecisionTraceAvailable, isFalse);
      expect(external.decisions, isEmpty);
      expect(incompleteNative.nativeDecisionTraceAvailable, isFalse);
      expect(incompleteNative.decisions, isEmpty);
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
      expect(detail.summary.turnCount, isNull);
      expect(detail.summary.eventCount, isNull);
      expect(detail.summary.turnLabel, 'Turnos nao informados');
      expect(detail.summary.eventLabel, 'Eventos nao informados');
      expect(detail.hasReplayBody, isFalse);
    });
  });
}
