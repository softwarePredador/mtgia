bool isCommanderEligibleCard({
  required String typeLine,
  String? oracleText,
  String? power,
  String? toughness,
}) {
  final normalizedTypeLine = typeLine.toLowerCase();
  final normalizedOracle = (oracleText ?? '').toLowerCase();

  final isLegendary = normalizedTypeLine.contains('legendary');
  final isCreature = normalizedTypeLine.contains('creature');
  if (isLegendary && isCreature) return true;

  final isVehicleOrSpacecraft = normalizedTypeLine.contains('vehicle') ||
      normalizedTypeLine.contains('spacecraft');
  final hasPowerToughnessBox =
      (power ?? '').trim().isNotEmpty && (toughness ?? '').trim().isNotEmpty;
  if (isLegendary && isVehicleOrSpacecraft && hasPowerToughnessBox) {
    return true;
  }

  return normalizedOracle.contains('can be your commander');
}
