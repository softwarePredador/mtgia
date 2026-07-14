import 'dart:convert';

import 'package:postgres/postgres.dart';

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
    if (!await _hasBattleSimulationTable()) {
      return const <Map<String, dynamic>>[];
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
          bs.metrics AS metrics,
          bs.created_at AS created_at,
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
          END AS winner_label
        FROM battle_simulations bs
        LEFT JOIN decks da ON da.id = bs.deck_a_id
        LEFT JOIN decks db ON db.id = bs.deck_b_id
        WHERE bs.deck_a_id = CAST(@deckId AS uuid)
           OR bs.deck_b_id = CAST(@deckId AS uuid)
        ORDER BY bs.created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'deckId': deckId,
        'userId': userId,
        'limit': limit.clamp(1, 100),
      },
    );

    return result
        .map((row) => _summaryFromRow(row.toColumnMap(), deckId: deckId))
        .toList(growable: false);
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
          CASE
            WHEN da.user_id = CAST(@userId AS uuid) OR da.is_public = true
            THEN da.name
            ELSE NULL
          END AS deck_a_name,
          CASE
            WHEN db.user_id = CAST(@userId AS uuid) OR db.is_public = true
            THEN db.name
            ELSE NULL
          END AS deck_b_name
        FROM battle_simulations bs
        LEFT JOIN decks da ON da.id = bs.deck_a_id
        LEFT JOIN decks db ON db.id = bs.deck_b_id
        WHERE bs.id = CAST(@replayId AS uuid)
          AND (
            bs.deck_a_id = CAST(@deckId AS uuid)
            OR bs.deck_b_id = CAST(@deckId AS uuid)
          )
        LIMIT 1
      '''),
      parameters: {
        'deckId': deckId,
        'replayId': replayId,
        'userId': userId,
      },
    );

    if (result.isEmpty) return null;
    return _detailFromRow(result.first.toColumnMap(), deckId: deckId);
  }

  Future<bool> _hasBattleSimulationTable() async {
    final result = await _pool.execute('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'battle_simulations'
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
    final opponentName = isDeckA
        ? row['deck_b_name']?.toString()
        : row['deck_a_name']?.toString();
    final winnerDeckId = row['winner_deck_id']?.toString();
    final winnerName = winnerDeckId == null
        ? row['winner_label']?.toString()
        : _winnerNameForRow(row, winnerDeckId);

    return {
      'id': row['id']?.toString(),
      'deck_id': deckId,
      'deck_a_id': deckAId,
      'deck_b_id': deckBId,
      'opponent_deck_id': opponentDeckId,
      if (opponentName != null && opponentName.trim().isNotEmpty)
        'opponent_name': opponentName,
      'type': row['game_log_type']?.toString() ??
          row['simulation_type']?.toString(),
      'simulation_type': row['simulation_type']?.toString(),
      'winner_deck_id': winnerDeckId,
      if (winnerName != null && winnerName.trim().isNotEmpty)
        'winner_name': winnerName,
      'turns_played': _toInt(row['turns_played']),
      'event_count': _toInt(row['event_count']),
      'metrics': _jsonValue(row['metrics']),
      'created_at': _timestamp(row['created_at']),
      'source': 'battle_simulations',
      'status': 'completed',
    };
  }

  Map<String, dynamic> _detailFromRow(
    Map<String, dynamic> row, {
    required String deckId,
  }) {
    final summary = _summaryFromRow(row, deckId: deckId);
    final gameLog = _jsonValue(row['game_log']);
    final events = _eventsFromGameLog(gameLog);
    final decisions = _decisionsFromGameLog(gameLog);
    final visualSnapshots = _visualSnapshotsFromGameLog(gameLog);
    final gameLogMap = gameLog is Map ? gameLog : const {};
    final winnerLabel = gameLogMap['winner']?.toString();
    final gameLogType = gameLogMap['type']?.toString();
    final gameLogTurns = _toInt(gameLogMap['turns']);
    final engine = gameLogMap['engine']?.toString();
    final engineContract = gameLogMap['engine_contract']?.toString();
    final rawLearningContract = gameLogMap['learning_contract'];
    final learningContract = rawLearningContract is Map
        ? Map<String, dynamic>.from(rawLearningContract)
        : const <String, dynamic>{};
    final isCanonicalRulesExecution =
        (engine == 'xmage' && engineContract == 'canonical_rules_execution') ||
            (engine == 'forge' &&
                engineContract == 'canonical_rules_execution_secondary');

    return {
      ...summary,
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
      'visual_snapshots': visualSnapshots,
      if (engine != null && engine.isNotEmpty) 'engine': engine,
      if (gameLogMap['engine_version'] != null)
        'engine_version': gameLogMap['engine_version'],
      if (gameLogMap['engine_commit'] != null)
        'engine_commit': gameLogMap['engine_commit'],
      if (learningContract.isNotEmpty) 'learning_contract': learningContract,
      'simulation_contract': {
        'status': isCanonicalRulesExecution
            ? engineContract
            : 'experimental_advisory',
        'advisory_only': !isCanonicalRulesExecution,
        'canonical_rules_execution': isCanonicalRulesExecution,
        if (isCanonicalRulesExecution)
          'rules_engine_priority': engine == 'xmage' ? 'primary' : 'secondary',
        'canonical_legality_source': false,
        'strategy_or_swap_proof': false,
        'event_learning_grade':
            learningContract.isEmpty ? 'not_declared' : 'visible_activity_only',
        'named_draw_identity_available':
            learningContract['named_draw_identity_available'] == true,
        'ai_decision_rationale_available':
            learningContract['ai_decision_rationale_available'] == true,
      },
    };
  }

  Object? _jsonValue(Object? value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
    return value;
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
