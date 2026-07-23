import 'package:server/pricing_contract.dart';
import 'package:test/test.dart';

void main() {
  group('pricing contract', () {
    test('keeps missing and invalid prices nullable instead of zero', () {
      expect(readNullablePrice(null), isNull);
      expect(readNullablePrice(''), isNull);
      expect(readNullablePrice('0'), isNull);
      expect(readNullablePrice(-1), isNull);
      expect(readNullablePrice('NaN'), isNull);
      expect(readNullablePrice('12.34'), 12.34);
    });

    test('only emits a total when at least one copy has known price', () {
      expect(nullableKnownTotal(total: 0, pricedCopies: 0), isNull);
      expect(nullableKnownTotal(total: 12.345, pricedCopies: 1), 12.35);
    });

    test('distinguishes unavailable, partial and complete coverage', () {
      expect(
        pricingCoverageStatus(pricedCopies: 0, totalCopies: 100),
        'unavailable',
      );
      expect(
        pricingCoverageStatus(pricedCopies: 98, totalCopies: 100),
        'partial',
      );
      expect(
        pricingCoverageStatus(pricedCopies: 100, totalCopies: 100),
        'complete',
      );
    });

    test('preserves source provenance without inventing one', () {
      expect(
        normalizePriceSource('scryfall', legacyFallback: false),
        pricingSourceScryfall,
      );
      expect(
        normalizePriceSource(null, legacyFallback: true),
        pricingSourceLegacy,
      );
      expect(
        normalizePriceSource(null, legacyFallback: false),
        pricingSourceUnknown,
      );
      expect(aggregatePriceSources(['scryfall', 'mtgjson']), 'mixed');
    });
  });
}
