import 'package:server/ai/optimize_route_post_validation_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildColorIdentityValidationWarning summarizes blocked additions', () {
    final warning = buildColorIdentityValidationWarning(
      const [
        'Swords to Plowshares',
        'Path to Exile',
        'Teferi Protection',
        'Wear'
      ],
    );

    expect(warning, isNotNull);
    expect(warning, contains('4 carta(s)'));
    expect(warning, contains('Swords to Plowshares, Path to Exile'));
    expect(warning, endsWith('...'));
    expect(buildColorIdentityValidationWarning(const []), isNull);
  });

  test('buildEdhrecValidationWarnings flags low synergy and mild novelty', () {
    final lowSynergy = buildEdhrecValidationWarnings(
      commanderName: 'Lorehold, the Historian',
      validAdditions: const ['A', 'B', 'C', 'D'],
      additionsNotInEdhrec: const ['A', 'B', 'C'],
    );

    expect(lowSynergy.single, contains('NÃO aparecem nos dados EDHREC'));
    expect(lowSynergy.single, contains('Lorehold, the Historian'));

    final mildNovelty = buildEdhrecValidationWarnings(
      commanderName: 'Lorehold, the Historian',
      validAdditions: const ['A', 'B', 'C', 'D', 'E', 'F'],
      additionsNotInEdhrec: const ['A', 'B', 'C'],
    );

    expect(mildNovelty.single, contains('podem ser inovadoras'));
  });

  test('buildThemeMismatchWarning returns null for matching themes', () {
    expect(
      buildThemeMismatchWarning(
        targetArchetype: 'artifacts recursion',
        edhrecThemes: const ['Artifacts', 'Graveyard'],
      ),
      isNull,
    );

    final warning = buildThemeMismatchWarning(
      targetArchetype: 'tokens',
      edhrecThemes: const ['Artifacts', 'Graveyard', 'Equipment'],
    );

    expect(warning, contains('Tema detectado "tokens"'));
    expect(warning, contains('Artifacts, Graveyard, Equipment'));
  });

  test('buildPostAnalysisValidationSummary reports warnings and improvements',
      () {
    final summary = buildPostAnalysisValidationSummary(
      effectiveOptimizeArchetype: 'aggro',
      deckAnalysis: const {
        'mana_base_assessment': 'Base de mana equilibrada',
        'average_cmc': '2.2',
        'type_distribution': {
          'lands': 36,
          'instants': 2,
        },
      },
      postAnalysis: const {
        'mana_base_assessment': 'Falta mana colorida',
        'average_cmc': '3.0',
        'type_distribution': {
          'lands': 31,
          'instants': 4,
        },
      },
    );

    expect(summary.warnings, hasLength(3));
    expect(summary.warnings.join('\n'), contains('piorar sua base de mana'));
    expect(summary.warnings.join('\n'), contains('mais lento'));
    expect(summary.warnings.join('\n'), contains('removeu muitos terrenos'));
    expect(summary.improvements, ['Mais interação instant-speed adicionada']);
  });

  test('buildPostAnalysisValidationSummary reports control curve warning', () {
    final summary = buildPostAnalysisValidationSummary(
      effectiveOptimizeArchetype: 'control',
      deckAnalysis: const {
        'mana_base_assessment': 'Falta mana',
        'average_cmc': '4.0',
        'type_distribution': {'lands': 35, 'instants': 2},
      },
      postAnalysis: const {
        'mana_base_assessment': 'Base de mana equilibrada',
        'average_cmc': '3.2',
        'type_distribution': {'lands': 35, 'instants': 2},
      },
    );

    expect(summary.warnings.single, contains('Para Control'));
    expect(summary.improvements, ['Base de mana corrigida']);
  });
}
