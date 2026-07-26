import '../../../core/api/api_client.dart';
import '../models/battle_replay.dart';
import '../models/battle_replay_annotation.dart';
import '../models/battle_test_setup.dart';

abstract class BattleReplayGateway {
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async => const <BattleOpponentDeck>[];

  Future<List<BattleReplaySummary>> listReplays(String deckId);

  Future<BattleReplayPageResult> listReplayPage(
    String deckId, {
    String? cursor,
    int limit = 30,
  });

  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  });

  Future<List<BattleReplayAnnotation>> listReplayAnnotations({
    required String deckId,
    required String replayId,
  }) async => const <BattleReplayAnnotation>[];

  Future<BattleReplayAnnotation> createReplayAnnotation({
    required String deckId,
    required String replayId,
    required BattleReplayAnnotationDraft draft,
  }) async {
    throw const BattleReplayException(
      'Anotações não estão disponíveis neste gateway.',
    );
  }

  Future<bool> deleteReplayAnnotation({
    required String deckId,
    required String replayId,
    required String annotationId,
  }) async => false;

  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  });

  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  });

  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
  }) async => const BattlePreflight(
    status: 'ready',
    cardCount: 0,
    commanderCount: 0,
    validationState: 'unknown',
    availableOpponentCount: 1,
    engineCoverage: {'gateway': 'ready'},
    blockers: [],
  );

  Future<BattleReplayDetail> runBattleTest({
    required String deckId,
    required BattleTestSetup setup,
    int maxTurns = 30,
  }) => runBattleSimulation(
    deckId: deckId,
    opponentDeckId: setup.opponentDeckId,
    maxTurns: maxTurns,
  );
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

class BattleReplayPageResult {
  const BattleReplayPageResult({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });

  final List<BattleReplaySummary> items;
  final bool hasMore;
  final String? nextCursor;
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
    final decks = byId.values.toList(growable: false)
      ..sort((left, right) {
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
      final items = data is List
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
    final page = await listReplayPage(deckId);
    return page.items;
  }

  @override
  Future<BattleReplayPageResult> listReplayPage(
    String deckId, {
    String? cursor,
    int limit = 30,
  }) async {
    if (limit < 1 || limit > 100) {
      throw const BattleReplayException('Limite de replays inválido.');
    }
    final normalizedCursor = cursor?.trim();
    if (normalizedCursor != null &&
        (normalizedCursor.isEmpty ||
            normalizedCursor.length > 512 ||
            !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(normalizedCursor))) {
      throw const BattleReplayException('Cursor de replay inválido.');
    }
    final query = Uri(
      queryParameters: {
        'limit': '$limit',
        if (normalizedCursor != null) 'cursor': normalizedCursor,
      },
    ).query;
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/battle-replays?$query',
    );
    _throwIfNotOk(response, fallback: 'Falha ao carregar replays de battle.');

    final data = response.data;
    final items = data is Map
        ? (data['data'] as List? ?? data['replays'] as List? ?? const [])
        : data is List
        ? data
        : const [];

    final replays = items
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
    final rawPagination = data is Map ? data['pagination'] : null;
    if (rawPagination is! Map ||
        rawPagination['schema_version'] != 'battle_replay_cursor_v1' ||
        rawPagination['has_more'] is! bool) {
      throw const BattleReplayException(
        'Resposta de paginação de replays inválida.',
      );
    }
    final hasMore = rawPagination['has_more'] as bool;
    final nextCursor = rawPagination['next_cursor']?.toString().trim();
    if (hasMore != (nextCursor != null && nextCursor.isNotEmpty) ||
        (nextCursor != null &&
            (nextCursor.length > 512 ||
                !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(nextCursor)))) {
      throw const BattleReplayException(
        'Resposta de paginação de replays inválida.',
      );
    }
    return BattleReplayPageResult(
      items: replays,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
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
  Future<List<BattleReplayAnnotation>> listReplayAnnotations({
    required String deckId,
    required String replayId,
  }) async {
    final response = await _apiClient.get(
      '${_annotationEndpoint(deckId: deckId, replayId: replayId)}?limit=100',
    );
    _throwIfNotOk(response, fallback: 'Falha ao carregar anotações do replay.');
    final data = response.data;
    final items = data is Map ? data['data'] : null;
    if (items is! List) {
      throw const BattleReplayException(
        'Resposta de anotações do replay inválida.',
      );
    }
    try {
      return items
          .whereType<Map>()
          .map(
            (item) => BattleReplayAnnotation.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where(
            (annotation) =>
                annotation.replayId == replayId &&
                annotation.subjectDeckId == deckId,
          )
          .toList(growable: false);
    } on FormatException {
      throw const BattleReplayException(
        'O servidor retornou uma anotação incompatível.',
      );
    }
  }

  @override
  Future<BattleReplayAnnotation> createReplayAnnotation({
    required String deckId,
    required String replayId,
    required BattleReplayAnnotationDraft draft,
  }) async {
    final idempotencyKey = 'annotation:${ApiClient.generateRequestId()}';
    final response = await _apiClient.post(
      _annotationEndpoint(deckId: deckId, replayId: replayId),
      draft.toJson(idempotencyKey: idempotencyKey),
    );
    _throwIfNotOk(response, fallback: 'Falha ao salvar anotação do replay.');
    final data = response.data;
    final rawAnnotation = data is Map ? data['annotation'] : null;
    if (rawAnnotation is! Map) {
      throw const BattleReplayException(
        'Resposta de anotação do replay inválida.',
      );
    }
    try {
      final annotation = BattleReplayAnnotation.fromJson(
        rawAnnotation.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (annotation.replayId != replayId ||
          annotation.subjectDeckId != deckId) {
        throw const FormatException('annotation_scope_mismatch');
      }
      return annotation;
    } on FormatException {
      throw const BattleReplayException(
        'O servidor retornou uma anotação incompatível.',
      );
    }
  }

  @override
  Future<bool> deleteReplayAnnotation({
    required String deckId,
    required String replayId,
    required String annotationId,
  }) async {
    final response = await _apiClient.delete(
      '${_annotationEndpoint(deckId: deckId, replayId: replayId)}/'
      '${Uri.encodeComponent(annotationId)}',
    );
    if (response.statusCode == 204) return true;
    _throwIfNotOk(response, fallback: 'Falha ao excluir anotação do replay.');
    return false;
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
    return _runBattleRequest(
      deckId: deckId,
      body: {'opponent_deck_id': opponentDeckId, 'max_turns': maxTurns},
    );
  }

  @override
  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
  }) async {
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/battle-preflight'
      '?opponent_deck_id=${Uri.encodeQueryComponent(opponentDeckId)}',
    );
    _throwIfNotOk(
      response,
      fallback: 'Falha ao verificar se os decks estao prontos para Battle.',
    );
    final data = response.data;
    if (data is! Map) {
      throw const BattleReplayException('Resposta de preflight invalida.');
    }
    return BattlePreflight.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<BattleReplayDetail> runBattleTest({
    required String deckId,
    required BattleTestSetup setup,
    int maxTurns = 30,
  }) {
    return _runBattleRequest(
      deckId: deckId,
      body: {...setup.toRequestJson(), 'max_turns': maxTurns},
    );
  }

  Future<BattleReplayDetail> _runBattleRequest({
    required String deckId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.post('/ai/simulate', {
      'deck_id': deckId,
      'type': 'battle',
      ...body,
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
    final persistenceMap = persistence is Map
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
    final message = data is Map
        ? data['message']?.toString() ?? data['error']?.toString()
        : null;
    throw BattleReplayException(message ?? fallback);
  }
}

String _annotationEndpoint({
  required String deckId,
  required String replayId,
}) =>
    '/decks/${Uri.encodeComponent(deckId)}/battle-replays/'
    '${Uri.encodeComponent(replayId)}/annotations';

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
