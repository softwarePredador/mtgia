import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'battle_replay_payload_sanitizer.dart';

final RegExp _battleReplayUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isBattleReplayUuid(String value) =>
    _battleReplayUuidPattern.hasMatch(value.trim());

const battleReplayCursorSchema = 'battle_replay_cursor_v1';
const interactiveUserDecisionTraceSchema = 'interactive_user_decision_trace_v1';

class BattleReplayCursorException implements Exception {
  const BattleReplayCursorException();
}

class BattleReplayPage {
  const BattleReplayPage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });

  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final String? nextCursor;
}

class BattleReplayReadService {
  BattleReplayReadService(this._pool);

  final Pool _pool;

  Future<bool> ownsDeck({
    required String userId,
    required String deckId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT 1
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> listReplays({
    required String userId,
    required String deckId,
    int limit = 30,
  }) async {
    final page = await listReplayPage(
      userId: userId,
      deckId: deckId,
      limit: limit,
    );
    return page.items;
  }

  Future<BattleReplayPage> listReplayPage({
    required String userId,
    required String deckId,
    int limit = 30,
    String? cursor,
  }) async {
    if (!await _hasBattleSimulationTable()) {
      return const BattleReplayPage(
        items: <Map<String, dynamic>>[],
        hasMore: false,
        nextCursor: null,
      );
    }
    final pageLimit = limit.clamp(1, 100);
    final marker = _decodeBattleReplayCursor(cursor);

    final result = await _pool.execute(
      Sql.named('''
        SELECT
          bs.id::text AS id,
          bs.deck_a_id::text AS deck_a_id,
          bs.deck_b_id::text AS deck_b_id,
          bs.simulation_type AS simulation_type,
          bs.winner_deck_id::text AS winner_deck_id,
          bs.turns_played AS turns_played,
          bs.metrics AS metrics,
          bs.created_at AS created_at,
          attempt.id::text AS attempt_id,
          attempt.outcome AS attempt_outcome,
          attempt.test_objective AS test_objective,
          attempt.request_schema_version AS request_schema_version,
          attempt.request_hash AS request_hash,
          attempt.deck_hash_schema AS deck_hash_schema,
          attempt.deck_a_hash AS deck_a_hash,
          attempt.deck_b_hash AS deck_b_hash,
          attempt.engine AS attempt_engine,
          attempt.engine_version AS attempt_engine_version,
          attempt.engine_commit AS attempt_engine_commit,
          attempt.engine_build AS attempt_engine_build,
          attempt.engine_process_id AS attempt_engine_process_id,
          attempt.timeout_ms AS timeout_ms,
          attempt.events_truncated AS events_truncated,
          attempt.snapshots_truncated AS snapshots_truncated,
          attempt.outcome_reason AS outcome_reason,
          attempt.error_code AS attempt_error_code,
          attempt.provenance AS attempt_provenance,
          CASE
            WHEN da.user_id = CAST(@userId AS uuid) OR da.is_public = true
            THEN da.name
            ELSE NULL
          END AS deck_a_name,
          CASE
            WHEN db.user_id = CAST(@userId AS uuid) OR db.is_public = true
            THEN db.name
            ELSE NULL
          END AS deck_b_name,
          CASE
            WHEN jsonb_typeof(bs.game_log) = 'object'
              AND jsonb_typeof(bs.game_log->'game_log') = 'array'
            THEN jsonb_array_length(bs.game_log->'game_log')
            WHEN jsonb_typeof(bs.game_log) = 'array'
            THEN jsonb_array_length(bs.game_log)
            ELSE NULL
          END AS event_count,
          CASE
            WHEN jsonb_typeof(bs.game_log) = 'object'
            THEN bs.game_log->>'type'
            ELSE NULL
          END AS game_log_type,
          CASE
            WHEN jsonb_typeof(bs.game_log) = 'object'
            THEN bs.game_log->>'winner'
            ELSE NULL
          END AS winner_label,
          CASE
            WHEN jsonb_typeof(bs.game_log) = 'object'
            THEN bs.game_log->>'status'
            ELSE NULL
          END AS game_log_status
        FROM battle_simulations bs
        LEFT JOIN battle_simulation_attempts attempt
          ON attempt.replay_id = bs.id
        JOIN decks requested
          ON requested.id = CAST(@deckId AS uuid)
         AND requested.user_id = CAST(@userId AS uuid)
        LEFT JOIN decks da ON da.id = bs.deck_a_id
        LEFT JOIN decks db ON db.id = bs.deck_b_id
        WHERE (
          bs.deck_a_id = CAST(@deckId AS uuid)
          OR bs.deck_b_id = CAST(@deckId AS uuid)
        )
        AND (
          CAST(@beforeCreatedAt AS timestamptz) IS NULL
          OR (bs.created_at, bs.id) < (
            CAST(@beforeCreatedAt AS timestamptz),
            CAST(@beforeId AS uuid)
          )
        )
        ORDER BY bs.created_at DESC, bs.id DESC
        LIMIT @queryLimit
      '''),
      parameters: {
        'deckId': deckId,
        'userId': userId,
        'beforeCreatedAt': marker?.createdAt.toIso8601String(),
        'beforeId': marker?.id,
        'queryLimit': pageLimit + 1,
      },
    );

    final rows = result.map((row) => row.toColumnMap()).toList(growable: false);
    final hasMore = rows.length > pageLimit;
    final visibleRows = rows.take(pageLimit).toList(growable: false);
    final items = visibleRows
        .map((row) => _summaryFromRow(row, deckId: deckId))
        .toList(growable: false);
    final nextCursor =
        hasMore && visibleRows.isNotEmpty
            ? _encodeBattleReplayCursor(visibleRows.last)
            : null;
    return BattleReplayPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  Future<Map<String, dynamic>?> fetchReplay({
    required String userId,
    required String deckId,
    required String replayId,
  }) async {
    if (!await _hasBattleSimulationTable()) {
      return null;
    }

    final result = await _pool.execute(
      Sql.named('''
        SELECT
          bs.id::text AS id,
          bs.deck_a_id::text AS deck_a_id,
          bs.deck_b_id::text AS deck_b_id,
          bs.simulation_type AS simulation_type,
          bs.winner_deck_id::text AS winner_deck_id,
          bs.turns_played AS turns_played,
          bs.game_log AS game_log,
          bs.metrics AS metrics,
          bs.created_at AS created_at,
          attempt.id::text AS attempt_id,
          attempt.outcome AS attempt_outcome,
          attempt.test_objective AS test_objective,
          attempt.request_schema_version AS request_schema_version,
          attempt.request_hash AS request_hash,
          attempt.deck_hash_schema AS deck_hash_schema,
          attempt.deck_a_hash AS deck_a_hash,
          attempt.deck_b_hash AS deck_b_hash,
          attempt.engine AS attempt_engine,
          attempt.engine_version AS attempt_engine_version,
          attempt.engine_commit AS attempt_engine_commit,
          attempt.engine_build AS attempt_engine_build,
          attempt.engine_process_id AS attempt_engine_process_id,
          attempt.timeout_ms AS timeout_ms,
          attempt.events_truncated AS events_truncated,
          attempt.snapshots_truncated AS snapshots_truncated,
          attempt.outcome_reason AS outcome_reason,
          attempt.error_code AS attempt_error_code,
          attempt.provenance AS attempt_provenance,
          CASE
            WHEN da.user_id = CAST(@userId AS uuid) OR da.is_public = true
            THEN da.name
            ELSE NULL
          END AS deck_a_name,
          CASE
            WHEN db.user_id = CAST(@userId AS uuid) OR db.is_public = true
            THEN db.name
            ELSE NULL
          END AS deck_b_name,
          (
            SELECT COALESCE(
              jsonb_agg(
                jsonb_strip_nulls(
                  jsonb_build_object(
                    'schema_version',
                      'interactive_user_decision_v1',
                    'decision_id',
                      'interactive-decision-' || submitted.sequence::text,
                    'decision_origin', 'human_user',
                    'decision_rationale_kind', 'recorded_human_choice',
                    'rules_engine_explanation', false,
                    'strategy_proof', false,
                    'decision_type', prompt.payload->>'kind',
                    'turn', state.payload->'turn',
                    'phase', COALESCE(
                      state.payload->>'phase',
                      state.payload->>'step'
                    ),
                    'actor', 'Você',
                    'choice', COALESCE(
                      selected.option->>'label',
                      CASE submitted.payload->>'response_kind'
                        WHEN 'delegate' THEN 'Delegar esta decisão ao motor'
                        WHEN 'integer' THEN
                          'Valor ' || COALESCE(
                            submitted.payload->>'integer_value',
                            'registrado'
                          )
                        WHEN 'multi_amount' THEN
                          'Distribuição de valores registrada'
                        ELSE 'Escolha registrada'
                      END
                    ),
                    'chosen_option', jsonb_strip_nulls(
                      jsonb_build_object(
                        'action', COALESCE(
                          selected.option->>'label',
                          'Escolha registrada'
                        ),
                        'role', selected.option->>'role'
                      )
                    ),
                    'reason', COALESCE(
                      prompt.payload->>'message',
                      'Escolha confirmada durante o Battle Coach.'
                    )
                  )
                )
                ORDER BY submitted.sequence
              ),
              '[]'::jsonb
            )
            FROM interactive_battle_sessions private_session
            JOIN interactive_battle_records submitted
              ON submitted.session_id = private_session.id
             AND submitted.record_kind = 'action_submitted'
            LEFT JOIN LATERAL (
              SELECT record.payload
              FROM interactive_battle_records record
              WHERE record.session_id = submitted.session_id
                AND record.record_kind = 'prompt_opened'
                AND record.prompt_id = submitted.prompt_id
                AND record.sequence <= submitted.sequence
              ORDER BY record.sequence DESC
              LIMIT 1
            ) prompt ON TRUE
            LEFT JOIN LATERAL (
              SELECT option
              FROM jsonb_array_elements(
                CASE
                  WHEN jsonb_typeof(prompt.payload->'options') = 'array'
                  THEN prompt.payload->'options'
                  ELSE '[]'::jsonb
                END
              ) option
              WHERE option->>'id' = submitted.option_id
              LIMIT 1
            ) selected ON TRUE
            LEFT JOIN LATERAL (
              SELECT record.payload
              FROM interactive_battle_records record
              WHERE record.session_id = submitted.session_id
                AND record.record_kind = 'private_state'
                AND record.sequence <= submitted.sequence
              ORDER BY record.sequence DESC
              LIMIT 1
            ) state ON TRUE
            WHERE private_session.replay_id = bs.id
              AND private_session.user_id = CAST(@userId AS uuid)
              AND private_session.deck_a_id = CAST(@deckId AS uuid)
              AND EXISTS (
                SELECT 1
                FROM interactive_battle_records accepted
                WHERE accepted.session_id = submitted.session_id
                  AND accepted.record_kind = 'action_accepted'
                  AND accepted.payload->>'action_id' =
                    submitted.idempotency_key
              )
          ) AS interactive_user_decisions
        FROM battle_simulations bs
        LEFT JOIN battle_simulation_attempts attempt
          ON attempt.replay_id = bs.id
        JOIN decks requested
          ON requested.id = CAST(@deckId AS uuid)
         AND requested.user_id = CAST(@userId AS uuid)
        LEFT JOIN decks da ON da.id = bs.deck_a_id
        LEFT JOIN decks db ON db.id = bs.deck_b_id
        WHERE bs.id = CAST(@replayId AS uuid)
          AND (
            bs.deck_a_id = CAST(@deckId AS uuid)
            OR bs.deck_b_id = CAST(@deckId AS uuid)
          )
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'replayId': replayId, 'userId': userId},
    );

    if (result.isEmpty) return null;
    return _detailFromRow(result.first.toColumnMap(), deckId: deckId);
  }

  Future<bool> _hasBattleSimulationTable() async {
    final result = await _pool.execute('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'battle_simulations'
          AND table_schema = current_schema()
      )
    ''');
    return result.isNotEmpty && result.first[0] == true;
  }

  Map<String, dynamic> _summaryFromRow(
    Map<String, dynamic> row, {
    required String deckId,
  }) {
    final deckAId = row['deck_a_id']?.toString();
    final deckBId = row['deck_b_id']?.toString();
    final isDeckA = deckAId == deckId;
    final opponentDeckId = isDeckA ? deckBId : deckAId;
    final opponentName =
        isDeckA
            ? row['deck_b_name']?.toString()
            : row['deck_a_name']?.toString();
    final winnerDeckId = row['winner_deck_id']?.toString();
    final winnerName =
        winnerDeckId == null
            ? sanitizeBattleReplayText(row['winner_label'])
            : _winnerNameForRow(row, winnerDeckId);
    final metrics = sanitizePersistedBattleMetrics(row['metrics']);
    final attemptProvenance = sanitizePersistedBattleMetrics(
      row['attempt_provenance'],
    );
    final engine =
        row['attempt_engine']?.toString() ?? metrics['engine']?.toString();
    final engineContract = metrics['engine_contract']?.toString();
    final outcome = _battleOutcome(
      row['attempt_outcome'],
      hasVersionedAttempt: row['attempt_id'] != null,
    );
    final subjectDeckHash =
        isDeckA
            ? row['deck_a_hash']?.toString()
            : row['deck_b_hash']?.toString();

    return {
      'id': row['id']?.toString(),
      'deck_id': deckId,
      'deck_a_id': deckAId,
      'deck_b_id': deckBId,
      'opponent_deck_id': opponentDeckId,
      if (opponentName != null && opponentName.trim().isNotEmpty)
        'opponent_name': opponentName,
      'type':
          sanitizeBattleReplayText(row['game_log_type']) ??
          row['simulation_type']?.toString(),
      'simulation_type': row['simulation_type']?.toString(),
      'winner_deck_id': winnerDeckId,
      if (winnerName != null && winnerName.trim().isNotEmpty)
        'winner_name': winnerName,
      'turns_played': _toInt(row['turns_played']),
      'event_count': _toInt(row['event_count']),
      'metrics': metrics,
      if (engine != null && engine.isNotEmpty) 'engine': engine,
      if (row['attempt_id'] != null)
        'attempt_id': row['attempt_id']?.toString(),
      'outcome': outcome,
      'test_objective':
          row['test_objective']?.toString() ??
          metrics['test_objective']?.toString() ??
          'general',
      if (row['outcome_reason'] != null)
        'outcome_reason': sanitizeBattleReplayText(row['outcome_reason']),
      if (row['attempt_error_code'] != null)
        'error_code': sanitizeBattleReplayText(row['attempt_error_code']),
      if (row['attempt_engine_version'] != null)
        'engine_version': row['attempt_engine_version'],
      if (row['attempt_engine_commit'] != null)
        'engine_commit': row['attempt_engine_commit'],
      if (row['attempt_engine_build'] != null)
        'engine_build': row['attempt_engine_build'],
      if (row['attempt_engine_process_id'] != null)
        'engine_process_id': row['attempt_engine_process_id'],
      if (row['request_schema_version'] != null)
        'request_schema_version': row['request_schema_version'],
      if (row['request_hash'] != null) 'request_hash': row['request_hash'],
      if (row['timeout_ms'] != null) 'timeout_ms': _toInt(row['timeout_ms']),
      'events_truncated': row['events_truncated'] == true,
      'snapshots_truncated': row['snapshots_truncated'] == true,
      if (attemptProvenance.isNotEmpty) 'attempt_provenance': attemptProvenance,
      'deck_revision': {
        'schema_version': row['deck_hash_schema'],
        'deck_a_hash': row['deck_a_hash'],
        'deck_b_hash': row['deck_b_hash'],
        'subject_deck_hash': subjectDeckHash,
        'compatibility':
            subjectDeckHash == null ? 'legacy_unknown' : 'recorded',
      },
      'simulation_contract': _simulationContract(
        engine: engine,
        engineContract: engineContract,
      ),
      'created_at': _timestamp(row['created_at']),
      'source': 'battle_simulations',
      'status': outcome,
    };
  }

  Map<String, dynamic> _detailFromRow(
    Map<String, dynamic> row, {
    required String deckId,
  }) {
    final summary = _summaryFromRow(row, deckId: deckId);
    final gameLog = sanitizePersistedBattleReplay(row['game_log']);
    final events = _eventsFromGameLog(gameLog);
    final publicDecisions = _decisionsFromGameLog(gameLog);
    final interactiveUserDecisions = _interactiveUserDecisionsFromRow(
      row['interactive_user_decisions'],
    );
    final decisions = <dynamic>[
      ...publicDecisions,
      ...interactiveUserDecisions,
    ];
    final visualSnapshots = _visualSnapshotsFromGameLog(gameLog);
    final gameLogMap = gameLog is Map ? gameLog : const {};
    final winnerLabel = gameLogMap['winner']?.toString();
    final gameLogType = gameLogMap['type']?.toString();
    final gameLogTurns = _toInt(gameLogMap['turns']);
    final engine = gameLogMap['engine']?.toString();
    final engineContract = gameLogMap['engine_contract']?.toString();
    final outcome = _battleOutcome(
      row['attempt_outcome'],
      hasVersionedAttempt: row['attempt_id'] != null,
    );
    final rawLearningContract = gameLogMap['learning_contract'];
    final learningContract =
        rawLearningContract is Map
            ? Map<String, dynamic>.from(rawLearningContract)
            : const <String, dynamic>{};

    return {
      ...summary,
      'outcome': outcome,
      'status': outcome,
      if (gameLogType != null && gameLogType.trim().isNotEmpty)
        'type': gameLogType,
      if (!summary.containsKey('winner_name') &&
          winnerLabel != null &&
          winnerLabel.trim().isNotEmpty)
        'winner_name': winnerLabel,
      if ((summary['turns_played'] as int? ?? 0) <= 0 && gameLogTurns > 0)
        'turns_played': gameLogTurns,
      'game_log': gameLog,
      'events': events,
      'decision_trace': decisions,
      if (interactiveUserDecisions.isNotEmpty)
        'decision_trace_contract': const {
          'schema_version': interactiveUserDecisionTraceSchema,
          'origin': 'human_user',
          'scope': 'initiating_user_only',
          'rules_engine_explanation': false,
          'strategy_proof': false,
          'privacy': 'selected_choice_without_private_state',
        },
      'visual_snapshots': visualSnapshots,
      if (engine != null && engine.isNotEmpty) 'engine': engine,
      if (gameLogMap['engine_version'] != null)
        'engine_version': gameLogMap['engine_version'],
      if (gameLogMap['engine_commit'] != null)
        'engine_commit': gameLogMap['engine_commit'],
      if (learningContract.isNotEmpty) 'learning_contract': learningContract,
      'replay_security': battleReplaySecurityContract,
      'simulation_contract': _simulationContract(
        engine: engine,
        engineContract: engineContract,
        learningContract: learningContract,
      ),
    };
  }

  String _battleOutcome(Object? value, {required bool hasVersionedAttempt}) {
    if (!hasVersionedAttempt) return 'legacy_unknown';
    final normalized = value?.toString().trim().toLowerCase();
    return const {
          'completed',
          'censored',
          'timeout',
          'coverage_error',
          'engine_error',
          'cancelled',
          'persistence_error',
        }.contains(normalized)
        ? normalized!
        : 'legacy_unknown';
  }

  Map<String, dynamic> _simulationContract({
    required String? engine,
    required String? engineContract,
    Map<String, dynamic> learningContract = const {},
  }) {
    final isExternalCanonicalExecution =
        (engine == 'xmage' && engineContract == 'canonical_rules_execution') ||
        (engine == 'forge' &&
            engineContract == 'canonical_rules_execution_secondary');
    final isReviewedNativeExecution =
        engine == 'manaloom_native_reviewed' &&
        engineContract == 'native_reviewed_rules_execution';
    final isRulesExecution =
        isExternalCanonicalExecution || isReviewedNativeExecution;
    return {
      'status': isRulesExecution ? engineContract : 'experimental_advisory',
      'advisory_only': !isRulesExecution,
      'rules_execution': isRulesExecution,
      'canonical_rules_execution': isExternalCanonicalExecution,
      'reviewed_native_rules_execution': isReviewedNativeExecution,
      if (isRulesExecution)
        'rules_engine_priority':
            engine == 'xmage'
                ? 'primary'
                : engine == 'forge'
                ? 'secondary'
                : 'native_residual',
      'canonical_legality_source': false,
      'strategy_or_swap_proof': false,
      'event_learning_grade':
          learningContract.isEmpty ? 'not_declared' : 'visible_activity_only',
      'event_stream_completeness':
          learningContract['event_stream_completeness'] ?? 'not_declared',
      'absence_proves_nonuse':
          learningContract['absence_proves_nonuse'] == true,
      'seed_semantics': learningContract['seed_semantics'] ?? 'not_declared',
      'named_draw_identity_available':
          learningContract['named_draw_identity_available'] == true,
      'ai_decision_rationale_available':
          learningContract['ai_decision_rationale_available'] == true,
    };
  }

  List<dynamic> _eventsFromGameLog(Object? gameLog) {
    if (gameLog is List) return gameLog;
    if (gameLog is Map) {
      final nested = gameLog['game_log'];
      if (nested is List) return nested;
      final events = gameLog['events'];
      if (events is List) return events;
    }
    return const [];
  }

  List<dynamic> _visualSnapshotsFromGameLog(Object? gameLog) {
    if (gameLog is! Map) return const [];

    for (final key in const [
      'visual_snapshots',
      'snapshots',
      'replay_snapshots',
    ]) {
      final snapshots = gameLog[key];
      if (snapshots is List && snapshots.isNotEmpty) return snapshots;
    }

    final events = _eventsFromGameLog(gameLog);
    final eventSnapshots = events
        .whereType<Map>()
        .map((event) => event['snapshot'])
        .whereType<Map>()
        .toList(growable: false);
    if (eventSnapshots.isNotEmpty) return eventSnapshots;

    final finalState = gameLog['final_state'];
    if (finalState is Map && finalState.isNotEmpty) {
      return [
        {
          'index': 0,
          'turn': _toInt(gameLog['turns']),
          'phase': 'final',
          'action': 'final_state',
          'active_player': gameLog['winner']?.toString(),
          'event': {
            'turn': _toInt(gameLog['turns']),
            'phase': 'final',
            'action': 'final_state',
            if (gameLog['winner'] != null) 'player': gameLog['winner'],
          },
          'players': [
            if (finalState['player_a'] is Map) finalState['player_a'],
            if (finalState['player_b'] is Map) finalState['player_b'],
          ],
        },
      ];
    }

    return const [];
  }

  List<dynamic> _decisionsFromGameLog(Object? gameLog) {
    if (gameLog is Map) {
      final decisions = gameLog['decision_trace'];
      if (decisions is List) return decisions;
    }
    return const [];
  }

  List<Map<String, dynamic>> _interactiveUserDecisionsFromRow(Object? value) {
    if (value == null) return const [];
    final sanitized = sanitizePersistedBattleReplay(value);
    if (sanitized is! List) return const [];
    return sanitized
        .whereType<Map>()
        .map(
          (decision) =>
              decision.map((key, entry) => MapEntry(key.toString(), entry)),
        )
        .toList(growable: false);
  }

  String? _winnerNameForRow(Map<String, dynamic> row, String winnerDeckId) {
    if (winnerDeckId == row['deck_a_id']?.toString()) {
      return row['deck_a_name']?.toString();
    }
    if (winnerDeckId == row['deck_b_id']?.toString()) {
      return row['deck_b_name']?.toString();
    }
    return null;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _timestamp(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    return value?.toString();
  }
}

class _BattleReplayCursorMarker {
  const _BattleReplayCursorMarker({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;
}

_BattleReplayCursorMarker? _decodeBattleReplayCursor(String? cursor) {
  final normalized = cursor?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized.length > 512 ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(normalized)) {
    throw const BattleReplayCursorException();
  }
  try {
    final decoded = utf8.decode(
      base64Url.decode(base64Url.normalize(normalized)),
    );
    final payload = jsonDecode(decoded);
    if (payload is! Map ||
        payload.length != 3 ||
        payload['schema_version'] != battleReplayCursorSchema) {
      throw const BattleReplayCursorException();
    }
    final createdAt =
        DateTime.tryParse(payload['created_at']?.toString() ?? '')?.toUtc();
    final id = payload['id']?.toString() ?? '';
    if (createdAt == null || !isBattleReplayUuid(id)) {
      throw const BattleReplayCursorException();
    }
    return _BattleReplayCursorMarker(createdAt: createdAt, id: id);
  } on BattleReplayCursorException {
    rethrow;
  } catch (_) {
    throw const BattleReplayCursorException();
  }
}

String _encodeBattleReplayCursor(Map<String, dynamic> row) {
  final createdAtValue = row['created_at'];
  final createdAt =
      createdAtValue is DateTime
          ? createdAtValue.toUtc()
          : DateTime.tryParse(createdAtValue?.toString() ?? '')?.toUtc();
  final id = row['id']?.toString() ?? '';
  if (createdAt == null || !isBattleReplayUuid(id)) {
    throw StateError('Battle replay page marker is invalid.');
  }
  final payload = jsonEncode({
    'schema_version': battleReplayCursorSchema,
    'created_at': createdAt.toIso8601String(),
    'id': id,
  });
  return base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
}
