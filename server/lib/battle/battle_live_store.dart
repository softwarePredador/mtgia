import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'battle_job_contract.dart';
import 'battle_live_cursor_contract.dart';
import 'battle_live_source_client.dart';

const battleLiveMaximumStoredRecords = battleLiveMaximumSourceRecords;

class BattleLiveStoreException implements Exception {
  const BattleLiveStoreException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveStoreException($code)';
}

class BattleLiveJobState {
  const BattleLiveJobState({
    required this.id,
    required this.userId,
    required this.status,
    required this.requestId,
    required this.requestedEngine,
    required this.engineLane,
    required this.engine,
    required this.replayId,
    required this.replayGameLog,
  });

  final String id;
  final String userId;
  final BattleJobStatus status;
  final String? requestId;
  final String requestedEngine;
  final String engineLane;
  final String? engine;
  final String? replayId;
  final Object? replayGameLog;
}

class BattleLiveRecordWrite {
  const BattleLiveRecordWrite({
    required this.kind,
    required this.payload,
    required this.contentTruncated,
    required this.fingerprint,
    required this.sourceKind,
    this.publicVisible = true,
    this.sourceProcessId,
    this.sourceSequence,
    this.sourceRecordId,
  });

  final BattleLiveRecordKind kind;
  final Map<String, dynamic> payload;
  final bool contentTruncated;
  final String fingerprint;
  final String sourceKind;
  final bool publicVisible;
  final String? sourceProcessId;
  final int? sourceSequence;
  final String? sourceRecordId;
}

class BattleLiveStoredRecords {
  BattleLiveStoredRecords({
    required List<BattleLiveSourceRecord> records,
    required this.sourceTruncated,
  }) : records = List.unmodifiable(records);

  final List<BattleLiveSourceRecord> records;
  final bool sourceTruncated;
}

class BattleLiveAppendResult {
  const BattleLiveAppendResult({
    required this.appended,
    required this.limitReached,
  });

  final int appended;
  final bool limitReached;
}

class BattleLiveSourceCheckpoint {
  const BattleLiveSourceCheckpoint({
    required this.sourceProcessId,
    required this.afterSequence,
  });

  final String sourceProcessId;
  final int afterSequence;
}

abstract interface class BattleLiveStoreApi {
  Future<BattleLiveJobState?> getJob({
    required String userId,
    required String jobId,
  });

  Future<BattleLiveAppendResult> append({
    required String userId,
    required String jobId,
    required List<BattleLiveRecordWrite> records,
    required bool sourceTruncated,
  });

  Future<BattleLiveSourceCheckpoint?> sourceCheckpoint({
    required String userId,
    required String jobId,
  });

  Future<BattleLiveStoredRecords> list({
    required String userId,
    required String jobId,
  });
}

class BattleLiveStore implements BattleLiveStoreApi {
  const BattleLiveStore(this._pool);

  final Pool _pool;

  @override
  Future<BattleLiveJobState?> getJob({
    required String userId,
    required String jobId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          job.id::text AS id,
          job.user_id::text AS user_id,
          job.status,
          job.request_payload,
          job.requested_engine,
          job.engine_lane,
          job.engine,
          job.replay_id::text AS replay_id,
          replay.game_log AS replay_game_log
        FROM battle_jobs job
        LEFT JOIN battle_simulations replay ON replay.id = job.replay_id
        WHERE job.id = CAST(@job_id AS uuid)
          AND job.user_id = CAST(@user_id AS uuid)
        LIMIT 1
      '''),
      parameters: {'job_id': jobId, 'user_id': userId},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    final request = decodeBattleJobJsonMap(row['request_payload']);
    return BattleLiveJobState(
      id: row['id']?.toString() ?? jobId,
      userId: row['user_id']?.toString() ?? userId,
      status: parseBattleJobStatus(row['status']),
      requestId: _nullableString(request['request_id']),
      requestedEngine: row['requested_engine']?.toString() ?? '',
      engineLane: row['engine_lane']?.toString() ?? '',
      engine: _nullableString(row['engine']),
      replayId: _nullableString(row['replay_id']),
      replayGameLog: row['replay_game_log'],
    );
  }

  @override
  Future<BattleLiveAppendResult> append({
    required String userId,
    required String jobId,
    required List<BattleLiveRecordWrite> records,
    required bool sourceTruncated,
  }) {
    if (records.length > battleLiveMaximumStoredRecords) {
      throw const BattleLiveStoreException('record_batch_too_large');
    }
    return _pool.runTx((transaction) async {
      final owner = await transaction.execute(
        Sql.named('''
          SELECT id
          FROM battle_jobs
          WHERE id = CAST(@job_id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
          FOR UPDATE
        '''),
        parameters: {'job_id': jobId, 'user_id': userId},
      );
      if (owner.isEmpty) {
        throw const BattleLiveStoreException('job_not_found');
      }

      final state = await transaction.execute(
        Sql.named('''
          SELECT
            COALESCE(MAX(sequence), -1)::bigint AS maximum_sequence,
            COUNT(*)::int AS record_count
          FROM battle_job_live_records
          WHERE job_id = CAST(@job_id AS uuid)
        '''),
        parameters: {'job_id': jobId},
      );
      final stateRow = state.first.toColumnMap();
      var nextSequence = _int(stateRow['maximum_sequence']) + 1;
      var count = _int(stateRow['record_count']);
      var appended = 0;
      var limitReached = count >= battleLiveMaximumStoredRecords;

      for (final record in records) {
        if (count >= battleLiveMaximumStoredRecords) {
          limitReached = true;
          break;
        }
        final inserted = await transaction.execute(
          Sql.named('''
            INSERT INTO battle_job_live_records (
              job_id,
              sequence,
              record_id,
              kind,
              payload,
              content_truncated,
              fingerprint,
              source_kind,
              source_process_id,
              source_sequence,
              source_record_id,
              source_truncated,
              public_visible
            )
            VALUES (
              CAST(@job_id AS uuid),
              @sequence,
              @record_id,
              @kind,
              @payload::jsonb,
              @content_truncated,
              @fingerprint,
              @source_kind,
              @source_process_id,
              @source_sequence,
              @source_record_id,
              @source_truncated,
              @public_visible
            )
            ON CONFLICT (job_id, fingerprint) DO NOTHING
            RETURNING sequence
          '''),
          parameters: {
            'job_id': jobId,
            'sequence': nextSequence,
            'record_id': 'blr-${record.fingerprint.substring(0, 40)}',
            'kind': record.kind.wireValue,
            'payload': jsonEncode(record.payload),
            'content_truncated': record.contentTruncated,
            'fingerprint': record.fingerprint,
            'source_kind': record.sourceKind,
            'source_process_id': record.sourceProcessId,
            'source_sequence': record.sourceSequence,
            'source_record_id': record.sourceRecordId,
            'source_truncated': sourceTruncated,
            'public_visible': record.publicVisible,
          },
        );
        if (inserted.isEmpty) continue;
        nextSequence += 1;
        count += 1;
        if (record.publicVisible) appended += 1;
      }
      return BattleLiveAppendResult(
        appended: appended,
        limitReached: limitReached,
      );
    });
  }

  @override
  Future<BattleLiveSourceCheckpoint?> sourceCheckpoint({
    required String userId,
    required String jobId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          record.source_process_id,
          record.source_sequence
        FROM battle_job_live_records record
        JOIN battle_jobs job ON job.id = record.job_id
        WHERE record.job_id = CAST(@job_id AS uuid)
          AND job.user_id = CAST(@user_id AS uuid)
          AND record.source_kind = 'xmage_checkpoint'
          AND record.source_process_id IS NOT NULL
          AND record.source_sequence IS NOT NULL
        ORDER BY record.sequence DESC
        LIMIT 1
      '''),
      parameters: {'job_id': jobId, 'user_id': userId},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    final processId = _nullableString(row['source_process_id']);
    if (processId == null) {
      throw const BattleLiveStoreException('checkpoint_invalid');
    }
    return BattleLiveSourceCheckpoint(
      sourceProcessId: processId,
      afterSequence: _int(row['source_sequence']),
    );
  }

  @override
  Future<BattleLiveStoredRecords> list({
    required String userId,
    required String jobId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          record.sequence,
          record.record_id,
          record.kind,
          record.payload,
          record.content_truncated,
          record.source_truncated,
          record.public_visible
        FROM battle_job_live_records record
        JOIN battle_jobs job ON job.id = record.job_id
        WHERE record.job_id = CAST(@job_id AS uuid)
          AND job.user_id = CAST(@user_id AS uuid)
        ORDER BY record.sequence ASC
        LIMIT @limit
      '''),
      parameters: {
        'job_id': jobId,
        'user_id': userId,
        'limit': battleLiveMaximumStoredRecords + 1,
      },
    );
    if (result.length > battleLiveMaximumStoredRecords) {
      throw const BattleLiveStoreException('record_limit_exceeded');
    }

    var sourceTruncated = false;
    final records = <BattleLiveSourceRecord>[];
    for (final resultRow in result) {
      final row = resultRow.toColumnMap();
      final sequence = _int(row['sequence']);
      final recordId = row['record_id']?.toString() ?? '';
      final payload = _jsonMap(row['payload']);
      final contentTruncated = row['content_truncated'] == true;
      sourceTruncated = sourceTruncated || row['source_truncated'] == true;
      if (row['public_visible'] != true) continue;
      switch (row['kind']) {
        case 'event':
          records.add(
            BattleLiveSourceRecord.event(
              sequence: sequence,
              recordId: recordId,
              event: payload,
              contentTruncated: contentTruncated,
            ),
          );
          break;
        case 'snapshot':
          records.add(
            BattleLiveSourceRecord.snapshot(
              sequence: sequence,
              recordId: recordId,
              snapshot: payload,
              contentTruncated: contentTruncated,
            ),
          );
          break;
        default:
          throw const BattleLiveStoreException('record_kind_invalid');
      }
    }
    return BattleLiveStoredRecords(
      records: records,
      sourceTruncated: sourceTruncated,
    );
  }
}

Map<String, dynamic> _jsonMap(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      // Fail closed below.
    }
  }
  throw const BattleLiveStoreException('record_payload_invalid');
}

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

int _int(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
