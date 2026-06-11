import 'package:server/ai/optimize_route_addition_data_support.dart';
import 'package:test/test.dart';

void main() {
  test('canonicalizeOptimizeAdditionNames preserves database casing', () {
    final names = canonicalizeOptimizeAdditionNames(
      validAdditions: const ['sol ring', 'Unknown Tech'],
      validByNameLower: const {
        'sol ring': {
          'name': 'Sol Ring',
        },
      },
    );

    expect(names, ['Sol Ring', 'Unknown Tech']);
  });

  test('mapOptimizeAdditionDataRow normalizes base card fields', () {
    final mapped = mapOptimizeAdditionDataRow(
      [
        'Arcane Signet',
        'Artifact',
        '{2}',
        ['C'],
        2,
        'Add one mana of any color.',
      ],
    );

    expect(mapped, {
      'name': 'Arcane Signet',
      'type_line': 'Artifact',
      'mana_cost': '{2}',
      'colors': ['C'],
      'cmc': 2.0,
      'oracle_text': 'Add one mana of any color.',
    });
  });

  test('mapOptimizeAdditionDataRow includes optional semantic fields', () {
    final mapped = mapOptimizeAdditionDataRow(
      [
        'Esper Sentinel',
        'Artifact Creature',
        '{W}',
        ['W'],
        1,
        'Whenever an opponent casts...',
        [
          {
            'tags': ['tax']
          },
        ],
        [
          {'tag': 'draw', 'confidence': 0.8},
        ],
      ],
      includeSemanticFields: true,
    );

    expect(mapped['semantic_tags_v2'], isA<List>());
    expect(mapped['functional_tags'], isA<List>());
  });

  test('mapOptimizeAdditionDataRows tolerates missing optional columns', () {
    final mapped = mapOptimizeAdditionDataRows(
      [
        [
          'Pongify',
          'Instant',
          '{U}',
          ['U'],
          1,
          'Destroy target creature.',
        ],
      ],
      includeSemanticFields: true,
    );

    expect(mapped.single['name'], 'Pongify');
    expect(mapped.single['semantic_tags_v2'], isNull);
    expect(mapped.single['functional_tags'], isNull);
  });
}
