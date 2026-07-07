import '../../../core/api/api_client.dart';
import '../models/battle_replay.dart';

abstract class BattleReplayGateway {
  Future<List<BattleReplaySummary>> listReplays(String deckId);

  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  });

  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  });

  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  });
}

class BattleReplayException implements Exception {
  const BattleReplayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BattleReplayService implements BattleReplayGateway {
  BattleReplayService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async {
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/battle-replays',
    );
    _throwIfNotOk(response, fallback: 'Falha ao carregar replays de battle.');

    final data = response.data;
    final items =
        data is Map
            ? (data['data'] as List? ?? data['replays'] as List? ?? const [])
            : data is List
            ? data
            : const [];

    return items
        .whereType<Map>()
        .toList(growable: false)
        .asMap()
        .entries
        .map(
          (entry) => BattleReplaySummary.fromJson(
            entry.value.map((key, value) => MapEntry(key.toString(), value)),
            fallbackDeckId: deckId,
            fallbackId: 'replay-${entry.key + 1}',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async {
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/battle-replays/'
      '${Uri.encodeComponent(replayId)}',
    );
    _throwIfNotOk(response, fallback: 'Falha ao abrir replay de battle.');

    final data = response.data;
    if (data is! Map) {
      throw const BattleReplayException('Resposta de replay invalida.');
    }
    return BattleReplayDetail.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
      fallbackDeckId: deckId,
      fallbackId: replayId,
    );
  }

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) async {
    final response = await _apiClient.post('/ai/simulate', {
      'deck_id': deckId,
      'type': 'goldfish',
      'simulations': simulations,
    }, timeout: const Duration(minutes: 2));
    _throwIfNotOk(response, fallback: 'Falha ao rodar goldfish.');
    return _detailFromSimulationResponse(
      response,
      deckId: deckId,
      replayId: 'goldfish-latest',
    );
  }

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) async {
    final response = await _apiClient.post('/ai/simulate', {
      'deck_id': deckId,
      'type': 'battle',
      'opponent_deck_id': opponentDeckId,
      'max_turns': maxTurns,
    }, timeout: const Duration(minutes: 2));
    _throwIfNotOk(response, fallback: 'Falha ao rodar battle.');
    return _detailFromSimulationResponse(
      response,
      deckId: deckId,
      replayId: 'battle-latest',
    );
  }

  BattleReplayDetail _detailFromSimulationResponse(
    ApiResponse response, {
    required String deckId,
    required String replayId,
  }) {
    final data = response.data;
    if (data is! Map) {
      throw const BattleReplayException('Resposta de simulacao invalida.');
    }
    return BattleReplayDetail.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
      fallbackDeckId: deckId,
      fallbackId: replayId,
      source: 'immediate_simulation',
    );
  }

  void _throwIfNotOk(ApiResponse response, {required String fallback}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = response.data;
    final message =
        data is Map
            ? data['error']?.toString() ?? data['message']?.toString()
            : null;
    throw BattleReplayException(message ?? fallback);
  }
}
