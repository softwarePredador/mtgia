import 'package:server/import_to_deck_merge_support.dart';
import 'package:test/test.dart';

void main() {
  group('mergeImportToDeckCards', () {
    test('adds imported quantities without dropping existing commander', () {
      final result = mergeImportToDeckCards(
        existingCards: const [
          {
            'card_id': 'commander-1',
            'quantity': 1,
            'is_commander': true,
            'condition': 'LP',
          },
          {
            'card_id': 'sol-ring',
            'quantity': 1,
            'is_commander': false,
            'condition': 'MP',
          },
        ],
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
          {'card_id': 'new-card', 'quantity': 2, 'is_commander': false},
        ],
      );

      final byId = {
        for (final card in result.cards) card['card_id'] as String: card,
      };

      expect(result.commanderDetected, isTrue);
      expect(result.commanderPreserved, isFalse);
      expect(result.totalCards, 5);
      expect(byId['commander-1']?['quantity'], 1);
      expect(byId['commander-1']?['condition'], 'LP');
      expect(byId['sol-ring']?['quantity'], 2);
      expect(byId['sol-ring']?['condition'], 'MP');
      expect(byId['new-card']?['quantity'], 2);
      expect(byId['new-card']?['condition'], 'NM');
    });

    test('marks preserved commander when replace-all seeds existing commander',
        () {
      final result = mergeImportToDeckCards(
        commanderPreserved: true,
        existingCards: const [
          {
            'card_id': 'commander-1',
            'quantity': 1,
            'is_commander': true,
            'condition': 'NM',
          },
        ],
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(result.commanderDetected, isTrue);
      expect(result.commanderPreserved, isTrue);
      expect(result.totalCards, 2);
    });
  });

  group('buildImportToDeckSuccessBody', () {
    test('reports final commander status and response shape', () {
      final merge = mergeImportToDeckCards(
        existingCards: const [
          {
            'card_id': 'commander-1',
            'quantity': 1,
            'is_commander': true,
          },
        ],
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
      );

      final body = buildImportToDeckSuccessBody(
        deckId: 'deck-1',
        normalizedFormat: 'commander',
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
        totalCards: merge.totalCards,
        notFoundLines: const ['1 Carta Fantasma'],
        localizedMatches: const [
          {'line': '1 Anel Solar', 'resolved_name': 'Sol Ring'},
        ],
        warnings: const ['warning'],
        commanderDetected: merge.commanderDetected,
        commanderPreserved: merge.commanderPreserved,
      );

      expect(body['success'], isTrue);
      expect(body['deck_id'], 'deck-1');
      expect(body['cards_imported'], 1);
      expect(body['total_cards'], 2);
      expect(body['not_found_lines'], ['1 Carta Fantasma']);
      expect(body['localized_matches_count'], 1);
      expect(body['warnings'], ['warning']);
      expect(body['commander_detected'], isTrue);
      expect(body['missing_commander'], isFalse);
      expect(body['commander_preserved'], isFalse);
    });

    test('flags missing commander for final Commander deck without commander',
        () {
      final merge = mergeImportToDeckCards(
        existingCards: const [],
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
      );

      final body = buildImportToDeckSuccessBody(
        deckId: 'deck-1',
        normalizedFormat: 'commander',
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
        totalCards: merge.totalCards,
        notFoundLines: const [],
        localizedMatches: const [],
        warnings: const [],
        commanderDetected: merge.commanderDetected,
        commanderPreserved: merge.commanderPreserved,
      );

      expect(body['commander_detected'], isFalse);
      expect(body['missing_commander'], isTrue);
      expect(body['commander_preserved'], isFalse);
    });
  });
}
