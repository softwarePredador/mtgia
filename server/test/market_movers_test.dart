import 'package:server/market_movers.dart';
import 'package:test/test.dart';

void main() {
  group('market movers contract', () {
    test('normalizes public query params without changing app defaults', () {
      expect(normalizeMarketMoversLimit(null), 20);
      expect(normalizeMarketMoversLimit('5'), 5);
      expect(normalizeMarketMoversLimit('0'), 1);
      expect(normalizeMarketMoversLimit('999'), 50);
      expect(normalizeMarketMoversLimit('bad'), 20);

      expect(normalizeMarketMoversMinPrice(null), 1.0);
      expect(normalizeMarketMoversMinPrice('1.25'), 1.25);
      expect(normalizeMarketMoversMinPrice('bad'), 1.0);
      expect(normalizeMarketMoversMinPrice('-2'), 1.0);
      expect(normalizeMarketMoversMinPrice('NaN'), 1.0);
    });

    test('builds the JSON shape consumed by MarketProvider', () {
      final row = [
        'card-1',
        'Sol Ring',
        'CMM',
        'https://example.test/card.jpg',
        'uncommon',
        'Artifact',
        '2.50',
        2,
        '0.50',
        '25.00',
      ];

      final payload = buildMarketMoversPayload(
        date: '2026-04-29',
        previousDate: '2026-04-28',
        gainers: [buildMarketMoverRow((index) => row[index])],
        losers: const [],
        totalTracked: 30569,
      );

      expect(
          payload.keys,
          containsAll([
            'date',
            'previous_date',
            'gainers',
            'losers',
            'total_tracked',
          ]));
      expect(payload['date'], '2026-04-29');
      expect(payload['previous_date'], '2026-04-28');
      expect(payload['total_tracked'], 30569);
      expect(payload['losers'], isEmpty);

      final gainers = payload['gainers'] as List<Map<String, dynamic>>;
      expect(gainers.single['card_id'], 'card-1');
      expect(gainers.single['name'], 'Sol Ring');
      expect(gainers.single['price_today'], 2.5);
      expect(gainers.single['price_yesterday'], 2.0);
      expect(gainers.single['change_usd'], 0.5);
      expect(gainers.single['change_pct'], 25.0);
    });

    test('uses bounded query patterns for the hot path', () {
      expect(marketMoversSummarySql, isNot(contains('SELECT DISTINCT')));
      expect(marketMoversSummarySql, isNot(contains('COUNT(DISTINCT')));
      expect(marketMoversGainersSql, contains('MATERIALIZED'));
      expect(marketMoversGainersSql, contains('LIMIT @limit'));
      expect(marketMoversLosersSql, contains('MATERIALIZED'));
      expect(marketMoversLosersSql, contains('LIMIT @limit'));
    });

    test('maps thousands of rows within a small local budget', () {
      final sw = Stopwatch()..start();
      final rows = List.generate(5000, (index) {
        final row = [
          'card-$index',
          'Card $index',
          'SET',
          null,
          'rare',
          'Creature',
          2.0 + index,
          1.0 + index,
          1.0,
          100.0 / (index + 1),
        ];
        return buildMarketMoverRow((cell) => row[cell]);
      });
      sw.stop();

      expect(rows, hasLength(5000));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  group('MarketMoversCache', () {
    test('returns fresh entries and allows stale entries for timeout fallback',
        () async {
      final cache = MarketMoversCache(ttl: const Duration(milliseconds: 10));
      final payload = buildMarketMoversPayload(
        date: '2026-04-29',
        previousDate: '2026-04-28',
        gainers: const [],
        losers: const [],
        totalTracked: 1,
      );

      cache.set(5, 1.0, payload);
      expect(cache.get(5, 1.0), isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cache.get(5, 1.0), isNull);
      expect(cache.get(5, 1.0, allowStale: true), isNotNull);
    });
  });
}
