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

    test('derives profile confidence conservatively from commander deck count',
        () {
      expect(
          commanderReferenceConfidenceFromDeckCount(0), equals('not_proven'));
      expect(commanderReferenceConfidenceFromDeckCount(12), equals('low'));
      expect(
          commanderReferenceConfidenceFromDeckCount(75), equals('medium_low'));
      expect(commanderReferenceConfidenceFromDeckCount(250), equals('medium'));
      expect(
        commanderReferenceConfidenceFromDeckCount(1500),
        equals('medium_high'),
      );
      expect(commanderReferenceConfidenceFromDeckCount(5000), equals('high'));
    });

    test('prefers a usable persisted profile when it exists', () {
      final persisted = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'persisted_v1',
        source: 'persisted_profile',
        confidence: 'high',
        sourceCount: 2,
        colorIdentity: const ['U'],
        themes: const [
          {'name': 'value', 'confidence': 'high'}
        ],
        roleTargets: const {},
        expectedPackages: const {},
        avoidPatterns: const [],
      );

      final resolved = resolveRuntimeCommanderReferenceProfile(
        commanderName: 'Test Commander',
        persistedProfile: persisted,
      );

      expect(resolved, isNotNull);
      expect(resolved!['version'], equals('persisted_v1'));
      expect(resolved['source'], equals('persisted_profile'));
      expect(resolved.containsKey('runtime_profile_origin'), isFalse);
    });

    test('accepts a medium-confidence persisted profile even if it is sparse',
        () {
      final resolved = resolveRuntimeCommanderReferenceProfile(
        commanderName: 'Exact Commander',
        persistedProfile: {
          'commander': 'Exact Commander',
          'source': 'edhrec',
          'confidence': 'medium',
          'source_count': 1,
          'themes': const ['tokens'],
          'average_type_distribution': const {'creatures': 24},
        },
      );

      expect(resolved, isNotNull);
      expect(resolved!['source'], equals('edhrec'));
      expect(resolved['confidence'], equals('medium'));
      expect(resolved['source_count'], equals(1));
      expect(resolved.containsKey('runtime_profile_origin'), isFalse);
    });

    test(
        'falls back to the built-in Lorehold profile when persisted row is weak',
        () {
      final resolved = resolveRuntimeCommanderReferenceProfile(
        commanderName: loreholdReferenceCommanderName,
        persistedProfile: {
          'commander': loreholdReferenceCommanderName,
          'confidence': 'low',
          'source_count': 0,
        },
        fallbackUpdatedAt: DateTime.utc(2026, 6, 16, 18),
      );

      expect(resolved, isNotNull);
      expect(resolved!['commander'], equals(loreholdReferenceCommanderName));
      expect(resolved['confidence'], equals('high'));
      expect(resolved['source_count'], equals(4));
      expect(resolved['runtime_profile_origin'], equals('built_in_fallback'));
      expect(
        resolved['runtime_profile_reason'],
        equals('persisted_profile_missing_or_not_usable'),
      );
    });

    test('does not invent a built-in fallback for unrelated commanders', () {
      final resolved = resolveRuntimeCommanderReferenceProfile(
        commanderName: 'Atraxa, Praetors\' Voice',
        persistedProfile: {
          'commander': 'Atraxa, Praetors\' Voice',
          'confidence': 'low',
        },
      );

      expect(resolved, isNull);
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

    test('builds a generic commander profile payload for future commanders',
        () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium-high',
        sourceCount: 2,
        colorIdentity: const ['G', 'U', 'G'],
        themes: const [
          {'name': 'test_value', 'confidence': 'medium'}
        ],
        roleTargets: const {
          'lands': {'min': 36, 'max': 38}
        },
        expectedPackages: const {
          'test_package': ['Cultivate']
        },
        avoidPatterns: const [
          {
            'pattern': 'off_color',
            'examples': ['Lightning Bolt'],
            'reason': 'outside commander identity',
          }
        ],
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );

      expect(profile['commander'], equals('Test Commander'));
      expect(profile['confidence'], equals('medium_high'));
      expect(profile['color_identity'], equals(['G', 'U']));
      expect(profile['expected_packages'], contains('test_package'));
      expect(isReferenceProfileConfidenceUsable(profile['confidence']), isTrue);
    });

    test('generic prompt uses commander name and profile color identity', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['B', 'G'],
        themes: const [
          {'name': 'graveyard_value', 'confidence': 'medium'}
        ],
        roleTargets: const {},
        expectedPackages: const {},
        avoidPatterns: const [],
      );

      final prompt = buildCommanderReferenceProfilePrompt(profile);

      expect(prompt, contains('"Test Commander"'));
      expect(prompt, contains('B/G'));
      expect(prompt, contains('graveyard_value'));
      expect(prompt, isNot(contains('Lorehold')));
    });

    test('prompt guidance forces Lorehold, R/W identity and avoid patterns',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final prompt = buildCommanderReferenceProfilePrompt(profile);

      expect(prompt, contains('"Lorehold, the Historian"'));
      expect(prompt, contains('Color identity is exactly R/W'));
      expect(prompt, contains('Every nonland, split, MDFC'));
      expect(prompt, contains('replace it with an on-color or colorless'));
      expect(prompt, contains('do not infer cards from generic off-color'));
      expect(prompt, contains('if color identity is uncertain, omit'));
      expect(prompt, contains('boros_miracle_big_spells'));
      expect(prompt, contains('topdeck_miracle_setup'));
      expect(prompt, contains('topdeck_and_miracle_setup (7 candidates)'));
      expect(prompt, isNot(contains('Temporal Mastery')));
      expect(prompt, isNot(contains('Brainstorm')));
      expect(prompt, contains('blue_miracle_package'));
      expect(prompt, contains('Do not copy a public decklist'));
    });

    test('diagnostics expose safe metadata only', () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final diagnostics = buildCommanderReferenceDiagnostics(
        profile,
        referenceDeterministicDeckDiagnostics: const {
          'built_in_fallback_enabled': true,
          'built_in_fallback_used_count': 12,
          'built_in_fallback_only_count': 4,
        },
      );

      expect(diagnostics['reference_profile_used'], isTrue);
      expect(diagnostics['reference_card_stats_used'], isFalse);
      expect(diagnostics['on_theme_candidate_count'], equals(0));
      expect(diagnostics['unresolved_reference_cards'], isEmpty);
      expect(diagnostics['package_keys'], isEmpty);
      expect(diagnostics['profile_confidence'], equals('high'));
      expect(diagnostics['source_count'], equals(4));
      expect(diagnostics['themes'], isA<List>());
      expect(
        (diagnostics['reference_deterministic_deck']
            as Map)['built_in_fallback_enabled'],
        isTrue,
      );
      expect(diagnostics.keys, isNot(contains('profile_json')));
      expect(diagnostics.toString().toLowerCase(), isNot(contains('secret')));
    });

    test(
        'diagnostics expose runtime fallback origin only when profile carries it',
        () {
      final resolved = resolveRuntimeCommanderReferenceProfile(
        commanderName: loreholdReferenceCommanderName,
        persistedProfile: {
          'commander': loreholdReferenceCommanderName,
          'confidence': 'low',
          'source_count': 0,
        },
      );

      expect(resolved, isNotNull);
      final diagnostics = buildCommanderReferenceDiagnostics(resolved!);

      expect(diagnostics['reference_profile_used'], isTrue);
      expect(
          diagnostics['runtime_profile_origin'], equals('built_in_fallback'));
      expect(
        diagnostics['runtime_profile_reason'],
        equals('persisted_profile_missing_or_not_usable'),
      );
      expect(diagnostics.toString().toLowerCase(), isNot(contains('secret')));
    });
  });
}
