import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';
import '../../binder/providers/binder_provider.dart';

/// Modelo simplificado de deck público da comunidade
class CommunityDeck {
  final String id;
  final String name;
  final String format;
  final String? description;
  final int? synergyScore;
  final String? ownerId;
  final String? ownerUsername;
  final String? commanderName;
  final String? commanderImageUrl;
  final int cardCount;
  final DateTime createdAt;

  CommunityDeck({
    required this.id,
    required this.name,
    required this.format,
    this.description,
    this.synergyScore,
    this.ownerId,
    this.ownerUsername,
    this.commanderName,
    this.commanderImageUrl,
    this.cardCount = 0,
    required this.createdAt,
  });

  factory CommunityDeck.fromJson(Map<String, dynamic> json) {
    return CommunityDeck(
      id: json['id'] as String,
      name: json['name'] as String,
      format: json['format'] as String,
      description: json['description'] as String?,
      synergyScore: json['synergy_score'] as int?,
      ownerId: json['owner_id'] as String?,
      ownerUsername: json['owner_username'] as String?,
      commanderName: json['commander_name'] as String?,
      commanderImageUrl: json['commander_image_url'] as String?,
      cardCount: json['card_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommunityDeckComment {
  const CommunityDeckComment({
    required this.id,
    required this.body,
    required this.createdAt,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.contextLabel,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? contextLabel;

  factory CommunityDeckComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final parsedBody = parseCommunityDeckCommentBody(
      json['body']?.toString() ?? '',
    );
    return CommunityDeckComment(
      id: json['id']?.toString() ?? '',
      body: parsedBody.body,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      authorId: author?['id']?.toString() ?? json['user_id']?.toString(),
      authorName: author?['display_name']?.toString().trim().isNotEmpty == true
          ? author!['display_name'].toString()
          : author?['username']?.toString(),
      authorAvatarUrl: author?['avatar_url']?.toString(),
      contextLabel: parsedBody.contextLabel,
    );
  }
}

typedef CommunityDeckCommentBody = ({String body, String? contextLabel});

String composeCommunityDeckCommentBody({
  required String body,
  String? contextLabel,
}) {
  final cleanBody = body.trim();
  final cleanContext = contextLabel
      ?.replaceAll(RegExp(r'[\[\]\r\n]+'), ' ')
      .trim();
  if (cleanContext == null ||
      cleanContext.isEmpty ||
      cleanContext == 'Deck todo') {
    return cleanBody;
  }
  final boundedContext = cleanContext.length <= 80
      ? cleanContext
      : cleanContext.substring(0, 80).trimRight();
  return '[Contexto: $boundedContext] $cleanBody';
}

CommunityDeckCommentBody parseCommunityDeckCommentBody(String value) {
  final cleanValue = value.trim();
  final match = RegExp(
    r'^\[Contexto:\s*([^\]]+)\]\s*(.*)$',
    dotAll: true,
  ).firstMatch(cleanValue);
  if (match == null) return (body: cleanValue, contextLabel: null);
  final contextLabel = match.group(1)?.trim();
  final body = match.group(2)?.trim() ?? '';
  return (
    body: body,
    contextLabel: contextLabel?.isEmpty == true ? null : contextLabel,
  );
}

class CommunityTradeMatch {
  CommunityTradeMatch({
    required this.item,
    required this.wantedQuantity,
    required this.ownerId,
    required this.ownerName,
    required this.sources,
    this.ownerUsername,
    this.ownerAvatarUrl,
    this.ownerLocationCity,
    this.ownerLocationState,
  });

  final BinderItem item;
  final int wantedQuantity;
  final String ownerId;
  final String ownerName;
  final String? ownerUsername;
  final String? ownerAvatarUrl;
  final String? ownerLocationCity;
  final String? ownerLocationState;
  final List<String> sources;

  String get cardName => item.cardName;
  String get cardId => item.cardId;
  String get binderItemId => item.id;
  double? get price => item.price;
  String get currency => item.currency;
  bool get forTrade => item.forTrade;
  bool get forSale => item.forSale;
  String get proposalType => forSale && forTrade
      ? 'mixed'
      : forSale
      ? 'sale'
      : 'trade';
  String get proposalSource =>
      sources.contains('deck_missing') ? 'deck_missing' : 'wishlist';
  bool get isActionable =>
      ownerId.isNotEmpty && binderItemId.isNotEmpty && (forTrade || forSale);
  String get freshnessLabel => marketplaceOfferFreshnessLabel(item.updatedAt);
  String? get ownerLocationLabel {
    final city = ownerLocationCity?.trim();
    final state = ownerLocationState?.trim();
    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
      return '$city, $state';
    }
    if (state != null && state.isNotEmpty) return state;
    return null;
  }

  factory CommunityTradeMatch.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>? ?? const {};
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    final offer = json['offer'] as Map<String, dynamic>? ?? const {};
    final binderItem = BinderItem.fromJson({
      'id': offer['binder_item_id']?.toString() ?? '',
      'card': card,
      'quantity': _readInt(offer['quantity']) ?? 0,
      'available_quantity': _readInt(offer['quantity']) ?? 0,
      'condition': offer['condition']?.toString() ?? 'NM',
      'is_foil': offer['is_foil'] == true,
      'language': offer['language']?.toString() ?? 'en',
      'for_trade': offer['for_trade'] == true,
      'for_sale': offer['for_sale'] == true,
      'price': _readDouble(offer['price']),
      'currency': offer['currency']?.toString() ?? 'BRL',
      'notes': offer['notes']?.toString(),
      'updated_at': offer['updated_at']?.toString(),
      'list_type': 'have',
    });
    return CommunityTradeMatch(
      item: binderItem,
      wantedQuantity: _readInt(json['wanted_quantity']) ?? 0,
      ownerId: owner['id']?.toString() ?? '',
      ownerName: owner['display_name']?.toString().trim().isNotEmpty == true
          ? owner['display_name'].toString()
          : owner['username']?.toString() ?? 'Jogador',
      ownerUsername: owner['username']?.toString(),
      ownerAvatarUrl: owner['avatar_url']?.toString(),
      ownerLocationCity: owner['location_city']?.toString(),
      ownerLocationState: owner['location_state']?.toString(),
      sources: (json['sources'] as List? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }
}

class CommunityTradeMatchSearchResult {
  const CommunityTradeMatchSearchResult({
    required this.matches,
    required this.source,
    this.deckId,
    this.message,
    this.error,
  });

  final List<CommunityTradeMatch> matches;
  final String source;
  final String? deckId;
  final String? message;
  final String? error;

  bool get failed => error != null;
}

/// Provider para o feed da comunidade (decks públicos)
class CommunityProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<CommunityDeck> _decks = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  String? _searchQuery;
  String? _formatFilter;
  int _fetchGeneration = 0;

  List<CommunityDeck> get decks => _decks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get total => _total;
  String? get searchQuery => _searchQuery;
  String? get formatFilter => _formatFilter;

  CommunityProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Busca decks públicos com paginação e filtros
  Future<void> fetchPublicDecks({
    String? search,
    String? format,
    bool reset = false,
  }) async {
    if (_isLoading && !reset) return;

    if (reset) {
      _page = 1;
      _decks = [];
      _hasMore = true;
    }

    if (!_hasMore) return;

    final generation = ++_fetchGeneration;
    _isLoading = true;
    _errorMessage = null;
    _searchQuery = search ?? _searchQuery;
    _formatFilter = format ?? _formatFilter;
    final requestPage = _page;
    final requestSearch = _searchQuery;
    final requestFormat = _formatFilter;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': '$requestPage',
        'limit': '20',
      };
      if (requestSearch != null && requestSearch.isNotEmpty) {
        queryParams['search'] = requestSearch;
      }
      if (requestFormat != null && requestFormat.isNotEmpty) {
        queryParams['format'] = requestFormat;
      }

      final queryString = queryParams.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&');

      final response = await _apiClient.get('/community/decks?$queryString');
      if (generation != _fetchGeneration) return;

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final deckList = data['data'];
        if (deckList is! List) {
          _recordCommunityEvent(
            'community_decks_contract_error',
            operation: 'fetchPublicDecks',
            endpoint: '/community/decks',
            statusCode: response.statusCode,
            requestId: response.requestId,
          );
          _errorMessage = 'Resposta inválida da comunidade';
        } else {
          final newDecks = deckList
              .map((d) => CommunityDeck.fromJson(d as Map<String, dynamic>))
              .toList();

          _decks.addAll(newDecks);
          _total = data['total'] as int? ?? 0;
          _hasMore = _decks.length < _total;
          _page = requestPage + 1;
        }
      } else {
        _recordCommunityEvent(
          'community_decks_http_error',
          operation: 'fetchPublicDecks',
          endpoint: '/community/decks',
          statusCode: response.statusCode,
          requestId: response.requestId,
        );
        _errorMessage = 'Falha ao carregar decks da comunidade';
      }
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] fetchPublicDecks error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'fetchPublicDecks',
          extras: {'endpoint': '/community/decks'},
        ),
      );
      _errorMessage =
          'Não foi possível carregar a comunidade agora. Verifique sua '
          'conexão e tente novamente.';
    }

    if (generation == _fetchGeneration) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa filtros e recarrega
  void clearFilters() {
    _searchQuery = null;
    _formatFilter = null;
    fetchPublicDecks(reset: true);
  }

  /// Busca detalhes de um deck público
  Future<Map<String, dynamic>?> fetchPublicDeckDetails(String deckId) async {
    try {
      final response = await _apiClient.get('/community/decks/$deckId');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      _recordCommunityEvent(
        'community_deck_detail_http_error',
        operation: 'fetchPublicDeckDetails',
        endpoint: '/community/decks/:id',
        statusCode: response.statusCode,
        requestId: response.requestId,
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] fetchPublicDeckDetails error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'fetchPublicDeckDetails',
          extras: {'endpoint': '/community/decks/:id'},
        ),
      );
      return null;
    }
  }

  Future<List<CommunityDeckComment>> fetchDeckComments(String deckId) async {
    try {
      final response = await _apiClient.get(
        '/community/decks/${Uri.encodeComponent(deckId)}/comments',
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = (response.data as Map<String, dynamic>)['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((entry) => CommunityDeckComment.fromJson(entry.cast()))
              .toList(growable: false);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] fetchDeckComments error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'fetchDeckComments',
          extras: {'endpoint': '/community/decks/:id/comments'},
        ),
      );
    }
    return const <CommunityDeckComment>[];
  }

  Future<bool> addDeckComment(String deckId, String body) async {
    try {
      final response = await _apiClient.post(
        '/community/decks/${Uri.encodeComponent(deckId)}/comments',
        {'body': body},
      );
      return response.statusCode == 201;
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] addDeckComment error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'addDeckComment',
          extras: {'endpoint': '/community/decks/:id/comments'},
        ),
      );
      return false;
    }
  }

  Future<bool> deleteDeckComment(String deckId, String commentId) async {
    try {
      final response = await _apiClient.delete(
        '/community/decks/${Uri.encodeComponent(deckId)}/comments/'
        '${Uri.encodeComponent(commentId)}',
      );
      return response.statusCode == 204;
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] deleteDeckComment error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'deleteDeckComment',
          extras: {'endpoint': '/community/decks/:id/comments/:commentId'},
        ),
      );
      return false;
    }
  }

  Future<bool> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
  }) async {
    try {
      final response = await _apiClient.post('/content-reports', {
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'details': details,
      });
      return response.statusCode == 201;
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] reportContent error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'reportContent',
          extras: {'endpoint': '/content-reports'},
        ),
      );
      return false;
    }
  }

  Future<bool> reportDeck(
    String deckId, {
    String reason = 'other',
    String details = '',
  }) async {
    return reportContent(
      targetType: 'deck',
      targetId: deckId,
      reason: reason,
      details: details,
    );
  }

  Future<List<CommunityTradeMatch>> fetchTradeMatches({String? deckId}) async {
    final result = await fetchTradeMatchResult(deckId: deckId);
    return result.matches;
  }

  Future<CommunityTradeMatchSearchResult> fetchTradeMatchResult({
    String? deckId,
  }) async {
    final normalizedDeckId = deckId?.trim();
    final query = normalizedDeckId == null || normalizedDeckId.isEmpty
        ? ''
        : '?deck_id=${Uri.encodeQueryComponent(normalizedDeckId)}';
    try {
      final response = await _apiClient.get('/community/trade-matches$query');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final payload = response.data as Map<String, dynamic>;
        final data = payload['matches'];
        final matches = data is List
            ? data
                  .whereType<Map>()
                  .map((entry) => CommunityTradeMatch.fromJson(entry.cast()))
                  .toList(growable: false)
            : const <CommunityTradeMatch>[];
        return CommunityTradeMatchSearchResult(
          matches: matches,
          source: payload['source']?.toString() ?? 'wishlist',
          deckId: payload['deck_id']?.toString(),
          message: payload['message']?.toString(),
        );
      }
      return CommunityTradeMatchSearchResult(
        matches: const [],
        source: normalizedDeckId == null || normalizedDeckId.isEmpty
            ? 'wishlist'
            : 'deck_missing_and_wishlist',
        deckId: normalizedDeckId,
        error: 'Não foi possível consultar os matches agora.',
      );
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] fetchTradeMatches error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'fetchTradeMatches',
          extras: {'endpoint': '/community/trade-matches'},
        ),
      );
      return CommunityTradeMatchSearchResult(
        matches: const [],
        source: normalizedDeckId == null || normalizedDeckId.isEmpty
            ? 'wishlist'
            : 'deck_missing_and_wishlist',
        deckId: normalizedDeckId,
        error:
            'Não foi possível consultar os matches. Sua wishlist foi preservada.',
      );
    }
  }

  /// Limpa todo o estado do provider (chamado no logout)
  void clearAllState() {
    _fetchGeneration++;
    if (_decks.isEmpty &&
        !_isLoading &&
        _errorMessage == null &&
        _page == 1 &&
        _total == 0 &&
        _hasMore &&
        _searchQuery == null &&
        _formatFilter == null) {
      return;
    }

    _decks = [];
    _isLoading = false;
    _errorMessage = null;
    _page = 1;
    _total = 0;
    _hasMore = true;
    _searchQuery = null;
    _formatFilter = null;
    notifyListeners();
  }

  void _recordCommunityEvent(
    String message, {
    required String operation,
    required String endpoint,
    int? statusCode,
    String? requestId,
  }) {
    debugPrint(
      '[CommunityProvider] $message operation=$operation endpoint=$endpoint '
      'status=${statusCode ?? 'n/a'} request_id=${requestId ?? 'n/a'}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        message,
        category: 'community',
        data: {
          'provider': 'CommunityProvider',
          'operation': operation,
          'endpoint': endpoint,
          if (statusCode != null) 'status_code': statusCode,
          if (requestId != null) 'request_id': requestId,
        },
      ),
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
