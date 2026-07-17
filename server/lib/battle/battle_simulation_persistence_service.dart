import 'dart:convert';

import 'package:postgres/postgres.dart';

class BattleSimulationPersistenceOutcome {
  const BattleSimulationPersistenceOutcome.saved(this.replayId)
    : status = 'saved',
      errorCode = null;

  const BattleSimulationPersistenceOutcome.failed(this.errorCode)
    : status = 'failed',
      replayId = null;

  final String status;
  final String? replayId;
  final String? errorCode;

  bool get isSaved => status == 'saved' && replayId?.trim().isNotEmpty == true;

  Map<String, dynamic> toJson() => {
    'status': status,
    'required': true,
    if (replayId != null) 'replay_id': replayId,
    if (errorCode != null) 'error': errorCode,
  };
}

class BattleSimulationPersistenceService {
  const BattleSimulationPersistenceService(this._pool);

  final Pool _pool;

  Future<BattleSimulationPersistenceOutcome> save({
    required String deckAId,
    String? deckBId,
    required String type,
    required Map<String, dynamic> result,
  }) async {
    try {
      final tableExists = await _pool.execute('''
        SELECT EXISTS (
          SELECT FROM information_schema.tables
          WHERE table_name = 'battle_simulations'
            AND table_schema = current_schema()
        )
      ''');
      if (tableExists.isEmpty || tableExists.first[0] != true) {
        return const BattleSimulationPersistenceOutcome.failed(
          'battle_simulations_unavailable',
        );
      }

      final columns = await _pool.execute('''
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'battle_simulations'
          AND table_schema = current_schema()
          AND column_name IN (
            'simulation_type',
            'metrics',
            'winner_deck_id',
            'turns_played'
          )
      ''');
      final availableColumns =
          columns.map((row) => row[0]?.toString()).whereType<String>().toSet();
      final hasSimulationType = availableColumns.contains('simulation_type');
      final hasMetrics = availableColumns.contains('metrics');
      final hasWinnerDeckId = availableColumns.contains('winner_deck_id');
      final hasTurnsPlayed = availableColumns.contains('turns_played');
      final winnerDeckId = canonicalBattleWinnerDeckId(
        result: result,
        deckAId: deckAId,
        deckBId: deckBId,
      );
      final payload = {...result, 'type': type, 'winner_deck_id': winnerDeckId};
      final turnsPlayed = (result['turns'] as num?)?.toInt();

      final insertResult = await _pool.execute(
        Sql.named('''
          INSERT INTO battle_simulations (
            deck_a_id,
            deck_b_id,
            game_log
            ${hasSimulationType ? ', simulation_type' : ''}
            ${hasMetrics ? ', metrics' : ''}
            ${hasWinnerDeckId ? ', winner_deck_id' : ''}
            ${hasTurnsPlayed ? ', turns_played' : ''}
          )
          VALUES (
            @deckAId,
            @deckBId,
            @gameLog::jsonb
            ${hasSimulationType ? ', @simulationType' : ''}
            ${hasMetrics ? ', @metrics::jsonb' : ''}
            ${hasWinnerDeckId ? ', @winnerDeckId' : ''}
            ${hasTurnsPlayed ? ', @turnsPlayed' : ''}
          )
          RETURNING id::text
          '''),
        parameters: {
          'deckAId': deckAId,
          'deckBId': deckBId,
          'gameLog': jsonEncode(payload),
          if (hasSimulationType) 'simulationType': type,
          if (hasMetrics)
            'metrics': jsonEncode(
              _simulationMetrics(result, winnerDeckId: winnerDeckId),
            ),
          if (hasWinnerDeckId) 'winnerDeckId': winnerDeckId,
          if (hasTurnsPlayed) 'turnsPlayed': turnsPlayed,
        },
      );
      final replayId =
          insertResult.isEmpty
              ? null
              : insertResult.first[0]?.toString().trim();
      if (replayId == null || replayId.isEmpty) {
        return const BattleSimulationPersistenceOutcome.failed(
          'simulation_persistence_missing_id',
        );
      }
      return BattleSimulationPersistenceOutcome.saved(replayId);
    } catch (_) {
      return const BattleSimulationPersistenceOutcome.failed(
        'simulation_persistence_failed',
      );
    }
  }
}

String? canonicalBattleWinnerDeckId({
  required Map<String, dynamic> result,
  required String deckAId,
  String? deckBId,
}) {
  final explicit = result['winner_deck_id']?.toString().trim();
  if (explicit == deckAId || (deckBId != null && explicit == deckBId)) {
    return explicit;
  }
  return switch (result['winner']?.toString()) {
    'Deck A' => deckAId,
    'Deck B' => deckBId,
    _ => null,
  };
}

Map<String, dynamic> _simulationMetrics(
  Map<String, dynamic> result, {
  required String? winnerDeckId,
}) {
  final nested = result['metrics'];
  return {
    if (nested is Map) ...nested.cast<String, dynamic>(),
    'engine': result['engine'],
    'engine_contract': result['engine_contract'],
    'duration_ms': result['duration_ms'],
    'turns': result['turns'],
    'winner_deck_id': winnerDeckId,
    'event_count':
        (result['events'] as List?)?.length ??
        (result['game_log'] as List?)?.length,
    'snapshot_count': (result['visual_snapshots'] as List?)?.length,
  }..removeWhere((_, value) => value == null);
}
