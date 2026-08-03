import 'dart:convert';

import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_live_cursor_contract.dart';
import 'package:server/battle/battle_live_service.dart';
import 'package:server/battle/battle_live_source_client.dart';
import 'package:server/battle/battle_live_store.dart';
import 'package:test/test.dart';

void main() {
  test('derives a deterministic domain-separated key from JWT_SECRET', () {
    final first = deriveBattleLiveCursorSigningKey('local-jwt-secret');
    final second = deriveBattleLiveCursorSigningKey('local-jwt-secret');
    final other = deriveBattleLiveCursorSigningKey('another-jwt-secret');

    expect(first, hasLength(32));
    expect(first, second);
    expect(first, isNot(other));
    expect(utf8.decode(first, allowMalformed: true), isNot('local-jwt-secret'));
    expect(
      () => deriveBattleLiveCursorSigningKey(''),
      throwsA(isA<BattleLiveUnavailableException>()),
    );
  });

  test(
    'persists pages and resumes after backend restart without duplicates',
    () async {
      final store = _MemoryStore(_runningJob());
      final source = _CallbackSource((_, after, __) {
        if (after == -1) {
          return _snapshot(
            records: [_event(0, 'Sol Ring'), _event(1, 'Arcane Signet')],
            nextAfter: 1,
            hasMore: true,
          );
        }
        expect(after, 1);
        return _snapshot(
          records: [_event(1, 'Arcane Signet'), _event(2, 'Command Tower')],
          after: 1,
          nextAfter: 2,
        );
      });
      final firstService = _service(store, source);

      final first = await firstService.read(userId: _userId, jobId: _jobId);
      final firstCursor = first.nextCursor;
      expect(first.items.map((item) => item.payload['card_name']), [
        'Sol Ring',
        'Arcane Signet',
      ]);
      expect(source.afters, [-1]);

      final restartedService = _service(store, source);
      final resumed = await restartedService.read(
        userId: _userId,
        jobId: _jobId,
        query: BattleLiveQuery(cursor: firstCursor),
      );

      expect(source.afters, [-1, 1]);
      expect(resumed.items, hasLength(1));
      expect(resumed.items.single.payload['card_name'], 'Command Tower');
      expect(store.publicRecords.map((record) => record.payload['card_name']), [
        'Sol Ring',
        'Arcane Signet',
        'Command Tower',
      ]);
    },
  );

  test(
    'detects sidecar restart and performs one bounded restart read',
    () async {
      final store = _MemoryStore(_runningJob());
      store.checkpoint = const BattleLiveSourceCheckpoint(
        sourceProcessId: 'process-old',
        afterSequence: 120,
      );
      final source = _CallbackSource((_, after, __) {
        if (after == 120) {
          return _snapshot(
            processId: 'process-new',
            records: const [],
            after: 120,
            nextAfter: 120,
          );
        }
        expect(after, -1);
        return _snapshot(
          processId: 'process-new',
          records: [_event(0, 'Restarted Stream Card')],
          nextAfter: 0,
        );
      });

      final page = await _service(
        store,
        source,
      ).read(userId: _userId, jobId: _jobId);

      expect(source.afters, [120, -1]);
      expect(page.items.single.payload['card_name'], 'Restarted Stream Card');
      expect(store.checkpoint?.sourceProcessId, 'process-new');
      expect(store.checkpoint?.afterSequence, 0);
    },
  );

  test(
    'running auto job with unresolved engine keeps source 404 recoverable',
    () async {
      final store = _MemoryStore(
        _runningJob(requestedEngine: 'auto', engineLane: 'auto'),
      );
      final source = _ThrowingSource(
        const BattleLiveSourceException(
          'source_stream_not_found',
          statusCode: 404,
          retryable: true,
        ),
      );

      final page = await _service(
        store,
        source,
      ).read(userId: _userId, jobId: _jobId);

      expect(page.status, BattleLiveStatus.running);
      expect(page.items, isEmpty);
      expect(page.replay, isNull);
      expect(page.status.isTerminal, isFalse);
      expect(source.calls, 1);
    },
  );

  test('queued auto jobs expose an empty page before XMage dispatch', () async {
    final store = _MemoryStore(
      _runningJob(
        status: BattleJobStatus.queued,
        requestedEngine: 'auto',
        engineLane: 'auto',
      ),
    );

    final page = await _service(
      store,
      null,
    ).read(userId: _userId, jobId: _jobId);

    expect(page.status, BattleLiveStatus.queued);
    expect(page.items, isEmpty);
    expect(page.replay, isNull);
  });

  test(
    'source failures stay retriable and never fabricate terminal state',
    () async {
      final store = _MemoryStore(_runningJob());
      final source = _ThrowingSource(
        const BattleLiveSourceException(
          'source_http_error',
          statusCode: 503,
          retryable: true,
        ),
      );

      await expectLater(
        _service(store, source).read(userId: _userId, jobId: _jobId),
        throwsA(
          isA<BattleLiveUnavailableException>().having(
            (error) => error.code,
            'code',
            'battle_live_source_unavailable',
          ),
        ),
      );
      expect(store.publicRecords, isEmpty);
    },
  );

  test(
    'terminal replay backfill is sanitized, deduplicated, and precedes replay',
    () async {
      final job = _runningJob(
        status: BattleJobStatus.completed,
        replayId: _replayId,
        replayGameLog: {
          'events': [
            {
              'action': 'stack_entry',
              'turn': 1,
              'player': 'deck_a',
              'card_name': 'Sol Ring',
              'hand': ['Secret Event Card'],
            },
            {'action': 'game_inform_personal', 'message': 'Secret callback'},
          ],
          'visual_snapshots': [
            {
              'index': 0,
              'turn': 1,
              'players': [
                {
                  'name': 'deck_a',
                  'life': 40,
                  'hand': ['Secret Hand Card'],
                  'library': ['Secret Library Card'],
                  'battlefield': [
                    {'name': 'Public Permanent'},
                  ],
                },
              ],
            },
          ],
        },
      );
      final store = _MemoryStore(job);
      final service = _service(store, null);

      final first = await service.read(
        userId: _userId,
        jobId: _jobId,
        query: const BattleLiveQuery(limit: 1),
      );
      expect(first.items, hasLength(1));
      expect(first.hasMore, isTrue);
      expect(first.replay, isNull);
      expect(first.replayPending, isTrue);

      final second = await service.read(
        userId: _userId,
        jobId: _jobId,
        query: BattleLiveQuery(cursor: first.nextCursor, limit: 10),
      );
      expect(second.items, hasLength(1));
      expect(second.replay?.replayId, _replayId);
      expect(second.replayPending, isFalse);
      expect(store.publicRecords, hasLength(2));

      final encoded = jsonEncode([
        ...first.items.map((item) => item.toJson()),
        ...second.items.map((item) => item.toJson()),
      ]);
      expect(encoded, isNot(contains('Secret Event Card')));
      expect(encoded, isNot(contains('Secret callback')));
      expect(encoded, isNot(contains('Secret Hand Card')));
      expect(encoded, isNot(contains('Secret Library Card')));
      expect(encoded, isNot(contains('Public Permanent')));
      expect(encoded, contains('"battlefield_count":1'));

      final reconnected = await service.read(
        userId: _userId,
        jobId: _jobId,
        query: BattleLiveQuery(cursor: second.nextCursor),
      );
      expect(reconnected.items, isEmpty);
      expect(reconnected.replay, isNull);
      expect(reconnected.replayAlreadyDelivered, isTrue);
      expect(
        store.publicRecords,
        hasLength(2),
        reason: 'fingerprints deduplicate',
      );
    },
  );

  test(
    'IDOR, unsupported engines, limits, and tampered cursors fail closed',
    () async {
      final store = _MemoryStore(_runningJob());
      final source = _CallbackSource(
        (_, __, ___) =>
            _snapshot(records: [_event(0, 'Sol Ring')], nextAfter: 0),
      );
      final service = _service(store, source);

      await expectLater(
        service.read(userId: _otherUserId, jobId: _jobId),
        throwsA(isA<BattleLiveNotFoundException>()),
      );
      expect(
        () => BattleLiveQuery.parse({'limit': '101'}),
        throwsA(isA<BattleLiveValidationException>()),
      );
      expect(
        () => BattleLiveQuery.parse({'unknown': '1'}),
        throwsA(isA<BattleLiveValidationException>()),
      );

      final first = await service.read(userId: _userId, jobId: _jobId);
      final cursor = first.nextCursor;
      final tampered =
          '${cursor.substring(0, cursor.length - 1)}'
          '${cursor.endsWith('A') ? 'B' : 'A'}';
      await expectLater(
        service.read(
          userId: _userId,
          jobId: _jobId,
          query: BattleLiveQuery(cursor: tampered),
        ),
        throwsA(isA<BattleLiveValidationException>()),
      );

      final unsupportedStore = _MemoryStore(
        _runningJob(requestedEngine: 'native', engineLane: 'native'),
      );
      await expectLater(
        _service(unsupportedStore, null).read(userId: _userId, jobId: _jobId),
        throwsA(
          isA<BattleLiveConflictException>().having(
            (error) => error.code,
            'code',
            'battle_live_engine_unsupported',
          ),
        ),
      );

      final resolvedNonXmageStore = _MemoryStore(
        _runningJob(
          requestedEngine: 'auto',
          engineLane: 'auto',
          engine: 'forge',
        ),
      );
      await expectLater(
        _service(
          resolvedNonXmageStore,
          null,
        ).read(userId: _userId, jobId: _jobId),
        throwsA(
          isA<BattleLiveConflictException>().having(
            (error) => error.code,
            'code',
            'battle_live_engine_unsupported',
          ),
        ),
      );
    },
  );
}

BattleLiveService _service(BattleLiveStoreApi store, BattleLiveSource? source) {
  return BattleLiveService(
    store: store,
    source: source,
    cursorContract: BattleLiveCursorContract(
      cursorSigningKey: deriveBattleLiveCursorSigningKey('shared-test-secret'),
    ),
  );
}

class _MemoryStore implements BattleLiveStoreApi {
  _MemoryStore(this.job);

  final BattleLiveJobState job;
  final List<BattleLiveSourceRecord> publicRecords = [];
  final Set<String> fingerprints = {};
  var nextSequence = 0;
  var sourceTruncated = false;
  BattleLiveSourceCheckpoint? checkpoint;

  @override
  Future<BattleLiveJobState?> getJob({
    required String userId,
    required String jobId,
  }) async {
    return userId == job.userId && jobId == job.id ? job : null;
  }

  @override
  Future<BattleLiveAppendResult> append({
    required String userId,
    required String jobId,
    required List<BattleLiveRecordWrite> records,
    required bool sourceTruncated,
  }) async {
    if (userId != job.userId || jobId != job.id) {
      throw const BattleLiveStoreException('job_not_found');
    }
    var appended = 0;
    for (final record in records) {
      if (!fingerprints.add(record.fingerprint)) continue;
      final sequence = nextSequence++;
      this.sourceTruncated = this.sourceTruncated || sourceTruncated;
      if (record.sourceKind == 'xmage_checkpoint') {
        checkpoint = BattleLiveSourceCheckpoint(
          sourceProcessId: record.sourceProcessId!,
          afterSequence: record.sourceSequence!,
        );
        continue;
      }
      if (!record.publicVisible) continue;
      publicRecords.add(switch (record.kind) {
        BattleLiveRecordKind.event => BattleLiveSourceRecord.event(
          sequence: sequence,
          recordId: 'memory-$sequence',
          event: record.payload,
          contentTruncated: record.contentTruncated,
        ),
        BattleLiveRecordKind.snapshot => BattleLiveSourceRecord.snapshot(
          sequence: sequence,
          recordId: 'memory-$sequence',
          snapshot: record.payload,
          contentTruncated: record.contentTruncated,
        ),
      });
      appended += 1;
    }
    return BattleLiveAppendResult(appended: appended, limitReached: false);
  }

  @override
  Future<BattleLiveStoredRecords> list({
    required String userId,
    required String jobId,
  }) async {
    if (userId != job.userId || jobId != job.id) {
      throw const BattleLiveStoreException('job_not_found');
    }
    return BattleLiveStoredRecords(
      records: publicRecords,
      sourceTruncated: sourceTruncated,
    );
  }

  @override
  Future<BattleLiveSourceCheckpoint?> sourceCheckpoint({
    required String userId,
    required String jobId,
  }) async {
    if (userId != job.userId || jobId != job.id) return null;
    return checkpoint;
  }
}

class _CallbackSource implements BattleLiveSource {
  _CallbackSource(this.callback);

  final BattleLiveSourceSnapshot Function(String, int, int) callback;
  final List<int> afters = [];
  var closed = false;

  @override
  Future<BattleLiveSourceSnapshot> read(
    String requestId, {
    int afterSequence = -1,
    int limit = battleLiveSourcePageLimit,
  }) async {
    afters.add(afterSequence);
    return callback(requestId, afterSequence, limit);
  }

  @override
  void close() {
    closed = true;
  }
}

class _ThrowingSource implements BattleLiveSource {
  _ThrowingSource(this.error);

  final BattleLiveSourceException error;
  var calls = 0;

  @override
  Future<BattleLiveSourceSnapshot> read(
    String requestId, {
    int afterSequence = -1,
    int limit = battleLiveSourcePageLimit,
  }) async {
    calls += 1;
    throw error;
  }

  @override
  void close() {}
}

BattleLiveSourceSnapshot _snapshot({
  required List<BattleLiveSourceRecord> records,
  int after = -1,
  required int nextAfter,
  bool hasMore = false,
  String processId = 'process-1',
}) {
  return BattleLiveSourceSnapshot(
    requestId: 'battle-job-$_jobId',
    status: BattleLiveStatus.running,
    terminal: false,
    sourceTruncated: false,
    sourceProcessId: processId,
    afterSequence: after,
    nextAfterSequence: nextAfter,
    hasMore: hasMore,
    totalRecordCount: records.length,
    records: records,
  );
}

BattleLiveSourceRecord _event(int sequence, String cardName) {
  return BattleLiveSourceRecord.event(
    sequence: sequence,
    recordId: 'source-event-$sequence',
    event: {
      'event_type': 'stack_entry',
      'turn': sequence + 1,
      'card_name': cardName,
    },
  );
}

BattleLiveJobState _runningJob({
  BattleJobStatus status = BattleJobStatus.running,
  String requestedEngine = 'xmage',
  String engineLane = 'xmage',
  String? engine,
  String? replayId,
  Object? replayGameLog,
}) {
  return BattleLiveJobState(
    id: _jobId,
    userId: _userId,
    status: status,
    requestId: 'battle-job-$_jobId',
    requestedEngine: requestedEngine,
    engineLane: engineLane,
    engine: engine ?? (status.isTerminal ? 'xmage' : null),
    replayId: replayId,
    replayGameLog: replayGameLog,
  );
}

const _jobId = '11111111-1111-4111-8111-111111111111';
const _userId = '22222222-2222-4222-8222-222222222222';
const _otherUserId = '33333333-3333-4333-8333-333333333333';
const _replayId = '44444444-4444-4444-8444-444444444444';
