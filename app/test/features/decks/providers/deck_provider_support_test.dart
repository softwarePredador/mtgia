import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';

void main() {
  test('extractCardSearchResults supports paginated and direct payloads', () {
    final paginated = extractCardSearchResults({
      'data': [
        {'id': 'card-1', 'name': 'Arcane Signet'},
      ],
    });
    final direct = extractCardSearchResults([
      {'id': 'card-2', 'name': 'Mind Stone'},
    ]);

    expect(paginated.single['id'], 'card-1');
    expect(direct.single['id'], 'card-2');
  });

  test('applyRemovalCountsToCurrentCards decrements and removes entries', () {
    final currentCards = <String, Map<String, dynamic>>{
      'card-1': {
        'card_id': 'card-1',
        'quantity': 2,
        'is_commander': false,
      },
      'card-2': {
        'card_id': 'card-2',
        'quantity': 1,
        'is_commander': false,
      },
    };

    applyRemovalCountsToCurrentCards(
      currentCards: currentCards,
      removalCounts: buildRemovalCounts(['card-1', 'card-2']),
    );

    expect(currentCards['card-1']?['quantity'], 1);
    expect(currentCards.containsKey('card-2'), isFalse);
  });

  test('applyAdditionsToCurrentCards enforces commander identity and limits', () {
    final currentCards = <String, Map<String, dynamic>>{
      'arcane-signet': {
        'card_id': 'arcane-signet',
        'quantity': 1,
        'is_commander': false,
      },
    };

    final applied = applyAdditionsToCurrentCards(
      currentCards: currentCards,
      cardsToAdd: const [
        {
          'card_id': 'arcane-signet',
          'quantity': 1,
          'is_commander': false,
          'type_line': 'Artifact',
          'color_identity': <String>[],
        },
        {
          'card_id': 'counterspell',
          'quantity': 1,
          'is_commander': false,
          'type_line': 'Instant',
          'color_identity': <String>['U'],
        },
        {
          'card_id': 'terminate',
          'quantity': 1,
          'is_commander': false,
          'type_line': 'Instant',
          'color_identity': <String>['B', 'R'],
        },
      ],
      format: 'commander',
      commanderIdentity: {'U'},
    );

    expect(applied, 1);
    expect(currentCards['arcane-signet']?['quantity'], 1);
    expect(currentCards.containsKey('counterspell'), isTrue);
    expect(currentCards.containsKey('terminate'), isFalse);
  });

  test('buildCurrentCardSnapshot reflects structural card changes', () {
    final before = buildCurrentCardSnapshot({
      'card-1': {'card_id': 'card-1', 'quantity': 1, 'is_commander': false},
    });
    final after = buildCurrentCardSnapshot({
      'card-1': {'card_id': 'card-1', 'quantity': 2, 'is_commander': false},
    });

    expect(before, isNot(after));
  });
}
