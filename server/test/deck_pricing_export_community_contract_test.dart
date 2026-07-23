import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('pricing/export/community source contracts', () {
    test(
      'pricing route is write-capable and returns current response fields',
      () {
        final source =
            File('routes/decks/[id]/pricing/index.dart').readAsStringSync();

        expect(source, contains('context.request.method != HttpMethod.post'));
        expect(source, contains("body['force'] == true"));
        expect(source, contains('UPDATE cards'));
        expect(source, contains('price_usd = @price'));
        expect(source, contains('price_source = @source'));
        expect(source, contains('price_updated_at = NOW()'));
        expect(source, contains('UPDATE decks'));
        expect(source, contains('pricing_total = @total'));

        final responseStart = source.indexOf("'deck_id': deckId");
        final responseEnd = source.indexOf('  } catch (e) {', responseStart);
        expect(responseStart, isNonNegative);
        expect(responseEnd, greaterThan(responseStart));
        final responseSource = source.substring(responseStart, responseEnd);

        expect(responseSource, contains("'deck_id': deckId"));
        expect(responseSource, contains("'currency': pricingCurrencyUsd"));
        expect(responseSource, contains("'estimated_total_usd'"));
        expect(responseSource, contains("'missing_price_cards'"));
        expect(responseSource, contains("'pricing_status'"));
        expect(responseSource, contains("'price_source'"));
        expect(responseSource, contains("'pricing_updated_at'"));
        expect(responseSource, contains("'cache_status'"));
        expect(responseSource, contains("'items': items"));
        expect(responseSource, isNot(contains("'total':")));
        expect(responseSource, isNot(contains("'missing':")));
      },
    );

    test(
      'pricing scripts keep canonical USD, source and nullable semantics',
      () {
        final route =
            File('routes/decks/[id]/pricing/index.dart').readAsStringSync();
        final scryfallSync = File('bin/sync_prices.dart').readAsStringSync();
        final mtgJsonSync =
            File('bin/sync_prices_mtgjson_fast.dart').readAsStringSync();
        final binder = File('routes/binder/index.dart').readAsStringSync();
        final marketplace =
            File('routes/community/marketplace/index.dart').readAsStringSync();

        expect(route, contains('nullableKnownTotal'));
        expect(route, contains('price_usd = @price'));
        expect(route, contains("'source': pricingSourceScryfall"));
        expect(route, contains('_priceFetchTimeout'));
        expect(scryfallSync, contains("price_source = 'scryfall'"));
        expect(mtgJsonSync, contains("price_source = 'mtgjson'"));
        expect(
          binder,
          isNot(contains('COALESCE(bi.price, c.price_usd, c.price, 0)')),
        );
        expect(marketplace, contains("advertisedCurrency == 'USD'"));
        expect(marketplace, contains('nenhuma conversao cambial foi inferida'));
      },
    );

    test('export route returns presentation text and line count only', () {
      final source =
          File('routes/decks/[id]/export/index.dart').readAsStringSync();

      expect(source, contains('context.request.method != HttpMethod.get'));
      expect(source, contains("'deck_name': deckName"));
      expect(source, contains("'format': deckFormat"));
      expect(source, contains("'text': text"));
      expect(
        source,
        contains("'card_count': commanders.length + mainCards.length"),
      );
      expect(source, isNot(contains("'deck_id':")));
    });

    test(
      'community copy returns deck wrapper and copies basic card fields',
      () {
        final source =
            File('routes/community/decks/[id]/index.dart').readAsStringSync();

        final responseStart = source.indexOf('statusCode: HttpStatus.created,');
        final responseEnd = source.indexOf(
          '  } on Exception catch',
          responseStart,
        );
        expect(responseStart, isNonNegative);
        expect(responseEnd, greaterThan(responseStart));
        final responseSource = source.substring(responseStart, responseEnd);

        expect(
          responseSource,
          contains('body: {\'success\': true, \'deck\': newDeck}'),
        );
        expect(responseSource, isNot(contains("'newDeckId':")));
        expect(
          source,
          contains(
            'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)',
          ),
        );
        expect(
          source,
          contains('SELECT @newDeckId, card_id, quantity, is_commander'),
        );
        expect(source, isNot(contains('condition)')));
      },
    );
  });
}
