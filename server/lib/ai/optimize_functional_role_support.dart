import 'optimization_functional_roles.dart';

String inferFunctionalRole({
  required String name,
  required String typeLine,
  required String oracleText,
  Object? functionalTags,
  Object? semanticTagsV2,
  String? manaCost,
  Object? cmc,
}) {
  if (functionalTags != null || semanticTagsV2 != null) {
    final resolved = resolveCardFunctionalRoles(
      functionalTags: functionalTags,
      semanticTagsV2: semanticTagsV2,
      oracleText: oracleText,
      typeLine: typeLine,
      name: name,
      manaCost: manaCost,
      cmc: cmc,
    );
    if (resolved.isNotEmpty && resolved.source != 'heuristic') {
      return _legacyOptimizeRoleForResolvedRoles(resolved.roles);
    }
  }

  final n = name.toLowerCase();
  final t = typeLine.toLowerCase();
  final o = oracleText.toLowerCase();

  final isRampByText = o.contains('add {') ||
      o.contains('add one mana') ||
      o.contains('search your library for a basic land') ||
      o.contains('search your library for a land');
  final isRampByName =
      n.contains('signet') || n.contains('talisman') || n.contains('sol ring');
  if (isRampByText || isRampByName) return 'ramp';

  if (o.contains('draw a card') ||
      o.contains('draw two cards') ||
      o.contains('draw three cards')) {
    return 'draw';
  }

  if ((o.contains('destroy target') || o.contains('exile target')) &&
      (o.contains('creature') ||
          o.contains('artifact') ||
          o.contains('enchantment') ||
          o.contains('permanent'))) {
    return 'removal';
  }

  if (o.contains('counter target') || o.contains('counterspell')) {
    return 'interaction';
  }

  if (o.contains('you win the game') || o.contains('each opponent loses')) {
    return 'wincon';
  }

  if (o.contains('whenever') ||
      o.contains('at the beginning of') ||
      o.contains('sacrifice')) {
    return 'engine';
  }

  if (t.contains('creature')) return 'engine';
  return 'utility';
}

String inferFunctionalRoleForCard(Map<String, dynamic> card) {
  return inferFunctionalRole(
    name: (card['name'] as String?) ?? '',
    typeLine: (card['type_line'] as String?) ?? '',
    oracleText: (card['oracle_text'] as String?) ?? '',
    functionalTags: card['functional_tags'],
    semanticTagsV2: card['semantic_tags_v2'],
    manaCost: card['mana_cost']?.toString(),
    cmc: card['cmc'],
  );
}

String _legacyOptimizeRoleForResolvedRoles(Set<String> roles) {
  if (roles.contains('ramp') || roles.contains('ritual')) return 'ramp';
  if (roles.contains('draw') ||
      roles.contains('loot') ||
      roles.contains('exile_value')) return 'draw';
  if (roles.contains('removal') ||
      roles.contains('wipe') ||
      roles.contains('board_wipe')) return 'removal';
  if (roles.contains('interaction') ||
      roles.contains('counterspell') ||
      roles.contains('protection')) return 'interaction';
  if (roles.contains('wincon') ||
      roles.contains('combo_piece') ||
      roles.contains('alt_win')) return 'wincon';
  if (roles.contains('engine') ||
      roles.contains('payoff') ||
      roles.contains('enabler') ||
      roles.contains('etb') ||
      roles.contains('blink') ||
      roles.contains('token_maker') ||
      roles.contains('sacrifice_outlet') ||
      roles.contains('graveyard_synergy') ||
      roles.contains('artifact_synergy') ||
      roles.contains('enchantment_synergy') ||
      roles.contains('spellslinger') ||
      roles.contains('aristocrat_payoff') ||
      roles.contains('creature')) return 'engine';
  return 'utility';
}

bool looksLikeBoardWipe(String oracleText) {
  final oracle = oracleText.toLowerCase();
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('each creature') ||
      oracle.contains('each player sacrifices') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('all creatures get');
}

bool looksLikeProtectionEffect({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedName = name.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();

  return normalizedName.contains('greaves') ||
      normalizedName.contains('boots') ||
      oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('ward') ||
      oracle.contains('phase out') ||
      oracle.contains('phases out') ||
      oracle.contains('gains shroud') ||
      (normalizedType.contains('equipment') &&
          (oracle.contains('equipped creature has') ||
              oracle.contains('equip')));
}

bool looksLikeTemporaryManaBurst({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedName = name.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();
  final generatesMana =
      oracle.contains('add {') || oracle.contains('add one mana');

  if (!generatesMana) return false;
  if (!(normalizedType.contains('instant') ||
      normalizedType.contains('sorcery'))) {
    return false;
  }

  return normalizedName.contains('ritual') ||
      oracle.contains('until end of turn') ||
      oracle.contains('for each');
}

String inferOptimizeFunctionalNeed({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final normalizedType = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();

  if (looksLikeProtectionEffect(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
  )) {
    return 'protection';
  }

  if (looksLikeBoardWipe(oracleText)) {
    return 'wipe';
  }

  if (oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('counter target')) {
    return 'removal';
  }

  if (oracle.contains('draw') || oracle.contains('cards')) {
    return 'draw';
  }

  if (oracle.contains('search your library') &&
      !normalizedType.contains('land')) {
    return oracle.contains('land') ? 'ramp' : 'tutor';
  }

  if ((looksLikeTemporaryManaBurst(
            name: name,
            typeLine: typeLine,
            oracleText: oracleText,
          ) ||
          oracle.contains('add {') ||
          oracle.contains('add one mana')) &&
      !normalizedType.contains('land')) {
    return 'ramp';
  }

  if (normalizedType.contains('artifact')) return 'artifact';
  if (normalizedType.contains('creature')) return 'creature';

  return 'utility';
}

bool matchesFunctionalNeed(
  String need, {
  required String oracleText,
  required String typeLine,
}) {
  final oracle = oracleText.toLowerCase();
  final type = typeLine.toLowerCase();

  return switch (need) {
    'draw' => oracle.contains('draw') || oracle.contains('cards'),
    'removal' => oracle.contains('destroy') ||
        oracle.contains('exile') ||
        oracle.contains('counter'),
    'wipe' => looksLikeBoardWipe(oracleText),
    'ramp' => (oracle.contains('add') && oracle.contains('mana')) ||
        oracle.contains('search your library for a land'),
    'tutor' =>
      oracle.contains('search your library') && !oracle.contains('land'),
    'protection' => oracle.contains('hexproof') ||
        oracle.contains('indestructible') ||
        oracle.contains('ward') ||
        oracle.contains('phase out') ||
        oracle.contains('phases out'),
    'creature' => type.contains('creature'),
    'artifact' => type.contains('artifact'),
    _ => true,
  };
}

int scoreOptimizeReplacementCandidate({
  required String functionalNeed,
  required String cardName,
  required String typeLine,
  required String oracleText,
  required String manaCost,
  required int popScore,
  required Set<String> preferredNames,
  required Map<String, int> rejectedAdditionCounts,
  bool preferLowCurve = false,
}) {
  final normalizedName = cardName.trim().toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final normalizedOracle = oracleText.toLowerCase();
  final estimatedCmc = _estimateManaCostCmc(manaCost);
  final matchesNeed = matchesFunctionalNeed(
    functionalNeed,
    oracleText: oracleText,
    typeLine: typeLine,
  );
  final needScore = matchesNeed ? 160 : (functionalNeed == 'utility' ? 40 : 0);
  final preferredScore = preferredNames.contains(normalizedName) ? 120 : 0;
  final popularityScore = (popScore ~/ 10).clamp(0, 90);
  final rejectionPenalty =
      ((rejectedAdditionCounts[normalizedName] ?? 0) * 35).clamp(0, 175);
  final protectionBonus =
      functionalNeed == 'protection' && normalizedOracle.contains('free')
          ? 15
          : 0;
  final offNeedPenalty = !matchesNeed && functionalNeed != 'utility' ? 90 : 0;
  final landPenalty = normalizedType.contains('land') ? 220 : 0;
  final temporaryManaPenalty = looksLikeTemporaryManaBurst(
    name: cardName,
    typeLine: typeLine,
    oracleText: oracleText,
  )
      ? (functionalNeed == 'ramp' ? 70 : 160)
      : 0;
  final lowCurveBonus = preferLowCurve
      ? ((4 - estimatedCmc).clamp(0, 4) * 18).round()
      : ((3 - estimatedCmc).clamp(0, 3) * 6).round();
  final expensiveSpellPenalty = preferLowCurve && estimatedCmc > 4
      ? ((estimatedCmc - 4) * 20).round()
      : 0;

  return needScore +
      preferredScore +
      popularityScore +
      protectionBonus +
      lowCurveBonus -
      rejectionPenalty -
      offNeedPenalty -
      landPenalty -
      temporaryManaPenalty -
      expensiveSpellPenalty;
}

double _estimateManaCostCmc(String manaCost) {
  if (manaCost.trim().isEmpty) return 0;

  final matches = RegExp(r'\{([^}]+)\}').allMatches(manaCost);
  var total = 0.0;

  for (final match in matches) {
    final symbol = (match.group(1) ?? '').trim().toUpperCase();
    if (symbol.isEmpty || symbol == 'X') continue;
    final numeric = int.tryParse(symbol);
    if (numeric != null) {
      total += numeric;
      continue;
    }
    total += 1;
  }

  return total;
}
