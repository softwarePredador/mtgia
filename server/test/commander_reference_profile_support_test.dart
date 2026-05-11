import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander Reference Profile v1 | Lorehold', () {
    test('matches only the exact Lorehold commander name', () {
      expect(
        isLoreholdCommanderReferenceCandidate('Lorehold, the Historian'),
        isTrue,
      );
      expect(
        isLoreholdCommanderReferenceCandidate('  lorehold,   the historian '),
        isTrue,
      );
      expect(isLoreholdCommanderReferenceCandidate('Lorehold'), isFalse);
      expect(
        isLoreholdCommanderReferenceCandidate('Lorehold Apprentice'),
        isFalse,
      );
      expect(
        isLoreholdCommanderReferenceCandidate('Atraxa, Praetors\' Voice'),
        isFalse,
      );
    });

    test('uses an explicit confidence ordering and rejects weak profiles', () {
      expect(isReferenceProfileConfidenceUsable('high'), isTrue);
      expect(isReferenceProfileConfidenceUsable('medium-high'), isTrue);
      expect(isReferenceProfileConfidenceUsable('medium'), isTrue);
      expect(isReferenceProfileConfidenceUsable('medium-low'), isFalse);
      expect(isReferenceProfileConfidenceUsable('low'), isFalse);
      expect(isReferenceProfileConfidenceUsable('not proven'), isFalse);
      expect(isReferenceProfileConfidenceUsable('unknown'), isFalse);
    });

    test('builds the persisted aggregate profile without copied decklists', () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );

      expect(profile['commander'], equals(loreholdReferenceCommanderName));
      expect(profile['confidence'], equals('high'));
      expect(profile['source_count'], equals(4));
      expect(profile['role_targets'], isA<Map>());
      expect(profile['expected_packages'], isA<Map>());
      expect(profile['avoid_patterns'], isA<List>());
      expect(
        (profile['source_limit_notes'] as List).join(' ').toLowerCase(),
        contains('no copied public decklist'),
      );
    });

    test('prompt guidance forces Lorehold, R/W identity and avoid patterns',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final prompt = buildCommanderReferenceProfilePrompt(profile);

      expect(prompt, contains('"Lorehold, the Historian"'));
      expect(prompt, contains('Color identity is exactly Red/White'));
      expect(prompt, contains('boros_miracle_big_spells'));
      expect(prompt, contains('topdeck_miracle_setup'));
      expect(prompt, contains('blue_miracle_package'));
      expect(prompt, contains('Do not copy a public decklist'));
    });

    test('diagnostics expose safe metadata only', () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final diagnostics = buildCommanderReferenceDiagnostics(profile);

      expect(diagnostics['reference_profile_used'], isTrue);
      expect(diagnostics['reference_card_stats_used'], isFalse);
      expect(diagnostics['on_theme_candidate_count'], equals(0));
      expect(diagnostics['unresolved_reference_cards'], isEmpty);
      expect(diagnostics['package_keys'], isEmpty);
      expect(diagnostics['profile_confidence'], equals('high'));
      expect(diagnostics['source_count'], equals(4));
      expect(diagnostics['themes'], isA<List>());
      expect(diagnostics.keys, isNot(contains('profile_json')));
      expect(diagnostics.toString().toLowerCase(), isNot(contains('secret')));
    });
  });
}
