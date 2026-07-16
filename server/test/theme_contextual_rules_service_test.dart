import 'package:test/test.dart';

import '../lib/ai/theme_contextual_rules_service.dart';

void main() {
  group('theme contextual functional tags', () {
    test('reads plural reviewed tags, deduplicates and respects quantity', () {
      final counts = countThemeFunctionsFromCards(const [
        {
          'name': 'Multi-role Engine',
          'quantity': 2,
          'functional_tags': [
            {'tag': 'draw', 'confidence': 0.98},
            {'tag': 'draw', 'confidence': 0.91},
            {'tag': 'engine', 'confidence': 0.64},
            {
              'tags': ['ramp'],
              'role_confidence': 0.90,
            },
          ],
        },
        {
          'name': 'Legacy Removal',
          'quantity': 1,
          'functional_tag': 'Targeted Removal',
        },
      ]);

      expect(counts, containsPair('draw', 2));
      expect(counts, containsPair('ramp', 2));
      expect(counts, containsPair('targeted_removal', 1));
      expect(counts, isNot(contains('engine')));
    });

    test('accepts JSON-encoded plural payloads', () {
      final counts = countThemeFunctionsFromCards(const [
        {
          'name': 'Encoded Tags',
          'quantity': 3,
          'functional_tags': '[{"tag":"spell_payoff","confidence":0.95}]',
        },
      ]);

      expect(counts, equals(const {'spell_payoff': 3}));
    });

    test('serializes critical validation evidence for the route report', () {
      const result = ThemeValidationResult(
        theme: 'spellslinger',
        hasCriticalViolation: true,
        checks: [
          ThemeCheck(
            function: 'spell_payoff',
            current: 2,
            min: 5,
            max: 9,
            priority: 'essential',
            status: 'below_min',
            description: 'Preservar payoffs.',
          ),
        ],
      );

      expect(result.toJson()['has_critical_violation'], isTrue);
      expect(
        (result.toJson()['checks'] as List).single,
        containsPair('function', 'spell_payoff'),
      );
    });
  });
}
