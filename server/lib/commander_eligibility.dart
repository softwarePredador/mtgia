bool isCommanderStyleFormat(String format) {
  final normalizedFormat = format.toLowerCase();
  return normalizedFormat == 'commander' || normalizedFormat == 'brawl';
}

bool isCommanderEligibleCard({
  required String typeLine,
  String? oracleText,
  String? power,
  String? toughness,
  String format = 'commander',
}) {
  final normalizedTypeLine = typeLine.toLowerCase();
  final normalizedOracle = (oracleText ?? '').toLowerCase();
  final normalizedFormat = format.toLowerCase();

  final isLegendary = normalizedTypeLine.contains('legendary');
  final isCreature = normalizedTypeLine.contains('creature');
  if (isLegendary && isCreature) return true;

  if (normalizedFormat == 'brawl' &&
      isLegendary &&
      normalizedTypeLine.contains('planeswalker')) {
    return true;
  }

  final isVehicleOrSpacecraft = normalizedTypeLine.contains('vehicle') ||
      normalizedTypeLine.contains('spacecraft');
  final hasPowerToughnessBox =
      (power ?? '').trim().isNotEmpty && (toughness ?? '').trim().isNotEmpty;
  if (isLegendary && isVehicleOrSpacecraft && hasPowerToughnessBox) {
    return true;
  }

  return normalizedOracle.contains('can be your commander');
}
