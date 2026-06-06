import 'package:test/test.dart';

import '../lib/ai/cmc_safety.dart';

void main() {
  group('CMC safety', () {
    test('parses mana cost symbols into mana value', () {
      expect(parseManaCostCmc('{2}{U}{U}'), equals(4));
      expect(parseManaCostCmc('{X}{R}'), equals(1));
      expect(parseManaCostCmc('{2/W}{G/P}'), equals(3));
      expect(parseManaCostCmc(''), isNull);
    });

    test('recovers corrupted zero CMC from mana cost', () {
      final card = {
        'name': 'Mana Vault',
        'type_line': 'Artifact',
        'cmc': 0,
        'mana_cost': '{1}',
      };

      expect(safeCmcForOptimization(card), equals(1));
      expect(hasSuspiciousNonLandCmc(card), isTrue);
    });

    test('treats unknown non-land CMC as expensive instead of free', () {
      expect(
        safeCmcForOptimization({
          'name': 'Mystery Spell',
          'type_line': 'Sorcery',
          'cmc': 'unknown',
        }),
        equals(99),
      );
    });

    test('keeps lands and real zero-cost spells at zero', () {
      expect(
        safeCmcForOptimization({
          'name': 'Island',
          'type_line': 'Basic Land — Island',
          'cmc': null,
        }),
        equals(0),
      );
      expect(
        safeCmcForOptimization({
          'name': 'Lotus Petal',
          'type_line': 'Artifact',
          'cmc': 0,
          'mana_cost': '{0}',
        }),
        equals(0),
      );
    });
  });
}
