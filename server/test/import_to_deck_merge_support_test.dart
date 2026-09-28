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

    test(
      'marks preserved commander when replace-all seeds existing commander',
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
      },
    );
  });

  group('buildImportToDeckSuccessBody', () {
    test('reports final commander status and response shape', () {
      final merge = mergeImportToDeckCards(
        existingCards: const [
          {'card_id': 'commander-1', 'quantity': 1, 'is_commander': true},
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

    test(
      'flags missing commander for final Commander deck without commander',
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
      },
    );
  });

  // DCK-P0-03: a prévia calcula a lista final e a diferença sem escrever.
  group('resolveImportToDeckFinalCards', () {
    const current = [
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
        'condition': 'NM',
      },
    ];
    Map<String, Map<String, dynamic>> byId(ImportToDeckMergeResult result) => {
      for (final card in result.cards) card['card_id'] as String: card,
    };

    test('merge soma à lista atual', () {
      final result = resolveImportToDeckFinalCards(
        importedCards: const [
          {'card_id': 'sol-ring', 'quantity': 1, 'is_commander': false},
        ],
        currentCards: current,
        replaceAll: false,
        normalizedFormat: 'commander',
      );

      expect(byId(result)['sol-ring']?['quantity'], 2);
      expect(byId(result).keys, containsAll(['commander-1', 'sol-ring']));
      expect(result.commanderPreserved, isFalse);
    });

    test('replace_all em Commander sem comandante na lista mantém o atual', () {
      final result = resolveImportToDeckFinalCards(
        importedCards: const [
          {'card_id': 'arcane-signet', 'quantity': 1, 'is_commander': false},
        ],
        currentCards: current,
        replaceAll: true,
        normalizedFormat: 'commander',
      );

      expect(byId(result).keys, {'commander-1', 'arcane-signet'});
      expect(byId(result)['commander-1']?['condition'], 'LP');
      expect(result.commanderPreserved, isTrue);
      expect(result.commanderDetected, isTrue);
    });

    test(
      'replace_all com comandante na lista, ou fora de Commander, troca tudo',
      () {
        final withCommander = resolveImportToDeckFinalCards(
          importedCards: const [
            {'card_id': 'commander-2', 'quantity': 1, 'is_commander': true},
          ],
          currentCards: current,
          replaceAll: true,
          normalizedFormat: 'commander',
        );
        final modern = resolveImportToDeckFinalCards(
          importedCards: const [
            {'card_id': 'bolt', 'quantity': 4, 'is_commander': false},
          ],
          currentCards: current,
          replaceAll: true,
          normalizedFormat: 'modern',
        );

        expect(byId(withCommander).keys, {'commander-2'});
        expect(withCommander.commanderPreserved, isFalse);
        expect(byId(modern).keys, {'bolt'});
      },
    );
  });

  group('buildImportToDeckDiff', () {
    test('separa o que entra, sai e muda, com nomes e totais', () {
      final diff = buildImportToDeckDiff(
        beforeCards: const [
          {'card_id': 'a', 'quantity': 1, 'is_commander': true},
          {'card_id': 'b', 'quantity': 2, 'is_commander': false},
          {'card_id': 'c', 'quantity': 4, 'is_commander': false},
        ],
        afterCards: const [
          {'card_id': 'a', 'quantity': 1, 'is_commander': true},
          {'card_id': 'b', 'quantity': 3, 'is_commander': false},
          {'card_id': 'd', 'quantity': 1, 'is_commander': false},
        ],
        namesById: const {'a': 'Ezuri', 'b': 'Urso', 'c': 'Raio', 'd': 'Elfo'},
      );

      expect(diff['added'], [
        {
          'card_id': 'd',
          'name': 'Elfo',
          'quantity': 1,
          'is_commander': false,
          'condition': 'NM',
        },
      ]);
      expect(diff['removed'], [
        {
          'card_id': 'c',
          'name': 'Raio',
          'quantity': 4,
          'is_commander': false,
          'condition': 'NM',
        },
      ]);
      expect(
        (diff['changed'] as List).single,
        containsPair('quantity_after', 3),
      );
      expect(diff['unchanged_count'], 1);
      expect(diff['total_before'], 7);
      expect(diff['total_after'], 5);
      expect(diff['commanders_before'], ['Ezuri']);
      expect(diff['commanders_after'], ['Ezuri']);
      expect(diff['has_changes'], isTrue);
    });

    test('mesma lista não tem mudança; condição e papel contam', () {
      const cards = [
        {'card_id': 'a', 'quantity': 1, 'is_commander': false},
      ];
      expect(
        buildImportToDeckDiff(
          beforeCards: cards,
          afterCards: cards,
        )['has_changes'],
        isFalse,
      );
      final condition = buildImportToDeckDiff(
        beforeCards: cards,
        afterCards: const [
          {
            'card_id': 'a',
            'quantity': 1,
            'is_commander': false,
            'condition': 'LP',
          },
        ],
      );
      final role = buildImportToDeckDiff(
        beforeCards: cards,
        afterCards: const [
          {'card_id': 'a', 'quantity': 1, 'is_commander': true},
        ],
      );
      expect((condition['changed'] as List), hasLength(1));
      expect((role['changed'] as List), hasLength(1));
    });
  });
}
