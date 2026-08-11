/// Public product identity shared by customer-facing Flutter surfaces.
///
/// Internal package names, storage keys, API contracts and bridge identifiers
/// intentionally remain under their legacy `manaloom` names so existing
/// installations keep their data and integrations intact.
abstract final class ProductIdentity {
  static const String displayName = 'BrewTact';
  static const String taglinePtBr = 'Monte melhor. Jogue melhor.';
  static const String taglineEn = 'Build smarter. Play better.';

  static const String descriptionPtBr =
      'Monte, analise, teste e acompanhe seus decks de Magic.';
  static const String descriptionEn =
      'Build, analyze, test, and track your Magic decks.';

  static const String appTitle = '$displayName — MTG Deck Builder';
  static const String proDisplayName = '$displayName Pro';
  static const String lifeCounterDisplayName = '$displayName Life Counter';
  static const String lifeCounterTitlePtBr = '$displayName • Contador de vida';
}
