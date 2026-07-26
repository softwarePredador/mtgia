import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/battle/battle_replay_annotation_service.dart';

const _deckHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('BattleReplayAnnotationService', () {
    test(
      'creates an owner-scoped reflection against a recorded revision',
      () async {
        final pool = _ScriptedPool([
          _scopeResult(),
          _annotationResult(
            payload: const {
              'stance': 'would_change',
              'reason': 'Seguraria a resposta.',
              'capture_contract': 'before_next_event_reveal',
            },
            eventRef: 'event:1',
            kind: 'would_do_differently',
          ),
        ]);

        final outcome = await BattleReplayAnnotationService(pool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'reflection-1',
          body: const {
            'kind': 'would_do_differently',
            'event_ref': 'event:1',
            'payload': {
              'stance': 'would_change',
              'reason': 'Seguraria a resposta.',
            },
          },
        );

        expect(outcome.created, isTrue);
        expect(outcome.annotation['kind'], 'would_do_differently');
        expect(
          outcome.annotation['subject_deck_revision'],
          'external_battle_deck_hash_v1:$_deckHash',
        );
        expect(
          outcome.annotation['payload'],
          containsPair('capture_contract', 'before_next_event_reveal'),
        );
        final insertParameters = pool.parameters[1] as Map<String, dynamic>;
        expect(insertParameters['subjectDeckHash'], _deckHash);
        expect(
          insertParameters['subjectDeckRevision'],
          'external_battle_deck_hash_v1:$_deckHash',
        );
        expect(
          jsonDecode(insertParameters['payload'] as String),
          containsPair('capture_contract', 'before_next_event_reveal'),
        );
        expect(
          insertParameters['requestFingerprint'],
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
      },
    );

    test('records keep or mulligan before heuristic reveal', () async {
      final pool = _ScriptedPool([
        _scopeResult(),
        _annotationResult(
          payload: const {
            'choice': 'mulligan',
            'hand_size': 7,
            'mulligan_number': 0,
            'capture_contract': 'human_choice_before_heuristic_reveal',
            'claims_correct_answer': false,
          },
          snapshotRef: 'snapshot:0',
          kind: 'mulligan_decision',
        ),
      ]);

      final outcome = await BattleReplayAnnotationService(pool).create(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'replay-1',
        idempotencyKey: 'mulligan-1',
        body: const {
          'kind': 'mulligan_decision',
          'snapshot_ref': 'snapshot:0',
          'payload': {
            'choice': 'mulligan',
            'hand_size': 7,
            'mulligan_number': 0,
          },
        },
      );

      expect(
        outcome.annotation['payload'],
        containsPair(
          'capture_contract',
          'human_choice_before_heuristic_reveal',
        ),
      );
      expect(
        outcome.annotation['payload'],
        containsPair('claims_correct_answer', false),
      );
    });

    test(
      'same idempotency key and fingerprint returns the original row',
      () async {
        final firstPool = _ScriptedPool([
          _scopeResult(),
          _annotationResult(
            payload: const {'helpful': true, 'surface': 'post_battle_report'},
            kind: 'helpful_feedback',
          ),
        ]);
        final request = const {
          'kind': 'helpful_feedback',
          'payload': {'helpful': true, 'surface': 'post_battle_report'},
        };
        await BattleReplayAnnotationService(firstPool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'helpful-1',
          body: request,
        );
        final fingerprint =
            (firstPool.parameters[1]
                    as Map<String, dynamic>)['requestFingerprint']
                as String;
        final retryPool = _ScriptedPool([
          _scopeResult(),
          _emptyResult(),
          _annotationResult(
            payload: const {'helpful': true, 'surface': 'post_battle_report'},
            kind: 'helpful_feedback',
            requestFingerprint: fingerprint,
          ),
        ]);

        final retry = await BattleReplayAnnotationService(retryPool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'helpful-1',
          body: request,
        );

        expect(retry.created, isFalse);
        expect(retry.annotation['id'], 'annotation-1');
      },
    );

    test(
      'reusing an idempotency key for another request is a conflict',
      () async {
        final pool = _ScriptedPool([
          _scopeResult(),
          _emptyResult(),
          _annotationResult(
            payload: const {'helpful': true, 'surface': 'post_battle_report'},
            kind: 'helpful_feedback',
            requestFingerprint: 'f' * 64,
          ),
        ]);

        expect(
          () => BattleReplayAnnotationService(pool).create(
            userId: 'user-1',
            deckId: 'deck-1',
            replayId: 'replay-1',
            idempotencyKey: 'helpful-1',
            body: const {
              'kind': 'helpful_feedback',
              'payload': {'helpful': false, 'surface': 'post_battle_report'},
            },
          ),
          throwsA(isA<BattleReplayAnnotationIdempotencyConflictException>()),
        );
      },
    );

    test('rejects invalid bodies and out-of-range replay references', () async {
      final noQueryPool = _ScriptedPool(const []);
      await expectLater(
        () => BattleReplayAnnotationService(noQueryPool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'bad key',
          body: const {'kind': 'bookmark', 'payload': {}},
        ),
        throwsA(isA<BattleReplayAnnotationValidationException>()),
      );
      expect(noQueryPool.calls, 0);

      final boundedPool = _ScriptedPool([_scopeResult()]);
      await expectLater(
        () => BattleReplayAnnotationService(boundedPool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'report-1',
          body: const {
            'kind': 'event_report',
            'event_ref': 'event:2',
            'payload': {'reason_code': 'incorrect_event'},
          },
        ),
        throwsA(isA<BattleReplayAnnotationValidationException>()),
      );
      expect(boundedPool.calls, 1);

      final unrelatedRefPool = _ScriptedPool(const []);
      await expectLater(
        () => BattleReplayAnnotationService(unrelatedRefPool).create(
          userId: 'user-1',
          deckId: 'deck-1',
          replayId: 'replay-1',
          idempotencyKey: 'helpful-ref-1',
          body: const {
            'kind': 'helpful_feedback',
            'event_ref': 'event:0',
            'payload': {'helpful': true, 'surface': 'post_battle_report'},
          },
        ),
        throwsA(isA<BattleReplayAnnotationValidationException>()),
      );
      expect(unrelatedRefPool.calls, 0);
    });

    test('list and delete keep annotation ownership and deck scope', () async {
      final pool = _ScriptedPool([
        _annotationResult(
          payload: const {'label': 'Combo'},
          eventRef: 'event:0',
          kind: 'bookmark',
        ),
        _result(
          columns: const ['id'],
          rows: const [
            ['annotation-1'],
          ],
        ),
      ]);
      final service = BattleReplayAnnotationService(pool);

      final annotations = await service.list(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'replay-1',
      );
      final deleted = await service.delete(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'replay-1',
        annotationId: 'annotation-1',
      );

      expect(annotations, hasLength(1));
      expect(deleted, isTrue);
    });

    test('source never mutates an immutable replay', () {
      final source =
          File(
            'lib/battle/battle_replay_annotation_service.dart',
          ).readAsStringSync();

      expect(source, isNot(contains('UPDATE battle_simulations')));
      expect(source, isNot(contains('DELETE FROM battle_simulations')));
      expect(source, contains('requested.user_id = CAST(@userId AS uuid)'));
      expect(source, contains('annotation.user_id = CAST(@userId AS uuid)'));
      expect(source, contains('subject_deck_id = CAST(@deckId AS uuid)'));
      expect(
        source,
        isNot(contains('attempt.user_id = CAST(@userId AS uuid)')),
      );
      expect(source, contains("'immutable_replay': true"));
    });
  });
}

Result _scopeResult() => _result(
  columns: const [
    'attempt_id',
    'subject_deck_key',
    'deck_hash_schema',
    'subject_deck_hash',
    'game_log',
  ],
  rows: const [
    [
      'attempt-1',
      'deck_a',
      'external_battle_deck_hash_v1',
      _deckHash,
      {
        'events': [
          {'type': 'draw'},
          {'type': 'cast'},
        ],
        'visual_snapshots': [
          {'turn': 0, 'phase': 'opening_hand'},
        ],
      },
    ],
  ],
);

Result _annotationResult({
  required Map<String, dynamic> payload,
  required String kind,
  String? eventRef,
  String? snapshotRef,
  String? requestFingerprint,
}) => _result(
  columns: [
    'id',
    'replay_id',
    'attempt_id',
    'subject_deck_id',
    'subject_deck_key',
    'deck_hash_schema',
    'subject_deck_hash',
    'subject_deck_revision',
    'event_ref',
    'snapshot_ref',
    'kind',
    'payload',
    if (requestFingerprint != null) 'request_fingerprint',
    'created_at',
    'updated_at',
  ],
  rows: [
    [
      'annotation-1',
      'replay-1',
      'attempt-1',
      'deck-1',
      'deck_a',
      'external_battle_deck_hash_v1',
      _deckHash,
      'external_battle_deck_hash_v1:$_deckHash',
      eventRef,
      snapshotRef,
      kind,
      payload,
      if (requestFingerprint != null) requestFingerprint,
      DateTime.utc(2026, 7, 26, 12),
      DateTime.utc(2026, 7, 26, 12),
    ],
  ],
);

Result _emptyResult() => _result(columns: const [], rows: const []);

class _ScriptedPool implements Pool {
  _ScriptedPool(this._results);

  final List<Result> _results;
  final List<String> queries = [];
  final List<Object?> parameters = [];
  int calls = 0;

  Future<Result> _execute(Object query, Object? parameters) async {
    queries.add(query.toString());
    this.parameters.add(parameters);
    if (calls >= _results.length) {
      throw StateError('Unexpected query #${calls + 1}: $query');
    }
    return _results[calls++];
  }

  @override
  bool get isOpen => true;

  @override
  Future<void> get closed async {}

  @override
  Future<void> close({bool force = false}) async {}

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) => _execute(query, parameters);

  @override
  Future<Statement> prepare(Object query) =>
      throw UnimplementedError('prepare is not used by this test fake');

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    dynamic locality,
  }) => fn(this);

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    dynamic locality,
  }) => fn(_ScriptedTxSession(this));

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) =>
      throw UnimplementedError('withConnection is not used by this test fake');
}

class _ScriptedTxSession implements TxSession {
  const _ScriptedTxSession(this.pool);

  final _ScriptedPool pool;

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) => pool._execute(query, parameters);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Result _result({
  required List<String> columns,
  required List<List<Object?>> rows,
}) {
  final schema = ResultSchema([
    for (final column in columns)
      ResultSchemaColumn(
        typeOid: 0,
        type: Type.unspecified,
        columnName: column,
      ),
  ]);
  return Result(
    rows: [for (final row in rows) ResultRow(values: row, schema: schema)],
    affectedRows: rows.length,
    schema: schema,
  );
}
