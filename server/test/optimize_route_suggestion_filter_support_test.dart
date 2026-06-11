import 'package:server/ai/optimize_route_suggestion_filter_support.dart';
import 'package:test/test.dart';

void main() {
  test(
      'filters removals not in deck, commanders, core cards and duplicate adds',
      () {
    final result = buildInitialOptimizeSuggestionFilters(
      removals: const [
        ' Lorehold, the Historian ',
        'Sun Titan',
        'Missing Card',
        'Thrill of Possibility',
      ],
      additions: const [
        'Sun Titan',
        'Esper Sentinel',
        'Smothering Tithe',
        'Boros Charm',
      ],
      deckNamesLower: const {
        'lorehold, the historian',
        'sun titan',
        'thrill of possibility',
      },
      commanderLower: const {'lorehold, the historian'},
      coreLower: const {'sun titan'},
      keepTheme: true,
      isComplete: false,
    );

    expect(result.removals, ['Thrill of Possibility']);
    expect(result.additions, ['Esper Sentinel']);
    expect(result.blockedByTheme, ['Sun Titan']);
  });

  test('balances optimize suggestions before and after filtering', () {
    final result = buildInitialOptimizeSuggestionFilters(
      removals: const ['A', 'B', 'C'],
      additions: const ['D'],
      deckNamesLower: const {'a', 'b', 'c'},
      commanderLower: const {},
      coreLower: const {},
      keepTheme: false,
      isComplete: false,
    );

    expect(result.removals, ['A']);
    expect(result.additions, ['D']);
    expect(result.blockedByTheme, isEmpty);
  });

  test(
      'complete mode preserves repeated additions and does not filter deck dupes',
      () {
    final result = buildInitialOptimizeSuggestionFilters(
      removals: const [],
      additions: const ['Plains', 'Plains', 'Sol Ring'],
      deckNamesLower: const {'sol ring'},
      commanderLower: const {},
      coreLower: const {},
      keepTheme: true,
      isComplete: true,
    );

    expect(result.removals, isEmpty);
    expect(result.additions, ['Plains', 'Plains', 'Sol Ring']);
    expect(result.blockedByTheme, isEmpty);
  });
}
