import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';

void main() {
  test('parses private XMage state without inventing opponent hand cards', () {
    final session = InteractiveBattleSession.fromJson({
      'schema_version': 'interactive_battle_session_v1',
      'id': 'session-1',
      'status': 'waiting_for_action',
      'state_version': 7,
      'deck_id': 'deck-a',
      'opponent_deck_id': 'deck-b',
      'expires_at': '2026-07-27T15:30:00Z',
      'updated_at': '2026-07-27T15:00:00Z',
      'private_state': {
        'schema_version': 'interactive_battle_private_state_v1',
        'turn': 2,
        'phase': 'PRECOMBAT_MAIN',
        'priority_player': 'ManaLoom',
        'own_player': 'ManaLoom',
        'players': [
          {
            'name': 'ManaLoom',
            'life': 39,
            'library_count': 91,
            'hand_count': 7,
            'battlefield': [
              {
                'id': 'card-1',
                'name': 'Plains',
                'set_code': 'm21',
                'card_number': '260',
                'tapped': true,
              },
            ],
            'graveyard': [],
            'exile': [],
            'command': [],
          },
          {
            'name': 'Opponent',
            'life': 40,
            'library_count': 90,
            'hand_count': 8,
            'battlefield': [],
            'graveyard': [],
            'exile': [],
            'command': [],
          },
        ],
        'stack': [],
        'combat': [],
        'own_hand': [
          {'id': 'card-2', 'name': 'Swords to Plowshares'},
        ],
      },
      'prompt': {
        'schema_version': 'interactive_battle_prompt_v1',
        'id': 'p_abcdefghijklmnop',
        'state_version': 7,
        'kind': 'main_action',
        'input_mode': 'options',
        'title': 'Sua prioridade',
        'message': 'Escolha uma ação.',
        'deadline_at': '2026-07-27T15:01:00Z',
        'options': [
          {
            'id': 'o_abcdefghijklmnop',
            'label': 'Conjurar Swords to Plowshares',
            'role': 'card',
            'card': {'name': 'Swords to Plowshares'},
          },
        ],
      },
    });

    expect(session.status, InteractiveBattleStatus.waitingForAction);
    expect(session.isWaitingForAction, isTrue);
    expect(session.privateState.ownPlayerState?.name, 'ManaLoom');
    expect(session.privateState.players.last.handCount, 8);
    expect(session.privateState.ownHand.single.name, 'Swords to Plowshares');
    expect(
      session.privateState.ownHand.single.effectiveImageUrl,
      contains('api.scryfall.com/cards/named'),
    );
    expect(
      session.privateState.players.last.battlefield,
      isEmpty,
      reason: 'Only public opponent zones may be represented as card lists.',
    );
    expect(session.prompt?.options.single.card?.name, 'Swords to Plowshares');
  });

  test('classifies every terminal status used by the API contract', () {
    for (final value in const [
      'completed',
      'censored',
      'conceded',
      'expired',
      'timeout',
      'abandoned',
      'engine_error',
      'process_lost',
      'persistence_error',
    ]) {
      final session = InteractiveBattleSession.fromJson({
        'schema_version': 'interactive_battle_session_v1',
        'id': 'session-$value',
        'status': value,
        'state_version': 1,
        'expires_at': '2026-07-27T15:30:00Z',
        'updated_at': '2026-07-27T15:00:00Z',
        'private_state': const <String, dynamic>{},
      });
      expect(session.isTerminal, isTrue, reason: value);
    }
  });

  test(
    'preserves unavailable private-state numbers instead of fabricating 0',
    () {
      final session = InteractiveBattleSession.fromJson({
        'schema_version': 'interactive_battle_session_v1',
        'id': 'session-unknown-state',
        'status': 'running',
        'state_version': 1,
        'expires_at': '2026-07-27T15:30:00Z',
        'updated_at': '2026-07-27T15:00:00Z',
        'private_state': {
          'players': [
            {
              'name': 'ManaLoom',
              'battlefield': [
                {
                  'name': 'Permanent without metrics',
                  'counters': [
                    {'name': '+1/+1'},
                  ],
                },
              ],
            },
          ],
        },
      });

      final state = session.privateState;
      final player = state.players.single;
      final card = player.battlefield.single;
      expect(state.turn, isNull);
      expect(state.priorityTimeSeconds, isNull);
      expect(player.life, isNull);
      expect(player.handCount, isNull);
      expect(player.libraryCount, isNull);
      expect(card.damage, isNull);
      expect(card.counters.single.count, isNull);
    },
  );
}
