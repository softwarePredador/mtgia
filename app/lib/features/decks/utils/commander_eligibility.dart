import '../models/deck_card_item.dart';

bool isCommanderStyleDeckFormat(String format) {
  final normalized = format.trim().toLowerCase();
  return normalized == 'commander' || normalized == 'brawl';
}

/// Fast client-side eligibility check for commander selection.
///
/// The backend remains authoritative for format legality, partner/background
/// pairing, quantity, and color identity. Keep this shape aligned with
/// `server/lib/commander_eligibility.dart`.
bool isPotentialCommander(DeckCardItem card, {required String format}) {
  final normalizedTypeLine = card.typeLine.toLowerCase();
  final normalizedOracle = (card.oracleText ?? '').toLowerCase();
  final normalizedFormat = format.trim().toLowerCase();

  final isLegendary = normalizedTypeLine.contains('legendary');
  final isCreature = normalizedTypeLine.contains('creature');
  if (isLegendary && isCreature) return true;

  if (normalizedFormat == 'brawl' &&
      isLegendary &&
      normalizedTypeLine.contains('planeswalker')) {
    return true;
  }

  final isVehicleOrSpacecraft =
      normalizedTypeLine.contains('vehicle') ||
      normalizedTypeLine.contains('spacecraft');
  final hasPowerToughnessBox =
      (card.power ?? '').trim().isNotEmpty &&
      (card.toughness ?? '').trim().isNotEmpty;
  if (isLegendary && isVehicleOrSpacecraft && hasPowerToughnessBox) {
    return true;
  }

  return normalizedOracle.contains('can be your commander');
}
