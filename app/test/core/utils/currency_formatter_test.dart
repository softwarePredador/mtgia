import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats full USD values for the Portuguese interface', () {
      expect(CurrencyFormatter.format(4533.77), r'US$ 4.533,77');
    });

    test('formats compact values without losing the currency', () {
      expect(CurrencyFormatter.format(4533.77, compact: true), r'US$ 4,5 mil');
      expect(
        CurrencyFormatter.format(1250000, currencyCode: 'BRL', compact: true),
        r'R$ 1,3 mi',
      );
    });

    test('keeps unknown currency codes explicit', () {
      expect(CurrencyFormatter.format(12.5, currencyCode: 'TIX'), 'TIX 12,50');
    });

    test('uses USD when an upstream currency code is blank', () {
      expect(CurrencyFormatter.format(12.5, currencyCode: '  '), r'US$ 12,50');
    });
  });
}
