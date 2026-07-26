enum BattleReportOutcome { completed, censored, timeout, unknown }

enum BattleCompletedResult { subjectWin, opponentWin, draw, unknown }

enum BattleEvidenceSource { event, snapshot }

enum BattleReportObservable {
  outcome,
  turnCount,
  duration,
  lifeCurve,
  typedActivity,
  eventStreamCompleteness,
  namedDrawIdentity,
  aiDecisionRationale,
  combatActivity,
  deckRevision,
  opponent,
  engine,
  engineCommit,
  timeoutPolicy,
}

enum BattleObservableState { available, unavailable, unknown }

class BattleRunIdentity {
  const BattleRunIdentity({
    required this.subjectDeckId,
    required this.opponentDeckId,
    required this.subjectDeckRevision,
    required this.subjectDeckHash,
    required this.opponentDeckHash,
    required this.engine,
    required this.engineCommit,
    required this.timeoutMs,
    required this.seed,
  });

  final String? subjectDeckId;
  final String? opponentDeckId;
  final String? subjectDeckRevision;
  final String? subjectDeckHash;
  final String? opponentDeckHash;
  final String? engine;
  final String? engineCommit;
  final int? timeoutMs;
  final int? seed;

  /// A hash has precedence because it identifies the actual deck payload.
  ///
  /// A textual revision is retained for older payloads, but a hash-only report
  /// is never silently matched to a revision-only report.
  String? get comparableSubjectRevision {
    final hash = subjectDeckHash?.trim();
    if (hash != null && hash.isNotEmpty) return 'hash:$hash';
    final revision = subjectDeckRevision?.trim();
    if (revision != null && revision.isNotEmpty) {
      return 'revision:$revision';
    }
    return null;
  }
}

class BattleReportReliability {
  const BattleReportReliability({
    required this.learningSchemaVersion,
    required this.eventStreamCompleteness,
    required this.absenceProvesNonuse,
    required this.namedDrawIdentityAvailable,
    required this.aiDecisionRationaleAvailable,
    required this.combatActivityAvailable,
    required this.decisionTraceAvailable,
    required this.eventsTruncated,
    required this.snapshotsTruncated,
  });

  final String? learningSchemaVersion;
  final String? eventStreamCompleteness;
  final bool? absenceProvesNonuse;
  final bool? namedDrawIdentityAvailable;
  final bool? aiDecisionRationaleAvailable;
  final bool? combatActivityAvailable;
  final bool? decisionTraceAvailable;
  final bool? eventsTruncated;
  final bool? snapshotsTruncated;

  bool get absenceSupportsNonuse =>
      absenceProvesNonuse == true &&
      eventsTruncated != true &&
      const {
        'complete',
        'complete_event_stream',
        'full',
      }.contains(eventStreamCompleteness);
}

class BattleLifeObservation {
  const BattleLifeObservation({
    required this.sequence,
    required this.player,
    required this.life,
    required this.source,
    this.turn,
  });

  final int sequence;
  final int? turn;
  final String player;
  final int life;
  final BattleEvidenceSource source;
}

class BattleObservedActivity {
  const BattleObservedActivity({
    required this.sequence,
    required this.type,
    required this.source,
    this.turn,
    this.actor,
    this.subjectDeckKey,
    this.cardName,
  });

  final int sequence;
  final int? turn;
  final String type;
  final String? actor;
  final String? subjectDeckKey;
  final String? cardName;
  final BattleEvidenceSource source;

  bool get hasNamedCard => cardName != null;
}

class BattlePostReport {
  BattlePostReport({
    required this.replayId,
    required this.outcome,
    required this.completedResult,
    required this.turnCount,
    required this.durationMs,
    required this.identity,
    required this.reliability,
    required List<BattleLifeObservation> lifeCurve,
    required List<BattleObservedActivity> observedActivities,
    required Map<BattleReportObservable, BattleObservableState> observability,
  }) : lifeCurve = List.unmodifiable(lifeCurve),
       observedActivities = List.unmodifiable(observedActivities),
       observability = Map.unmodifiable(observability);

  final String replayId;
  final BattleReportOutcome outcome;
  final BattleCompletedResult completedResult;
  final int? turnCount;
  final int? durationMs;
  final BattleRunIdentity identity;
  final BattleReportReliability reliability;
  final List<BattleLifeObservation> lifeCurve;
  final List<BattleObservedActivity> observedActivities;
  final Map<BattleReportObservable, BattleObservableState> observability;

  /// A replay is one sample. Aggregate rates use [BattleOutcomeSample.n].
  int get n => 1;

  Set<BattleReportObservable> get unknownObservables => Set.unmodifiable(
    observability.entries
        .where((entry) => entry.value == BattleObservableState.unknown)
        .map((entry) => entry.key),
  );

  Set<BattleReportObservable> get unavailableObservables => Set.unmodifiable(
    observability.entries
        .where((entry) => entry.value == BattleObservableState.unavailable)
        .map((entry) => entry.key),
  );

  Map<String, int> get observedActivityCounts {
    final counts = <String, int>{};
    for (final activity in observedActivities) {
      counts.update(activity.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }
}

class BattleRate {
  const BattleRate({required this.numerator, required this.n});

  final int numerator;
  final int n;

  double? get value => n == 0 ? null : numerator / n;
}

class BattleOutcomeSample {
  const BattleOutcomeSample({
    required this.n,
    required this.completed,
    required this.censored,
    required this.timeouts,
    required this.unknown,
    required this.subjectWins,
    required this.opponentWins,
    required this.draws,
    required this.unknownCompletedResults,
  });

  final int n;
  final int completed;
  final int censored;
  final int timeouts;
  final int unknown;
  final int subjectWins;
  final int opponentWins;
  final int draws;
  final int unknownCompletedResults;

  int get completedWithKnownResult => subjectWins + opponentWins + draws;

  BattleRate get completionRate => BattleRate(numerator: completed, n: n);

  BattleRate get censoringRate => BattleRate(numerator: censored, n: n);

  BattleRate get timeoutRate => BattleRate(numerator: timeouts, n: n);

  BattleRate get subjectWinRate =>
      BattleRate(numerator: subjectWins, n: completedWithKnownResult);
}

enum BattleComparisonBlocker {
  emptySample,
  unknownOutcome,
  missingDeckRevision,
  deckRevisionMismatch,
  missingOpponent,
  opponentMismatch,
  missingOpponentRevision,
  opponentRevisionMismatch,
  missingEngine,
  engineMismatch,
  missingEngineCommit,
  engineCommitMismatch,
  missingTimeoutPolicy,
  timeoutPolicyMismatch,
}

class BattleComparisonResult {
  BattleComparisonResult({
    required this.left,
    required this.right,
    required Set<BattleComparisonBlocker> blockers,
    required Set<int> sharedSeedLabels,
  }) : blockers = Set.unmodifiable(blockers),
       sharedSeedLabels = Set.unmodifiable(sharedSeedLabels);

  final BattleOutcomeSample left;
  final BattleOutcomeSample right;
  final Set<BattleComparisonBlocker> blockers;
  final Set<int> sharedSeedLabels;

  bool get isAllowed => blockers.isEmpty;

  /// Equal seed labels are scheduling/correlation metadata, not paired RNG.
  bool get seedPairingClaim => false;

  int get pairedSampleSize => 0;

  String get statisticalDesign => 'engine_semantics_aware_independent_samples';

  /// This layer only establishes homogeneous descriptive samples.
  bool get superiorityClaimAllowed => false;
}
