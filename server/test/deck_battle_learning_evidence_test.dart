import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/deck_battle_learning_evidence.dart';

void main() {
  test('aggregates only trusted battle execution into deckbuilder evidence',
      () async {
    final pool = _ScriptedPool([
      _result(rows: const [
        [true],
      ]),
      _result(rows: [
        [
          'trusted-replay',
          'deck-1',
          'deck-2',
          {
            'engine_contract': 'native_reviewed_rules_execution',
            'battle_learning_evidence': {
              'schema_version': 'battle_positive_evidence_v1',
              'positive_exposure_ready': true,
              'natural_sample': true,
              'exposed_card_names_normalized': ['aerialephant'],
            },
          },
          {'engine_contract': 'native_reviewed_rules_execution'},
          DateTime.utc(2026, 7, 15),
        ],
        [
          'forced-replay',
          'deck-1',
          'deck-2',
          {
            'engine_contract': 'native_reviewed_rules_execution',
            'battle_learning_evidence': {
              'schema_version': 'battle_positive_evidence_v1',
              'positive_exposure_ready': true,
              'natural_sample': false,
              'exposed_card_names_normalized': ['forced-only'],
            },
          },
          {'engine_contract': 'native_reviewed_rules_execution'},
          DateTime.utc(2026, 7, 15),
        ],
        [
          'legacy-replay',
          'deck-1',
          'deck-3',
          {
            'engine_contract': 'experimental_advisory',
            'battle_learning_evidence': {
              'schema_version': 'battle_positive_evidence_v1',
              'positive_exposure_ready': true,
              'exposed_card_names_normalized': ['untrusted'],
            },
          },
          {'engine_contract': 'experimental_advisory'},
          DateTime.utc(2026, 7, 14),
        ],
      ]),
    ]);

    final evidence = await loadDeckBattleLearningEvidence(
      pool: pool,
      deckId: 'deck-1',
    );

    expect(evidence['battle_count'], 3);
    expect(evidence['trusted_battle_count'], 2);
    expect(evidence['positive_exposure_ready'], isTrue);
    expect(
      evidence['exposed_card_names_normalized'],
      equals(['aerialephant']),
    );
    expect(evidence['swap_superiority_proven'], isFalse);
    expect(evidence['promotion_allowed'], isFalse);
  });
}

class _ScriptedPool implements Pool {
  _ScriptedPool(this._results);

  final List<Result> _results;
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
  }) async =>
      _results[calls++];

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    dynamic locality,
  }) =>
      fn(this);

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

Result _result({required List<List<Object?>> rows}) {
  final width = rows.isEmpty ? 0 : rows.first.length;
  final schema = ResultSchema([
    for (var index = 0; index < width; index++)
      ResultSchemaColumn(
        typeOid: 0,
        type: Type.unspecified,
        columnName: 'c$index',
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
