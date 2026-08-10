const String marketplaceRouteLocation = '/collection?tab=1';
const String wishlistRouteLocation = '/collection?tab=0&list=want';
const String quotesRouteLocation = '/community?tab=3';

const Set<String> supportedTradeProposalTypes = {'trade', 'sale', 'mixed'};

const Set<String> supportedTradeProposalSources = {
  'marketplace',
  'deck_missing',
  'wishlist',
  'profile',
  'trade_match',
  'counter',
};

String normalizeTradeProposalType(String? value) {
  final normalized = value?.trim().toLowerCase();
  return supportedTradeProposalTypes.contains(normalized)
      ? normalized!
      : 'trade';
}

String? normalizeTradeProposalSource(String? value) {
  final normalized = value?.trim().toLowerCase();
  return supportedTradeProposalSources.contains(normalized) ? normalized : null;
}

String tradeMatchesRouteLocation({String? deckId}) {
  final normalizedDeckId = deckId?.trim();
  return Uri(
    path: '/collection/matches',
    queryParameters: normalizedDeckId == null || normalizedDeckId.isEmpty
        ? null
        : {'deck': normalizedDeckId},
  ).toString();
}

String createTradeRouteLocation({
  required String receiverId,
  String? binderItemId,
  required String type,
  String? source,
  String? deckId,
  String? counterTradeId,
}) {
  final normalizedReceiverId = receiverId.trim();
  final normalizedBinderItemId = binderItemId?.trim();
  final normalizedDeckId = deckId?.trim();
  final normalizedCounterTradeId = counterTradeId?.trim();
  final normalizedSource = normalizeTradeProposalSource(source);

  return Uri(
    path: '/trades/create/${Uri.encodeComponent(normalizedReceiverId)}',
    queryParameters: {
      if (normalizedBinderItemId != null && normalizedBinderItemId.isNotEmpty)
        'item': normalizedBinderItemId,
      'type': normalizeTradeProposalType(type),
      if (normalizedSource != null) 'source': normalizedSource,
      if (normalizedDeckId != null && normalizedDeckId.isNotEmpty)
        'deck': normalizedDeckId,
      if (normalizedCounterTradeId != null &&
          normalizedCounterTradeId.isNotEmpty)
        'counter': normalizedCounterTradeId,
    },
  ).toString();
}

class TradeProposalDeepLink {
  const TradeProposalDeepLink({
    required this.type,
    this.binderItemId,
    this.source,
    this.deckId,
    this.counterTradeId,
  });

  final String type;
  final String? binderItemId;
  final String? source;
  final String? deckId;
  final String? counterTradeId;

  factory TradeProposalDeepLink.fromUri(Uri uri) {
    final binderItemId = uri.queryParameters['item']?.trim();
    final deckId = uri.queryParameters['deck']?.trim();
    final counterTradeId = uri.queryParameters['counter']?.trim();
    return TradeProposalDeepLink(
      type: normalizeTradeProposalType(uri.queryParameters['type']),
      binderItemId: binderItemId == null || binderItemId.isEmpty
          ? null
          : binderItemId,
      source: normalizeTradeProposalSource(uri.queryParameters['source']),
      deckId: deckId == null || deckId.isEmpty ? null : deckId,
      counterTradeId: counterTradeId == null || counterTradeId.isEmpty
          ? null
          : counterTradeId,
    );
  }
}
