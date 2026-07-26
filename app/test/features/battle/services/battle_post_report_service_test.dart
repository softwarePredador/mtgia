import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_post_report.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/services/battle_post_report_service.dart';

void main() {
  const service = BattlePostReportService();

  group('BattlePostReportService.build', () {
    test('builds a report only from observed payload fields', () {
      final detail = BattleReplayDetail.fromJson({
        'id': 'replay-1',
        'deck_id': 'deck-a',
        'deck_a_id': 'deck-a',
        'deck_b_id': 'deck-b',
        'opponent_deck_id': 'deck-b',
        'outcome': 'completed',
        'winner_deck_id': 'deck-a',
        'turns_played': 7,
        'duration_ms': 1234,
        'engine': 'xmage',
        'engine_commit': 'xmage-commit',
        'timeout_ms': 40000,
        'attempt_provenance': {'seed': 77},
        'deck_revision': {
          'subject_deck_hash': 'deck-a-hash',
          'deck_a_hash': 'deck-a-hash',
          'deck_b_hash': 'deck-b-hash',
        },
        'learning_contract': {
          'schema_version': 'external_battle_learning_v1',
          'event_stream_completeness': 'visible_activity_lower_bound',
          'absence_proves_nonuse': false,
          'named_draw_identity_available': false,
          'ai_decision_rationale_available': false,
          'combat_activity_available': true,
        },
        'events': [
          {
            'event_type': 'spell_cast',
            'actor': 'Player A',
            'subject_deck_key': 'deck_a',
            'card_name': 'Sol Ring',
          },
          {'event_type': 'waiting', 'message': 'Player A casts a hidden card'},
          {'message': 'Player B activated something'},
        ],
        'visual_snapshots': [
          {
            'index': 0,
            'turn': 1,
            'players': [
              {'deck_key': 'deck_a', 'name': 'Player A', 'life': 40},
              {'deck_key': 'deck_b', 'name': 'Player B', 'life': 40},
            ],
          },
          {
            'index': 2,
            'turn': 2,
            'players': [
              {'deck_key': 'deck_a', 'name': 'Player A', 'life': 36},
              {'deck_key': 'deck_b', 'name': 'Player B'},
            ],
          },
        ],
      });

      final report = service.build(detail);

      expect(report.n, 1);
      expect(report.outcome, BattleReportOutcome.completed);
      expect(report.completedResult, BattleCompletedResult.subjectWin);
      expect(report.turnCount, 7);
      expect(report.durationMs, 1234);
      expect(report.identity.subjectDeckHash, 'deck-a-hash');
      expect(report.identity.opponentDeckHash, 'deck-b-hash');
      expect(report.identity.engine, 'xmage');
      expect(report.identity.engineCommit, 'xmage-commit');
      expect(report.identity.timeoutMs, 40000);
      expect(report.identity.seed, 77);
      expect(report.reliability.absenceProvesNonuse, isFalse);
      expect(report.reliability.absenceSupportsNonuse, isFalse);
      expect(report.lifeCurve, hasLength(3));
      expect(
        report.lifeCurve.map((point) => point.life),
        orderedEquals([40, 40, 36]),
      );
      expect(report.lifeCurve.map((point) => point.source).toSet(), {
        BattleEvidenceSource.snapshot,
      });
      expect(report.observedActivities, hasLength(1));
      expect(report.observedActivities.single.type, 'spell_cast');
      expect(report.observedActivities.single.cardName, 'Sol Ring');
      expect(report.observedActivities.single.hasNamedCard, isTrue);
      expect(report.observedActivityCounts, {'spell_cast': 1});
      expect(
        report.observability[BattleReportObservable.namedDrawIdentity],
        BattleObservableState.unavailable,
      );
      expect(
        report.observability[BattleReportObservable.aiDecisionRationale],
        BattleObservableState.unavailable,
      );
      expect(
        report.observability[BattleReportObservable.typedActivity],
        BattleObservableState.available,
      );
    });

    test(
      'does not turn parser defaults or empty evidence into conclusions',
      () {
        final detail = BattleReplayDetail.fromJson({
          'id': 'legacy-replay',
          'deck_id': 'deck-a',
          'events': const [],
          'visual_snapshots': const [],
          'learning_contract': const {
            'schema_version': 'external_battle_learning_v1',
            'event_stream_completeness': 'lower_bound',
            'absence_proves_nonuse': false,
            'named_draw_identity_available': false,
            'ai_decision_rationale_available': false,
          },
        });

        expect(detail.summary.status, 'legacy_unknown');

        final report = service.build(detail);

        expect(report.outcome, BattleReportOutcome.unknown);
        expect(report.completedResult, BattleCompletedResult.unknown);
        expect(report.turnCount, isNull);
        expect(report.durationMs, isNull);
        expect(report.lifeCurve, isEmpty);
        expect(report.observedActivities, isEmpty);
        expect(
          report.unknownObservables,
          containsAll({
            BattleReportObservable.outcome,
            BattleReportObservable.lifeCurve,
            BattleReportObservable.typedActivity,
            BattleReportObservable.duration,
            BattleReportObservable.engine,
            BattleReportObservable.engineCommit,
            BattleReportObservable.timeoutPolicy,
          }),
        );
        expect(
          report.unavailableObservables,
          containsAll({
            BattleReportObservable.namedDrawIdentity,
            BattleReportObservable.aiDecisionRationale,
          }),
        );
      },
    );

    test('uses explicit life events and never parses narrative text', () {
      final report = service.build(
        BattleReplayDetail.fromJson({
          'id': 'event-life',
          'deck_id': 'deck-a',
          'outcome': 'completed',
          'events': const [
            {'event_type': 'life_change', 'player': 'deck_a', 'life_after': 36},
            {'event_type': 'damage', 'actor': 'deck_a', 'life_after': 30},
            {'event_type': 'waiting', 'message': 'deck_b is now at 12 life'},
          ],
        }),
      );

      expect(report.lifeCurve, hasLength(1));
      expect(report.lifeCurve.single.player, 'deck_a');
      expect(report.lifeCurve.single.life, 36);
      expect(report.lifeCurve.single.source, BattleEvidenceSource.event);
      expect(
        report.observedActivities.map((activity) => activity.type),
        orderedEquals(['life_change', 'damage']),
      );
    });

    test('keeps empty activity unknown under a complete stream contract', () {
      final report = service.build(
        BattleReplayDetail.fromJson({
          'id': 'empty-complete-stream',
          'deck_id': 'deck-a',
          'outcome': 'completed',
          'events': const [],
          'learning_contract': const {
            'schema_version': 'future_complete_contract_v1',
            'event_stream_completeness': 'complete',
            'absence_proves_nonuse': true,
          },
        }),
      );

      expect(report.reliability.absenceSupportsNonuse, isTrue);
      expect(report.observedActivities, isEmpty);
      expect(
        report.observability[BattleReportObservable.typedActivity],
        BattleObservableState.unknown,
      );
    });

    test(
      'keeps censored and timeout results non-terminal for winner claims',
      () {
        final censored = _report(
          service,
          outcome: 'censored',
          winnerDeckId: 'deck-a',
        );
        final timeout = _report(
          service,
          outcome: 'timed_out',
          winnerDeckId: 'deck-a',
        );

        expect(censored.outcome, BattleReportOutcome.censored);
        expect(censored.completedResult, BattleCompletedResult.unknown);
        expect(timeout.outcome, BattleReportOutcome.timeout);
        expect(timeout.completedResult, BattleCompletedResult.unknown);
      },
    );
  });

  group('BattlePostReportService.summarize', () {
    test('separates completion, censoring and timeout and puts n on rates', () {
      final sample = service.summarize([
        _report(service, outcome: 'completed', winnerDeckId: 'deck-a'),
        _report(service, outcome: 'completed'),
        _report(service, outcome: 'censored', winnerDeckId: 'deck-a'),
        _report(service, outcome: 'timeout', winnerDeckId: 'deck-a'),
      ]);

      expect(sample.n, 4);
      expect(sample.completed, 2);
      expect(sample.censored, 1);
      expect(sample.timeouts, 1);
      expect(sample.unknown, 0);
      expect(sample.subjectWins, 1);
      expect(sample.unknownCompletedResults, 1);
      expect(sample.completionRate.numerator, 2);
      expect(sample.completionRate.n, 4);
      expect(sample.completionRate.value, 0.5);
      expect(sample.censoringRate.n, 4);
      expect(sample.timeoutRate.n, 4);
      expect(sample.subjectWinRate.numerator, 1);
      expect(sample.subjectWinRate.n, 1);
      expect(sample.subjectWinRate.value, 1);
    });

    test('returns a null value with an explicit zero denominator', () {
      final sample = service.summarize(const []);

      expect(sample.n, 0);
      expect(sample.completionRate.n, 0);
      expect(sample.completionRate.value, isNull);
      expect(sample.subjectWinRate.n, 0);
      expect(sample.subjectWinRate.value, isNull);
    });
  });

  group('BattlePostReportService.compare', () {
    test(
      'allows homogeneous descriptive samples without pairing equal seeds',
      () {
        final comparison = service.compare(
          left: [
            _report(
              service,
              outcome: 'completed',
              winnerDeckId: 'deck-a',
              seed: 55,
            ),
          ],
          right: [
            _report(service, outcome: 'censored', seed: 55),
            _report(service, outcome: 'timeout', seed: 56),
          ],
        );

        expect(comparison.isAllowed, isTrue);
        expect(comparison.blockers, isEmpty);
        expect(comparison.left.n, 1);
        expect(comparison.right.n, 2);
        expect(comparison.right.completed, 0);
        expect(comparison.right.censored, 1);
        expect(comparison.right.timeouts, 1);
        expect(comparison.sharedSeedLabels, {55});
        expect(comparison.seedPairingClaim, isFalse);
        expect(comparison.pairedSampleSize, 0);
        expect(
          comparison.statisticalDesign,
          'engine_semantics_aware_independent_samples',
        );
        expect(comparison.superiorityClaimAllowed, isFalse);
      },
    );

    test('blocks every heterogeneous execution identity', () {
      final reference = _report(service, outcome: 'completed');
      final cases = <BattleComparisonBlocker, BattlePostReport>{
        BattleComparisonBlocker.deckRevisionMismatch: _report(
          service,
          outcome: 'completed',
          deckHash: 'different-deck-hash',
        ),
        BattleComparisonBlocker.opponentMismatch: _report(
          service,
          outcome: 'completed',
          opponentDeckId: 'different-opponent',
        ),
        BattleComparisonBlocker.opponentRevisionMismatch: _report(
          service,
          outcome: 'completed',
          opponentDeckHash: 'different-opponent-hash',
        ),
        BattleComparisonBlocker.engineMismatch: _report(
          service,
          outcome: 'completed',
          engine: 'forge',
        ),
        BattleComparisonBlocker.engineCommitMismatch: _report(
          service,
          outcome: 'completed',
          engineCommit: 'different-commit',
        ),
        BattleComparisonBlocker.timeoutPolicyMismatch: _report(
          service,
          outcome: 'completed',
          timeoutMs: 30000,
        ),
      };

      for (final entry in cases.entries) {
        final comparison = service.compare(
          left: [reference],
          right: [entry.value],
        );
        expect(
          comparison.blockers,
          contains(entry.key),
          reason: 'Expected blocker ${entry.key}',
        );
        expect(comparison.isAllowed, isFalse);
      }
    });

    test('fails closed when required comparison identity is missing', () {
      final complete = _report(service, outcome: 'completed');
      final missing = _report(
        service,
        outcome: 'completed',
        deckHash: null,
        opponentDeckId: null,
        opponentDeckHash: null,
        engine: null,
        engineCommit: null,
        timeoutMs: null,
      );

      final comparison = service.compare(left: [complete], right: [missing]);

      expect(
        comparison.blockers,
        containsAll({
          BattleComparisonBlocker.missingDeckRevision,
          BattleComparisonBlocker.missingOpponent,
          BattleComparisonBlocker.missingOpponentRevision,
          BattleComparisonBlocker.missingEngine,
          BattleComparisonBlocker.missingEngineCommit,
          BattleComparisonBlocker.missingTimeoutPolicy,
        }),
      );
      expect(comparison.isAllowed, isFalse);
    });

    test('blocks unknown outcomes instead of mixing them into rates', () {
      final comparison = service.compare(
        left: [_report(service, outcome: 'completed')],
        right: [_report(service, outcome: null)],
      );

      expect(
        comparison.blockers,
        contains(BattleComparisonBlocker.unknownOutcome),
      );
      expect(comparison.right.unknown, 1);
      expect(comparison.isAllowed, isFalse);
    });
  });
}

BattlePostReport _report(
  BattlePostReportService service, {
  String? outcome = 'completed',
  String? winnerDeckId,
  String? deckHash = 'deck-a-hash',
  String? opponentDeckId = 'deck-b',
  String? opponentDeckHash = 'deck-b-hash',
  String? engine = 'xmage',
  String? engineCommit = 'xmage-commit',
  int? timeoutMs = 40000,
  int? seed = 1,
}) {
  return service.build(
    BattleReplayDetail.fromJson({
      'id': 'fixture-$outcome-$seed',
      'deck_id': 'deck-a',
      'deck_a_id': 'deck-a',
      if (opponentDeckId != null) ...{
        'deck_b_id': opponentDeckId,
        'opponent_deck_id': opponentDeckId,
      },
      if (outcome != null) 'outcome': outcome,
      if (winnerDeckId != null) 'winner_deck_id': winnerDeckId,
      if (engine != null) 'engine': engine,
      if (engineCommit != null) 'engine_commit': engineCommit,
      if (timeoutMs != null) 'timeout_ms': timeoutMs,
      if (seed != null) 'attempt_provenance': {'seed': seed},
      if (deckHash != null || opponentDeckHash != null)
        'deck_revision': {
          if (deckHash != null) ...{
            'subject_deck_hash': deckHash,
            'deck_a_hash': deckHash,
          },
          if (opponentDeckHash != null) 'deck_b_hash': opponentDeckHash,
        },
    }),
  );
}
