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
      },
    );

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
      },
    );

    test(
      'replace route remains same-name-only, not oracle identity replacement',
      () {
        final source =
            File(
              'routes/decks/[id]/cards/replace/index.dart',
            ).readAsStringSync();

        expect(
          source,
          contains('oldName.toLowerCase() != newName.toLowerCase()'),
        );
        expect(
          source,
          contains('Só é permitido trocar edição da mesma carta.'),
        );
        expect(source, isNot(contains('oracle_id')));
        expect(source, contains("'changed': true"));
        expect(source, contains("'name': oldName"));
        expect(source, contains("'old_card_id': oldCardId"));
        expect(source, contains("'new_card_id': newCardId"));
        expect(source, contains("body: {'ok': true, 'changed': false}"));
      },
    );

    test(
      'import commit locks the deck and checks the review before writing',
      () {
        // DCK-P0-03: o commit trava o deck (lockDeckForMutation, com
        // FOR UPDATE), confere o artefato da prévia e só então escreve.
        final source =
            File('routes/import/to-deck/index.dart').readAsStringSync();
        final lock = source.indexOf('lockDeckForMutation(');
        final review = source.indexOf('verifyDeckReviewArtifact(');
        final rules = source.indexOf('DeckRulesService(session)');
        final write = source.indexOf('replaceDeckCardRows(');

        expect(lock, greaterThanOrEqualTo(0));
        expect(review, greaterThan(lock));
        expect(rules, greaterThan(review));
        expect(write, greaterThan(rules));
        expect(source, contains("'import_review_required'"));
        expect(source, isNot(contains('DELETE FROM deck_cards WHERE deck_id')));
        final lib =
            File('lib/decks/deck_revision_support.dart').readAsStringSync();
        expect(lib, contains('FOR UPDATE'));
      },
    );
  });
}
