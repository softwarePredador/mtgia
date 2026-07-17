import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/battle-replays/[replayId]/index.dart'
    as replay_detail_route;
import '../routes/decks/[id]/battle-replays/index.dart' as replay_list_route;

const _secretError =
    'password=prod-secret SELECT * FROM users WHERE token=internal-token';

void main() {
  group('battle replay route error responses', () {
    test('list route does not expose database exception details', () async {
      final response = await replay_list_route.onRequest(
        _context('/decks/deck-1/battle-replays'),
        'deck-1',
      );

      await _expectSanitized(response, 'Falha ao carregar replays de battle');
    });

    test('detail route does not expose database exception details', () async {
      final response = await replay_detail_route.onRequest(
        _context('/decks/deck-1/battle-replays/replay-1'),
        'deck-1',
        'replay-1',
      );

      await _expectSanitized(response, 'Falha ao carregar replay de battle');
    });
  });
}

Future<void> _expectSanitized(Response response, String expectedError) async {
  final body = jsonDecode(await response.body()) as Map<String, dynamic>;

  expect(response.statusCode, HttpStatus.internalServerError);
  expect(body, {'error': expectedError});
  expect(body, isNot(contains('details')));
  expect(body.toString(), isNot(contains('prod-secret')));
  expect(body.toString(), isNot(contains('SELECT * FROM users')));
  expect(body.toString(), isNot(contains('internal-token')));
}

RequestContext _context(String path) => _BattleReplayRequestContext(
  Request(
    HttpMethod.get.name.toUpperCase(),
    Uri.parse('http://localhost$path'),
  ),
  _ThrowingPool(),
);

class _BattleReplayRequestContext implements RequestContext {
  const _BattleReplayRequestContext(this.request, this.pool);

  @override
  final Request request;
  final Pool pool;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return 'user-1' as T;
    throw StateError('No battle replay test provider for $T');
  }
}

class _ThrowingPool implements Pool {
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
  }) => Future<Result>.error(StateError(_secretError));

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
