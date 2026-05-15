import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user_trust_insight.dart';
import '../../../core/utils/friendly_error_mapper.dart';

// =====================================================================
// Model: BinderItem
// =====================================================================

class BinderItem {
  final String id;
  final String cardId;
  final String cardName;
  final String? cardImageUrl;
  final String? cardSetCode;
  final String? cardManaCost;
  final String? cardRarity;
  final String? cardTypeLine;
  final double? cardMarketPrice;
  final String? createdAt;
  final String? updatedAt;
  final int deckCount;
  final int deckQuantity;
  int quantity;
  String condition; // NM, LP, MP, HP, DMG
  bool isFoil;
  bool forTrade;
  bool forSale;
  double? price;
  String currency;
  String? notes;
  String language;
  String listType; // 'have' or 'want'

  BinderItem({
    required this.id,
    required this.cardId,
    required this.cardName,
    this.cardImageUrl,
    this.cardSetCode,
    this.cardManaCost,
    this.cardRarity,
    this.cardTypeLine,
    this.cardMarketPrice,
    this.createdAt,
    this.updatedAt,
    this.deckCount = 0,
    this.deckQuantity = 0,
    this.quantity = 1,
    this.condition = 'NM',
    this.isFoil = false,
    this.forTrade = false,
    this.forSale = false,
    this.price,
    this.currency = 'BRL',
    this.notes,
    this.language = 'en',
    this.listType = 'have',
  });

  factory BinderItem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>?;
    return BinderItem(
      id: json['id'] as String,
      cardId: card?['id'] as String? ?? json['card_id'] as String,
      cardName: card?['name'] as String? ?? json['card_name'] as String? ?? '',
      cardImageUrl:
          card?['image_url'] as String? ?? json['card_image_url'] as String?,
      cardSetCode:
          card?['set_code'] as String? ?? json['card_set_code'] as String?,
      cardManaCost:
          card?['mana_cost'] as String? ?? json['card_mana_cost'] as String?,
      cardRarity: card?['rarity'] as String? ?? json['card_rarity'] as String?,
      cardTypeLine:
          card?['type_line'] as String? ?? json['card_type_line'] as String?,
      cardMarketPrice:
          card?['market_price'] != null
              ? (card?['market_price'] as num).toDouble()
              : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      deckCount: json['deck_count'] as int? ?? 0,
      deckQuantity: json['deck_quantity'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      condition: json['condition'] as String? ?? 'NM',
      isFoil: json['is_foil'] as bool? ?? false,
      forTrade: json['for_trade'] as bool? ?? false,
      forSale: json['for_sale'] as bool? ?? false,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'BRL',
      notes: json['notes'] as String?,
      language: json['language'] as String? ?? 'en',
      listType: json['list_type'] as String? ?? 'have',
    );
  }
}

class BinderDistributionEntry {
  final String label;
  final int quantity;

  const BinderDistributionEntry({required this.label, required this.quantity});

  factory BinderDistributionEntry.fromJson(Map<String, dynamic> json) {
    return BinderDistributionEntry(
      label: json['label']?.toString() ?? 'unknown',
      quantity: json['quantity'] as int? ?? 0,
    );
  }
}

class BinderSetProgress {
  final String setCode;
  final String? setName;
  final int uniqueOwned;
  final int quantityOwned;
  final int totalCards;
  final double completionRatio;
  final double estimatedValue;

  const BinderSetProgress({
    required this.setCode,
    this.setName,
    this.uniqueOwned = 0,
    this.quantityOwned = 0,
    this.totalCards = 0,
    this.completionRatio = 0.0,
    this.estimatedValue = 0.0,
  });

  factory BinderSetProgress.fromJson(Map<String, dynamic> json) {
    return BinderSetProgress(
      setCode: json['set_code']?.toString() ?? '',
      setName: json['set_name']?.toString(),
      uniqueOwned: json['unique_owned'] as int? ?? 0,
      quantityOwned: json['quantity_owned'] as int? ?? 0,
      totalCards: json['total_cards'] as int? ?? 0,
      completionRatio:
          json['completion_ratio'] != null
              ? (json['completion_ratio'] as num).toDouble()
              : 0.0,
      estimatedValue:
          json['estimated_value'] != null
              ? (json['estimated_value'] as num).toDouble()
              : 0.0,
    );
  }
}

class BinderWishlistEntry {
  final String cardId;
  final String cardName;
  final String? setCode;
  final String? rarity;
  final int wantQuantity;
  final int haveQuantity;
  final int missingQuantity;

  const BinderWishlistEntry({
    required this.cardId,
    required this.cardName,
    this.setCode,
    this.rarity,
    this.wantQuantity = 0,
    this.haveQuantity = 0,
    this.missingQuantity = 0,
  });

  factory BinderWishlistEntry.fromJson(Map<String, dynamic> json) {
    return BinderWishlistEntry(
      cardId: json['card_id']?.toString() ?? '',
      cardName: json['card_name']?.toString() ?? 'Carta',
      setCode: json['set_code']?.toString(),
      rarity: json['rarity']?.toString(),
      wantQuantity: json['want_quantity'] as int? ?? 0,
      haveQuantity: json['have_quantity'] as int? ?? 0,
      missingQuantity: json['missing_quantity'] as int? ?? 0,
    );
  }
}

// =====================================================================
// Model: BinderStats
// =====================================================================

class BinderStats {
  final int totalItems;
  final int uniqueCards;
  final int duplicateCopies;
  final int forTradeCount;
  final int forSaleCount;
  final double estimatedValue;
  final int wishlistCount;
  final int wishlistUniqueCards;
  final int missingCardsCount;
  final int priceMissingCount;
  final int cardsUsedInDecks;
  final int decksUsingBinderCards;
  final List<BinderSetProgress> setProgress;
  final List<BinderWishlistEntry> wishlist;
  final Map<String, List<BinderDistributionEntry>> distributions;

  BinderStats({
    this.totalItems = 0,
    this.uniqueCards = 0,
    this.duplicateCopies = 0,
    this.forTradeCount = 0,
    this.forSaleCount = 0,
    this.estimatedValue = 0.0,
    this.wishlistCount = 0,
    this.wishlistUniqueCards = 0,
    this.missingCardsCount = 0,
    this.priceMissingCount = 0,
    this.cardsUsedInDecks = 0,
    this.decksUsingBinderCards = 0,
    this.setProgress = const [],
    this.wishlist = const [],
    this.distributions = const {},
  });

  factory BinderStats.fromJson(Map<String, dynamic> json) {
    final distributionsJson =
        json['distributions'] as Map<String, dynamic>? ?? const {};
    final distributions = <String, List<BinderDistributionEntry>>{};
    for (final entry in distributionsJson.entries) {
      distributions[entry.key] =
          (entry.value as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => BinderDistributionEntry.fromJson(e.cast()))
              .toList();
    }

    return BinderStats(
      totalItems: json['total_items'] as int? ?? 0,
      uniqueCards: json['unique_cards'] as int? ?? 0,
      duplicateCopies: json['duplicate_copies'] as int? ?? 0,
      forTradeCount: json['for_trade_count'] as int? ?? 0,
      forSaleCount: json['for_sale_count'] as int? ?? 0,
      estimatedValue:
          json['estimated_value'] != null
              ? (json['estimated_value'] as num).toDouble()
              : 0.0,
      wishlistCount: json['wishlist_count'] as int? ?? 0,
      wishlistUniqueCards: json['wishlist_unique_cards'] as int? ?? 0,
      missingCardsCount: json['missing_cards_count'] as int? ?? 0,
      priceMissingCount: json['price_missing_count'] as int? ?? 0,
      cardsUsedInDecks: json['cards_used_in_decks'] as int? ?? 0,
      decksUsingBinderCards: json['decks_using_binder_cards'] as int? ?? 0,
      setProgress:
          (json['set_progress'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => BinderSetProgress.fromJson(e.cast()))
              .toList(),
      wishlist:
          (json['wishlist'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => BinderWishlistEntry.fromJson(e.cast()))
              .toList(),
      distributions: distributions,
    );
  }
}

// =====================================================================
// Model: MarketplaceItem (item no marketplace com dados do owner)
// =====================================================================

class MarketplaceItem extends BinderItem {
  final String ownerId;
  final String ownerUsername;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final String? ownerLocationState;
  final String? ownerLocationCity;
  final String? ownerTradeNotes;
  final MarketplacePriceInsight? priceInsight;
  final UserTrustInsight ownerTrust;

  MarketplaceItem({
    required super.id,
    required super.cardId,
    required super.cardName,
    super.cardImageUrl,
    super.cardSetCode,
    super.cardManaCost,
    super.cardRarity,
    super.cardTypeLine,
    super.quantity,
    super.condition,
    super.isFoil,
    super.forTrade,
    super.forSale,
    super.price,
    super.currency,
    super.notes,
    super.language,
    super.listType,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    this.ownerLocationState,
    this.ownerLocationCity,
    this.ownerTradeNotes,
    this.priceInsight,
    this.ownerTrust = const UserTrustInsight(),
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>?;
    return MarketplaceItem(
      id: json['id'] as String,
      cardId: card?['id'] as String? ?? json['card_id'] as String? ?? '',
      cardName: card?['name'] as String? ?? '',
      cardImageUrl: card?['image_url'] as String?,
      cardSetCode: card?['set_code'] as String?,
      cardManaCost: card?['mana_cost'] as String?,
      cardRarity: card?['rarity'] as String?,
      cardTypeLine: card?['type_line'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      condition: json['condition'] as String? ?? 'NM',
      isFoil: json['is_foil'] as bool? ?? false,
      forTrade: json['for_trade'] as bool? ?? false,
      forSale: json['for_sale'] as bool? ?? false,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'BRL',
      notes: json['notes'] as String?,
      language: json['language'] as String? ?? 'en',
      listType: json['list_type'] as String? ?? 'have',
      ownerId: owner?['id'] as String? ?? '',
      ownerUsername: owner?['username'] as String? ?? '',
      ownerDisplayName: owner?['display_name'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      ownerLocationState: owner?['location_state'] as String?,
      ownerLocationCity: owner?['location_city'] as String?,
      ownerTradeNotes: owner?['trade_notes'] as String?,
      priceInsight: MarketplacePriceInsight.fromJson(
        json['price_insight'] as Map<String, dynamic>?,
      ),
      ownerTrust: UserTrustInsight.fromJson(
        owner?['trust'] as Map<String, dynamic>?,
      ),
    );
  }

  String get ownerDisplayLabel => ownerDisplayName ?? ownerUsername;

  /// Retorna label de localização formatada
  String? get ownerLocationLabel {
    if (ownerLocationCity != null && ownerLocationState != null) {
      return '$ownerLocationCity, $ownerLocationState';
    }
    if (ownerLocationState != null) return ownerLocationState;
    return null;
  }
}

class MarketplacePriceInsight {
  final double? referencePrice;
  final String referenceCurrency;
  final int historyPoints;
  final MarketplacePriceTrend trend;
  final MarketplacePriceComparison comparison;

  const MarketplacePriceInsight({
    this.referencePrice,
    this.referenceCurrency = 'USD',
    this.historyPoints = 0,
    this.trend = const MarketplacePriceTrend(),
    this.comparison = const MarketplacePriceComparison(),
  });

  factory MarketplacePriceInsight.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MarketplacePriceInsight();
    return MarketplacePriceInsight(
      referencePrice:
          json['reference_price'] != null
              ? (json['reference_price'] as num).toDouble()
              : null,
      referenceCurrency: json['reference_currency'] as String? ?? 'USD',
      historyPoints: json['history_points'] as int? ?? 0,
      trend: MarketplacePriceTrend.fromJson(
        json['trend'] as Map<String, dynamic>?,
      ),
      comparison: MarketplacePriceComparison.fromJson(
        json['comparison'] as Map<String, dynamic>?,
      ),
    );
  }
}

class MarketplacePriceTrend {
  final String status;
  final String direction;
  final double? latestPrice;
  final double? previousPrice;
  final double? changeAbs;
  final double? changePct;
  final String? latestDate;
  final String? previousDate;
  final String? message;

  const MarketplacePriceTrend({
    this.status = 'insufficient_data',
    this.direction = 'flat',
    this.latestPrice,
    this.previousPrice,
    this.changeAbs,
    this.changePct,
    this.latestDate,
    this.previousDate,
    this.message,
  });

  factory MarketplacePriceTrend.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MarketplacePriceTrend();
    return MarketplacePriceTrend(
      status: json['status'] as String? ?? 'insufficient_data',
      direction: json['direction'] as String? ?? 'flat',
      latestPrice:
          json['latest_price'] != null
              ? (json['latest_price'] as num).toDouble()
              : null,
      previousPrice:
          json['previous_price'] != null
              ? (json['previous_price'] as num).toDouble()
              : null,
      changeAbs:
          json['change_abs'] != null
              ? (json['change_abs'] as num).toDouble()
              : null,
      changePct:
          json['change_pct'] != null
              ? (json['change_pct'] as num).toDouble()
              : null,
      latestDate: json['latest_date'] as String?,
      previousDate: json['previous_date'] as String?,
      message: json['message'] as String?,
    );
  }

  bool get hasTrend => status == 'available' && changePct != null;
}

class MarketplacePriceComparison {
  final String status;
  final String direction;
  final double? differenceAbs;
  final double? differencePct;
  final double thresholdPct;
  final double thresholdAbs;
  final String? message;

  const MarketplacePriceComparison({
    this.status = 'insufficient_data',
    this.direction = 'unknown',
    this.differenceAbs,
    this.differencePct,
    this.thresholdPct = 35,
    this.thresholdAbs = 5,
    this.message,
  });

  factory MarketplacePriceComparison.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MarketplacePriceComparison();
    return MarketplacePriceComparison(
      status: json['status'] as String? ?? 'insufficient_data',
      direction: json['direction'] as String? ?? 'unknown',
      differenceAbs:
          json['difference_abs'] != null
              ? (json['difference_abs'] as num).toDouble()
              : null,
      differencePct:
          json['difference_pct'] != null
              ? (json['difference_pct'] as num).toDouble()
              : null,
      thresholdPct:
          json['threshold_pct'] != null
              ? (json['threshold_pct'] as num).toDouble()
              : 35,
      thresholdAbs:
          json['threshold_abs'] != null
              ? (json['threshold_abs'] as num).toDouble()
              : 5,
      message: json['message'] as String?,
    );
  }

  bool get hasAlert => status == 'alert_high' || status == 'alert_low';
}

// =====================================================================
// Provider: BinderProvider
// =====================================================================

class BinderProvider extends ChangeNotifier {
  final ApiClient _api;

  BinderProvider({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // My Binder
  List<BinderItem> _items = [];
  BinderStats? _stats;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _currentFilter; // condition filter
  String? _currentSearch;
  bool? _filterForTrade;
  bool? _filterForSale;
  String? _currentListType; // 'have', 'want', or null (all)
  String? _currentSet;
  String? _currentRarity;
  String? _currentLanguage;
  bool? _filterFoil;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  int _binderFetchGeneration = 0;

  List<BinderItem> get items => _items;
  BinderStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Marketplace
  List<MarketplaceItem> _marketItems = [];
  bool _isLoadingMarket = false;
  String? _marketError;
  int _marketPage = 1;
  bool _hasMoreMarket = true;
  int _marketFetchGeneration = 0;

  List<MarketplaceItem> get marketItems => _marketItems;
  bool get isLoadingMarket => _isLoadingMarket;
  String? get marketError => _marketError;
  bool get hasMoreMarket => _hasMoreMarket;

  // Public binder (other user)
  List<BinderItem> _publicItems = [];
  bool _isLoadingPublic = false;
  String? _publicError;
  int _publicPage = 1;
  bool _hasMorePublic = true;
  Map<String, dynamic>? _publicOwner;
  int _publicFetchGeneration = 0;

  List<BinderItem> get publicItems => _publicItems;
  bool get isLoadingPublic => _isLoadingPublic;
  String? get publicError => _publicError;
  bool get hasMorePublic => _hasMorePublic;
  Map<String, dynamic>? get publicOwner => _publicOwner;

  // ---------------------------------------------------------------
  // My Binder — CRUD
  // ---------------------------------------------------------------

  /// Fetch my binder items (paginado, incremental)
  Future<void> fetchMyBinder({bool reset = false}) async {
    if (_isLoading && !reset) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      _page = 1;
      _items = [];
      _hasMore = true;
    }

    final generation = ++_binderFetchGeneration;
    final requestPage = _page;
    final requestListType = _currentListType;
    final requestFilter = _currentFilter;
    final requestSearch = _currentSearch;
    final requestForTrade = _filterForTrade;
    final requestForSale = _filterForSale;
    final requestSet = _currentSet;
    final requestRarity = _currentRarity;
    final requestLanguage = _currentLanguage;
    final requestFoil = _filterFoil;
    final requestSortBy = _sortBy;
    final requestSortOrder = _sortOrder;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var endpoint = '/binder?page=$requestPage&limit=20';
      if (requestListType != null) endpoint += '&list_type=$requestListType';
      if (requestFilter != null) endpoint += '&condition=$requestFilter';
      if (requestSearch != null && requestSearch.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(requestSearch)}';
      }
      if (requestForTrade == true) endpoint += '&for_trade=true';
      if (requestForSale == true) endpoint += '&for_sale=true';
      if (requestSet != null && requestSet.isNotEmpty) {
        endpoint += '&set=${Uri.encodeComponent(requestSet)}';
      }
      if (requestRarity != null) endpoint += '&rarity=$requestRarity';
      if (requestLanguage != null) endpoint += '&language=$requestLanguage';
      if (requestFoil != null) endpoint += '&foil=$requestFoil';
      endpoint += '&sort=$requestSortBy&order=$requestSortOrder';

      final res = await _api.get(endpoint);
      if (generation != _binderFetchGeneration) return;
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final list =
            (data['data'] as List<dynamic>? ?? [])
                .map((e) => BinderItem.fromJson(e as Map<String, dynamic>))
                .toList();
        _items.addAll(list);
        _hasMore = list.length >= 20;
        _page = requestPage + 1;
        _error = null;
      } else {
        _error = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.binder,
        );
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] fetchMyBinder: $e');
      _error = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.binder,
      );
    } finally {
      if (generation == _binderFetchGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Aplicar filtros e recarregar
  void applyFilters({
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
    String? listType,
    String? setCode,
    String? rarity,
    String? language,
    bool? foil,
    String? sortBy,
    String? sortOrder,
  }) {
    _currentFilter = condition;
    _currentSearch = search;
    _filterForTrade = forTrade;
    _filterForSale = forSale;
    _currentListType = listType;
    _currentSet = setCode;
    _currentRarity = rarity;
    _currentLanguage = language;
    _filterFoil = foil;
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    fetchMyBinder(reset: true);
  }

  /// Fetch stats
  Future<void> fetchStats() async {
    try {
      final res = await _api.get('/binder/stats');
      if (res.statusCode == 200 && res.data is Map) {
        final next = BinderStats.fromJson(res.data as Map<String, dynamic>);
        final current = _stats;
        final changed =
            current == null ||
            current.totalItems != next.totalItems ||
            current.uniqueCards != next.uniqueCards ||
            current.duplicateCopies != next.duplicateCopies ||
            current.forTradeCount != next.forTradeCount ||
            current.forSaleCount != next.forSaleCount ||
            current.estimatedValue != next.estimatedValue ||
            current.wishlistCount != next.wishlistCount ||
            current.missingCardsCount != next.missingCardsCount ||
            current.priceMissingCount != next.priceMissingCount ||
            current.cardsUsedInDecks != next.cardsUsedInDecks ||
            current.setProgress.length != next.setProgress.length ||
            current.wishlist.length != next.wishlist.length;

        if (changed) {
          _stats = next;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] fetchStats: $e');
    }
  }

  /// Adicionar carta ao binder
  Future<bool> addItem({
    required String cardId,
    int quantity = 1,
    String condition = 'NM',
    bool isFoil = false,
    bool forTrade = false,
    bool forSale = false,
    double? price,
    String? notes,
    String language = 'en',
    String listType = 'have',
  }) async {
    try {
      final body = <String, dynamic>{
        'card_id': cardId,
        'quantity': quantity,
        'condition': condition,
        'is_foil': isFoil,
        'for_trade': forTrade,
        'for_sale': forSale,
        'language': language,
        'list_type': listType,
        if (price != null) 'price': price,
        if (notes != null) 'notes': notes,
      };

      final res = await _api.post('/binder', body);
      if (res.statusCode == 201) {
        // Recarregar
        await fetchMyBinder(reset: true);
        await fetchStats();
        return true;
      } else {
        _error = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.binder,
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] addItem: $e');
      _error = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.binder,
      );
      notifyListeners();
      return false;
    }
  }

  /// Atualizar item do binder
  Future<bool> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final res = await _api.put('/binder/$itemId', updates);
      if (res.statusCode == 200) {
        // Atualizar local
        final idx = _items.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          final item = _items[idx];
          if (updates.containsKey('quantity')) {
            item.quantity = updates['quantity'] as int;
          }
          if (updates.containsKey('condition')) {
            item.condition = updates['condition'] as String;
          }
          if (updates.containsKey('is_foil')) {
            item.isFoil = updates['is_foil'] as bool;
          }
          if (updates.containsKey('for_trade')) {
            item.forTrade = updates['for_trade'] as bool;
          }
          if (updates.containsKey('for_sale')) {
            item.forSale = updates['for_sale'] as bool;
          }
          if (updates.containsKey('price')) {
            item.price =
                updates['price'] != null
                    ? (updates['price'] as num).toDouble()
                    : null;
          }
          if (updates.containsKey('notes')) {
            item.notes = updates['notes'] as String?;
          }
          if (updates.containsKey('language')) {
            item.language = updates['language'] as String? ?? 'en';
          }
          if (updates.containsKey('list_type')) {
            item.listType = updates['list_type'] as String? ?? 'have';
            if (_currentListType != null && item.listType != _currentListType) {
              _items.removeAt(idx);
            }
          }
          notifyListeners();
        }
        await fetchStats();
        return true;
      } else {
        _error = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.binder,
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] updateItem: $e');
      _error = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.binder,
      );
      notifyListeners();
      return false;
    }
  }

  /// Remover item do binder
  Future<bool> removeItem(String itemId) async {
    try {
      final res = await _api.delete('/binder/$itemId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        _items.removeWhere((i) => i.id == itemId);
        notifyListeners();
        await fetchStats();
        return true;
      } else {
        _error = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.binder,
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] removeItem: $e');
      _error = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.binder,
      );
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Direct fetch (for independent list views by list_type)
  // ---------------------------------------------------------------

  /// Fetches binder items directly without updating shared provider state.
  /// Returns a list of BinderItem or null on error.
  /// Used by _BinderListView to manage its own state independently.
  Future<List<BinderItem>?> fetchBinderDirect({
    required String listType,
    int page = 1,
    int limit = 20,
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
    String? setCode,
    String? rarity,
    String? language,
    bool? foil,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    try {
      var endpoint = '/binder?page=$page&limit=$limit&list_type=$listType';
      if (condition != null) endpoint += '&condition=$condition';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      if (forTrade == true) endpoint += '&for_trade=true';
      if (forSale == true) endpoint += '&for_sale=true';
      if (setCode != null && setCode.isNotEmpty) {
        endpoint += '&set=${Uri.encodeComponent(setCode)}';
      }
      if (rarity != null) endpoint += '&rarity=$rarity';
      if (language != null) endpoint += '&language=$language';
      if (foil != null) endpoint += '&foil=$foil';
      endpoint += '&sort=$sortBy&order=$sortOrder';

      final res = await _api.get(endpoint);
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        return (data['data'] as List<dynamic>? ?? [])
            .map((e) => BinderItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('[❌ BinderProvider] fetchBinderDirect($listType): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------
  // Public Binder Direct (for independent tabs by list_type)
  // ---------------------------------------------------------------

  /// Fetches a public user's binder items directly without updating shared state.
  /// Returns a list of BinderItem or null on error.
  Future<List<BinderItem>?> fetchPublicBinderDirect({
    required String userId,
    required String listType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/community/binders/$userId?page=$page&limit=$limit&list_type=$listType',
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        // Update owner if not set yet
        _publicOwner ??= data['owner'] as Map<String, dynamic>?;
        return (data['data'] as List<dynamic>? ?? [])
            .map((e) => BinderItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint(
        '[❌ BinderProvider] fetchPublicBinderDirect($userId, $listType): $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------
  // Public Binder (outro usuário)
  // ---------------------------------------------------------------

  Future<void> fetchPublicBinder(String userId, {bool reset = false}) async {
    if (_isLoadingPublic && !reset) return;
    if (!reset && !_hasMorePublic) return;

    if (reset) {
      _publicPage = 1;
      _publicItems = [];
      _hasMorePublic = true;
      _publicOwner = null;
    }

    final generation = ++_publicFetchGeneration;
    final requestPage = _publicPage;
    _isLoadingPublic = true;
    _publicError = null;
    notifyListeners();

    try {
      final res = await _api.get(
        '/community/binders/$userId?page=$requestPage&limit=20',
      );
      if (generation != _publicFetchGeneration) return;
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        _publicOwner = data['owner'] as Map<String, dynamic>?;
        final list =
            (data['data'] as List<dynamic>? ?? [])
                .map((e) => BinderItem.fromJson(e as Map<String, dynamic>))
                .toList();
        _publicItems.addAll(list);
        _hasMorePublic = list.length >= 20;
        _publicPage = requestPage + 1;
      } else {
        _publicError = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.binder,
        );
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] fetchPublicBinder: $e');
      _publicError = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.binder,
      );
    } finally {
      if (generation == _publicFetchGeneration) {
        _isLoadingPublic = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------
  // Marketplace (global)
  // ---------------------------------------------------------------

  Future<void> fetchMarketplace({
    String? search,
    String? condition,
    bool? forTrade,
    bool? forSale,
    bool reset = false,
  }) async {
    if (_isLoadingMarket && !reset) return;
    if (!reset && !_hasMoreMarket) return;

    if (reset) {
      _marketPage = 1;
      _marketItems = [];
      _hasMoreMarket = true;
    }

    final generation = ++_marketFetchGeneration;
    final requestPage = _marketPage;
    _isLoadingMarket = true;
    _marketError = null;
    notifyListeners();

    try {
      var endpoint = '/community/marketplace?page=$requestPage&limit=20';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      if (condition != null) endpoint += '&condition=$condition';
      if (forTrade == true) endpoint += '&for_trade=true';
      if (forSale == true) endpoint += '&for_sale=true';

      final res = await _api.get(endpoint);
      if (generation != _marketFetchGeneration) return;
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final list =
            (data['data'] as List<dynamic>? ?? [])
                .map((e) => MarketplaceItem.fromJson(e as Map<String, dynamic>))
                .toList();
        _marketItems.addAll(list);
        _hasMoreMarket = list.length >= 20;
        _marketPage = requestPage + 1;
      } else {
        _marketError = FriendlyErrorMapper.fromApiResponse(
          res,
          context: FriendlyErrorContext.marketplace,
        );
      }
    } catch (e) {
      debugPrint('[❌ BinderProvider] fetchMarketplace: $e');
      _marketError = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.marketplace,
      );
    } finally {
      if (generation == _marketFetchGeneration) {
        _isLoadingMarket = false;
        notifyListeners();
      }
    }
  }

  /// Limpa todo o estado do provider (chamado no logout)
  void clearAllState() {
    _binderFetchGeneration++;
    _marketFetchGeneration++;
    _publicFetchGeneration++;
    if (_items.isEmpty &&
        _stats == null &&
        !_isLoading &&
        _error == null &&
        _page == 1 &&
        _hasMore &&
        _currentFilter == null &&
        _currentSearch == null &&
        _filterForTrade == null &&
        _filterForSale == null &&
        _currentListType == null &&
        _currentSet == null &&
        _currentRarity == null &&
        _currentLanguage == null &&
        _filterFoil == null &&
        _sortBy == 'name' &&
        _sortOrder == 'asc' &&
        _marketItems.isEmpty &&
        !_isLoadingMarket &&
        _marketError == null &&
        _marketPage == 1 &&
        _hasMoreMarket &&
        _publicItems.isEmpty &&
        !_isLoadingPublic &&
        _publicError == null &&
        _publicPage == 1 &&
        _hasMorePublic &&
        _publicOwner == null) {
      return;
    }

    _items = [];
    _stats = null;
    _isLoading = false;
    _error = null;
    _page = 1;
    _hasMore = true;
    _currentFilter = null;
    _currentSearch = null;
    _filterForTrade = null;
    _filterForSale = null;
    _currentListType = null;
    _currentSet = null;
    _currentRarity = null;
    _currentLanguage = null;
    _filterFoil = null;
    _sortBy = 'name';
    _sortOrder = 'asc';
    _marketItems = [];
    _isLoadingMarket = false;
    _marketError = null;
    _marketPage = 1;
    _hasMoreMarket = true;
    _publicItems = [];
    _isLoadingPublic = false;
    _publicError = null;
    _publicPage = 1;
    _hasMorePublic = true;
    _publicOwner = null;
    notifyListeners();
  }
}
