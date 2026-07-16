import 'package:server/ai/battle_simulation_request_support.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes and bounds battle simulation input', () {
    final request = parseBattleSimulationRequest({
      'deck_id': ' deck-a ',
      'opponent_deck_id': ' deck-b ',
      'type': ' BATTLE ',
      'simulations': 9000,
      'timeout_ms': 90000,
      'max_turns': 250,
      'seed': 42,
      'focus_cards': [' Sol Ring ', 'sol ring', 'The One Ring'],
      'force_focus_access_mode': 'OPENING_HAND',
      'same_lane': true,
      'natural_sample': false,
    });

    expect(request.validationError, isNull);
    expect(request.deckId, 'deck-a');
    expect(request.opponentDeckId, 'deck-b');
    expect(request.type, 'battle');
    expect(request.simulations, 5000);
    expect(request.timeoutMs, 40000);
    expect(request.maxTurns, 100);
    expect(request.seed, 42);
    expect(request.focusCards, ['Sol Ring', 'The One Ring']);
    expect(request.forceFocusAccessMode, 'opening_hand');
    expect(request.sameLane, isTrue);
    expect(request.naturalSample, isFalse);
  });

  test('rejects unknown modes and malformed diagnostic fields', () {
    final unknownType = parseBattleSimulationRequest({'type': 'surprise'});
    final malformedFocus = parseBattleSimulationRequest({
      'type': 'battle',
      'focus_cards': [42],
    });
    final malformedTurns = parseBattleSimulationRequest({
      'type': 'battle',
      'max_turns': '30',
    });

    expect(
      unknownType.validationError,
      'type must be goldfish, matchup or battle',
    );
    expect(
      malformedFocus.validationError,
      'focus_cards must contain only strings',
    );
    expect(malformedTurns.validationError, 'max_turns must be an integer');
  });
}
