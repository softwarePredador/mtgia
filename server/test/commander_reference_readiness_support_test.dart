import 'package:server/ai/commander_reference_readiness_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander Reference Readiness Scorecard', () {
    test('marks strong Lorehold-style evidence ready for mini batch', () {
      final scorecard = calculateCommanderReferenceReadinessScorecard(
        const CommanderReferenceReadinessInputs(
          commanderName: 'Lorehold, the Historian',
          commanderCardResolved: true,
          profileAvailable: true,
          profileConfidence: 'high',
          profileSourceCount: 4,
          profileThemeCount: 6,
          profileExpectedPackageCount: 4,
          cardStatsCount: 34,
          cardStatsUnresolvedCount: 0,
          cardStatsPackageCount: 4,
          corpusAvailable: true,
          corpusAcceptedDeckCount: 3,
          corpusCorePackageCount: 26,
          corpusThemePackageCount: 10,
          corpusSupportPackageCount: 12,
          deterministicDeckValid: true,
          deterministicMainQuantity: 99,
          deterministicWarnings: [],
          runtimeProof: CommanderReferenceReadinessRuntimeProof(
            available: true,
            status: 'PASS',
            backendSha: 'd1e1b184',
            withCommander: {
              'http_200': 5,
              'validation_ok': 5,
              'commander_preserved': 5,
              'main_quantity_99': 5,
              'profile_used': 5,
              'stats_used': 5,
              'corpus_used': 5,
              'fallback': 0,
              'timeout_fallback': 0,
            },
          ),
        ),
      );

      expect(scorecard.score, greaterThanOrEqualTo(85));
      expect(scorecard.status, equals('ready_for_mini_batch'));
      expect(scorecard.expansionReady, isTrue);
      expect(scorecard.blockers, isEmpty);
      expect(scorecard.warnings, isEmpty);
      expect(scorecard.gates['runtime_public_gate_passed'], isTrue);
    });

    test('blocks missing commander resolution and unresolved stats', () {
      final scorecard = calculateCommanderReferenceReadinessScorecard(
        const CommanderReferenceReadinessInputs(
          commanderName: 'Example Commander',
          commanderCardResolved: false,
          profileAvailable: true,
          profileConfidence: 'high',
          profileSourceCount: 2,
          profileThemeCount: 3,
          profileExpectedPackageCount: 2,
          cardStatsCount: 12,
          cardStatsUnresolvedCount: 2,
          cardStatsPackageCount: 2,
          corpusAvailable: false,
          corpusAcceptedDeckCount: 0,
          corpusCorePackageCount: 0,
          corpusThemePackageCount: 0,
          corpusSupportPackageCount: 0,
          deterministicDeckValid: false,
          deterministicMainQuantity: 97,
          deterministicWarnings: ['invalid deck'],
        ),
      );

      expect(scorecard.status, equals('blocked'));
      expect(scorecard.expansionReady, isFalse);
      expect(scorecard.blockers, contains('commander_card_not_resolved'));
      expect(scorecard.blockers, contains('card_stats_unresolved_present'));
      expect(
        scorecard.blockers,
        contains('deterministic_reference_deck_invalid'),
      );
      expect(scorecard.warnings, contains('corpus_missing'));
      expect(scorecard.nextActions, isNotEmpty);
    });

    test('parses public runtime proof gate from sanitized summary', () {
      final proof = parseCommanderReferenceReadinessRuntimeProof({
        'status': 'PASS',
        'health': {'git_sha': 'abc123'},
        'by_mode': {
          'with_commander_corpus': {
            'http_200': 5,
            'validation_ok': 5,
            'commander_preserved': 5,
            'main_quantity_99': 5,
            'profile_used': 5,
            'stats_used': 5,
            'corpus_used': 5,
            'fallback': 0,
            'timeout_fallback': 0,
            'invalid_cards_total': 0,
            'off_identity_total': 0,
          },
        },
      });

      expect(proof, isNotNull);
      expect(proof!.available, isTrue);
      expect(proof.backendSha, equals('abc123'));
      expect(proof.gatePassed, isTrue);
    });

    test('accepts flat deterministic reference proof without timeout fallback',
        () {
      final proof = parseCommanderReferenceReadinessRuntimeProof({
        'status': 'PASS',
        'backend_git_sha': 'def456',
        'http_200': 5,
        'validation_ok': 5,
        'commander_preserved': 5,
        'main_quantity_99': 5,
        'profile_used': 5,
        'stats_used': 5,
        'corpus_used': 5,
        'fallback_count': 5,
        'timeout_fallback_count': 0,
        'invalid_cards_total': 0,
        'off_identity_total': 0,
        'p95_ms': 1332,
      });

      expect(proof, isNotNull);
      expect(proof!.available, isTrue);
      expect(proof.backendSha, equals('def456'));
      expect(proof.gatePassed, isTrue);
    });

    test('rejects deterministic reference proof with high p95 latency', () {
      final proof = parseCommanderReferenceReadinessRuntimeProof({
        'status': 'PASS_WITH_RISKS',
        'backend_git_sha': 'def456',
        'http_200': 5,
        'validation_ok': 5,
        'commander_preserved': 5,
        'main_quantity_99': 5,
        'profile_used': 5,
        'stats_used': 5,
        'corpus_used': 5,
        'fallback_count': 5,
        'timeout_fallback_count': 0,
        'invalid_cards_total': 0,
        'off_identity_total': 0,
        'p95_ms': 23000,
      });

      expect(proof, isNotNull);
      expect(proof!.available, isTrue);
      expect(proof.gatePassed, isFalse);
    });

    test('rejects non-fallback proof with invalid cards', () {
      final proof = parseCommanderReferenceReadinessRuntimeProof({
        'status': 'PASS_WITH_RISKS',
        'backend_git_sha': 'def456',
        'http_200': 5,
        'validation_ok': 5,
        'commander_preserved': 5,
        'main_quantity_99': 5,
        'profile_used': 5,
        'stats_used': 5,
        'corpus_used': 5,
        'fallback_count': 0,
        'timeout_fallback_count': 0,
        'invalid_cards_total': 1,
        'off_identity_total': 0,
        'p95_ms': 1200,
      });

      expect(proof, isNotNull);
      expect(proof!.gatePassed, isFalse);
    });

    test('rejects non-fallback proof with high p95 latency', () {
      final proof = parseCommanderReferenceReadinessRuntimeProof({
        'status': 'PASS_WITH_RISKS',
        'backend_git_sha': 'def456',
        'http_200': 5,
        'validation_ok': 5,
        'commander_preserved': 5,
        'main_quantity_99': 5,
        'profile_used': 5,
        'stats_used': 5,
        'corpus_used': 5,
        'fallback_count': 0,
        'timeout_fallback_count': 0,
        'invalid_cards_total': 0,
        'off_identity_total': 0,
        'p95_ms': 23000,
      });

      expect(proof, isNotNull);
      expect(proof!.gatePassed, isFalse);
    });
  });
}
