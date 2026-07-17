import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse> getResponses = const {},
    Map<String, ApiResponse> postResponses = const {},
  }) : _getResponses = getResponses,
       _postResponses = postResponses;

  final Map<String, ApiResponse> _getResponses;
  final Map<String, ApiResponse> _postResponses;
  final List<String> getCalls = [];
  final List<String> postCalls = [];
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
          '/decks/deck-1/battle-replays': ApiResponse(200, {
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
          }),
        },
      );
      final service = BattleReplayService(apiClient: apiClient);

      final replays = await service.listReplays('deck-1');

      expect(apiClient.getCalls, ['/decks/deck-1/battle-replays']);
      expect(replays, hasLength(1));
      expect(replays.single.title, 'Battle contra Atraxa Superfriends');
      expect(replays.single.eventLabel, '12 eventos');
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
      expect(replay.summary.sourceLabel, 'Historico salvo');
      expect(replay.events, hasLength(1));
    });

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
              contains('nao confirmou o salvamento'),
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
              contains('nao confirmou o salvamento'),
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
  });
}
