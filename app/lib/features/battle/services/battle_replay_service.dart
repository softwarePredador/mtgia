import '../../../core/api/api_client.dart';
import '../models/battle_replay.dart';

abstract class BattleReplayGateway {
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async => const <BattleOpponentDeck>[];

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

enum BattleOpponentDeckSource { own, community }

class BattleOpponentDeck {
  const BattleOpponentDeck({
    required this.id,
    required this.name,
    required this.format,
    required this.source,
    this.commanderName,
    this.ownerUsername,
    this.cardCount = 0,
  });

  final String id;
  final String name;
  final String format;
  final BattleOpponentDeckSource source;
  final String? commanderName;
  final String? ownerUsername;
  final int cardCount;

  factory BattleOpponentDeck.fromJson(
    Map<String, dynamic> json, {
    required BattleOpponentDeckSource source,
  }) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    return BattleOpponentDeck(
      id: id,
      name: name.isEmpty ? 'Deck sem nome' : name,
      format: json['format']?.toString().trim() ?? '',
      source: source,
      commanderName: _optionalText(json['commander_name']),
      ownerUsername: _optionalText(json['owner_username']),
      cardCount: _readInt(json['card_count']) ?? 0,
    );
  }

  bool get isOwn => source == BattleOpponentDeckSource.own;

  String get sourceLabel => isOwn ? 'Meu deck' : 'Comunidade';

  String get supportingLabel {
    final commander = commanderName?.trim();
    if (commander != null && commander.isNotEmpty) return commander;
    final normalizedFormat = format.trim();
    return normalizedFormat.isEmpty
        ? 'Formato nao informado'
        : normalizedFormat;
  }

  String get metadataLabel {
    final parts = <String>[
      sourceLabel,
      if (!isOwn && ownerUsername?.trim().isNotEmpty == true)
        '@${ownerUsername!.trim()}',
      if (cardCount > 0) '$cardCount cartas',
    ];
    return parts.join(' · ');
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      format,
      commanderName ?? '',
      ownerUsername ?? '',
    ].any((value) => value.toLowerCase().contains(normalized));
  }
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
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async {
    final ownFuture = _loadOpponentDecks(
      '/decks',
      source: BattleOpponentDeckSource.own,
    );
    final communityFuture = _loadOpponentDecks(
      '/community/decks?page=1&limit=50',
      source: BattleOpponentDeckSource.community,
    );
    final own = await ownFuture;
    final community = await communityFuture;
    if (!own.succeeded && !community.succeeded) {
      throw const BattleReplayException(
        'Nao foi possivel carregar os decks adversarios.',
      );
    }

    final byId = <String, BattleOpponentDeck>{};
    for (final deck in [...own.decks, ...community.decks]) {
      if (deck.id.isEmpty || deck.id == currentDeckId || deck.cardCount <= 0) {
        continue;
      }
      byId.putIfAbsent(deck.id, () => deck);
    }
    final decks = byId.values.toList(growable: false)..sort((left, right) {
      final sourceOrder = (left.isOwn ? 0 : 1).compareTo(right.isOwn ? 0 : 1);
      if (sourceOrder != 0) return sourceOrder;
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return decks;
  }

  Future<_OpponentDeckLoadResult> _loadOpponentDecks(
    String endpoint, {
    required BattleOpponentDeckSource source,
  }) async {
    try {
      final response = await _apiClient.get(endpoint);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const _OpponentDeckLoadResult.failed();
      }
      final data = response.data;
      final items =
          data is List
              ? data
              : data is Map
              ? data['data'] as List? ?? const <dynamic>[]
              : const <dynamic>[];
      final decks = items
          .whereType<Map>()
          .map(
            (item) => BattleOpponentDeck.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
              source: source,
            ),
          )
          .toList(growable: false);
      return _OpponentDeckLoadResult.succeeded(decks);
    } catch (_) {
      return const _OpponentDeckLoadResult.failed();
    }
  }

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
    return _detailFromSimulationResponse(response, deckId: deckId);
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
    return _detailFromSimulationResponse(response, deckId: deckId);
  }

  BattleReplayDetail _detailFromSimulationResponse(
    ApiResponse response, {
    required String deckId,
  }) {
    final data = response.data;
    if (data is! Map) {
      throw const BattleReplayException('Resposta de simulacao invalida.');
    }
    final persistence = data['persistence'];
    final persistenceMap =
        persistence is Map
            ? persistence.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    final replayIdValue = data['replay_id']?.toString().trim();
    final persistedReplayId = persistenceMap['replay_id']?.toString().trim();
    if (persistenceMap['status'] != 'saved' ||
        replayIdValue == null ||
        replayIdValue.isEmpty ||
        persistedReplayId == null ||
        persistedReplayId.isEmpty ||
        replayIdValue != persistedReplayId) {
      throw const BattleReplayException(
        'O servidor nao confirmou o salvamento do replay. Tente novamente.',
      );
    }
    return BattleReplayDetail.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
      fallbackDeckId: deckId,
      fallbackId: replayIdValue,
      source: 'battle_simulations',
    );
  }

  void _throwIfNotOk(ApiResponse response, {required String fallback}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = response.data;
    final message =
        data is Map
            ? data['message']?.toString() ?? data['error']?.toString()
            : null;
    throw BattleReplayException(message ?? fallback);
  }
}

class _OpponentDeckLoadResult {
  const _OpponentDeckLoadResult.succeeded(this.decks) : succeeded = true;

  const _OpponentDeckLoadResult.failed()
    : succeeded = false,
      decks = const <BattleOpponentDeck>[];

  final bool succeeded;
  final List<BattleOpponentDeck> decks;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
