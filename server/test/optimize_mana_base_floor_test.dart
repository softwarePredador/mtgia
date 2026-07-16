import 'package:test/test.dart';

import '../lib/ai/deck_state_analysis.dart';
import '../lib/ai/optimize_state_support.dart';

void main() {
  group('Commander mana-base floor', () {
    const symbols = {'W': 20, 'U': 0, 'B': 0, 'R': 0, 'G': 0};
    const sources = {'W': 20, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'Any': 0};

    test('core assessment flags 32 lands against the 34 floor', () {
      final assessment = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        32,
      );

      expect(assessment, contains('Poucos terrenos'));
      expect(assessment, contains('Tem 32'));
      expect(assessment, contains('mínimo seguro 34'));
    });

    test('route analyzer uses the same floor and message', () {
      final analyzer = DeckArchetypeAnalyzer(
        const [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'oracle_text': '{T}: Add {W}.',
            'quantity': 32,
          },
          {
            'name': 'White Spell',
            'type_line': 'Sorcery',
            'mana_cost': '{W}',
            'oracle_text': 'Draw a card.',
            'quantity': 1,
          },
        ],
        const ['W'],
      );

      final assessment = analyzer.analyzeManaBase()['assessment'] as String;
      expect(assessment, contains('Poucos terrenos'));
      expect(assessment, contains('mínimo seguro 34'));
    });

    test('34 lands no longer emits the low-land warning', () {
      final assessment = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        34,
      );

      expect(assessment, isNot(contains('Poucos terrenos')));
    });
  });
}
