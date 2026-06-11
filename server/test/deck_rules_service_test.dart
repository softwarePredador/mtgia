import 'package:test/test.dart';

import '../lib/deck_rules_service.dart';

void main() {
  group('parseDeckRulesCmcValue', () {
    test('accepts numeric database values', () {
      expect(parseDeckRulesCmcValue(3), equals(3.0));
      expect(parseDeckRulesCmcValue(2.5), equals(2.5));
    });

    test('accepts string numeric values returned by PostgreSQL numeric', () {
      expect(parseDeckRulesCmcValue('4'), equals(4.0));
      expect(parseDeckRulesCmcValue('3.5'), equals(3.5));
    });

    test('returns null for absent or invalid values', () {
      expect(parseDeckRulesCmcValue(null), isNull);
      expect(parseDeckRulesCmcValue('not-a-number'), isNull);
      expect(parseDeckRulesCmcValue(const <String>[]), isNull);
    });
  });
}
