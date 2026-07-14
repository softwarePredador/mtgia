import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('POST /decks inserts initial deck cards with one bulk statement', () {
    final source = File('routes/decks/index.dart').readAsStringSync();

    expect(
      source,
      contains(
        'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)',
      ),
    );
    expect(source, contains('VALUES \${values.join(\', \')}'));
    expect(source, contains('params[pId]'));
    expect(source, contains('params[pQty]'));
    expect(source, contains('params[pCommander]'));
    expect(
      source,
      isNot(contains(
        'VALUES (@deckId, @cardId, @quantity, @isCommander)',
      )),
    );
  });
}
