import 'package:server/ai/optimize_route_empty_fallback_support.dart';
import 'package:test/test.dart';

void main() {
  group('selectEmptySuggestionFallbackRemovalCandidates', () {
    test('prefers nonland cards and skips commander, core cards and duplicates',
        () {
      final candidates = selectEmptySuggestionFallbackRemovalCandidates(
        allCardData: const [
          {'name': 'Lorehold, the Historian', 'type_line': 'Creature'},
          {'name': 'Core Theme Card', 'type_line': 'Artifact'},
          {'name': 'Mountain', 'type_line': 'Basic Land'},
          {'name': 'Slow Spell', 'type_line': 'Sorcery'},
          {'name': 'Slow Spell', 'type_line': 'Sorcery'},
          {'name': 'Clunky Artifact', 'type_line': 'Artifact'},
          {'name': 'Extra Spell', 'type_line': 'Instant'},
        ],
        commanderLower: const {'lorehold, the historian'},
        coreLower: const {'core theme card'},
      );

      expect(candidates, ['Slow Spell', 'Clunky Artifact']);
    });

    test('falls back to lands only when no nonland candidate exists', () {
      final candidates = selectEmptySuggestionFallbackRemovalCandidates(
        allCardData: const [
          {'name': 'Commander', 'type_line': 'Creature'},
          {'name': 'Core Piece', 'type_line': 'Artifact'},
          {'name': 'Plains', 'type_line': 'Basic Land'},
          {'name': 'Mountain', 'type_line': 'Basic Land'},
        ],
        commanderLower: const {'commander'},
        coreLower: const {'core piece'},
      );

      expect(candidates, ['Plains', 'Mountain']);
    });
  });

  group('buildEmptySuggestionFallbackApplication', () {
    test('applies paired removals and non-empty replacement names', () {
      final result = buildEmptySuggestionFallbackApplication(
        removalCandidates: const ['Slow Spell', 'Clunky Artifact'],
        replacements: const [
          {'name': 'Better Spell'},
          {'name': ''},
          {'name': 'Better Artifact'},
        ],
      );

      expect(result.applied, isTrue);
      expect(result.removals, ['Slow Spell', 'Clunky Artifact']);
      expect(result.additions, ['Better Spell', 'Better Artifact']);
      expect(result.replacementCount, 3);
      expect(result.pairCount, 2);
      expect(result.successReason, contains('fallback heurístico'));
    });

    test('does not apply when replacement names are empty', () {
      final result = buildEmptySuggestionFallbackApplication(
        removalCandidates: const ['Slow Spell'],
        replacements: const [
          {'name': ''},
          {'id': 'missing-name'},
        ],
      );

      expect(result.applied, isFalse);
      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.replacementCount, 2);
      expect(result.pairCount, 0);
    });
  });

  group('buildEmptySuggestionFallbackFailureReason', () {
    test('reports no candidate reason', () {
      expect(
        buildEmptySuggestionFallbackFailureReason(
          hasRemovalCandidates: false,
          replacementCount: 0,
        ),
        contains('não possui candidatas seguras'),
      );
    });

    test('reports no replacement reason', () {
      expect(
        buildEmptySuggestionFallbackFailureReason(
          hasRemovalCandidates: true,
          replacementCount: 0,
        ),
        contains('substitutas válidas'),
      );
    });

    test('reports generic unsafe fallback reason', () {
      expect(
        buildEmptySuggestionFallbackFailureReason(
          hasRemovalCandidates: true,
          replacementCount: 2,
        ),
        contains('gerar fallback seguro'),
      );
    });
  });
}
