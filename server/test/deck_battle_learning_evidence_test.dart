import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/battle_engine_config.dart';
import '../lib/ai/battle_learning_evidence_support.dart';
import '../lib/ai/deck_battle_learning_evidence.dart';

const _hashB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _hashC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _hashD =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  test('legacy replays without a versioned attempt cannot enter learning', () {
    final source =
        File('lib/ai/deck_battle_learning_evidence.dart').readAsStringSync();

    expect(source, contains('JOIN battle_simulation_attempts attempt'));
    expect(
      source,
      isNot(contains('LEFT JOIN battle_simulation_attempts attempt')),
    );
    expect(source, contains("outcome != 'completed'"));
  });

  test(
    'aggregates only trusted battle execution into deckbuilder evidence',
    () async {
      final currentHash = canonicalExternalBattleDeckHash({
        'cards': [
          {
            'name': 'Aerialephant',
            'set_code': 'UST',
            'collector_number': '1',
            'quantity': 1,
            'is_commander': true,
          },
        ],
      });
      final pool = _ScriptedPool([
        _result(
          rows: const [
            [true, true],
          ],
        ),
        _result(
          rows: const [
            ['Aerialephant', 'UST', '1', 1, true],
          ],
        ),
        _result(
          rows: [
            [
              'trusted-replay',
              'deck-1',
              'deck-2',
              {
                'engine_contract': 'native_reviewed_rules_execution',
                'battle_learning_evidence_by_subject': {
                  'deck_a': {
                    'schema_version': battlePositiveEvidenceSchema,
                    'subject_deck_key': 'deck_a',
                    'positive_exposure_ready': true,
                    'natural_sample': true,
                    'exposed_card_names_normalized': ['aerialephant'],
                  },
                },
              },
              {'engine_contract': 'native_reviewed_rules_execution'},
              DateTime.utc(2026, 7, 15),
              'completed',
              currentHash,
              _hashB,
            ],
            [
              'forced-replay',
              'deck-1',
              'deck-2',
              {
                'engine_contract': 'native_reviewed_rules_execution',
                'battle_learning_evidence_by_subject': {
                  'deck_a': {
                    'schema_version': battlePositiveEvidenceSchema,
                    'subject_deck_key': 'deck_a',
                    'positive_exposure_ready': true,
                    'natural_sample': false,
                    'exposed_card_names_normalized': ['forced-only'],
                  },
                },
              },
              {'engine_contract': 'native_reviewed_rules_execution'},
              DateTime.utc(2026, 7, 15),
              'completed',
              currentHash,
              _hashB,
            ],
            [
              'stale-replay',
              'deck-1',
              'deck-3',
              {
                'engine_contract': 'native_reviewed_rules_execution',
                'battle_learning_evidence_by_subject': {
                  'deck_a': {
                    'schema_version': battlePositiveEvidenceSchema,
                    'subject_deck_key': 'deck_a',
                    'positive_exposure_ready': true,
                    'natural_sample': true,
                    'exposed_card_names_normalized': ['stale-only'],
                  },
                },
              },
              {'engine_contract': 'native_reviewed_rules_execution'},
              DateTime.utc(2026, 7, 14),
              'completed',
              _hashC,
              _hashD,
            ],
          ],
        ),
      ]);

      final evidence = await loadDeckBattleLearningEvidence(
        pool: pool,
        deckId: 'deck-1',
      );

      expect(evidence['battle_count'], 3);
      expect(evidence['trusted_battle_count'], 3);
      expect(evidence['compatible_revision_battle_count'], 2);
      expect(evidence['reliable_compatible_battle_count'], 2);
      expect(evidence['stale_revision_battle_count'], 1);
      expect(evidence['censored_battle_count'], 0);
      expect(evidence['timeout_battle_count'], 0);
      expect(evidence['current_deck_hash'], currentHash);
      expect(evidence['positive_exposure_ready'], isTrue);
      expect(
        evidence['exposed_card_names_normalized'],
        equals(['aerialephant']),
      );
      expect(evidence['swap_superiority_proven'], isFalse);
      expect(evidence['promotion_allowed'], isFalse);
    },
  );
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
  }) async => _results[calls++];

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
    rows: [for (final row in rows) ResultRow(values: row, schema: schema)],
    affectedRows: rows.length,
    schema: schema,
  );
}
