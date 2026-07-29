import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/battle/models/battle_replay_annotation.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse> getResponses = const {},
    Map<String, ApiResponse> postResponses = const {},
    Map<String, ApiResponse> deleteResponses = const {},
  }) : _getResponses = getResponses,
       _postResponses = postResponses,
       _deleteResponses = deleteResponses;

  final Map<String, ApiResponse> _getResponses;
  final Map<String, ApiResponse> _postResponses;
  final Map<String, ApiResponse> _deleteResponses;
  final List<String> getCalls = [];
  final List<String> postCalls = [];
  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    final response = _getResponses[endpoint];
    if (response == null) {
      throw UnimplementedError('No GET response for $endpoint');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    final response = _postResponses[endpoint];
    if (response == null) {
      throw UnimplementedError('No POST response for $endpoint');
    }
    return response;
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    deleteCalls.add(endpoint);
    final response = _deleteResponses[endpoint];
    if (response == null) {
      throw UnimplementedError('No DELETE response for $endpoint');
    }
    return response;
  }
}

void main() {
  group('BattleReplayService', () {
    test(
      'lists usable own and public opponent decks without duplicates',
      () async {
        final apiClient = _FakeApiClient(
          getResponses: {
            '/decks': ApiResponse(200, const [
              {
                'id': 'current-deck',
                'name': 'Deck atual',
                'format': 'commander',
                'card_count': 100,
              },
              {
                'id': 'own-deck',
                'name': 'Meu Korvold',
                'format': 'commander',
                'commander_name': 'Korvold, Fae-Cursed King',
                'card_count': 100,
              },
              {
                'id': 'empty-deck',
                'name': 'Rascunho vazio',
                'format': 'commander',
                'card_count': 0,
              },
            ]),
            '/community/decks?page=1&limit=50': ApiResponse(200, {
              'data': const [
                {
                  'id': 'own-deck',
                  'name': 'Copia publica',
                  'format': 'commander',
                  'owner_username': 'me',
                  'card_count': 100,
                },
                {
                  'id': 'public-deck',
                  'name': 'Atraxa publica',
                  'format': 'commander',
                  'owner_username': 'planeswalker',
                  'card_count': 100,
                },
              ],
            }),
          },
        );
        final service = BattleReplayService(apiClient: apiClient);

        final decks = await service.listOpponentDecks(
          currentDeckId: 'current-deck',
        );

        expect(
          apiClient.getCalls,
          containsAll(['/decks', '/community/decks?page=1&limit=50']),
        );
        expect(decks.map((deck) => deck.id), ['own-deck', 'public-deck']);
        expect(decks.first.isOwn, isTrue);
        expect(decks.last.metadataLabel, contains('@planeswalker'));
        expect(decks.last.matches('atraxa'), isTrue);
      },
    );

    test('keeps available own decks when community listing fails', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks': ApiResponse(200, const [
            {
              'id': 'own-deck',
              'name': 'Meu deck',
              'format': 'commander',
              'card_count': 100,
            },
          ]),
          '/community/decks?page=1&limit=50': ApiResponse(503, const {
            'error': 'unavailable',
          }),
        },
      );

      final decks = await BattleReplayService(
        apiClient: apiClient,
      ).listOpponentDecks(currentDeckId: 'current-deck');

      expect(decks, hasLength(1));
      expect(decks.single.id, 'own-deck');
    });

    test('lists saved battle replays from deck route', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-replays?limit=30': ApiResponse(200, {
            'data': const [
              {
                'id': 'sim-1',
                'deck_id': 'deck-1',
                'type': 'battle',
                'opponent_name': 'Atraxa Superfriends',
                'turns_played': 5,
                'event_count': 12,
              },
            ],
            'pagination': const {
              'schema_version': 'battle_replay_cursor_v1',
              'limit': 30,
              'has_more': false,
            },
          }),
        },
      );
      final service = BattleReplayService(apiClient: apiClient);

      final replays = await service.listReplays('deck-1');

      expect(apiClient.getCalls, ['/decks/deck-1/battle-replays?limit=30']);
      expect(replays, hasLength(1));
      expect(replays.single.title, 'Battle contra Atraxa Superfriends');
      expect(replays.single.eventLabel, '12 eventos');
    });

    test('continues replay history with the opaque server cursor', () async {
      const cursor = 'eyJzY2hlbWFfdmVyc2lvbiI6InRlc3QifQ';
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-replays?limit=1': ApiResponse(200, {
            'data': const [
              {
                'id': 'sim-1',
                'deck_id': 'deck-1',
                'type': 'battle',
                'status': 'completed',
              },
            ],
            'pagination': const {
              'schema_version': 'battle_replay_cursor_v1',
              'limit': 1,
              'has_more': true,
              'next_cursor': cursor,
            },
          }),
          '/decks/deck-1/battle-replays?limit=1&cursor=$cursor': ApiResponse(
            200,
            {
              'data': const [
                {
                  'id': 'sim-2',
                  'deck_id': 'deck-1',
                  'type': 'battle',
                  'status': 'timeout',
                },
              ],
              'pagination': const {
                'schema_version': 'battle_replay_cursor_v1',
                'limit': 1,
                'has_more': false,
              },
            },
          ),
        },
      );
      final service = BattleReplayService(apiClient: apiClient);

      final first = await service.listReplayPage('deck-1', limit: 1);
      final second = await service.listReplayPage(
        'deck-1',
        limit: 1,
        cursor: first.nextCursor,
      );

      expect(first.hasMore, isTrue);
      expect(first.items.single.id, 'sim-1');
      expect(second.hasMore, isFalse);
      expect(second.items.single.id, 'sim-2');
      expect(apiClient.getCalls.last, contains('cursor=$cursor'));
    });

    test('fetches replay detail from deck route', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-replays/sim-1': ApiResponse(200, {
            'replay': const {
              'id': 'sim-1',
              'deck_id': 'deck-1',
              'type': 'battle',
              'events': [
                {
                  'turn': 2,
                  'player': 'Player B',
                  'phase': 'combat',
                  'action': 'attacks',
                },
              ],
            },
          }),
        },
      );
      final service = BattleReplayService(apiClient: apiClient);

      final replay = await service.fetchReplay(
        deckId: 'deck-1',
        replayId: 'sim-1',
      );

      expect(apiClient.getCalls, ['/decks/deck-1/battle-replays/sim-1']);
      expect(replay.events.single.message, 'Player B attacks');
    });

    test('lists PostgreSQL-backed replay annotations in owner scope', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-replays/sim-1/annotations?limit=100':
              ApiResponse(200, {
                'schema_version': 'battle_replay_annotation_v1',
                'immutable_replay': true,
                'data': const [
                  {
                    'schema_version': 'battle_replay_annotation_v1',
                    'id': 'annotation-1',
                    'replay_id': 'sim-1',
                    'subject_deck_id': 'deck-1',
                    'subject_deck_revision': 'v1:hash',
                    'kind': 'note',
                    'payload': {
                      'title': 'Sequência',
                      'text': 'Eu seguraria a remoção.',
                    },
                    'created_at': '2026-07-26T12:00:00Z',
                  },
                ],
              }),
        },
      );

      final annotations = await BattleReplayService(
        apiClient: apiClient,
      ).listReplayAnnotations(deckId: 'deck-1', replayId: 'sim-1');

      expect(annotations, hasLength(1));
      expect(annotations.single.title, 'Sequência');
      expect(annotations.single.detail, 'Eu seguraria a remoção.');
    });

    test(
      'creates an idempotent annotation without local persistence',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/decks/deck-1/battle-replays/sim-1/annotations': ApiResponse(201, {
              'created': true,
              'annotation': const {
                'schema_version': 'battle_replay_annotation_v1',
                'id': 'annotation-2',
                'replay_id': 'sim-1',
                'subject_deck_id': 'deck-1',
                'subject_deck_revision': 'v1:hash',
                'event_ref': 'event:0',
                'kind': 'would_do_differently',
                'payload': {
                  'stance': 'would_change',
                  'reason': 'Eu esperaria a pilha resolver.',
                },
                'created_at': '2026-07-26T12:01:00Z',
              },
            }),
          },
        );

        final annotation = await BattleReplayService(apiClient: apiClient)
            .createReplayAnnotation(
              deckId: 'deck-1',
              replayId: 'sim-1',
              draft: const BattleReplayAnnotationDraft(
                kind: BattleReplayAnnotationKind.wouldDoDifferently,
                eventRef: 'event:0',
                payload: {
                  'stance': 'would_change',
                  'reason': 'Eu esperaria a pilha resolver.',
                },
              ),
            );

        expect(annotation.eventRef, 'event:0');
        expect(apiClient.postBodies.single['idempotency_key'], isNotEmpty);
        expect(apiClient.postBodies.single['kind'], 'would_do_differently');
      },
    );

    test('deletes an annotation through the scoped replay route', () async {
      final endpoint =
          '/decks/deck-1/battle-replays/sim-1/annotations/annotation-1';
      final apiClient = _FakeApiClient(
        deleteResponses: {endpoint: ApiResponse(204, null)},
      );

      final deleted = await BattleReplayService(apiClient: apiClient)
          .deleteReplayAnnotation(
            deckId: 'deck-1',
            replayId: 'sim-1',
            annotationId: 'annotation-1',
          );

      expect(deleted, isTrue);
      expect(apiClient.deleteCalls, [endpoint]);
    });

    test('parses Forge snapshots returned by the saved replay route', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-replays/forge-1': ApiResponse(200, {
            'id': 'forge-1',
            'deck_id': 'deck-1',
            'type': 'battle',
            'engine': 'forge',
            'learning_contract': const {
              'schema_version': 'external_battle_learning_v1',
              'combat_activity_available': false,
              'ai_decision_rationale_available': false,
            },
            'visual_snapshots': const [
              {
                'turn': 1,
                'players': {
                  'deck_a': {'life': 40},
                  'deck_b': {'life': 37},
                },
              },
            ],
          }),
        },
      );

      final replay = await BattleReplayService(
        apiClient: apiClient,
      ).fetchReplay(deckId: 'deck-1', replayId: 'forge-1');

      expect(apiClient.getCalls, ['/decks/deck-1/battle-replays/forge-1']);
      expect(replay.visualSnapshots, hasLength(1));
      final players = replay.visualSnapshots.single.players;
      expect(players.map((player) => player.deckKey), ['deck_a', 'deck_b']);
      expect(players.first.life, 40);
      expect(players.first.handSize, isNull);
      expect(players.first.librarySize, isNull);
      expect(players.first.mana, isNull);
      expect(replay.decisions, isEmpty);
    });

    test('runs battle simulation through ai simulate endpoint', () async {
      final apiClient = _FakeApiClient(
        postResponses: {
          '/ai/simulate': ApiResponse(200, {
            'type': 'battle',
            'deck_a_id': 'deck-1',
            'deck_b_id': 'deck-2',
            'replay_id': 'sim-saved-1',
            'persistence': const {
              'status': 'saved',
              'required': true,
              'replay_id': 'sim-saved-1',
            },
            'winner': 'Player A',
            'turns': 4,
            'game_log': const [
              {'turn': 1, 'player': 'Player A', 'action': 'draws'},
            ],
          }),
        },
      );
      final service = BattleReplayService(apiClient: apiClient);

      final replay = await service.runBattleSimulation(
        deckId: 'deck-1',
        opponentDeckId: 'deck-2',
      );

      expect(apiClient.postCalls, ['/ai/simulate']);
      expect(apiClient.postBodies.single, {
        'deck_id': 'deck-1',
        'type': 'battle',
        'opponent_deck_id': 'deck-2',
        'max_turns': 30,
      });
      expect(replay.summary.typeLabel, 'Battle');
      expect(replay.summary.id, 'sim-saved-1');
      expect(replay.summary.sourceLabel, 'Histórico salvo');
      expect(replay.events, hasLength(1));
    });

    test('loads read-only battle preflight for the selected opponent', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-preflight?opponent_deck_id=deck-2&mode=simulation':
              ApiResponse(200, const {
                'status': 'ready',
                'card_count': 100,
                'commander_count': 1,
                'validation_state': 'validated',
                'available_opponent_count': 4,
                'engine_coverage': {'xmage': 'unsupported', 'forge': 'ready'},
                'blockers': <String>[],
                'deck_snapshot_hash': 'hash-1',
                'deck_revision': 'revision-1',
              }),
        },
      );

      final preflight = await BattleReplayService(
        apiClient: apiClient,
      ).loadBattlePreflight(deckId: 'deck-1', opponentDeckId: 'deck-2');

      expect(preflight.canStart, isTrue);
      expect(preflight.cardCount, 100);
      expect(preflight.engineCoverage['forge'], 'ready');
      expect(preflight.deckRevision, 'revision-1');
    });

    test('requests XMage-only preflight for Battle Coach', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/decks/deck-1/battle-preflight'
              '?opponent_deck_id=deck-2&mode=interactive': ApiResponse(
            200,
            const {
              'status': 'ready',
              'mode': 'interactive',
              'selected_engine': 'xmage',
              'card_count': 100,
              'commander_count': 1,
              'validation_state': 'validated',
              'available_opponent_count': 1,
              'engine_coverage': {'xmage': 'ready'},
              'blockers': <String>[],
            },
          ),
        },
      );

      final preflight = await BattleReplayService(apiClient: apiClient)
          .loadBattlePreflight(
            deckId: 'deck-1',
            opponentDeckId: 'deck-2',
            interactive: true,
          );

      expect(preflight.mode, 'interactive');
      expect(preflight.selectedEngine, 'xmage');
      expect(preflight.canStartInteractive, isTrue);
    });

    test('sends objective and focus cards without forcing access', () async {
      final apiClient = _FakeApiClient(
        postResponses: {
          '/ai/simulate': ApiResponse(200, {
            'type': 'battle',
            'deck_a_id': 'deck-1',
            'deck_b_id': 'deck-2',
            'replay_id': 'sim-focused',
            'persistence': const {
              'status': 'saved',
              'required': true,
              'replay_id': 'sim-focused',
            },
            'turns': 4,
          }),
        },
      );

      await BattleReplayService(apiClient: apiClient).runBattleTest(
        deckId: 'deck-1',
        setup: BattleTestSetup(
          opponentDeckId: 'deck-2',
          objective: BattleTestObjective.focusCards,
          focusCards: const ['Sol Ring', 'Arcane Signet'],
        ),
      );

      expect(apiClient.postBodies.single, {
        'deck_id': 'deck-1',
        'type': 'battle',
        'opponent_deck_id': 'deck-2',
        'test_objective': 'focus_cards',
        'focus_cards': const ['Sol Ring', 'Arcane Signet'],
        'max_turns': 30,
      });
      expect(
        apiClient.postBodies.single,
        isNot(contains('force_focus_access_mode')),
      );
    });

    test(
      'maps native choices only when the simulation declares decision traces',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/ai/simulate': ApiResponse(200, {
              'type': 'battle',
              'deck_a_id': 'deck-1',
              'deck_b_id': 'deck-2',
              'replay_id': 'native-saved-1',
              'persistence': const {
                'status': 'saved',
                'required': true,
                'replay_id': 'native-saved-1',
              },
              'engine': 'manaloom_native_reviewed',
              'engine_contract': 'native_reviewed_rules_execution',
              'learning_contract': const {
                'schema_version': 'native_battle_learning_v1',
                'decision_trace_available': true,
              },
              'decision_trace': const [
                {
                  'decision_id': 'decision-000001',
                  'turn': 1,
                  'decision_type': 'cast_spell',
                  'chosen_option': {
                    'card': 'Arcane Signet',
                    'action': 'cast',
                    'score': 0.82,
                  },
                  'alternatives_considered': [
                    {'action': 'pass', 'score': 0},
                  ],
                  'score_components': {'mana_efficiency': 0.82},
                  'reason': 'Develops mana.',
                  'heuristic_version': 'battle_decision_strategy_v1',
                },
              ],
            }),
          },
        );

        final replay = await BattleReplayService(
          apiClient: apiClient,
        ).runBattleSimulation(deckId: 'deck-1', opponentDeckId: 'deck-2');

        expect(replay.nativeDecisionTraceAvailable, isTrue);
        expect(replay.decisions, hasLength(1));
        expect(replay.decisions.single.choice, 'cast · Arcane Signet');
        expect(replay.decisions.single.alternatives, hasLength(1));
        expect(
          replay.decisions.single.scoreComponents['mana_efficiency'],
          0.82,
        );
        expect(
          replay.decisions.single.heuristicVersion,
          'battle_decision_strategy_v1',
        );
      },
    );

    test(
      'rejects a success response that does not confirm replay persistence',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/ai/simulate': ApiResponse(200, const {
              'type': 'battle',
              'deck_a_id': 'deck-1',
              'deck_b_id': 'deck-2',
            }),
          },
        );

        expect(
          () => BattleReplayService(
            apiClient: apiClient,
          ).runBattleSimulation(deckId: 'deck-1', opponentDeckId: 'deck-2'),
          throwsA(
            isA<BattleReplayException>().having(
              (error) => error.message,
              'message',
              contains('não confirmou o salvamento'),
            ),
          ),
        );
      },
    );

    test(
      'rejects a success response with inconsistent replay identifiers',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/ai/simulate': ApiResponse(200, const {
              'type': 'battle',
              'deck_a_id': 'deck-1',
              'deck_b_id': 'deck-2',
              'replay_id': 'sim-response',
              'persistence': {
                'status': 'saved',
                'required': true,
                'replay_id': 'sim-persisted',
              },
            }),
          },
        );

        expect(
          () => BattleReplayService(
            apiClient: apiClient,
          ).runBattleSimulation(deckId: 'deck-1', opponentDeckId: 'deck-2'),
          throwsA(
            isA<BattleReplayException>().having(
              (error) => error.message,
              'message',
              contains('não confirmou o salvamento'),
            ),
          ),
        );
      },
    );

    test(
      'prefers the backend user message over a persistence error code',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/ai/simulate': ApiResponse(503, const {
              'error': 'simulation_persistence_failed',
              'message': 'O replay nao pode ser salvo agora.',
            }),
          },
        );

        expect(
          () => BattleReplayService(
            apiClient: apiClient,
          ).runBattleSimulation(deckId: 'deck-1', opponentDeckId: 'deck-2'),
          throwsA(
            isA<BattleReplayException>().having(
              (error) => error.message,
              'message',
              'O replay nao pode ser salvo agora.',
            ),
          ),
        );
      },
    );

    test('sanitizes runtime vendors from backend errors', () async {
      final apiClient = _FakeApiClient(
        postResponses: {
          '/ai/simulate': ApiResponse(503, const {
            'error': 'simulation_runtime_failed',
            'message': 'XMage failed to execute the battle.',
          }),
        },
      );

      expect(
        () => BattleReplayService(
          apiClient: apiClient,
        ).runBattleSimulation(deckId: 'deck-1', opponentDeckId: 'deck-2'),
        throwsA(
          isA<BattleReplayException>()
              .having(
                (error) => error.message,
                'message',
                contains('motor de regras'),
              )
              .having(
                (error) => error.message,
                'vendor names',
                isNot(contains('XMage')),
              ),
        ),
      );
    });
  });
}
