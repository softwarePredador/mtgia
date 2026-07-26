import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/battle/battle_simulation_attempt_service.dart';

const _deckAHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _deckBHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  test('closed outcome vocabulary is complete and versioned', () {
    expect(
      BattleSimulationAttemptOutcome.values.map((value) => value.value).toSet(),
      battleSimulationAttemptOutcomes,
    );
    expect(battleSimulationAttemptSchema, 'battle_simulation_attempt_v1');
  });

  test('starts only through an owner-scoped deck insert', () async {
    final pool = _ScriptedPool([
      _result(
        columns: const ['id'],
        rows: const [
          ['attempt-1'],
        ],
      ),
    ]);

    final start = await BattleSimulationAttemptService(pool).start(
      userId: 'user-1',
      deckAId: 'deck-a',
      deckBId: 'deck-b',
      simulationType: 'battle',
      testObjective: 'focus_cards',
      requestId: 'request-1',
      deckAHash: _deckAHash,
      deckBHash: _deckBHash,
      deckHashSchema: 'external_battle_deck_hash_v1',
      timeoutMs: 30000,
      engine: 'xmage',
    );

    expect(start.isStarted, isTrue);
    expect(start.handle!.id, 'attempt-1');
    final source =
        File(
          'lib/battle/battle_simulation_attempt_service.dart',
        ).readAsStringSync();
    expect(source, contains('owner_deck.user_id = CAST(@userId AS uuid)'));
    expect(source, contains('opponent_deck.user_id = CAST(@userId AS uuid)'));
    expect(source, contains('opponent_deck.is_public = TRUE'));
    final parameters = pool.parameters.single as Map<String, dynamic>;
    expect(parameters['deckAHash'], _deckAHash);
    expect(parameters['deckBHash'], _deckBHash);
    expect(parameters['testObjective'], 'focus_cards');
    expect(parameters['timeoutMs'], 30000);
  });

  test(
    'finishes owner-scoped attempt with replay and queryable identity',
    () async {
      final pool = _ScriptedPool([
        _result(
          columns: const ['id'],
          rows: const [
            ['attempt-1'],
          ],
        ),
      ]);
      final service = BattleSimulationAttemptService(pool);

      final finish = await service.finish(
        attempt: const BattleSimulationAttemptHandle(
          id: 'attempt-1',
          userId: 'user-1',
        ),
        outcome: BattleSimulationAttemptOutcome.censored,
        replayId: 'replay-1',
        reason: 'max_turns',
        result: const {
          'status': 'censored',
          'engine': 'xmage',
          'engine_version': '1.4.60',
          'engine_commit': 'commit',
          'sidecar_build_identity': 'xmage-sidecar-v2@commit',
          'sidecar_process_id': 'process-1',
          'request_schema_version': 'external_battle_request_v2',
          'request_hash':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'metrics': {'events_truncated': true},
        },
        provenance: const {
          'api_key': 'must-not-be-written',
          'fallback_reason': 'none',
        },
      );

      expect(finish.isFinished, isTrue);
      final source =
          File(
            'lib/battle/battle_simulation_attempt_service.dart',
          ).readAsStringSync();
      expect(source, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(source, contains('AND outcome IS NULL'));
      final parameters = pool.parameters.single as Map<String, dynamic>;
      expect(parameters['outcome'], 'censored');
      expect(parameters['replayId'], 'replay-1');
      expect(parameters['engine'], 'xmage');
      expect(parameters['engineProcessId'], 'process-1');
      expect(parameters['eventsTruncated'], isTrue);
      final provenance =
          jsonDecode(parameters['provenance'] as String)
              as Map<String, dynamic>;
      expect(provenance, isNot(contains('api_key')));
      expect(provenance['fallback_reason'], 'none');
    },
  );

  test('fails closed when owner-scoped start inserts no row', () async {
    final pool = _ScriptedPool([
      _result(columns: const ['id'], rows: const []),
    ]);

    final start = await BattleSimulationAttemptService(pool).start(
      userId: 'user-1',
      deckAId: 'deck-a',
      simulationType: 'goldfish',
      requestId: 'request-1',
      deckAHash: _deckAHash,
      deckHashSchema: 'external_battle_deck_hash_v1',
      timeoutMs: 30000,
    );

    expect(start.isStarted, isFalse);
    expect(start.errorCode, 'battle_attempt_owner_scope_failed');
  });
}

class _ScriptedPool implements Pool {
  _ScriptedPool(this._results);

  final List<Result> _results;
  final List<String> queries = [];
  final List<Object?> parameters = [];
  int calls = 0;

  @override
  bool get isOpen => true;

  @override
  Future<void> get closed async {}

  @override
  Future<void> close({bool force = false}) async {}

  @override
  Future<Statement> prepare(Object query) {
    throw UnimplementedError();
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    queries.add(query.toString());
    this.parameters.add(parameters);
    return _results[calls++];
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) {
    throw UnimplementedError();
  }
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
