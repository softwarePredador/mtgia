import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/battle/battle_simulation_persistence_service.dart';

void main() {
  group('BattleSimulationPersistenceService', () {
    test('canonical winner helper never returns an unrelated deck', () {
      expect(
        canonicalBattleWinnerDeckId(
          result: const {
            'winner_deck_id': 'deck-unrelated',
            'winner': 'Deck B',
          },
          deckAId: 'deck-a',
          deckBId: 'deck-b',
        ),
        'deck-b',
      );
      expect(
        canonicalBattleWinnerDeckId(
          result: const {'winner_deck_id': 'deck-unrelated'},
          deckAId: 'deck-a',
          deckBId: 'deck-b',
        ),
        isNull,
      );
    });

    test('returns the durable replay id after a successful insert', () async {
      final pool = _ScriptedPool([
        _result(
          columns: const ['exists'],
          rows: const [
            [true],
          ],
        ),
        _result(
          columns: const ['column_name'],
          rows: const [
            ['simulation_type'],
            ['metrics'],
            ['winner_deck_id'],
            ['turns_played'],
          ],
        ),
        _result(
          columns: const ['id'],
          rows: const [
            ['replay-123'],
          ],
        ),
      ]);

      final outcome = await BattleSimulationPersistenceService(pool).save(
        deckAId: 'deck-a',
        deckBId: 'deck-b',
        type: 'battle',
        result: const {
          'type': 'engine_override',
          'winner_deck_id': 'deck-b',
          'winner': 'Deck A',
          'turns': 8,
          'engine': 'xmage',
          'game_log': [
            {'turn': 1, 'action': 'draw'},
          ],
        },
      );

      expect(outcome.isSaved, isTrue);
      expect(outcome.replayId, 'replay-123');
      expect(outcome.toJson(), {
        'status': 'saved',
        'required': true,
        'replay_id': 'replay-123',
      });
      final parameters = pool.parameters.last as Map<String, dynamic>;
      expect(parameters['winnerDeckId'], 'deck-b');
      expect(parameters['simulationType'], 'battle');
      final gameLog =
          jsonDecode(parameters['gameLog'] as String) as Map<String, dynamic>;
      expect(gameLog['type'], 'battle');
      expect(gameLog['winner_deck_id'], 'deck-b');
      expect(gameLog.toString(), isNot(contains('engine_override')));
    });

    test('never persists a winner outside the simulated decks', () async {
      final pool = _ScriptedPool([
        _result(
          columns: const ['exists'],
          rows: const [
            [true],
          ],
        ),
        _result(
          columns: const ['column_name'],
          rows: const [
            ['simulation_type'],
            ['metrics'],
            ['winner_deck_id'],
            ['turns_played'],
          ],
        ),
        _result(
          columns: const ['id'],
          rows: const [
            ['replay-guarded'],
          ],
        ),
      ]);

      final outcome = await BattleSimulationPersistenceService(pool).save(
        deckAId: 'deck-a',
        deckBId: 'deck-b',
        type: 'battle',
        result: const {
          'winner_deck_id': 'deck-owned-by-someone-else',
          'winner': 'Deck A',
          'turns': 6,
        },
      );

      expect(outcome.isSaved, isTrue);
      final parameters = pool.parameters.last as Map<String, dynamic>;
      expect(parameters['winnerDeckId'], 'deck-a');
      final gameLog =
          jsonDecode(parameters['gameLog'] as String) as Map<String, dynamic>;
      final metrics =
          jsonDecode(parameters['metrics'] as String) as Map<String, dynamic>;
      expect(gameLog['winner_deck_id'], 'deck-a');
      expect(metrics['winner_deck_id'], 'deck-a');
      expect(
        '$gameLog $metrics',
        isNot(contains('deck-owned-by-someone-else')),
      );
    });

    test('fails closed when the replay table is unavailable', () async {
      final pool = _ScriptedPool([
        _result(
          columns: const ['exists'],
          rows: const [
            [false],
          ],
        ),
      ]);

      final outcome = await BattleSimulationPersistenceService(
        pool,
      ).save(deckAId: 'deck-a', type: 'goldfish', result: const {});

      expect(outcome.isSaved, isFalse);
      expect(outcome.errorCode, 'battle_simulations_unavailable');
      expect(pool.calls, 1);
    });

    test('fails closed when the insert raises an error', () async {
      final pool = _ScriptedPool([
        _result(
          columns: const ['exists'],
          rows: const [
            [true],
          ],
        ),
        _result(columns: const ['column_name'], rows: const []),
      ], failAtCall: 2);

      final outcome = await BattleSimulationPersistenceService(pool).save(
        deckAId: 'deck-a',
        deckBId: 'deck-b',
        type: 'battle',
        result: const {},
      );

      expect(outcome.isSaved, isFalse);
      expect(outcome.errorCode, 'simulation_persistence_failed');
    });
  });
}

class _ScriptedPool implements Pool {
  _ScriptedPool(this._results, {this.failAtCall});

  final List<Result> _results;
  final int? failAtCall;
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
    throw UnimplementedError('prepare is not used by this test fake');
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    final callIndex = calls++;
    this.parameters.add(parameters);
    if (failAtCall == callIndex) {
      throw StateError('scripted persistence failure');
    }
    if (callIndex >= _results.length) {
      throw StateError('Unexpected query #${callIndex + 1}: $query');
    }
    return _results[callIndex];
  }

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    dynamic locality,
  }) {
    return fn(this);
  }

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    dynamic locality,
  }) {
    throw UnimplementedError('runTx is not used by this test fake');
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) {
    throw UnimplementedError('withConnection is not used by this test fake');
  }
}

Result _result({
  List<String> columns = const [],
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
