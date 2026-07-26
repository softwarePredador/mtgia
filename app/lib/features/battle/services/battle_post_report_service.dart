import '../models/battle_post_report.dart';
import '../models/battle_replay.dart';

class BattlePostReportService {
  const BattlePostReportService();

  BattlePostReport build(BattleReplayDetail detail) {
    final raw = detail.raw;
    final outcome = _outcome(raw);
    final identity = _identity(detail);
    final reliability = _reliability(detail);
    final lifeCurve = _lifeCurve(detail);
    final observedActivities = _observedActivities(detail);
    final completedResult = _completedResult(
      detail,
      outcome: outcome,
      identity: identity,
    );

    return BattlePostReport(
      replayId: detail.summary.id,
      outcome: outcome,
      completedResult: completedResult,
      turnCount: detail.summary.turnCount,
      durationMs: _durationMs(raw),
      identity: identity,
      reliability: reliability,
      lifeCurve: lifeCurve,
      observedActivities: observedActivities,
      observability: _observability(
        outcome: outcome,
        turnCount: detail.summary.turnCount,
        durationMs: _durationMs(raw),
        identity: identity,
        reliability: reliability,
        lifeCurve: lifeCurve,
        observedActivities: observedActivities,
      ),
    );
  }

  BattleOutcomeSample summarize(Iterable<BattlePostReport> reports) {
    var n = 0;
    var completed = 0;
    var censored = 0;
    var timeouts = 0;
    var unknown = 0;
    var subjectWins = 0;
    var opponentWins = 0;
    var draws = 0;
    var unknownCompletedResults = 0;

    for (final report in reports) {
      n += 1;
      switch (report.outcome) {
        case BattleReportOutcome.completed:
          completed += 1;
          switch (report.completedResult) {
            case BattleCompletedResult.subjectWin:
              subjectWins += 1;
            case BattleCompletedResult.opponentWin:
              opponentWins += 1;
            case BattleCompletedResult.draw:
              draws += 1;
            case BattleCompletedResult.unknown:
              unknownCompletedResults += 1;
          }
        case BattleReportOutcome.censored:
          censored += 1;
        case BattleReportOutcome.timeout:
          timeouts += 1;
        case BattleReportOutcome.unknown:
          unknown += 1;
      }
    }

    return BattleOutcomeSample(
      n: n,
      completed: completed,
      censored: censored,
      timeouts: timeouts,
      unknown: unknown,
      subjectWins: subjectWins,
      opponentWins: opponentWins,
      draws: draws,
      unknownCompletedResults: unknownCompletedResults,
    );
  }

  BattleComparisonResult compare({
    required List<BattlePostReport> left,
    required List<BattlePostReport> right,
  }) {
    final blockers = <BattleComparisonBlocker>{};
    if (left.isEmpty || right.isEmpty) {
      blockers.add(BattleComparisonBlocker.emptySample);
    }

    final reports = <BattlePostReport>[...left, ...right];
    if (reports.any(
      (report) => report.outcome == BattleReportOutcome.unknown,
    )) {
      blockers.add(BattleComparisonBlocker.unknownOutcome);
    }

    _validateRequiredIdentity<String>(
      reports: reports,
      value: (report) => report.identity.comparableSubjectRevision,
      missing: BattleComparisonBlocker.missingDeckRevision,
      mismatch: BattleComparisonBlocker.deckRevisionMismatch,
      blockers: blockers,
    );
    _validateRequiredIdentity<String>(
      reports: reports,
      value: (report) => report.identity.opponentDeckId,
      missing: BattleComparisonBlocker.missingOpponent,
      mismatch: BattleComparisonBlocker.opponentMismatch,
      blockers: blockers,
    );
    _validateOptionalOpponentRevision(reports, blockers);
    _validateRequiredIdentity<String>(
      reports: reports,
      value: (report) => report.identity.engine,
      missing: BattleComparisonBlocker.missingEngine,
      mismatch: BattleComparisonBlocker.engineMismatch,
      blockers: blockers,
    );
    _validateRequiredIdentity<String>(
      reports: reports,
      value: (report) => report.identity.engineCommit,
      missing: BattleComparisonBlocker.missingEngineCommit,
      mismatch: BattleComparisonBlocker.engineCommitMismatch,
      blockers: blockers,
    );
    _validateRequiredIdentity<int>(
      reports: reports,
      value: (report) => report.identity.timeoutMs,
      missing: BattleComparisonBlocker.missingTimeoutPolicy,
      mismatch: BattleComparisonBlocker.timeoutPolicyMismatch,
      blockers: blockers,
    );

    final leftSeeds = left
        .map((report) => report.identity.seed)
        .whereType<int>()
        .toSet();
    final rightSeeds = right
        .map((report) => report.identity.seed)
        .whereType<int>()
        .toSet();

    return BattleComparisonResult(
      left: summarize(left),
      right: summarize(right),
      blockers: blockers,
      sharedSeedLabels: leftSeeds.intersection(rightSeeds),
    );
  }

  BattleReportOutcome _outcome(Map<String, dynamic> raw) {
    final gameLog = _map(raw['game_log']);
    final value = _firstText([
      raw['outcome'],
      raw['attempt_outcome'],
      raw['status'],
      gameLog['outcome'],
      gameLog['status'],
    ])?.toLowerCase();

    return switch (value) {
      'completed' || 'success' => BattleReportOutcome.completed,
      'censored' || 'max_turns_censored' => BattleReportOutcome.censored,
      'timeout' || 'timed_out' => BattleReportOutcome.timeout,
      _ => BattleReportOutcome.unknown,
    };
  }

  BattleCompletedResult _completedResult(
    BattleReplayDetail detail, {
    required BattleReportOutcome outcome,
    required BattleRunIdentity identity,
  }) {
    if (outcome != BattleReportOutcome.completed) {
      return BattleCompletedResult.unknown;
    }

    final winnerDeckId = _text(detail.raw['winner_deck_id']);
    if (winnerDeckId != null && winnerDeckId == identity.subjectDeckId) {
      return BattleCompletedResult.subjectWin;
    }
    if (winnerDeckId != null && winnerDeckId == identity.opponentDeckId) {
      return BattleCompletedResult.opponentWin;
    }

    final explicitDraw =
        _bool(detail.raw['is_draw']) == true ||
        _bool(detail.raw['draw']) == true ||
        const {'draw', 'tie', 'empate'}.contains(
          _firstText([
            detail.raw['winner'],
            detail.raw['winner_name'],
            detail.raw['result'],
          ])?.toLowerCase(),
        );
    return explicitDraw
        ? BattleCompletedResult.draw
        : BattleCompletedResult.unknown;
  }

  BattleRunIdentity _identity(BattleReplayDetail detail) {
    final raw = detail.raw;
    final metrics = _map(raw['metrics']);
    final provenance = _map(raw['attempt_provenance']);
    final revision = _map(raw['deck_revision']);
    final subjectDeckId = _text(detail.summary.deckId);
    final opponentDeckId =
        _text(detail.summary.opponentDeckId) ?? _text(raw['opponent_deck_id']);
    final deckAId = _text(raw['deck_a_id']);
    final deckBId = _text(raw['deck_b_id']);
    final subjectIsDeckA =
        subjectDeckId != null && deckAId != null && subjectDeckId == deckAId;
    final subjectIsDeckB =
        subjectDeckId != null && deckBId != null && subjectDeckId == deckBId;

    final deckAHash =
        _text(revision['deck_a_hash']) ?? _text(raw['deck_a_hash']);
    final deckBHash =
        _text(revision['deck_b_hash']) ?? _text(raw['deck_b_hash']);
    final subjectDeckHash =
        _text(revision['subject_deck_hash']) ??
        _text(raw['subject_deck_hash']) ??
        _text(raw['deck_hash']) ??
        (subjectIsDeckA
            ? deckAHash
            : subjectIsDeckB
            ? deckBHash
            : null);
    final opponentDeckHash =
        _text(revision['opponent_deck_hash']) ??
        _text(raw['opponent_deck_hash']) ??
        (subjectIsDeckA
            ? deckBHash
            : subjectIsDeckB
            ? deckAHash
            : null);
    final rawRevision = raw['deck_revision'];
    final subjectDeckRevision = _firstText([
      revision['subject_deck_revision'],
      revision['revision_id'],
      revision['revision'],
      raw['subject_deck_revision'],
      raw['deck_revision_id'],
      rawRevision is Map ? null : rawRevision,
    ]);

    return BattleRunIdentity(
      subjectDeckId: subjectDeckId,
      opponentDeckId: opponentDeckId,
      subjectDeckRevision: subjectDeckRevision,
      subjectDeckHash: subjectDeckHash,
      opponentDeckHash: opponentDeckHash,
      engine: _firstText([raw['engine'], metrics['engine']]),
      engineCommit: _firstText([
        raw['engine_commit'],
        metrics['engine_commit'],
        provenance['engine_commit'],
      ]),
      timeoutMs: _firstInt([
        raw['timeout_ms'],
        provenance['timeout_ms'],
        metrics['timeout_ms'],
      ]),
      seed: _firstInt([raw['seed'], provenance['seed'], metrics['seed']]),
    );
  }

  BattleReportReliability _reliability(BattleReplayDetail detail) {
    final raw = detail.raw;
    final learning = _map(raw['learning_contract']);
    final simulation = _map(raw['simulation_contract']);
    final metrics = _map(raw['metrics']);
    final completeness = _firstText([
      learning['event_stream_completeness'],
      simulation['event_stream_completeness'],
    ]);
    final hasDeclaredLearning =
        learning.isNotEmpty ||
        (completeness != null && completeness != 'not_declared');

    bool? capability(String key) {
      if (learning.containsKey(key)) return _bool(learning[key]);
      if (hasDeclaredLearning && simulation.containsKey(key)) {
        return _bool(simulation[key]);
      }
      return null;
    }

    return BattleReportReliability(
      learningSchemaVersion: _text(learning['schema_version']),
      eventStreamCompleteness: completeness,
      absenceProvesNonuse: capability('absence_proves_nonuse'),
      namedDrawIdentityAvailable: capability('named_draw_identity_available'),
      aiDecisionRationaleAvailable: capability(
        'ai_decision_rationale_available',
      ),
      combatActivityAvailable: capability('combat_activity_available'),
      decisionTraceAvailable:
          capability('decision_trace_available') ??
          (detail.nativeDecisionTraceAvailable ? true : null),
      eventsTruncated: _firstBool([
        raw['events_truncated'],
        metrics['events_truncated'],
      ]),
      snapshotsTruncated: _firstBool([
        raw['snapshots_truncated'],
        metrics['snapshots_truncated'],
      ]),
    );
  }

  int? _durationMs(Map<String, dynamic> raw) {
    final metrics = _map(raw['metrics']);
    final provenance = _map(raw['attempt_provenance']);
    return _firstInt([
      raw['duration_ms'],
      raw['elapsed_ms'],
      metrics['duration_ms'],
      metrics['elapsed_ms'],
      provenance['duration_ms'],
      provenance['elapsed_ms'],
    ]);
  }

  List<BattleLifeObservation> _lifeCurve(BattleReplayDetail detail) {
    final snapshotObservations = <BattleLifeObservation>[];
    for (final snapshot in detail.visualSnapshots) {
      for (final player in snapshot.players) {
        final life = player.life;
        final playerIdentity = _firstText([
          player.raw['deck_key'],
          player.raw['name'],
          player.raw['player'],
        ]);
        if (life == null || playerIdentity == null) continue;
        snapshotObservations.add(
          BattleLifeObservation(
            sequence: snapshot.index,
            turn: snapshot.turn,
            player: playerIdentity,
            life: life,
            source: BattleEvidenceSource.snapshot,
          ),
        );
      }
    }
    if (snapshotObservations.isNotEmpty) {
      return List.unmodifiable(snapshotObservations);
    }

    final eventObservations = <BattleLifeObservation>[];
    for (final entry in detail.events.asMap().entries) {
      final event = entry.value;
      final raw = event.raw;
      final type = _eventType(raw, fallback: event.action);
      if (!_lifeObservationTypes.contains(type)) continue;
      final life = _firstInt([
        raw['life_after'],
        raw['new_life'],
        raw['life_total'],
        raw['life'],
      ]);
      final player = _firstText([
        raw['target_player'],
        raw['affected_player'],
        raw['player'],
        raw['deck_key'],
        raw['subject_deck_key'],
        if (type != 'damage' && type != 'combat_damage') raw['actor'],
      ]);
      if (life == null || player == null) continue;
      eventObservations.add(
        BattleLifeObservation(
          sequence: entry.key,
          turn: event.turn,
          player: player,
          life: life,
          source: BattleEvidenceSource.event,
        ),
      );
    }
    return List.unmodifiable(eventObservations);
  }

  List<BattleObservedActivity> _observedActivities(BattleReplayDetail detail) {
    final eventActivities = <BattleObservedActivity>[];
    for (final entry in detail.events.asMap().entries) {
      final event = entry.value;
      final raw = event.raw;
      final type = _eventType(raw, fallback: event.action);
      if (!_typedActivityTypes.contains(type)) continue;
      eventActivities.add(
        BattleObservedActivity(
          sequence: entry.key,
          turn: event.turn,
          type: type,
          actor: event.actor,
          subjectDeckKey: _firstText([
            raw['subject_deck_key'],
            raw['actor_deck_key'],
            raw['player_deck_key'],
            raw['deck_key'],
            raw['actor_side'],
          ]),
          cardName: _cardName(raw),
          source: BattleEvidenceSource.event,
        ),
      );
    }
    if (eventActivities.isNotEmpty) return List.unmodifiable(eventActivities);

    final snapshotActivities = <BattleObservedActivity>[];
    for (final snapshot in detail.visualSnapshots) {
      final event = snapshot.event;
      final type = _eventType(event, fallback: snapshot.action);
      if (!_typedActivityTypes.contains(type)) continue;
      snapshotActivities.add(
        BattleObservedActivity(
          sequence: snapshot.index,
          turn: snapshot.turn,
          type: type,
          actor: _firstText([
            event['actor'],
            event['player'],
            event['controller'],
            snapshot.activePlayer,
          ]),
          subjectDeckKey: _firstText([
            event['subject_deck_key'],
            event['actor_deck_key'],
            event['player_deck_key'],
            event['deck_key'],
            event['actor_side'],
          ]),
          cardName: _cardName(event),
          source: BattleEvidenceSource.snapshot,
        ),
      );
    }
    return List.unmodifiable(snapshotActivities);
  }

  Map<BattleReportObservable, BattleObservableState> _observability({
    required BattleReportOutcome outcome,
    required int? turnCount,
    required int? durationMs,
    required BattleRunIdentity identity,
    required BattleReportReliability reliability,
    required List<BattleLifeObservation> lifeCurve,
    required List<BattleObservedActivity> observedActivities,
  }) {
    return {
      BattleReportObservable.outcome: outcome == BattleReportOutcome.unknown
          ? BattleObservableState.unknown
          : BattleObservableState.available,
      BattleReportObservable.turnCount: _presence(turnCount),
      BattleReportObservable.duration: _presence(durationMs),
      BattleReportObservable.lifeCurve: lifeCurve.isEmpty
          ? BattleObservableState.unknown
          : BattleObservableState.available,
      BattleReportObservable.typedActivity: observedActivities.isNotEmpty
          ? BattleObservableState.available
          : BattleObservableState.unknown,
      BattleReportObservable.eventStreamCompleteness:
          reliability.eventStreamCompleteness == null ||
              reliability.eventStreamCompleteness == 'not_declared'
          ? BattleObservableState.unknown
          : BattleObservableState.available,
      BattleReportObservable.namedDrawIdentity: _capability(
        reliability.namedDrawIdentityAvailable,
      ),
      BattleReportObservable.aiDecisionRationale: _capability(
        reliability.aiDecisionRationaleAvailable,
      ),
      BattleReportObservable.combatActivity: _capability(
        reliability.combatActivityAvailable,
      ),
      BattleReportObservable.deckRevision: _presence(
        identity.comparableSubjectRevision,
      ),
      BattleReportObservable.opponent: _presence(identity.opponentDeckId),
      BattleReportObservable.engine: _presence(identity.engine),
      BattleReportObservable.engineCommit: _presence(identity.engineCommit),
      BattleReportObservable.timeoutPolicy: _presence(identity.timeoutMs),
    };
  }

  void _validateOptionalOpponentRevision(
    List<BattlePostReport> reports,
    Set<BattleComparisonBlocker> blockers,
  ) {
    if (reports.isEmpty) return;
    final values = reports
        .map((report) => report.identity.opponentDeckHash)
        .toList(growable: false);
    if (values.every((value) => value == null)) return;
    if (values.any((value) => value == null)) {
      blockers.add(BattleComparisonBlocker.missingOpponentRevision);
      return;
    }
    if (values.whereType<String>().toSet().length > 1) {
      blockers.add(BattleComparisonBlocker.opponentRevisionMismatch);
    }
  }

  void _validateRequiredIdentity<T>({
    required List<BattlePostReport> reports,
    required T? Function(BattlePostReport report) value,
    required BattleComparisonBlocker missing,
    required BattleComparisonBlocker mismatch,
    required Set<BattleComparisonBlocker> blockers,
  }) {
    if (reports.isEmpty) return;
    final values = reports.map(value).toList(growable: false);
    if (values.any((item) => item == null)) {
      blockers.add(missing);
      return;
    }
    if (values.whereType<T>().toSet().length > 1) {
      blockers.add(mismatch);
    }
  }
}

BattleObservableState _presence(Object? value) => value == null
    ? BattleObservableState.unknown
    : BattleObservableState.available;

BattleObservableState _capability(bool? value) => switch (value) {
  true => BattleObservableState.available,
  false => BattleObservableState.unavailable,
  null => BattleObservableState.unknown,
};

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String? _text(Object? value) {
  if (value == null || value is Map || value is Iterable) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstText(Iterable<Object?> values) {
  for (final value in values) {
    final text = _text(value);
    if (text != null) return text;
  }
  return null;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int? _firstInt(Iterable<Object?> values) {
  for (final value in values) {
    final parsed = _int(value);
    if (parsed != null) return parsed;
  }
  return null;
}

bool? _bool(Object? value) {
  if (value is bool) return value;
  return switch (value?.toString().trim().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => null,
  };
}

bool? _firstBool(Iterable<Object?> values) {
  for (final value in values) {
    final parsed = _bool(value);
    if (parsed != null) return parsed;
  }
  return null;
}

String _eventType(Map<String, dynamic> event, {required String fallback}) {
  final raw = _firstText([
    event['event_type'],
    event['type'],
    event['action'],
    event['event'],
    event['kind'],
    fallback,
  ]);
  return raw
          ?.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '') ??
      '';
}

String? _cardName(Map<String, dynamic> event) {
  for (final key in const [
    'card_name',
    'card',
    'source_card',
    'creature',
    'object_name',
  ]) {
    final value = event[key];
    if (value is Map) {
      final name = _text(value['name'] ?? value['card_name']);
      if (name != null) return name;
      continue;
    }
    final name = _text(value);
    if (name != null) return name;
  }
  return null;
}

const _lifeObservationTypes = <String>{
  'combat_damage',
  'damage',
  'life_change',
  'life_changed',
  'life_gain',
  'life_loss',
  'life_total_changed',
};

const _typedActivityTypes = <String>{
  'ability_activated',
  'activate_ability',
  'activation',
  'add_to_stack',
  'attack',
  'attacker_declared',
  'attackers_declared',
  'attacks',
  'battlefield_entry',
  'block',
  'blocker_declared',
  'blockers_declared',
  'blocks',
  'card_draw',
  'card_played',
  'cast',
  'cast_spell',
  'casts',
  'combat_damage',
  'commander_cast',
  'counter_added',
  'counter_change',
  'counter_removed',
  'damage',
  'destroy',
  'dies',
  'discard',
  'discards',
  'draw',
  'draws',
  'enters_battlefield',
  'exile',
  'land_played',
  'leave_battlefield',
  'life_change',
  'life_changed',
  'life_gain',
  'life_loss',
  'life_total_changed',
  'move_to_zone',
  'play',
  'play_land',
  'resolve',
  'resolves',
  'sacrifice',
  'spell_cast',
  'stack_entry',
  'stack_resolved',
  'tap_change',
  'tapped',
  'untapped',
  'zone_change',
  'zone_transition',
};
