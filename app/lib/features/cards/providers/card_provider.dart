import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../decks/models/deck_card_item.dart';

class CardCollectionAvailability {
  const CardCollectionAvailability({
    required this.cardId,
    required this.playableCardId,
    required this.ownedQuantity,
    required this.allocatedQuantity,
    required this.committedTradeQuantity,
    required this.freeQuantity,
    required this.missingQuantity,
  });

  factory CardCollectionAvailability.fromJson(Map<String, dynamic> json) {
    int quantity(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CardCollectionAvailability(
      cardId: json['card_id']?.toString() ?? '',
      playableCardId: json['playable_card_id']?.toString() ?? '',
      ownedQuantity: quantity('owned_quantity'),
      allocatedQuantity: quantity('allocated_quantity'),
      committedTradeQuantity: quantity('committed_trade_quantity'),
      freeQuantity: quantity('free_quantity'),
      missingQuantity: quantity('missing_quantity'),
    );
  }

  final String cardId;
  final String playableCardId;
  final int ownedQuantity;
  final int allocatedQuantity;
  final int committedTradeQuantity;
  final int freeQuantity;
  final int missingQuantity;
}

class CardProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<DeckCardItem> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _currentQuery = '';
  String? _errorMessage;
  Map<String, CardCollectionAvailability> _collectionAvailability = {};

  List<DeckCardItem> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  CardCollectionAvailability? collectionAvailabilityFor(String cardId) =>
      _collectionAvailability[cardId];

  CardProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> searchCards(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      clearSearch();
      return;
    }

    _currentQuery = q;
    _page = 1;
    _hasMore = true;
    _searchResults = [];
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchPage(query: q, page: 1, append: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (_currentQuery.trim().isEmpty) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchPage(query: _currentQuery, page: _page + 1, append: true);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPage({
    required String query,
    required int page,
    required bool append,
  }) async {
    const limit = 50;
    final requestQuery = query.trim();
    final encoded = Uri.encodeQueryComponent(requestQuery);
    final response = await _apiClient.get(
      '/cards?name=$encoded&limit=$limit&page=$page',
    );

    // Se o usuário trocou o query no meio, ignora a resposta antiga.
    if (requestQuery != _currentQuery) return;

    if (response.statusCode != 200) {
      _errorMessage =
          'Não foi possível buscar cartas agora. Verifique a conexão e tente novamente.';
      _hasMore = false;
      return;
    }

    final data = response.data as Map<String, dynamic>;
    final List<dynamic> cardsJson = (data['data'] as List?) ?? const [];
    final results = cardsJson
        .whereType<Map>()
        .map(
          (json) => _cardFromJson(
            json.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
    final availability = await _fetchCollectionAvailability(
      results.map((card) => card.id),
    );

    if (requestQuery != _currentQuery) return;

    if (append) {
      _searchResults = [..._searchResults, ...results];
      _collectionAvailability = {
        ..._collectionAvailability,
        ...availability,
      };
    } else {
      _searchResults = results;
      _collectionAvailability = availability;
    }

    _page = page;
    _hasMore = results.length == limit;
  }

  Future<Map<String, CardCollectionAvailability>>
  _fetchCollectionAvailability(Iterable<String> rawCardIds) async {
    final cardIds = rawCardIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cardIds.isEmpty) return const {};

    try {
      final encoded = Uri.encodeQueryComponent(cardIds.join(','));
      final response = await _apiClient.get(
        '/binder/availability?card_ids=$encoded',
      );
      if (response.statusCode != 200 || response.data is! Map) {
        return const {};
      }
      final rows = (response.data as Map)['data'];
      if (rows is! List) return const {};
      final output = <String, CardCollectionAvailability>{};
      for (final row in rows.whereType<Map>()) {
        final availability = CardCollectionAvailability.fromJson(
          row.map((key, value) => MapEntry(key.toString(), value)),
        );
        if (availability.cardId.isNotEmpty) {
          output[availability.cardId] = availability;
        }
      }
      return output;
    } catch (error) {
      AppLogger.warning(
        '[CardProvider] Disponibilidade da coleção indisponível; '
        'a busca de cartas continua sem bloquear.',
      );
      return const {};
    }
  }

  Future<DeckCardItem> fetchCardById(String cardId) async {
    final normalizedId = cardId.trim();
    if (normalizedId.isEmpty) {
      throw const FormatException('Card id is required');
    }

    final response = await _apiClient.get(
      '/cards?id=${Uri.encodeQueryComponent(normalizedId)}&limit=1&dedupe=false',
    );
    if (response.statusCode != 200) {
      throw Exception(
        FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.deckDetails,
          fallback: 'Não foi possível carregar esta carta agora.',
        ),
      );
    }

    final data = response.data;
    final rawCards = data is Map ? data['data'] : null;
    if (rawCards is! List || rawCards.isEmpty || rawCards.first is! Map) {
      throw StateError('Carta não encontrada.');
    }
    final rawCard = rawCards.first as Map;
    final card = _cardFromJson(
      rawCard.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (card.id != normalizedId) {
      throw StateError('Carta não encontrada.');
    }
    return card;
  }

  DeckCardItem _cardFromJson(Map<String, dynamic> json) {
    return DeckCardItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      manaCost: json['mana_cost']?.toString(),
      typeLine: json['type_line']?.toString() ?? '',
      oracleText: json['oracle_text']?.toString(),
      colors:
          (json['colors'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      colorIdentity:
          (json['color_identity'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      imageUrl: json['image_url']?.toString(),
      layout: json['layout']?.toString(),
      cardFaces: CardFaceArtwork.fromJsonValue(json['card_faces']),
      setCode: json['set_code']?.toString() ?? '',
      setName: json['set_name']?.toString(),
      setReleaseDate: json['set_release_date']?.toString(),
      rarity: json['rarity']?.toString() ?? '',
      isReserved: json['is_reserved'] as bool? ?? false,
      collectorNumber: json['collector_number']?.toString(),
      foil: json['foil'] as bool?,
      quantity: 1,
      isCommander: false,
    );
  }

  void clearSearch() {
    _searchResults = [];
    _collectionAvailability = {};
    _errorMessage = null;
    _currentQuery = '';
    _page = 1;
    _hasMore = false;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Solicita uma explicação da carta via IA
  Future<String?> explainCard(DeckCardItem card) async {
    late final ApiResponse response;
    try {
      response = await _apiClient.post('/ai/explain', {
        'card_id': card.id,
        'card_name': card.name,
        'oracle_text': card.oracleText,
        'type_line': card.typeLine,
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        '[CardProvider] Falha de transporte ao obter explicação da carta',
        error,
        stackTrace,
      );
      rethrow;
    }

    if (response.statusCode != 200) {
      throw Exception(
        FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.deckDetails,
          fallback:
              'Não foi possível explicar esta carta agora. Tente novamente em instantes.',
        ),
      );
    }

    final data = response.data;
    if (data is Map) {
      final explanation = data['explanation']?.toString().trim();
      if (explanation != null && explanation.isNotEmpty) {
        return explanation;
      }
    }

    const error = FormatException('Invalid AI explanation response');
    AppLogger.error(
      '[CardProvider] Resposta inválida ao explicar carta',
      error,
      StackTrace.current,
    );
    throw error;
  }

  Future<List<Map<String, dynamic>>> fetchPrintingsByName(String name) async {
    final encoded = Uri.encodeQueryComponent(name.trim());
    final response = await _apiClient.get(
      '/cards/printings?name=$encoded&limit=50',
    );
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar as edições agora.');
    }

    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?)?.whereType<Map>().toList() ?? const [];
    return list.map((m) => m.cast<String, dynamic>()).toList();
  }

  /// Chama /cards/resolve para importar todas as edições do Scryfall
  /// e depois retorna a lista atualizada de printings do banco.
  Future<List<Map<String, dynamic>>> resolveAndFetchPrintings(
    String name,
  ) async {
    // Usa o parâmetro sync=true que importa automaticamente do Scryfall
    final encoded = Uri.encodeQueryComponent(name.trim());
    final response = await _apiClient.get(
      '/cards/printings?name=$encoded&limit=50&sync=true',
    );
    if (response.statusCode != 200) {
      throw Exception('Não foi possível sincronizar as edições agora.');
    }

    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?)?.whereType<Map>().toList() ?? const [];
    return list.map((m) => m.cast<String, dynamic>()).toList();
  }
}
