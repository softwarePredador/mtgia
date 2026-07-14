import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/battle/battle_replay_read_service.dart';

void main() {
  group('BattleReplayReadService', () {
    test('maps saved replay summaries from battle_simulations', () async {
      final createdAt = DateTime.utc(2026, 7, 6, 12);
      final pool = _ScriptedPool([
        _result(rows: const [
          [true],
        ]),
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
              'sim-1',
              'deck-1',
              'deck-2',
              'battle',
              'deck-1',
              5,
              {'turns': 5},
              createdAt,
              'Lorehold',
              'Atraxa',
              12,
              'battle',
              null,
            ],
          ],
        ),
      ]);
      final service = BattleReplayReadService(pool);

      final replays = await service.listReplays(
        userId: 'user-1',
        deckId: 'deck-1',
      );

      expect(replays, hasLength(1));
      expect(replays.single['id'], 'sim-1');
      expect(replays.single['opponent_name'], 'Atraxa');
      expect(replays.single['winner_name'], 'Lorehold');
      expect(replays.single['event_count'], 12);
      expect(replays.single['created_at'], createdAt.toIso8601String());
    });

    test('maps replay detail with events and decision trace', () async {
      final pool = _ScriptedPool([
        _result(rows: const [
          [true],
        ]),
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
              'sim-1',
              'deck-1',
              'deck-2',
              'battle',
              null,
              null,
              {
                'type': 'battle',
                'winner': 'Player A',
                'turns': 4,
                'game_log': [
                  {'turn': 1, 'player': 'Player A', 'action': 'draws'},
                ],
                'decision_trace': [
                  {
                    'turn': 1,
                    'choice': 'keep hand',
                    'reason': 'two lands and ramp',
                  },
                ],
                'visual_snapshots': [
                  {
                    'turn': 1,
                    'phase': 'main',
                    'action': 'play_land',
                    'players': [
                      {
                        'name': 'Deck A',
                        'life': 40,
                        'hand': [
                          {
                            'name': 'Arcane Signet',
                            'image_url': 'https://cards.example/signet.jpg',
                          },
                        ],
                        'battlefield': [],
                        'graveyard': [],
                      },
                    ],
                  },
                ],
              },
              const {},
              DateTime.utc(2026, 7, 6, 12),
              'Lorehold',
              'Atraxa',
            ],
          ],
        ),
      ]);
      final service = BattleReplayReadService(pool);

      final replay = await service.fetchReplay(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'sim-1',
      );

      expect(replay, isNotNull);
      expect(replay!['winner_name'], 'Player A');
      expect(replay['events'], hasLength(1));
      expect(replay['decision_trace'], hasLength(1));
      expect(replay['visual_snapshots'], hasLength(1));
      expect(
          replay['simulation_contract'], containsPair('advisory_only', true));
    });

    test('marks pinned XMage execution as canonical rules evidence', () async {
      final pool = _ScriptedPool([
        _result(rows: const [
          [true],
        ]),
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
              'sim-xmage',
              'deck-1',
              'deck-2',
              'battle',
              'deck-1',
              8,
              {
                'type': 'battle',
                'engine': 'xmage',
                'engine_version': '1.4.60',
                'engine_commit': 'pinned-commit',
                'engine_contract': 'canonical_rules_execution',
                'learning_contract': const {
                  'schema_version': 'external_battle_learning_v1',
                  'named_draw_identity_available': false,
                  'visible_stack_activity_available': true,
                  'ai_decision_rationale_available': false,
                  'strategy_or_swap_proof': false,
                },
                'game_log': const [],
              },
              const {'engine': 'xmage'},
              DateTime.utc(2026, 7, 14, 12),
              'Lorehold',
              'Atraxa',
            ],
          ],
        ),
      ]);
      final service = BattleReplayReadService(pool);

      final replay = await service.fetchReplay(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'sim-xmage',
      );

      expect(replay!['engine'], 'xmage');
      expect(replay['engine_commit'], 'pinned-commit');
      expect(
        replay['simulation_contract'],
        containsPair('canonical_rules_execution', true),
      );
      expect(
        replay['simulation_contract'],
        containsPair('advisory_only', false),
      );
      expect(
        replay['simulation_contract'],
        containsPair('event_learning_grade', 'visible_activity_only'),
      );
      expect(
        replay['simulation_contract'],
        containsPair('named_draw_identity_available', false),
      );
      expect(
        replay['learning_contract'],
        containsPair('schema_version', 'external_battle_learning_v1'),
      );
    });

    test('marks pinned Forge execution as secondary canonical rules evidence',
        () async {
      final pool = _ScriptedPool([
        _result(rows: const [
          [true],
        ]),
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
              'sim-forge',
              'deck-1',
              'deck-2',
              'battle',
              'deck-2',
              10,
              {
                'type': 'battle',
                'engine': 'forge',
                'engine_version': '2.0.14-SNAPSHOT',
                'engine_commit': 'pinned-forge-commit',
                'engine_contract': 'canonical_rules_execution_secondary',
                'game_log': const [],
              },
              const {'engine': 'forge'},
              DateTime.utc(2026, 7, 14, 12),
              'Lorehold',
              'Korvold',
            ],
          ],
        ),
      ]);
      final service = BattleReplayReadService(pool);

      final replay = await service.fetchReplay(
        userId: 'user-1',
        deckId: 'deck-1',
        replayId: 'sim-forge',
      );

      expect(replay!['engine'], 'forge');
      expect(
        replay['simulation_contract'],
        containsPair('canonical_rules_execution', true),
      );
      expect(
        replay['simulation_contract'],
        containsPair('rules_engine_priority', 'secondary'),
      );
      expect(
        replay['simulation_contract'],
        containsPair('strategy_or_swap_proof', false),
      );
    });
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
    if (calls >= _results.length) {
      throw StateError('Unexpected query #${calls + 1}: $query');
    }
    return _results[calls++];
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
