bool isCommanderStyleFormat(String format) {
  final normalizedFormat = format.trim().toLowerCase();
  return normalizedFormat == 'commander' || normalizedFormat == 'brawl';
}

String? normalizeCommanderCandidateFormat(String? format) {
  final normalizedFormat = format?.trim().toLowerCase();
  if (normalizedFormat == null || normalizedFormat.isEmpty) return null;
  return isCommanderStyleFormat(normalizedFormat) ? normalizedFormat : null;
}

/// SQL predicate kept deliberately aligned with [isCommanderEligibleCard].
///
/// The caller controls [tableAlias]; it must be an internal SQL identifier,
/// never a request value. Format is normalized to the two supported values.
String commanderEligibilitySql({
  required String format,
  String tableAlias = 'c',
}) {
  final normalizedFormat = normalizeCommanderCandidateFormat(format);
  if (normalizedFormat == null) {
    throw ArgumentError.value(format, 'format', 'Use commander or brawl.');
  }
  if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(tableAlias)) {
    throw ArgumentError.value(tableAlias, 'tableAlias', 'Invalid SQL alias.');
  }

  final typeLine = "LOWER(COALESCE($tableAlias.type_line, ''))";
  final oracleText = "LOWER(COALESCE($tableAlias.oracle_text, ''))";
  final legendaryCreature =
      "($typeLine LIKE '%legendary%' AND $typeLine LIKE '%creature%')";
  final brawlPlaneswalker =
      normalizedFormat == 'brawl'
          ? " OR ($typeLine LIKE '%legendary%'"
              " AND $typeLine LIKE '%planeswalker%')"
          : '';
  final legendaryVehicleOrSpacecraft =
      " OR ($typeLine LIKE '%legendary%'"
      " AND ($typeLine LIKE '%vehicle%' OR $typeLine LIKE '%spacecraft%')"
      " AND NULLIF(BTRIM($tableAlias.power), '') IS NOT NULL"
      " AND NULLIF(BTRIM($tableAlias.toughness), '') IS NOT NULL)";
  final explicitCommander = " OR $oracleText LIKE '%can be your commander%'";

  return '($legendaryCreature'
      '$brawlPlaneswalker'
      '$legendaryVehicleOrSpacecraft'
      '$explicitCommander)';
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

  final isVehicleOrSpacecraft =
      normalizedTypeLine.contains('vehicle') ||
      normalizedTypeLine.contains('spacecraft');
  final hasPowerToughnessBox =
      (power ?? '').trim().isNotEmpty && (toughness ?? '').trim().isNotEmpty;
  if (isLegendary && isVehicleOrSpacecraft && hasPowerToughnessBox) {
    return true;
  }

  return normalizedOracle.contains('can be your commander');
}
