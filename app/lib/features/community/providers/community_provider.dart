import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';

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
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  factory CommunityDeckComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return CommunityDeckComment(
      id: json['id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      authorName:
          author?['display_name']?.toString().trim().isNotEmpty == true
              ? author!['display_name'].toString()
              : author?['username']?.toString(),
      authorAvatarUrl: author?['avatar_url']?.toString(),
    );
  }
}

class CommunityTradeMatch {
  const CommunityTradeMatch({
    required this.cardName,
    required this.wantedQuantity,
    required this.ownerName,
    required this.sources,
    this.price,
    this.currency,
    this.forTrade = false,
    this.forSale = false,
  });

  final String cardName;
  final int wantedQuantity;
  final String ownerName;
  final List<String> sources;
  final double? price;
  final String? currency;
  final bool forTrade;
  final bool forSale;

  factory CommunityTradeMatch.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>? ?? const {};
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    final offer = json['offer'] as Map<String, dynamic>? ?? const {};
    return CommunityTradeMatch(
      cardName: card['name']?.toString() ?? '',
      wantedQuantity: _readInt(json['wanted_quantity']) ?? 0,
      ownerName:
          owner['display_name']?.toString().trim().isNotEmpty == true
              ? owner['display_name'].toString()
              : owner['username']?.toString() ?? 'Jogador',
      sources: (json['sources'] as List? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      price: _readDouble(offer['price']),
      currency: offer['currency']?.toString(),
      forTrade: offer['for_trade'] == true,
      forSale: offer['for_sale'] == true,
    );
  }
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
          final newDecks =
              deckList
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

  Future<bool> reportDeck(
    String deckId, {
    String reason = 'other',
    String details = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/community/decks/${Uri.encodeComponent(deckId)}/reports',
        {'target_type': 'deck', 'reason': reason, 'details': details},
      );
      return response.statusCode == 201;
    } catch (e, stackTrace) {
      debugPrint('[CommunityProvider] reportDeck error: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'CommunityProvider',
          operation: 'reportDeck',
          extras: {'endpoint': '/community/decks/:id/reports'},
        ),
      );
      return false;
    }
  }

  Future<List<CommunityTradeMatch>> fetchTradeMatches({String? deckId}) async {
    try {
      final query =
          deckId == null || deckId.isEmpty
              ? ''
              : '?deck_id=${Uri.encodeQueryComponent(deckId)}';
      final response = await _apiClient.get('/community/trade-matches$query');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = (response.data as Map<String, dynamic>)['matches'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((entry) => CommunityTradeMatch.fromJson(entry.cast()))
              .toList(growable: false);
        }
      }
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
    }
    return const <CommunityTradeMatch>[];
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
