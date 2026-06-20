import 'package:server/ai/optimize_route_warnings_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildOptimizeWarnings returns empty map when no warning applies', () {
    final warnings = buildOptimizeWarnings(
      invalidCards: const [],
      suggestions: const {},
      filteredByColorIdentity: const [],
      filteredByMissingIdentity: const [],
      commanderColorIdentity: const {'R', 'W'},
      blockedByBracket: const [],
      bracket: null,
      blockedByTheme: const [],
      keepTheme: true,
      emptySuggestionFallbackReason: null,
      recognizedSuggestionFormat: true,
      emptySuggestionFallbackApplied: false,
    );

    expect(warnings, isEmpty);
  });

  test('buildOptimizeWarnings includes invalid card details and suggestions',
      () {
    final warnings = buildOptimizeWarnings(
      invalidCards: const ['Unknown Card'],
      suggestions: const {
        'Unknown Card': ['Known Card'],
      },
      filteredByColorIdentity: const [],
      filteredByMissingIdentity: const [],
      commanderColorIdentity: const {'U'},
      blockedByBracket: const [],
      bracket: null,
      blockedByTheme: const [],
      keepTheme: true,
      emptySuggestionFallbackReason: null,
      recognizedSuggestionFormat: true,
      emptySuggestionFallbackApplied: false,
    );

    expect(warnings['invalid_cards'], ['Unknown Card']);
    expect(warnings['suggestions'], {
      'Unknown Card': ['Known Card'],
    });
  });

  test('buildOptimizeWarnings includes color, bracket, theme and fallback data',
      () {
    final warnings = buildOptimizeWarnings(
      invalidCards: const [],
      suggestions: const {},
      filteredByColorIdentity: const ['Swords to Plowshares'],
      filteredByMissingIdentity: const ['Unknown Identity Card'],
      commanderColorIdentity: const {'R', 'W'},
      blockedByBracket: const [
        {'name': 'Mana Crypt', 'reason': 'game_changer_limit'},
      ],
      bracket: 2,
      blockedByTheme: const ['Theme Piece'],
      keepTheme: true,
      emptySuggestionFallbackReason: 'IA retornou sugestões vazias.',
      recognizedSuggestionFormat: true,
      emptySuggestionFallbackApplied: true,
    );

    expect(
      (warnings['filtered_by_color_identity'] as Map)['commander_identity'],
      ['R', 'W'],
    );
    expect(
      (warnings['filtered_by_color_identity'] as Map)['removed_additions'],
      ['Swords to Plowshares'],
    );
    expect(
      (warnings['filtered_by_missing_identity'] as Map)['removed_additions'],
      ['Unknown Identity Card'],
    );
    expect((warnings['blocked_by_bracket'] as Map)['bracket'], 2);
    expect(
      (warnings['blocked_by_bracket'] as Map)['blocked_additions'],
      [
        {'name': 'Mana Crypt', 'reason': 'game_changer_limit'},
      ],
    );
    expect((warnings['blocked_by_theme'] as Map)['blocked_removals'], [
      'Theme Piece',
    ]);
    expect((warnings['empty_suggestions_handling'] as Map), {
      'recognized_format': true,
      'fallback_applied': true,
      'message': 'IA retornou sugestões vazias.',
    });
  });
}
