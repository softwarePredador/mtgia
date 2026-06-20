import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('manual deck mutation route contracts', () {
    test(
        'single-card add response shape and condition persistence are explicit',
        () {
      final source =
          File('routes/decks/[id]/cards/index.dart').readAsStringSync();

      expect(source, contains("'ok': true"));
      expect(source, contains("'deck_id': deckId"));
      expect(source, contains("'card_id': cardId"));
      expect(source, contains("'card_name': cardName"));
      expect(source, contains("'quantity': nextQty"));
      expect(source, contains("'condition': condition"));
      expect(source, contains("'total_cards': updatedTotal"));
      expect(source, contains('condition = EXCLUDED.condition'));
    });

    test(
        'set route uses same-name replacement semantics and documents response',
        () {
      final source =
          File('routes/decks/[id]/cards/set/index.dart').readAsStringSync();

      expect(source, contains('final replaceSameName'));
      expect(source, contains("card['name'] as String"));
      expect(source, contains('toLowerCase() == cardName.toLowerCase()'));
      expect(source, contains("'ok': true"));
      expect(source, contains("'deck_id': deckId"));
      expect(source, contains("'card_id': cardId"));
      expect(source, contains("'name': cardName"));
      expect(source, contains("'quantity': quantity"));
      expect(source, contains("'condition': condition"));
      expect(source, contains("'replace_same_name': replaceSameName"));
    });

    test(
        'replace route remains same-name-only, not oracle identity replacement',
        () {
      final source =
          File('routes/decks/[id]/cards/replace/index.dart').readAsStringSync();

      expect(
          source, contains('oldName.toLowerCase() != newName.toLowerCase()'));
      expect(source, contains('Só é permitido trocar edição da mesma carta.'));
      expect(source, isNot(contains('oracle_id')));
      expect(source, contains("'changed': true"));
      expect(source, contains("'name': oldName"));
      expect(source, contains("'old_card_id': oldCardId"));
      expect(source, contains("'new_card_id': newCardId"));
      expect(source, contains("body: {'ok': true, 'changed': false}"));
    });
  });
}
