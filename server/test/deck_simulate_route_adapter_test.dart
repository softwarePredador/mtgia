import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/simulate/index.dart' as simulate_route;

void main() {
  group('deck simulate Dart Frog adapter', () {
    test('rejects non-GET methods without touching the pool', () async {
      final pool = _FakeDeckSimulatePool();
      final context = _FakeDeckSimulateRequestContext(
        request: Request(
          HttpMethod.post.name.toUpperCase(),
          Uri.parse('http://localhost/decks/deck-6/simulate'),
        ),
        pool: pool,
        userId: 'user-1',
      );

      final response = await simulate_route.onRequest(context, 'deck-6');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(pool.queries, isEmpty);
    });

    test('returns not found before loading cards for non-owner decks',
        () async {
      final pool = _FakeDeckSimulatePool(ownerFound: false);
      final context = _context(pool);

      final response = await simulate_route.onRequest(context, 'deck-6');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.notFound);
      expect(body, containsPair('error', 'Deck not found'));
      expect(pool.queries, hasLength(1));
    });

    test('returns not found for empty owner decks', () async {
      final pool = _FakeDeckSimulatePool(cards: const []);
      final context = _context(pool);

      final response = await simulate_route.onRequest(context, 'deck-6');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.notFound);
      expect(body, containsPair('error', 'Deck not found or empty'));
      expect(pool.queries, hasLength(2));
    });

    test('returns deterministic legacy advisory metadata with seed controls',
        () async {
      final firstContext = _context(
        _FakeDeckSimulatePool(),
        query: 'iterations=12&seed=42',
      );
      final secondContext = _context(
        _FakeDeckSimulatePool(),
        query: 'iterations=12&seed=42',
      );

      final first = await simulate_route.onRequest(firstContext, 'deck-6');
      final second = await simulate_route.onRequest(secondContext, 'deck-6');
      final firstBody = jsonDecode(await first.body()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.body()) as Map<String, dynamic>;

      expect(first.statusCode, HttpStatus.ok);
      expect(second.statusCode, HttpStatus.ok);
      expect(firstBody, secondBody);
      expect(firstBody['deck_id'], 'deck-6');
      expect(firstBody['iterations'], 12);
      expect(firstBody['seed'], 42);
      expect(firstBody['engine'], 'legacy_monte_carlo');
      expect(firstBody['advisory'], isTrue);
      expect(
        firstBody['simulation_contract'],
        containsPair('status', 'legacy_consistency_only'),
      );
      expect(
        firstBody['simulation_contract'],
        containsPair('advisory_only', true),
      );
      expect(
        firstBody['simulation_contract'],
        containsPair('uses_goldfish_simulator', false),
      );
      expect(
        firstBody['simulation_contract'],
        containsPair('canonical_legality_source', false),
      );
      expect(
        firstBody['simulation_contract'],
        containsPair('strategy_or_swap_proof', false),
      );
      expect(
        firstBody['opening_hand'],
        containsPair('land_distribution', isA<Map<String, dynamic>>()),
      );
      expect(firstBody['on_curve_probability'], isA<Map<String, dynamic>>());
    });

    test('clamps iteration query parameters to audit-safe bounds', () async {
      final low = await simulate_route.onRequest(
        _context(_FakeDeckSimulatePool(), query: 'iterations=0&seed=1'),
        'deck-6',
      );
      final high = await simulate_route.onRequest(
        _context(_FakeDeckSimulatePool(), query: 'iterations=99999&seed=1'),
        'deck-6',
      );

      final lowBody = jsonDecode(await low.body()) as Map<String, dynamic>;
      final highBody = jsonDecode(await high.body()) as Map<String, dynamic>;

      expect(lowBody['iterations'], 1);
      expect(highBody['iterations'], 5000);
    });
  });
}

_FakeDeckSimulateRequestContext _context(
  _FakeDeckSimulatePool pool, {
  String query = '',
}) {
  final uri = Uri.parse(
    'http://localhost/decks/deck-6/simulate${query.isEmpty ? '' : '?$query'}',
  );
  return _FakeDeckSimulateRequestContext(
    request: Request(HttpMethod.get.name.toUpperCase(), uri),
    pool: pool,
    userId: 'user-1',
  );
}

class _FakeDeckSimulateRequestContext implements RequestContext {
  _FakeDeckSimulateRequestContext({
    required this.request,
    required this.pool,
    required this.userId,
  });

  @override
  final Request request;
  final Pool pool;
  final String userId;

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return userId as T;
    throw StateError('No fake deck simulate context value for $T');
  }

  @override
  Map<String, String> get mountedParams => const {};
}

class _FakeDeckSimulatePool implements Pool {
  _FakeDeckSimulatePool({
    this.ownerFound = true,
    this.cards = _defaultCards,
  });

  final bool ownerFound;
  final List<List<Object?>> cards;
  final queries = <Object>[];

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
    queries.add(query);
    if (queries.length == 1) {
      return ownerFound
          ? _result(rows: const [
              [1]
            ])
          : _result(rows: const []);
    }
    if (queries.length == 2) {
      return _result(
        columns: const [
          'name',
          'mana_cost',
          'type_line',
          'quantity',
          'is_commander',
        ],
        rows: cards,
      );
    }
    throw StateError('Unexpected fake deck simulate query #${queries.length}');
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
    rows: [
      for (final row in rows) ResultRow(values: row, schema: schema),
    ],
    affectedRows: rows.length,
    schema: schema,
  );
}

const _defaultCards = [
  ['Lorehold, the Historian', '{2}{R}{W}', 'Legendary Creature', 1, true],
  ['Mountain', '', 'Basic Land - Mountain', 20, false],
  ['Plains', '', 'Basic Land - Plains', 13, false],
  ['Faithless Looting', '{R}', 'Sorcery', 1, false],
  ['Boros Signet', '{2}', 'Artifact', 1, false],
  ['Wheel of Fortune', '{2}{R}', 'Sorcery', 1, false],
  ['Austere Command', '{4}{W}{W}', 'Sorcery', 1, false],
];
