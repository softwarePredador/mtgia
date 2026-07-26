import 'package:test/test.dart';

import '../lib/ai/battle_replay_event_support.dart';

void main() {
  test('normalizes Forge type and actor slot into public event v2', () {
    final result = normalizeBattleReplayResultEvents(
      result: const {
        'engine': 'forge',
        'events': [
          {
            'type': 'add_to_stack',
            'message': 'Ai(1)-Deck A cast Sol Ring',
            'card_name': 'Sol Ring',
          },
          {
            'type': 'add_to_stack',
            'message': 'Ai(2)-Deck B cast Arcane Signet',
            'card_name': 'Arcane Signet',
          },
        ],
      },
      deckAId: 'deck-a-id',
      deckAName: 'Deck A',
      deckBId: 'deck-b-id',
      deckBName: 'Deck B',
    );

    final events = (result['events'] as List).cast<Map>();
    expect(events.first['schema_version'], battleReplayEventSchema);
    expect(events.first['event_type'], 'add_to_stack');
    expect(events.first['subject_deck_key'], 'deck_a');
    expect(events.last['subject_deck_key'], 'deck_b');
  });

  test('leaves ambiguous actor unattributed instead of guessing a side', () {
    final result = normalizeBattleReplayResultEvents(
      result: const {
        'events': [
          {
            'action': 'spell_cast',
            'player': 'unknown-player',
            'card_name': 'Candidate',
          },
        ],
      },
      deckAId: 'deck-a-id',
      deckAName: 'Same name',
      deckBId: 'deck-b-id',
      deckBName: 'Same name',
    );

    final event = (result['events'] as List).single as Map;
    expect(event, isNot(contains('subject_deck_key')));
    expect(event['event_type'], 'spell_cast');
  });

  test('labels native decision traces as heuristics', () {
    final result = normalizeBattleReplayResultEvents(
      result: const {
        'engine': 'manaloom_native_reviewed',
        'events': <Object>[],
        'decision_trace': [
          {'choice': 'cast_spell', 'reason': 'highest score'},
        ],
      },
      deckAId: 'deck-a-id',
      deckAName: 'Deck A',
    );

    final decision = (result['decision_trace'] as List).single as Map;
    expect(decision['decision_origin'], 'native_heuristic');
    expect(decision['rules_engine_explanation'], isFalse);
    expect(
      result['decision_trace_contract'],
      containsPair('strategy_proof', false),
    );
  });
}
