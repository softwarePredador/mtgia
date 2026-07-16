import 'package:server/ai/rebuild_route_request_support.dart';
import 'package:test/test.dart';

void main() {
  test('parses and normalizes the rebuild contract', () {
    final request = parseRebuildRouteRequest({
      'deck_id': ' deck-1 ',
      'theme': ' Artifacts ',
      'archetype': ' Midrange ',
      'rebuild_scope': ' REPAIR_PARTIAL ',
      'save_mode': ' PREVIEW_ONLY ',
      'bracket': '3',
      'must_keep': [' Sol Ring ', 'sol ring', 'Arcane Signet'],
      'must_avoid': ['Mana Crypt'],
    });

    expect(request.validationError, isNull);
    expect(request.deckId, 'deck-1');
    expect(request.theme, 'Artifacts');
    expect(request.archetype, 'Midrange');
    expect(request.scope, 'repair_partial');
    expect(request.saveMode, 'preview_only');
    expect(request.bracket, 3);
    expect(request.mustKeep, ['Sol Ring', 'Arcane Signet']);
    expect(request.mustAvoid, ['Mana Crypt']);
  });

  test('rejects malformed user-controlled fields without throwing', () {
    final wrongList = parseRebuildRouteRequest({
      'deck_id': 'deck-1',
      'must_keep': 'Sol Ring',
    });
    final wrongItem = parseRebuildRouteRequest({
      'deck_id': 'deck-1',
      'must_avoid': [42],
    });
    final oversizedTheme = parseRebuildRouteRequest({
      'deck_id': 'deck-1',
      'theme': 'x' * 241,
    });

    expect(wrongList.validationError, 'must_keep must be a list');
    expect(wrongItem.validationError, 'must_avoid must contain only strings');
    expect(oversizedTheme.validationError, 'theme exceeds the allowed size');
  });

  test('rejects malformed and out-of-range Commander brackets', () {
    for (final entry
        in <Object, String>{
          'competitive': 'bracket must be an integer',
          0: 'bracket must be between 1 and 5',
          6: 'bracket must be between 1 and 5',
        }.entries) {
      final request = parseRebuildRouteRequest({
        'deck_id': 'deck-1',
        'bracket': entry.key,
      });

      expect(request.bracket, isNull);
      expect(request.validationError, entry.value);
    }
  });
}
