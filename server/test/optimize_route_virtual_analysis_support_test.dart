import 'package:server/ai/optimize_route_virtual_analysis_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildOptimizeVirtualPostAnalysis builds future deck and improvements',
      () {
    final result = buildOptimizeVirtualPostAnalysis(
      originalDeck: const [
        {
          'name': 'Mind Stone',
          'type_line': 'Artifact',
          'mana_cost': '{2}',
          'colors': <String>[],
          'cmc': 2.0,
          'oracle_text': '{T}: Add {C}.',
          'quantity': 1,
        },
        {
          'name': 'Island',
          'type_line': 'Basic Land',
          'mana_cost': '',
          'colors': <String>[],
          'cmc': 0.0,
          'oracle_text': '',
          'quantity': 36,
        },
      ],
      validRemovals: const ['Mind Stone'],
      validAdditions: const ['Counterspell'],
      additionsData: const [
        {
          'name': 'Counterspell',
          'type_line': 'Instant',
          'mana_cost': '{U}{U}',
          'colors': ['U'],
          'cmc': 2.0,
          'oracle_text': 'Counter target spell.',
        },
      ],
      deckColors: const ['U'],
      deckAnalysis: const {
        'mana_base_assessment': 'Falta mana',
        'average_cmc': '2.5',
        'type_distribution': {
          'lands': 36,
          'instants': 0,
        },
      },
      effectiveOptimizeArchetype: 'control',
    );

    final names = result.virtualDeck
        .map((card) => card['name']?.toString())
        .whereType<String>()
        .toList();

    expect(names, isNot(contains('Mind Stone')));
    expect(names, contains('Counterspell'));
    expect(result.additionsForAnalysis.single['quantity'], 1);
    expect(result.postAnalysis, contains('average_cmc'));
    expect(
      result.postAnalysis['improvements'],
      contains('Mais interação instant-speed adicionada'),
    );
  });
}
