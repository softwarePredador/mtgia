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
      expect(replay.summary.sourceLabel, 'Simulacao recem-gerada');
      expect(replay.events, hasLength(1));
    });
  });
}
