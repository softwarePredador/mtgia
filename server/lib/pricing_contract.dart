const pricingCurrencyUsd = 'USD';
const pricingSourceScryfall = 'scryfall';
const pricingSourceMtgJson = 'mtgjson';
const pricingSourceLegacy = 'legacy';
const pricingSourceUnknown = 'unknown';

double? readNullablePrice(Object? value) {
  final parsed = switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text.trim()),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed;
}

String normalizePriceSource(Object? value, {required bool legacyFallback}) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == pricingSourceScryfall ||
      normalized == pricingSourceMtgJson ||
      normalized == pricingSourceLegacy) {
    return normalized!;
  }
  return legacyFallback ? pricingSourceLegacy : pricingSourceUnknown;
}

String aggregatePriceSources(Iterable<Object?> values) {
  final sources =
      values
          .map((value) => value?.toString().trim().toLowerCase())
          .whereType<String>()
          .where((value) => value.isNotEmpty && value != pricingSourceUnknown)
          .toSet();
  if (sources.isEmpty) return pricingSourceUnknown;
  if (sources.length == 1) return sources.single;
  return 'mixed';
}

String pricingCoverageStatus({
  required int pricedCopies,
  required int totalCopies,
}) {
  if (pricedCopies <= 0) return 'unavailable';
  if (pricedCopies < totalCopies) return 'partial';
  return 'complete';
}

double? nullableKnownTotal({
  required double total,
  required int pricedCopies,
}) => pricedCopies > 0 ? double.parse(total.toStringAsFixed(2)) : null;
