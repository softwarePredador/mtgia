import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/battle-replays/[replayId]/annotations/[annotationId].dart'
    as annotation_item_route;
import '../routes/decks/[id]/battle-replays/[replayId]/annotations/index.dart'
    as annotations_route;

const _deckId = '11111111-1111-4111-8111-111111111111';
const _replayId = '22222222-2222-4222-8222-222222222222';
const _otherReplayId = '33333333-3333-4333-8333-333333333333';
const _annotationId = '44444444-4444-4444-8444-444444444444';
const _otherAnnotationId = '55555555-5555-4555-8555-555555555555';
const _userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('battle replay annotation routes', () {
    test('invalid UUIDs are rejected before any database query', () async {
      final pool = _ThrowingPool();

      final collection = await annotations_route.onRequest(
        _context(HttpMethod.get, '/decks/not-a-uuid/annotations', pool: pool),
        'not-a-uuid',
        _replayId,
      );
      final item = await annotation_item_route.onRequest(
        _context(
          HttpMethod.delete,
          '/decks/$_deckId/annotations/not-a-uuid',
          pool: pool,
        ),
        _deckId,
        _replayId,
        'not-a-uuid',
      );

      expect(collection.statusCode, HttpStatus.notFound);
      expect(item.statusCode, HttpStatus.notFound);
      expect(pool.calls, 0);
    });

    test(
      'oversized bodies fail before service or database execution',
      () async {
        final pool = _ThrowingPool();
        final response = await annotations_route.onRequest(
          _context(
            HttpMethod.post,
            '/decks/$_deckId/battle-replays/$_replayId/annotations',
            pool: pool,
            body: 'x' * (16 * 1024 + 1),
          ),
          _deckId,
          _replayId,
        );

        expect(response.statusCode, HttpStatus.requestEntityTooLarge);
        expect(
          await _jsonBody(response),
          containsPair('error', 'battle_annotation_body_too_large'),
        );
        expect(pool.calls, 0);
      },
    );

    test('missing idempotency key is a bounded validation error', () async {
      final pool = _ThrowingPool();
      final response = await annotations_route.onRequest(
        _context(
          HttpMethod.post,
          '/decks/$_deckId/battle-replays/$_replayId/annotations',
          pool: pool,
          body: jsonEncode({
            'kind': 'note',
            'payload': {'text': 'Linha importante.'},
          }),
        ),
        _deckId,
        _replayId,
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(
        await _jsonBody(response),
        containsPair('error', 'invalid_battle_annotation'),
      );
      expect(pool.calls, 0);
    });

    test(
      'missing and inaccessible replays have identical create responses',
      () async {
        Future<Response> request(String replayId) {
          final pool = _ScriptedPool([
            _result(columns: const [], rows: const []),
          ]);
          return annotations_route.onRequest(
            _context(
              HttpMethod.post,
              '/decks/$_deckId/battle-replays/$replayId/annotations',
              pool: pool,
              headers: const {'idempotency-key': 'note-1'},
              body: jsonEncode({
                'kind': 'note',
                'payload': {'text': 'Linha importante.'},
              }),
            ),
            _deckId,
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
      },
    );

    test(
      'missing and inaccessible annotations have identical delete responses',
      () async {
        Future<Response> request(String annotationId) {
          final pool = _ScriptedPool([
            _result(columns: const [], rows: const []),
          ]);
          return annotation_item_route.onRequest(
            _context(
              HttpMethod.delete,
              '/decks/$_deckId/battle-replays/$_replayId/'
              'annotations/$annotationId',
              pool: pool,
            ),
            _deckId,
            _replayId,
            annotationId,
          );
        }

        final missing = await request(_annotationId);
        final inaccessible = await request(_otherAnnotationId);

        expect(missing.statusCode, HttpStatus.notFound);
        expect(inaccessible.statusCode, HttpStatus.notFound);
        expect(await missing.body(), await inaccessible.body());
        expect(await _jsonBody(inaccessible), {
          'error': 'Anotacao nao encontrada.',
        });
      },
    );

    test('updates are not part of the immutable annotation API', () async {
      final pool = _ThrowingPool();
      final response = await annotation_item_route.onRequest(
        _context(
          HttpMethod.put,
          '/decks/$_deckId/battle-replays/$_replayId/'
          'annotations/$_annotationId',
          pool: pool,
        ),
        _deckId,
        _replayId,
        _annotationId,
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(pool.calls, 0);
    });
  });
}

Future<Map<String, dynamic>> _jsonBody(Response response) async =>
    jsonDecode(await response.body()) as Map<String, dynamic>;

RequestContext _context(
  HttpMethod method,
  String path, {
  required Pool pool,
  Object? body,
  Map<String, Object>? headers,
}) => _AnnotationRequestContext(
  Request(
    method.name.toUpperCase(),
    Uri.parse('http://localhost$path'),
    headers: headers,
    body: body,
  ),
  pool,
);

class _AnnotationRequestContext implements RequestContext {
  const _AnnotationRequestContext(this.request, this.pool);

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
    if (T == String) return _userId as T;
    throw StateError('No annotation route test provider for $T');
  }
}

class _ThrowingPool implements Pool {
  int calls = 0;

  Never _fail() {
    calls++;
    throw StateError('database must not be called');
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
  }) async => _fail();

  @override
  Future<Statement> prepare(Object query) =>
      throw UnimplementedError('prepare is not used by this test fake');

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    dynamic locality,
  }) async => _fail();

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    dynamic locality,
  }) async => _fail();

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    dynamic locality,
  }) async => _fail();
}

class _ScriptedPool implements Pool {
  _ScriptedPool(this._results);

  final List<Result> _results;
  int calls = 0;

  Future<Result> _execute() async {
    if (calls >= _results.length) {
      throw StateError('Unexpected database query #${calls + 1}');
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
  }) => _execute();

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
  }) => pool._execute();

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
