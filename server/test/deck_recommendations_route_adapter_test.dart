import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/recommendations/index.dart'
    as recommendations_route;

void main() {
  group('deck recommendations Dart Frog adapter', () {
    test('executes the no-key path with a fake RequestContext and Pool',
        () async {
      final pool = _FakeRecommendationsPool();
      final context = _FakeRecommendationsRequestContext(
        request: Request(
          HttpMethod.post.name.toUpperCase(),
          Uri.parse('http://localhost/decks/deck-6/recommendations'),
        ),
        pool: pool,
        userId: 'user-1',
        env: DotEnv()..addAll({'ENVIRONMENT': 'development'}),
      );

      final response = await recommendations_route.onRequest(context, 'deck-6');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(body['source'], 'heuristic');
      expect(body['color_identity_source'], 'commander_color_identity');
      expect(body['candidate_color_identity'], ['R', 'W']);
      expect(body['trending'], hasLength(1));
      expect(
        body['recommendations']['add'],
        contains(
          containsPair('card_name', 'Pool-Backed Candidate'),
        ),
      );
      expect(
        body['recommendations']['add'],
        contains(
          containsPair('card_name', 'Pool-Backed Rising Trend'),
        ),
      );
      expect(pool.queries, hasLength(9));
      expect(pool.tableChecks, [
        'card_intelligence_snapshot',
        'card_function_tags',
        'card_semantic_tags_v2',
      ]);
      expect(pool.candidateDeckColors, ['R', 'W']);
      expect(pool.trendSlug, 'lorehold-the-historian');
    });
  });
}

class _FakeRecommendationsRequestContext implements RequestContext {
  _FakeRecommendationsRequestContext({
    required this.request,
    required this.pool,
    required this.userId,
    required this.env,
  });

  @override
  final Request request;
  final Pool pool;
  final String userId;
  final DotEnv env;

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return userId as T;
    if (T == DotEnv) return env as T;
    throw StateError('No fake recommendation context value for $T');
  }

  @override
  Map<String, String> get mountedParams => const {};
}

class _FakeRecommendationsPool implements Pool {
  final queries = <Object>[];
  final tableChecks = <String>[];
  List<String> candidateDeckColors = const [];
  String? trendSlug;

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
    final params = parameters as Map?;

    if (params != null &&
        params.containsKey('deckId') &&
        params.containsKey('userId')) {
      return _result(
        columns: const ['name', 'format', 'description'],
        rows: const [
          ['Lorehold Adapter Fixture', 'commander', 'adapter no-key test'],
        ],
      );
    }

    final tableName = params?['tableName'] as String?;
    if (tableName != null) {
      tableChecks.add(tableName);
      return _result(rows: [
        [
          tableName == 'card_intelligence_snapshot' ||
              tableName == 'card_function_tags'
        ],
      ]);
    }

    if (params != null && params.containsKey('deckId')) {
      return _result(rows: _completeLoreholdRows());
    }

    if (params != null && params.containsKey('limit_plus')) {
      final deckColors = params['deck_colors'] as TypedValue?;
      candidateDeckColors =
          ((deckColors?.value as List?) ?? const <String>[]).cast<String>();
      return _result(rows: const [
        ['Pool-Backed Candidate', 2.0],
      ]);
    }

    if (params != null &&
        params.containsKey('slug') &&
        !params.containsKey('d')) {
      trendSlug = params['slug'] as String?;
      return _result(
        columns: const ['snapshot_date'],
        rows: const [
          ['2026-06-20'],
          ['2026-06-19'],
        ],
      );
    }

    if (params != null && params['d'] == '2026-06-20') {
      return _result(
        columns: const [
          'card_name',
          'inclusion',
          'synergy',
          'num_decks',
          'category',
        ],
        rows: const [
          ['Pool-Backed Rising Trend', 0.12, 0.04, 800, 'newcards'],
        ],
      );
    }

    if (params != null && params['d'] == '2026-06-19') {
      return _result(
        columns: const ['card_name', 'inclusion'],
        rows: const [
          ['Pool-Backed Rising Trend', 0.07],
        ],
      );
    }

    throw StateError(
        'Unexpected fake recommendations query #${queries.length}');
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

List<List<Object?>> _completeLoreholdRows() {
  return const [
    [
      'Lorehold, the Historian',
      'Legendary Creature',
      '',
      '',
      ['R', 'W'],
      ['R', 'W'],
      1,
      true,
      4.0,
      [],
      [],
    ],
    [
      'Off Color Ramp Test',
      'Artifact',
      'tap: add {b}.',
      '',
      ['B'],
      ['B'],
      10,
      false,
      2.0,
      [],
      [],
    ],
    [
      'Draw Density Test',
      'Instant',
      'draw a card.',
      '',
      ['W'],
      ['W'],
      8,
      false,
      2.0,
      [],
      [],
    ],
    [
      'Removal Density Test',
      'Instant',
      'destroy target creature.',
      '',
      ['R'],
      ['R'],
      6,
      false,
      2.0,
      [],
      [],
    ],
    [
      'Board Wipe Density Test',
      'Sorcery',
      'destroy all creatures.',
      '',
      ['W'],
      ['W'],
      2,
      false,
      4.0,
      [],
      [],
    ],
    [
      'Protection Density Test',
      'Instant',
      'permanents you control gain indestructible.',
      '',
      ['W'],
      ['W'],
      3,
      false,
      3.0,
      [],
      [],
    ],
    [
      'Plains',
      'Basic Land - Plains',
      '',
      '',
      <String>[],
      ['W'],
      33,
      false,
      0.0,
      [],
      [],
    ],
  ];
}
