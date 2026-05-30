import 'dart:io';

import 'package:test/test.dart';

import '../lib/edh_bracket_policy.dart';
import '../lib/ai/aggressive_candidate_meta_signal_support.dart';
import '../lib/ai/commander_fallback_policy.dart';
import '../lib/ai/optimization_quality_gate.dart';
import '../lib/ai/optimize_runtime_support.dart';

void main() {
  group('resolveOptimizeIntensity', () {
    test('omitted intensity remains backward-compatible focused default', () {
      final config = resolveOptimizeIntensity(null);

      expect(config.selected, equals('focused'));
      expect(config.wasOmitted, isTrue);
      expect(config.targetMin, equals(6));
      expect(config.targetMax, equals(10));
      expect(config.toJson()['source'], equals('omitted_default'));
    });

    test('maps official intensities to target swap scopes', () {
      final light = resolveOptimizeIntensity('light');
      final focused = resolveOptimizeIntensity('focused');
      final aggressive = resolveOptimizeIntensity('aggressive');
      final rebuild = resolveOptimizeIntensity('rebuild');

      expect(light.targetMin, equals(3));
      expect(light.targetMax, equals(5));
      expect(focused.targetMin, equals(6));
      expect(focused.targetMax, equals(10));
      expect(aggressive.targetMin, equals(10));
      expect(aggressive.targetMax, equals(20));
      expect(rebuild.isRebuild, isTrue);
      expect(rebuild.targetMax, equals(0));
    });

    test('rejects unknown intensity values', () {
      final config = resolveOptimizeIntensity('reckless');

      expect(config.valid, isFalse);
      expect(config.source, equals('invalid'));
    });
  });

  group('shouldUseAsyncOptimizeExecutor', () {
    test('routes aggressive optimize to async by default', () {
      final aggressive = resolveOptimizeIntensity('aggressive');

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: false,
        ),
        isTrue,
      );
    });

    test('preserves focused sync compatibility when async is omitted', () {
      final focused = resolveOptimizeIntensity(null);

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: focused,
          requestMode: 'optimize',
          forceSync: false,
        ),
        isFalse,
      );
    });

    test('honors internal force sync and explicit async opt-out', () {
      final aggressive = resolveOptimizeIntensity('aggressive');

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: true,
        ),
        isFalse,
      );
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: false,
          asyncRequested: false,
        ),
        isFalse,
      );
    });

    test('does not turn complete or rebuild into optimize async jobs', () {
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: resolveOptimizeIntensity('aggressive'),
          requestMode: 'complete',
          forceSync: false,
        ),
        isFalse,
      );
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: resolveOptimizeIntensity('rebuild'),
          requestMode: 'optimize',
          forceSync: false,
          asyncRequested: true,
        ),
        isFalse,
      );
    });
  });

  group('buildOptimizeCacheKey', () {
    test('separates cache entries by intensity', () {
      final light = buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'midrange',
        mode: 'optimize',
        bracket: 2,
        keepTheme: true,
        deckSignature: 'a:1|b:1',
        intensity: 'light',
      );
      final aggressive = buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'midrange',
        mode: 'optimize',
        bracket: 2,
        keepTheme: true,
        deckSignature: 'a:1|b:1',
        intensity: 'aggressive',
      );

      expect(light, isNot(equals(aggressive)));
      expect(light, startsWith('v7:'));
      expect(aggressive, startsWith('v7:'));
    });
  });

  group('aggressive optimize utility', () {
    test('classifies actionable and quality rejected outcomes', () {
      final actionable = buildAggressiveOptimizeUtilitySignal(
        requestedSwaps: 10,
        returnedSwaps: 6,
        rejectionBuckets: const {},
        lowCandidateCoverage: false,
      );
      final rejected = buildAggressiveOptimizeUtilitySignal(
        requestedSwaps: 10,
        returnedSwaps: 0,
        rejectionBuckets: const {'color_identity': 4},
        lowCandidateCoverage: false,
      );

      expect(actionable['status'], equals('actionable'));
      expect(actionable['has_actionable_swaps'], isTrue);
      expect(actionable['needs_product_explanation'], isFalse);
      expect(rejected['status'], equals('quality_rejected'));
      expect(rejected['has_actionable_swaps'], isFalse);
      expect(rejected['needs_product_explanation'], isTrue);
      expect(
        rejected['user_message_key'],
        equals('aggressive_quality_gate_blocked'),
      );
    });

    test('summarizes fixture success rate for release utility gate', () {
      final summary = summarizeAggressiveOptimizeUtilitySamples(
        samples: const [
          {'eligible': true, 'returned_swaps': 4, 'latency_ms': 900},
          {'eligible': true, 'returned_swaps': 2, 'latency_ms': 1100},
          {'eligible': true, 'returned_swaps': 0, 'latency_ms': 1200},
          {'eligible': true, 'returned_swaps': 3, 'latency_ms': 1300},
          {'eligible': false, 'returned_swaps': 0, 'latency_ms': 500},
        ],
        minApplicableRatePercent: 70,
      );

      expect(summary['eligible_samples'], equals(4));
      expect(summary['applicable_samples'], equals(3));
      expect(summary['applicable_rate_percent'], equals(75));
      expect(summary['passes_utility_gate'], isTrue);
      expect(summary['p95_ms'], equals(1300));
    });
  });

  group('landFixesCommanderColors', () {
    test('accepts five-color fixing lands', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text': '{T}, Pay 1 life: Add one mana of any color.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U', 'B', 'G'},
        ),
        isTrue,
      );
    });

    test('accepts fetch-style lands that search matching land types', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text':
                '{T}, Pay 1 life, Sacrifice this land: Search your library for a Plains or Island card, put it onto the battlefield, then shuffle.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U'},
        ),
        isTrue,
      );
    });

    test('rejects utility lands that do not fix commander colors', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text': '{T}: Add {C}{C}.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U'},
        ),
        isFalse,
      );
    });
  });

  group('shouldKeepCommanderFillerCandidate', () {
    test('uses versioned denylist policy for weak commander fillers', () {
      expect(commanderFallbackPolicyVersion, contains('2026_05_28'));
      expect(commanderWeakFillerDenylist, contains('cancel'));
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Cancel',
            'mana_cost': '{1}{U}{U}',
            'oracle_text': 'Counter target spell.',
            'colors': const ['U'],
            'color_identity': const ['U'],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'U'},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });

    test('uses versioned premium policy in commander filler scoring', () {
      final premium = commanderFillerQualityScore({
        'name': 'Arcane Signet',
        'type_line': 'Artifact',
        'oracle_text': '{T}: Add one mana of any color.',
        'mana_cost': '{2}',
        'cmc': 2,
      });
      final generic = commanderFillerQualityScore({
        'name': 'Generic Mana Rock',
        'type_line': 'Artifact',
        'oracle_text': '{T}: Add one mana of any color.',
        'mana_cost': '{2}',
        'cmc': 2,
      });

      expect(commanderPremiumFillerNames, contains('arcane signet'));
      expect(premium, greaterThan(generic));
    });

    test(
        'rejects colored spell inferred only from mana cost for colorless commander',
        () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Swan Song',
            'mana_cost': '{U}',
            'oracle_text':
                'Counter target enchantment, instant, or sorcery spell.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const <String>{},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });

    test('rejects additions outside commander color identity', () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Swords to Plowshares',
            'mana_cost': '{W}',
            'oracle_text': 'Exile target creature.',
            'colors': const ['W'],
            'color_identity': const ['W'],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'U'},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });
  });

  group('bracket safety', () {
    test('detects commander free-cast interaction as free interaction', () {
      final tags = tagCardForBracket(
        name: 'Fierce Guardianship',
        typeLine: 'Instant',
        oracleText:
            'If you control a commander, you may cast this spell without paying its mana cost. Counter target noncreature spell.',
      );

      expect(tags.categories, contains(BracketCategory.freeInteraction));
    });

    test('blocks power additions above low bracket budgets', () {
      final decision = applyBracketPolicyToAdditions(
        bracket: 1,
        currentDeckCards: const [
          {
            'name': 'Sol Ring',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'quantity': 1,
          }
        ],
        additionsCardsData: const [
          {
            'name': 'Mana Crypt',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'quantity': 1,
          }
        ],
      );

      expect(decision.allowed, isEmpty);
      expect(decision.blocked.single['name'], equals('Mana Crypt'));
    });

    test('filler loaders use current deck state for bracket policy', () {
      final source = File(
        'lib/ai/optimize_filler_loader_support.dart',
      ).readAsStringSync();
      final completeSource = File(
        'lib/ai/optimize_complete_support.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('currentDeckCards: const []')));
      expect(source, isNot(contains('if (filtered.isNotEmpty)')));
      expect(source, contains('currentDeckCards: currentDeckCards'));
      expect(completeSource, contains('currentDeckCards: state.virtualDeck'));
      expect(
        source,
        contains('aggregated.length < limit && bracket == null'),
      );
    });
  });

  group('resolveCommanderOptimizeMetaScope', () {
    test('uses competitive commander references only for bracket 3+', () {
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 3,
        ),
        equals('competitive_commander'),
      );
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 4,
        ),
        equals('competitive_commander'),
      );
    });

    test('keeps casual commander out of competitive commander meta', () {
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 2,
        ),
        isNull,
      );
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'modern',
          bracket: 4,
        ),
        isNull,
      );
    });
  });

  group('commander fallback policy', () {
    test('keeps universal and completion staples in policy data', () {
      expect(
        universalCommanderFallbackNames.take(3),
        equals(const ['Sol Ring', 'Arcane Signet', 'Command Tower']),
      );
      expect(commanderCompletionStapleNames, contains('Nature\'s Claim'));
      expect(commanderCompletionStapleNames, contains('Teferi\'s Protection'));
      expect(commanderPremiumFixingLandNames, contains('command tower'));
    });

    test('adds mono-blue contextual foundation names without runtime hardcode',
        () {
      final base = commanderFoundationNamesFor(
        commanderColorIdentity: const {'W', 'U'},
        targetArchetype: 'midrange',
        detectedTheme: null,
      );
      final monoBlueCombo = commanderFoundationNamesFor(
        commanderColorIdentity: const {'U'},
        targetArchetype: 'combo control',
        detectedTheme: 'proliferate',
      );

      expect(base, contains('The One Ring'));
      expect(base, isNot(contains('High Tide')));
      expect(monoBlueCombo, contains('High Tide'));
      expect(monoBlueCombo, contains('Thrummingbird'));
      expect(monoBlueCombo, contains('Pongify'));
    });
  });

  group('aggressive candidate quality ranking', () {
    test('uses role, synergy and meta signal scores before quality gate', () {
      final pairs = [
        {
          'remove': 'Expensive Draw Spell',
          'add': 'Generic Draw Spell',
          'remove_role': 'draw',
          'remove_score': 120,
        },
        {
          'remove': 'Clunky Draw Engine',
          'add': 'Proven Commander Draw',
          'remove_role': 'draw',
          'remove_score': 80,
        },
      ];
      final ranked = rankAggressiveCandidateQualityPairs(
        pairs: pairs,
        bracket: 3,
        signalsByName: {
          'proven commander draw': AggressiveCandidateQualitySignal(
            cardName: 'Proven Commander Draw',
            roles: const {'draw'},
            roleScore: 88,
            functionConfidence: 0.9,
            synergyScore: 92,
            synergyEvidenceCount: 9,
            rejectionPenalty: 0,
            budgetTier: 'accessible',
            bracketScope: 'bracket_2_4',
            sources: const {aggressiveCandidateMetaSignalSource},
          ),
        },
      );

      expect(ranked.first['add'], equals('Proven Commander Draw'));
      expect(
        ranked.first['candidate_quality_sources'],
        contains(aggressiveCandidateMetaSignalSource),
      );
      expect(
        ranked.first['candidate_quality_score'],
        greaterThan(ranked.last['candidate_quality_score'] as int),
      );
    });

    test('aggressive can expose more safe approved swaps than focused scope',
        () {
      final removals = List.generate(12, (i) => 'Slow Ramp Rock $i');
      final additions = List.generate(12, (i) => 'Efficient Ramp Rock $i');
      final originalDeck = [
        for (final name in removals)
          _qualityCard(
            name: name,
            typeLine: 'Artifact',
            manaCost: '{3}',
            cmc: 3,
            oracleText: '{T}: Add one mana of any color.',
          ),
      ];
      final additionsData = [
        for (final name in additions)
          _qualityCard(
            name: name,
            typeLine: 'Artifact',
            manaCost: '{2}',
            cmc: 2,
            oracleText: '{T}: Add one mana of any color.',
          ),
      ];

      final focused = filterUnsafeOptimizeSwapsByCardData(
        removals: removals.take(5).toList(),
        additions: additions.take(5).toList(),
        originalDeck: originalDeck,
        additionsData: additionsData,
        archetype: 'midrange',
      );
      final aggressive = filterUnsafeOptimizeSwapsByCardData(
        removals: removals,
        additions: additions,
        originalDeck: originalDeck,
        additionsData: additionsData,
        archetype: 'midrange',
      );

      expect(focused.removals, hasLength(5));
      expect(aggressive.removals, hasLength(12));
      expect(aggressive.removals.length, greaterThan(focused.removals.length));
    });

    test('exposes safe no-op diagnostics when quality gate rejects all pairs',
        () {
      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Aggro Creature A', 'Aggro Creature B'],
        additions: const ['Slow Engine A', 'Slow Engine B'],
        originalDeck: [
          _qualityCard(
            name: 'Aggro Creature A',
            typeLine: 'Creature - Goblin',
            manaCost: '{1}{R}',
            cmc: 2,
            oracleText: 'Haste.',
          ),
          _qualityCard(
            name: 'Aggro Creature B',
            typeLine: 'Creature - Goblin',
            manaCost: '{1}{R}',
            cmc: 2,
            oracleText: 'Haste.',
          ),
        ],
        additionsData: [
          _qualityCard(
            name: 'Slow Engine A',
            typeLine: 'Artifact',
            manaCost: '{6}',
            cmc: 6,
            oracleText: 'At the beginning of your upkeep, draw a card.',
          ),
          _qualityCard(
            name: 'Slow Engine B',
            typeLine: 'Artifact',
            manaCost: '{6}',
            cmc: 6,
            oracleText: 'At the beginning of your upkeep, draw a card.',
          ),
        ],
        archetype: 'aggro',
      );
      final buckets =
          bucketOptimizeQualityGateDroppedReasons(result.droppedReasons);

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(
          buckets.values.fold<int>(0, (sum, count) => sum + count), equals(2));
      expect(buckets, contains('curve_or_role_mismatch'));
    });
  });
}

Map<String, dynamic> _qualityCard({
  required String name,
  required String typeLine,
  required String manaCost,
  required num cmc,
  required String oracleText,
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'mana_cost': manaCost,
    'cmc': cmc,
    'oracle_text': oracleText,
    'quantity': 1,
  };
}
