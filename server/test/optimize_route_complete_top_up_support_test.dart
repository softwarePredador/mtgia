import 'package:server/ai/optimize_route_complete_top_up_support.dart';
import 'package:test/test.dart';

void main() {
  test('deduplicates nonbasic additions in singleton formats', () {
    final seed = buildOptimizeCompleteTopUpSeed(
      validAdditions: const ['Sol Ring', 'Sol Ring', 'Island', 'Island'],
      desired: 4,
      basicNames: const ['Island'],
      deckFormat: 'Commander',
    );

    expect(seed.countsByName, {'Sol Ring': 1, 'Island': 2});
    expect(seed.missing, 1);
  });

  test('keeps nonbasic copies outside singleton formats', () {
    final seed = buildOptimizeCompleteTopUpSeed(
      validAdditions: const ['Lightning Bolt', 'Lightning Bolt'],
      desired: 2,
      basicNames: const ['Mountain'],
      deckFormat: 'modern',
    );

    expect(seed.countsByName, {'Lightning Bolt': 2});
    expect(seed.missing, 0);
  });

  test('adds missing basics round-robin and builds detailed entries', () {
    final seed = buildOptimizeCompleteTopUpSeed(
      validAdditions: const ['Sol Ring'],
      desired: 5,
      basicNames: const ['Plains', 'Mountain'],
      deckFormat: 'Commander',
    );

    final result = buildOptimizeCompleteTopUpResult(
      seed: seed,
      basicIdsByName: const {
        'Mountain': 'mountain-id',
        'Plains': 'plains-id',
      },
      validByNameLower: const {
        'sol ring': {'id': 'sol-ring-id', 'name': 'Sol Ring'},
      },
    );

    expect(result.additions, ['Sol Ring', 'Mountain', 'Plains']);
    expect(result.additionsDetailed, [
      {'name': 'Sol Ring', 'card_id': 'sol-ring-id', 'quantity': 1},
      {'name': 'Mountain', 'card_id': 'mountain-id', 'quantity': 2},
      {'name': 'Plains', 'card_id': 'plains-id', 'quantity': 2},
    ]);
  });

  test('skips entries without card ids like previous route behavior', () {
    const seed = OptimizeCompleteTopUpSeed(
      countsByName: {'Unknown': 1},
      missing: 0,
      basicNames: [],
    );

    final result = buildOptimizeCompleteTopUpResult(
      seed: seed,
      basicIdsByName: const {},
      validByNameLower: const {},
    );

    expect(result.additions, isEmpty);
    expect(result.additionsDetailed, isEmpty);
  });
}
