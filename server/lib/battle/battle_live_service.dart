import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'battle_job_contract.dart';
import 'battle_live_cursor_contract.dart';
import 'battle_live_source_client.dart';
import 'battle_live_store.dart';
import 'battle_replay_payload_sanitizer.dart';

const battleLiveCursorKeyDomain = 'manaloom:battle-live-cursor:v1';
const battleLiveSpectatorEnabledEnvironment = 'BATTLE_LIVE_SPECTATOR_ENABLED';

bool battleLiveSpectatorEnabledValue(String? raw) =>
    raw?.trim().toLowerCase() == 'true';

class BattleLiveValidationException implements Exception {
  const BattleLiveValidationException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveValidationException($code)';
}

class BattleLiveNotFoundException implements Exception {
  const BattleLiveNotFoundException();
}

class BattleLiveConflictException implements Exception {
  const BattleLiveConflictException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveConflictException($code)';
}

class BattleLiveUnavailableException implements Exception {
  const BattleLiveUnavailableException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveUnavailableException($code)';
}

class BattleLiveQuery {
  const BattleLiveQuery({this.cursor, this.limit});

  final String? cursor;
  final int? limit;

  factory BattleLiveQuery.parse(Map<String, String> query) {
    const allowed = <String>{'cursor', 'limit'};
    if (query.keys.any((key) => !allowed.contains(key))) {
      throw const BattleLiveValidationException('query_invalid');
    }
    final rawCursor = query['cursor'];
    final cursor =
        rawCursor == null
            ? null
            : rawCursor.trim().isEmpty || rawCursor.length > 2048
            ? throw const BattleLiveValidationException('cursor_invalid')
            : rawCursor.trim();
    final rawLimit = query['limit'];
    final limit = rawLimit == null ? null : int.tryParse(rawLimit);
    if (rawLimit != null &&
        (limit == null || limit < 1 || limit > battleLiveMaximumPageLimit)) {
      throw const BattleLiveValidationException('limit_invalid');
    }
    return BattleLiveQuery(cursor: cursor, limit: limit);
  }
}

List<int> deriveBattleLiveCursorSigningKey(String jwtSecret) {
  final secret = jwtSecret.trim();
  if (secret.isEmpty) {
    throw const BattleLiveUnavailableException(
      'cursor_signing_key_unavailable',
    );
  }
  return Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(battleLiveCursorKeyDomain)).bytes;
}

class BattleLiveService {
  const BattleLiveService({
    required BattleLiveStoreApi store,
    required BattleLiveCursorContract cursorContract,
    BattleLiveSource? source,
  }) : _store = store,
       _cursorContract = cursorContract,
       _source = source;

  final BattleLiveStoreApi _store;
  final BattleLiveCursorContract _cursorContract;
  final BattleLiveSource? _source;

  void close() => _source?.close();

  Future<BattleLivePage> read({
    required String userId,
    required String jobId,
    BattleLiveQuery query = const BattleLiveQuery(),
  }) async {
    final job = await _store.getJob(userId: userId, jobId: jobId);
    if (job == null) throw const BattleLiveNotFoundException();
    if (!_supportsXmageLive(job)) {
      throw const BattleLiveConflictException('battle_live_engine_unsupported');
    }

    var sourceTruncated = false;
    var sourceLimitReached = false;
    final jobStatus = _liveStatus(job.status);
    if (jobStatus == BattleLiveStatus.running ||
        jobStatus == BattleLiveStatus.cancelPending) {
      final source = _source;
      if (source == null) {
        throw const BattleLiveUnavailableException(
          'battle_live_source_unavailable',
        );
      }
      final requestId = job.requestId;
      if (requestId == null ||
          !battleLiveSourceRequestIdPattern.hasMatch(requestId)) {
        throw const BattleLiveConflictException(
          'battle_live_request_incompatible',
        );
      }

      final checkpoint = await _store.sourceCheckpoint(
        userId: userId,
        jobId: jobId,
      );
      BattleLiveSourceSnapshot? snapshot;
      try {
        snapshot = await source.read(
          requestId,
          afterSequence: checkpoint?.afterSequence ?? -1,
          limit: battleLiveSourcePageLimit,
        );
        if (checkpoint != null &&
            snapshot.sourceProcessId != checkpoint.sourceProcessId) {
          snapshot = await source.read(
            requestId,
            limit: battleLiveSourcePageLimit,
          );
        }
      } on BattleLiveSourceException catch (error) {
        if (error.code == 'invalid_request_id') {
          throw const BattleLiveConflictException(
            'battle_live_request_incompatible',
          );
        }
        if (error.code == 'source_stream_not_found') {
          snapshot = null;
        } else {
          throw const BattleLiveUnavailableException(
            'battle_live_source_unavailable',
          );
        }
      }
      if (snapshot != null) {
        final sanitized = _cursorContract.sanitizeRecordsForStorage(
          snapshot.records,
        );
        final writes = _recordWrites(
          sanitized,
          sourceKind: 'xmage_live',
          sourceProcessId: snapshot.sourceProcessId,
        )..add(_checkpointWrite(snapshot));
        final appended = await _store.append(
          userId: userId,
          jobId: jobId,
          records: writes,
          sourceTruncated: snapshot.sourceTruncated,
        );
        sourceTruncated = snapshot.sourceTruncated;
        sourceLimitReached = appended.limitReached;

        if (snapshot.status == BattleLiveStatus.interrupted) {
          throw const BattleLiveUnavailableException(
            'battle_live_source_interrupted',
          );
        }
      }
    }

    if (jobStatus.isTerminal &&
        job.replayId != null &&
        job.replayGameLog != null) {
      final replayRecords = _recordsFromReplay(job.replayGameLog);
      final sanitized = _cursorContract.sanitizeRecordsForStorage(
        replayRecords,
      );
      final appended = await _store.append(
        userId: userId,
        jobId: jobId,
        records: _recordWrites(sanitized, sourceKind: 'terminal_replay'),
        sourceTruncated: false,
      );
      sourceLimitReached = sourceLimitReached || appended.limitReached;
    }

    final stored = await _store.list(userId: userId, jobId: jobId);
    try {
      return _cursorContract.buildPage(
        streamId: job.id,
        status: jobStatus,
        records: stored.records,
        cursor: query.cursor,
        requestedLimit: query.limit,
        replayId: jobStatus.isTerminal ? job.replayId : null,
        terminalReason:
            jobStatus.isTerminal ? 'battle_job_${jobStatus.wireValue}' : null,
        sourceTruncated:
            stored.sourceTruncated || sourceTruncated || sourceLimitReached,
      );
    } on BattleLiveContractException catch (error) {
      if (error.code == 'invalid_cursor' ||
          error.code == 'cursor_stream_mismatch' ||
          error.code == 'invalid_page_limit') {
        throw const BattleLiveValidationException('cursor_invalid');
      }
      throw const BattleLiveUnavailableException(
        'battle_live_contract_unavailable',
      );
    }
  }
}

BattleLiveRecordWrite _checkpointWrite(BattleLiveSourceSnapshot snapshot) {
  final material =
      'battle_live_source_checkpoint_v1\n'
      '${snapshot.sourceProcessId}\n'
      '${snapshot.nextAfterSequence}\n';
  return BattleLiveRecordWrite(
    kind: BattleLiveRecordKind.event,
    payload: const {},
    contentTruncated: false,
    fingerprint: sha256.convert(utf8.encode(material)).toString(),
    sourceKind: 'xmage_checkpoint',
    publicVisible: false,
    sourceProcessId: snapshot.sourceProcessId,
    sourceSequence: snapshot.nextAfterSequence,
  );
}

bool _supportsXmageLive(BattleLiveJobState job) {
  final actual = job.engine?.trim().toLowerCase();
  if (actual != null && actual.isNotEmpty) return actual == 'xmage';
  if (job.status == BattleJobStatus.queued ||
      job.status == BattleJobStatus.claimed) {
    return job.requestedEngine == 'auto' || job.requestedEngine == 'xmage';
  }
  return job.engineLane == 'xmage' &&
      (job.requestedEngine == 'auto' || job.requestedEngine == 'xmage');
}

BattleLiveStatus _liveStatus(BattleJobStatus status) => switch (status) {
  BattleJobStatus.queued => BattleLiveStatus.queued,
  BattleJobStatus.claimed => BattleLiveStatus.claimed,
  BattleJobStatus.running => BattleLiveStatus.running,
  BattleJobStatus.cancelPending => BattleLiveStatus.cancelPending,
  BattleJobStatus.completed => BattleLiveStatus.completed,
  BattleJobStatus.censored => BattleLiveStatus.censored,
  BattleJobStatus.timeout => BattleLiveStatus.timeout,
  BattleJobStatus.coverageError => BattleLiveStatus.coverageError,
  BattleJobStatus.engineError => BattleLiveStatus.engineError,
  BattleJobStatus.cancelled => BattleLiveStatus.cancelled,
  BattleJobStatus.persistenceError => BattleLiveStatus.persistenceError,
};

List<BattleLiveRecordWrite> _recordWrites(
  List<BattleLiveSourceRecord> records, {
  required String sourceKind,
  String? sourceProcessId,
}) {
  return records
      .map(
        (record) => BattleLiveRecordWrite(
          kind: record.kind,
          payload: record.payload,
          contentTruncated: record.contentTruncated,
          fingerprint: _recordFingerprint(record),
          sourceKind: sourceKind,
          sourceProcessId: sourceProcessId,
          sourceSequence: sourceKind == 'xmage_live' ? record.sequence : null,
          sourceRecordId: sourceKind == 'xmage_live' ? record.recordId : null,
        ),
      )
      .toList();
}

String _recordFingerprint(BattleLiveSourceRecord record) {
  final material = <String>[
    'battle_live_record_fingerprint_v1',
    record.kind.wireValue,
    jsonEncode(_canonicalJson(record.payload)),
  ].join('\n');
  return sha256.convert(utf8.encode('$material\n')).toString();
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, dynamic>{
      for (final key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) {
    return value.map(_canonicalJson).toList(growable: false);
  }
  return value;
}

List<BattleLiveSourceRecord> _recordsFromReplay(Object? persisted) {
  late final Object sanitized;
  try {
    sanitized = sanitizePersistedBattleReplay(persisted);
  } on BattleReplayPayloadException {
    throw const BattleLiveUnavailableException('battle_live_replay_invalid');
  }
  final events = _eventsFromReplay(sanitized);
  final snapshots = _snapshotsFromReplay(sanitized, events: events);
  final records = <BattleLiveSourceRecord>[];
  for (var index = 0; index < events.length; index += 1) {
    final event = _stringMap(events[index]);
    if (event == null) continue;
    final normalized = normalizeXmageBattleLiveEvent(event);
    if (normalized == null) continue;
    records.add(
      BattleLiveSourceRecord.event(
        sequence: records.length,
        recordId: 'replay-e-$index',
        event: normalized,
      ),
    );
  }
  for (var index = 0; index < snapshots.length; index += 1) {
    final snapshot = _stringMap(snapshots[index]);
    if (snapshot == null) continue;
    records.add(
      BattleLiveSourceRecord.snapshot(
        sequence: records.length,
        recordId: 'replay-s-$index',
        snapshot: normalizeXmageBattleLiveSnapshot(snapshot),
      ),
    );
  }
  return records;
}

List<dynamic> _eventsFromReplay(Object? gameLog) {
  if (gameLog is List) return gameLog;
  if (gameLog is Map) {
    final nested = gameLog['game_log'];
    if (nested is List) return nested;
    final events = gameLog['events'];
    if (events is List) return events;
  }
  return const [];
}

List<dynamic> _snapshotsFromReplay(
  Object? gameLog, {
  required List<dynamic> events,
}) {
  if (gameLog is! Map) return const [];
  for (final key in const [
    'visual_snapshots',
    'snapshots',
    'replay_snapshots',
  ]) {
    final snapshots = gameLog[key];
    if (snapshots is List && snapshots.isNotEmpty) return snapshots;
  }
  return events
      .whereType<Map>()
      .map((event) => event['snapshot'])
      .whereType<Map>()
      .toList(growable: false);
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}
