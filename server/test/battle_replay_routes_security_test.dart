import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/battle-replays/[replayId]/index.dart'
    as replay_detail_route;
import '../routes/decks/[id]/battle-replays/index.dart' as replay_list_route;
import '../routes/decks/_middleware.dart' as decks_middleware;

const _deckAId = '11111111-1111-4111-8111-111111111111';
const _deckBId = '22222222-2222-4222-8222-222222222222';
const _replayId = '33333333-3333-4333-8333-333333333333';
const _otherReplayId = '44444444-4444-4444-8444-444444444444';
const _userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _secretError =
    'password=prod-secret SELECT * FROM users WHERE token=internal-token';

void main() {
  group('battle replay authentication and identifiers', () {
    test('parent deck middleware rejects unauthenticated requests', () async {
      var handlerCalled = false;
      final handler = decks_middleware.middleware((_) async {
        handlerCalled = true;
        return Response();
      });

      final response = await handler(
        _context('/decks/$_deckAId/battle-replays'),
      );
      final body = await _jsonBody(response);

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(handlerCalled, isFalse);
      expect(body['error'], 'Token de autenticação não fornecido');
      expect(body, isNot(contains('details')));
    });

    test('invalid deck id is a not-found without a database lookup', () async {
      final pool = _ThrowingPool();

      final response = await replay_list_route.onRequest(
        _context('/decks/not-a-uuid/battle-replays', pool: pool),
        'not-a-uuid',
      );

      expect(response.statusCode, HttpStatus.notFound);
      expect(await _jsonBody(response), {'error': 'Deck nao encontrado.'});
      expect(pool.calls, 0);
    });

    test(
      'invalid replay id is a not-found without a database lookup',
      () async {
        final pool = _ThrowingPool();

        final response = await replay_detail_route.onRequest(
          _context('/decks/$_deckAId/battle-replays/not-a-uuid', pool: pool),
          _deckAId,
          'not-a-uuid',
        );

        expect(response.statusCode, HttpStatus.notFound);
        expect(await _jsonBody(response), {'error': 'Replay nao encontrado.'});
        expect(pool.calls, 0);
      },
    );
  });

  group('battle replay authorization', () {
    test('public visibility never replaces replay ownership', () async {
      final pool = _ScriptedPool([_result(rows: const [])]);

      final response = await replay_list_route.onRequest(
        _context('/decks/$_deckBId/battle-replays', pool: pool),
        _deckBId,
      );

      expect(response.statusCode, HttpStatus.notFound);
      expect(await _jsonBody(response), {'error': 'Deck nao encontrado.'});
      expect(pool.queries, hasLength(1));
      expect(pool.parameters.single, {'deckId': _deckBId, 'userId': _userId});
    });

    test('missing and inaccessible replay ids are indistinguishable', () async {
      Future<Response> request(String replayId) {
        final pool = _ScriptedPool([
          _result(
            rows: const [
              [1],
            ],
          ),
          _result(
            rows: const [
              [true],
            ],
          ),
          _result(rows: const []),
        ]);
        return replay_detail_route.onRequest(
          _context('/decks/$_deckAId/battle-replays/$replayId', pool: pool),
          _deckAId,
          replayId,
        );
      }

      final missing = await request(_replayId);
      final inaccessible = await request(_otherReplayId);

      expect(missing.statusCode, HttpStatus.notFound);
      expect(inaccessible.statusCode, HttpStatus.notFound);
      expect(await missing.body(), await inaccessible.body());
      expect(await _jsonBody(inaccessible), {
        'error': 'Replay nao encontrado.',
      });
    });

    test(
      'owner of deck B cannot read a replay initiated by another owner',
      () async {
        final listPool = _ScriptedPool([
          _result(
            rows: const [
              [1],
            ],
          ),
          _result(
            rows: const [
              [true],
            ],
          ),
          _result(rows: const []),
        ]);
        final detailPool = _ScriptedPool([
          _result(
            rows: const [
              [1],
            ],
          ),
          _result(
            rows: const [
              [true],
            ],
          ),
          _result(rows: const []),
        ]);

        final listResponse = await replay_list_route.onRequest(
          _context('/decks/$_deckBId/battle-replays', pool: listPool),
          _deckBId,
        );
        final detailResponse = await replay_detail_route.onRequest(
          _context(
            '/decks/$_deckBId/battle-replays/$_replayId',
            pool: detailPool,
          ),
          _deckBId,
          _replayId,
        );

        expect(listResponse.statusCode, HttpStatus.ok);
        expect((await _jsonBody(listResponse))['data'], isEmpty);
        expect(detailResponse.statusCode, HttpStatus.notFound);
        expect(await _jsonBody(detailResponse), {
          'error': 'Replay nao encontrado.',
        });
      },
    );

    test('list and detail expose the same persisted replay id', () async {
      final createdAt = DateTime.utc(2026, 7, 22, 12);
      final listPool = _ScriptedPool([
        _result(
          rows: const [
            [1],
          ],
        ),
        _result(
          rows: const [
            [true],
          ],
        ),
        _result(
          columns: const [
            'id',
            'deck_a_id',
            'deck_b_id',
            'simulation_type',
            'winner_deck_id',
            'turns_played',
            'metrics',
            'created_at',
            'deck_a_name',
            'deck_b_name',
            'event_count',
            'game_log_type',
            'winner_label',
          ],
          rows: [
            [
              _replayId,
              _deckAId,
              _deckBId,
              'battle',
              _deckAId,
              7,
              const {'engine': 'xmage'},
              createdAt,
              'Deck A',
              'Deck B',
              3,
              'battle',
              'Deck A',
            ],
          ],
        ),
      ]);
      final detailPool = _ScriptedPool([
        _result(
          rows: const [
            [1],
          ],
        ),
        _result(
          rows: const [
            [true],
          ],
        ),
        _result(
          columns: const [
            'id',
            'deck_a_id',
            'deck_b_id',
            'simulation_type',
            'winner_deck_id',
            'turns_played',
            'game_log',
            'metrics',
            'created_at',
            'deck_a_name',
            'deck_b_name',
          ],
          rows: [
            [
              _replayId,
              _deckAId,
              _deckBId,
              'battle',
              _deckAId,
              7,
              const {'type': 'battle', 'engine': 'xmage', 'game_log': []},
              const {'engine': 'xmage'},
              createdAt,
              'Deck A',
              'Deck B',
            ],
          ],
        ),
      ]);

      final listResponse = await replay_list_route.onRequest(
        _context('/decks/$_deckAId/battle-replays', pool: listPool),
        _deckAId,
      );
      final detailResponse = await replay_detail_route.onRequest(
        _context(
          '/decks/$_deckAId/battle-replays/$_replayId',
          pool: detailPool,
        ),
        _deckAId,
        _replayId,
      );
      final listBody = await _jsonBody(listResponse);
      final detailBody = await _jsonBody(detailResponse);

      expect(listResponse.statusCode, HttpStatus.ok);
      expect(detailResponse.statusCode, HttpStatus.ok);
      expect(((listBody['data'] as List).single as Map)['id'], _replayId);
      expect((detailBody['replay'] as Map)['id'], _replayId);
    });
  });

  group('battle replay error responses', () {
    test('list route does not expose database exception details', () async {
      final response = await replay_list_route.onRequest(
        _context('/decks/$_deckAId/battle-replays'),
        _deckAId,
      );

      await _expectSanitized(response, 'Falha ao carregar replays de battle');
    });

    test('detail route does not expose database exception details', () async {
      final response = await replay_detail_route.onRequest(
        _context('/decks/$_deckAId/battle-replays/$_replayId'),
        _deckAId,
        _replayId,
      );

      await _expectSanitized(response, 'Falha ao carregar replay de battle');
    });

    test('corrupt persisted payload returns a sanitized 500', () async {
      final pool = _ScriptedPool([
        _result(
          rows: const [
            [1],
          ],
        ),
        _result(
          rows: const [
            [true],
          ],
        ),
        _result(
          columns: const [
            'id',
            'deck_a_id',
            'deck_b_id',
            'simulation_type',
            'winner_deck_id',
            'turns_played',
            'game_log',
            'metrics',
            'created_at',
            'deck_a_name',
            'deck_b_name',
          ],
          rows: [
            [
              _replayId,
              _deckAId,
              _deckBId,
              'battle',
              null,
              null,
              _secretError,
              const {},
              DateTime.utc(2026, 7, 22, 12),
              'Deck A',
              'Deck B',
            ],
          ],
        ),
      ]);

      final response = await replay_detail_route.onRequest(
        _context('/decks/$_deckAId/battle-replays/$_replayId', pool: pool),
        _deckAId,
        _replayId,
      );

      await _expectSanitized(response, 'Falha ao carregar replay de battle');
    });
  });
}

Future<Map<String, dynamic>> _jsonBody(Response response) async =>
    jsonDecode(await response.body()) as Map<String, dynamic>;

Future<void> _expectSanitized(Response response, String expectedError) async {
  final body = await _jsonBody(response);

  expect(response.statusCode, HttpStatus.internalServerError);
  expect(body, {'error': expectedError});
  expect(body, isNot(contains('details')));
  expect(body.toString(), isNot(contains('prod-secret')));
  expect(body.toString(), isNot(contains('SELECT * FROM users')));
  expect(body.toString(), isNot(contains('internal-token')));
}

RequestContext _context(String path, {Pool? pool, String userId = _userId}) =>
    _BattleReplayRequestContext(
      Request(
        HttpMethod.get.name.toUpperCase(),
        Uri.parse('http://localhost$path'),
      ),
      pool ?? _ThrowingPool(),
      userId,
    );

class _BattleReplayRequestContext implements RequestContext {
  const _BattleReplayRequestContext(this.request, this.pool, this.userId);

  @override
  final Request request;
  final Pool pool;
  final String userId;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return userId as T;
    throw StateError('No battle replay test provider for $T');
  }
}

class _ThrowingPool implements Pool {
  int calls = 0;

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
  }) {
    calls++;
    return Future<Result>.error(StateError(_secretError));
  }

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
  }) => throw UnimplementedError('runTx is not used by this test fake');

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) =>
      throw UnimplementedError('withConnection is not used by this test fake');
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
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    queries.add(query.toString());
    this.parameters.add(parameters);
    if (calls >= _results.length) {
      throw StateError('Unexpected query #${calls + 1}: $query');
    }
    return _results[calls++];
  }

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
  }) => throw UnimplementedError('runTx is not used by this test fake');

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) =>
      throw UnimplementedError('withConnection is not used by this test fake');
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
