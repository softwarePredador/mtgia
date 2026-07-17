import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('saved deck fetch/hydration source contracts', () {
    test(
      'GET /decks returns raw list rows with count and presentation colors',
      () {
        final source = File('routes/decks/index.dart').readAsStringSync();

        expect(source, contains('context.request.method == HttpMethod.get'));
        expect(source, contains('WHERE d.user_id = @userId'));
        expect(
          source,
          contains('COALESCE(SUM(dc.quantity), 0)::int as card_count'),
        );
        expect(
          source,
          contains(
            'array_agg(DISTINCT unnested ORDER BY unnested) AS color_identity',
          ),
        );
        expect(source, contains("deck['color_identity'] = colorMap[deckId]"));
        expect(source, contains("deck['color_identity_known'] = true"));
        expect(source, contains("deck['color_identity_known'] = false"));
        expect(source, contains('return Response.json(body: decks);'));
        expect(source, isNot(contains("body: {'data': decks")));
      },
    );

    test(
      'GET /decks/:id returns root detail fields and UI aggregates only',
      () {
        final source = File('routes/decks/[id]/index.dart').readAsStringSync();

        expect(source, contains('context.request.method == HttpMethod.get'));
        expect(
          source,
          contains('FROM decks WHERE id = @deckId AND user_id = @userId'),
        );
        expect(source, contains('final responseBody = {'));
        expect(source, contains('...deckInfo'));
        expect(
          source,
          contains("'color_identity': deckColorIdentity.toList()"),
        );
        expect(source, contains("'color_identity_known': true"));
        expect(source, contains("'stats': {"));
        expect(source, contains("'total_cards': cardsList.fold<int>"));
        expect(source, contains("'unique_cards': cardsList.length"));
        expect(source, contains("'mana_curve': manaCurve"));
        expect(source, contains("'color_distribution': colorDistribution"));
        expect(source, contains("'commander': commander"));
        expect(source, contains("'main_board': groupedMainBoard"));
        expect(source, contains("'all_cards_flat': cardsList"));
        expect(source, contains('return Response.json(body: responseBody);'));
        expect(source, isNot(contains("'deck': responseBody")));
      },
    );

    test(
      'GET /decks/:id card rows expose display fields, not identity payloads',
      () {
        final source = File('routes/decks/[id]/index.dart').readAsStringSync();
        final cardsSelectStart = source.indexOf(
          'final cardsResult = await conn.execute',
        );
        final cardsSelectEnd = source.indexOf(
          '// 3. Organizar',
          cardsSelectStart,
        );
        expect(cardsSelectStart, isNonNegative);
        expect(cardsSelectEnd, greaterThan(cardsSelectStart));
        final cardsSelect = source.substring(cardsSelectStart, cardsSelectEnd);

        expect(cardsSelect, contains('dc.condition'));
        expect(cardsSelect, contains('c.collector_number'));
        expect(cardsSelect, contains('c.foil'));
        expect(cardsSelect, contains('c.color_identity'));
        expect(cardsSelect, contains('AS set_name'));
        expect(cardsSelect, contains('AS set_release_date'));
        expect(cardsSelect, isNot(contains('oracle_id')));
        expect(cardsSelect, isNot(contains('layout')));
        expect(cardsSelect, isNot(contains('card_faces')));
        expect(cardsSelect, isNot(contains('scryfall_id')));
      },
    );
  });
}
