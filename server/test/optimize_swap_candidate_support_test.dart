import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_runtime_support.dart' as runtime;
import '../lib/ai/optimize_swap_candidate_support.dart';

Pool _unusedPool() {
  return Pool.withEndpoints([
    Endpoint(
      host: '127.0.0.1',
      port: 65535,
      database: 'unused',
      username: 'unused',
      password: 'unused',
    ),
  ], settings: const PoolSettings(maxConnectionCount: 1));
}

void main() {
  group('optimize swap candidate support', () {
    test('binder preference parameters have explicit PostgreSQL types', () {
      final source =
          File(
            'lib/ai/optimize_swap_candidate_support.dart',
          ).readAsStringSync();

      expect(source, contains('CAST(@prefer_collection AS boolean)'));
      expect(source, contains("NULLIF(CAST(@user_id AS text), '')"));
      expect(
        source,
        contains("CAST(NULLIF(CAST(@user_id AS text), '') AS uuid)"),
      );
    });

    test('returns no swaps for empty deck without touching database', () async {
      final pool = _unusedPool();
      addTearDown(pool.close);

      final result = await buildDeterministicOptimizeSwapCandidates(
        pool: pool,
        allCardData: const [],
        commanders: const ['Talrand, Sky Summoner'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'control',
        bracket: 2,
        keepTheme: true,
        detectedTheme: null,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(result, isEmpty);
    });

    test(
      'runtime re-export keeps existing swap builder API compatible',
      () async {
        final pool = _unusedPool();
        addTearDown(pool.close);

        final result = await runtime.buildDeterministicOptimizeSwapCandidates(
          pool: pool,
          allCardData: const [],
          commanders: const ['Talrand, Sky Summoner'],
          commanderColorIdentity: const {'U'},
          targetArchetype: 'control',
          bracket: 2,
          keepTheme: true,
          detectedTheme: null,
          coreCards: const [],
          commanderPriorityNames: const [],
        );

        expect(result, isEmpty);
        expect(runtime.findSynergyReplacements, isA<Function>());
      },
    );

    test('matches replacement need from persisted multi-role tags', () {
      final candidate = {
        'name': 'Source-backed Engine',
        'type_line': 'Enchantment',
        'oracle_text': 'Whenever you cast your second spell each turn, scry 1.',
        'functional_tags': const ['engine', 'draw'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 72,
      };

      expect(
        matchesFunctionalNeedForCandidate('draw', candidate: candidate),
        isTrue,
      );
      expect(
        matchesFunctionalNeedForCandidate('engine', candidate: candidate),
        isTrue,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'draw',
          candidate: candidate,
        ),
        greaterThan(90),
      );
    });

    test(
      'matches replacement need from semantic v2 when text is ambiguous',
      () {
        final candidate = {
          'name': 'Traceable Answer',
          'type_line': 'Instant',
          'oracle_text': 'Choose one — target player investigates.',
          'functional_tags': const <String>[],
          'semantic_tags_v2': const [
            {
              'role_confidence': 0.91,
              'tags': ['removal', 'protection'],
            },
          ],
          'best_role_score': 51,
        };

        expect(
          matchesFunctionalNeedForCandidate('removal', candidate: candidate),
          isTrue,
        );
        expect(
          semanticReplacementScoreBoost(
            functionalNeed: 'removal',
            candidate: candidate,
          ),
          greaterThan(90),
        );
      },
    );

    test('does not fill a generic ramp need with contextual ramp tags', () {
      final contextualRamp = {
        'name': 'Ruby Medallion',
        'type_line': 'Artifact',
        'oracle_text': 'Red spells you cast cost {1} less to cast.',
        'functional_tags': const ['ramp'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 92,
      };
      final genericFloorRamp = {
        'name': 'Arcane Signet',
        'type_line': 'Artifact',
        'oracle_text':
            '{T}: Add one mana of any color in your commander\'s color identity.',
        'functional_tags': const ['ramp'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 92,
      };

      expect(
        matchesFunctionalNeedForCandidate('ramp', candidate: contextualRamp),
        isFalse,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'ramp',
          candidate: contextualRamp,
        ),
        equals(0),
      );
      expect(
        matchesFunctionalNeedForCandidate('ramp', candidate: genericFloorRamp),
        isTrue,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'ramp',
          candidate: genericFloorRamp,
        ),
        greaterThan(90),
      );
    });
  });
}
