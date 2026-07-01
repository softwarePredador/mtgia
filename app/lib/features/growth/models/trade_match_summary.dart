import '../../binder/providers/binder_provider.dart';

class TradeMatchSummary {
  final int wishlistCards;
  final int missingCards;
  final int cardsForTrade;
  final int duplicateCopies;

  const TradeMatchSummary({
    required this.wishlistCards,
    required this.missingCards,
    required this.cardsForTrade,
    required this.duplicateCopies,
  });

  factory TradeMatchSummary.fromBinderStats(BinderStats stats) {
    return TradeMatchSummary(
      wishlistCards: stats.wishlistUniqueCards,
      missingCards: stats.missingCardsCount,
      cardsForTrade: stats.forTradeCount,
      duplicateCopies: stats.duplicateCopies,
    );
  }

  int get tradePotentialScore {
    final score = cardsForTrade + duplicateCopies + missingCards;
    return score.clamp(0, 999);
  }

  bool get hasTradeLoop =>
      wishlistCards > 0 || missingCards > 0 || cardsForTrade > 0;

  String get primaryInsight {
    if (!hasTradeLoop) {
      return 'Cadastre want list e cartas para troca para ativar matches.';
    }
    if (missingCards > 0 && cardsForTrade > 0) {
      return 'Você já tem cartas faltantes e cartas para oferecer em troca.';
    }
    if (missingCards > 0) {
      return 'Sua want list já pode encontrar fichários públicos compatíveis.';
    }
    return 'Suas cartas para troca podem completar decks de outros jogadores.';
  }
}
