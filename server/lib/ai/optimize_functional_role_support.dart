import '../basic_land_utils.dart' as basic_lands;
import 'optimization_functional_roles.dart';
import 'optimization_ramp_profile.dart';

const commanderFunctionalRoleFloorPolicyVersion =
    'commander_functional_role_floors_v2';
const commanderCriticalFunctionalRoleNames = <String>{
  'ramp',
  'draw',
  'interaction',
  'wipe',
};

bool hasCompleteCommanderFunctionalRoleFloorMap(Map<String, int> counts) {
  return counts.keys.toSet().containsAll(commanderCriticalFunctionalRoleNames);
}

bool hasCanonicalCommanderFunctionalRoleMinimumCounts({
  required Map<String, int> counts,
  required String targetArchetype,
  required int bracket,
}) {
  if (bracket < 1 || bracket > 5) return false;
  final expected = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: bracket,
  );
  if (counts.length != expected.length) return false;
  return expected.entries.every((entry) => counts[entry.key] == entry.value);
}

class CommanderFunctionalRoleFloorAssessment {
  const CommanderFunctionalRoleFloorAssessment({
    required this.archetype,
    required this.totalCards,
    required this.minimumCounts,
    required this.actualCounts,
    this.bracket,
  });

  final String archetype;
  final int totalCards;
  final Map<String, int> minimumCounts;
  final Map<String, int> actualCounts;
  final int? bracket;

  bool get applies => totalCards >= 90;

  Map<String, int> get deficits => {
    for (final entry in minimumCounts.entries)
      if ((actualCounts[entry.key] ?? 0) < entry.value)
        entry.key: entry.value - (actualCounts[entry.key] ?? 0),
  };

  bool get satisfied => !applies || deficits.isEmpty;

  Map<String, dynamic> toJson() => {
    'policy': commanderFunctionalRoleFloorPolicyVersion,
    'archetype': archetype,
    if (bracket != null) 'bracket': bracket,
    'applies': applies,
    'total_cards': totalCards,
    'minimum_counts': minimumCounts,
    'actual_counts': actualCounts,
    'deficits': deficits,
    'satisfied': satisfied,
  };
}

const _commanderCriticalRoleFloorOrder = <String>[
  'ramp',
  'draw',
  'interaction',
  'wipe',
];

const _minimumCommanderStructuralRamp = 8;
const _minimumCommanderStructuralDraw = 8;
const _minimumCommanderStructuralInteraction = 6;

Map<String, int> commanderFunctionalRoleMinimumCounts({
  required String targetArchetype,
  int? bracket,
}) {
  final normalizedBracket = bracket?.clamp(1, 5).toInt();
  return Map<String, int>.unmodifiable({
    'ramp': _minimumCommanderStructuralRamp,
    'draw': _minimumCommanderStructuralDraw,
    'interaction': _minimumCommanderStructuralInteraction,
    'wipe': minimumCommanderWipeCountForArchetype(
      targetArchetype,
      bracket: normalizedBracket,
    ),
  });
}

int minimumCommanderWipeCountForArchetype(
  String targetArchetype, {
  int? bracket,
}) {
  final archetype = targetArchetype.trim().toLowerCase();
  final archetypeMinimum =
      archetype.contains('control')
          ? 3
          : archetype.contains('aggro')
          ? 1
          : 2;
  final normalizedBracket = bracket?.clamp(1, 5).toInt();
  if (normalizedBracket == 5) return 0;
  if (normalizedBracket == 4) {
    return archetypeMinimum > 1 ? 1 : archetypeMinimum;
  }
  return archetypeMinimum;
}

int countOptimizationFunctionalRole(
  Iterable<Map<String, dynamic>> cards, {
  required String role,
}) {
  final normalizedRole = _normalizeCriticalRole(role);
  var count = 0;
  for (final card in cards) {
    final quantity = _positiveOptimizationCardQuantity(card['quantity']);
    if (quantity <= 0 ||
        !_cardCountsTowardOptimizationFunctionalRole(
          card,
          role: normalizedRole,
        )) {
      continue;
    }
    if (quantity > 0) count += quantity;
  }
  return count;
}

CommanderFunctionalRoleFloorAssessment assessCommanderFunctionalRoleFloors({
  required Iterable<Map<String, dynamic>> cards,
  required String targetArchetype,
  int? bracket,
}) {
  final materialized = cards.toList(growable: false);
  final totalCards = materialized.fold<int>(0, (sum, card) {
    final quantity = _positiveOptimizationCardQuantity(card['quantity']);
    return sum + (quantity > 0 ? quantity : 0);
  });
  final normalizedBracket = bracket?.clamp(1, 5).toInt();
  final minimumCounts = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: normalizedBracket,
  );
  return CommanderFunctionalRoleFloorAssessment(
    archetype: targetArchetype.trim().toLowerCase(),
    bracket: normalizedBracket,
    totalCards: totalCards,
    minimumCounts: minimumCounts,
    actualCounts: {
      for (final role in minimumCounts.keys)
        role: countOptimizationFunctionalRole(materialized, role: role),
    },
  );
}

List<String> buildCommanderCriticalRoleFloorNeeds({
  required Iterable<Map<String, dynamic>> cards,
  required String targetArchetype,
  required int limit,
  int? bracket,
}) {
  if (limit <= 0) return const [];
  final assessment = assessCommanderFunctionalRoleFloors(
    cards: cards,
    targetArchetype: targetArchetype,
    bracket: bracket,
  );
  final orderedRoles = <String>[
    ..._commanderCriticalRoleFloorOrder,
    ...assessment.deficits.keys
      .where((role) => !_commanderCriticalRoleFloorOrder.contains(role))
      .toList(growable: false)..sort(),
  ];
  final needs = <String>[];
  for (final role in orderedRoles) {
    final deficit = assessment.deficits[role] ?? 0;
    final remaining = limit - needs.length;
    if (deficit <= 0 || remaining <= 0) continue;
    final count = deficit < remaining ? deficit : remaining;
    needs.addAll(List<String>.filled(count, role));
  }
  return List<String>.unmodifiable(needs);
}

bool _cardCountsTowardOptimizationFunctionalRole(
  Map<String, dynamic> card, {
  required String role,
}) {
  if (role == 'ramp') {
    return optimizationRampProfileForCard(card).countsTowardGenericFloor;
  }
  if (role == 'wipe') {
    return looksLikeBoardWipe(card['oracle_text']?.toString() ?? '');
  }

  final roles =
      optimizationFunctionalRolesForCard(
        card,
      ).map(_normalizeCriticalRole).toSet();

  return switch (role) {
    'draw' =>
      roles.contains('draw') ||
          roles.contains('loot') ||
          roles.contains('exile_value') ||
          roles.contains('card_advantage'),
    'interaction' =>
      roles.contains('interaction') ||
          roles.contains('counterspell') ||
          roles.contains('removal'),
    _ => roles.contains(role),
  };
}

String _normalizeCriticalRole(String value) {
  return switch (value.trim().toLowerCase()) {
    'board_wipe' => 'wipe',
    _ => value.trim().toLowerCase(),
  };
}

int _positiveOptimizationCardQuantity(Object? raw) {
  final quantity = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()) ?? 1,
    _ => 1,
  };
  return quantity > 0 ? quantity : 0;
}

String inferFunctionalRole({
  required String name,
  required String typeLine,
  required String oracleText,
  Object? functionalTags,
  Object? semanticTagsV2,
  String? manaCost,
  Object? cmc,
}) {
  // A função de reset é estrutural e pode coexistir com compra/ramp. Ela deve
  // continuar visível mesmo quando tags persistidas parciais omitem "wipe".
  if (looksLikeBoardWipe(oracleText)) {
    return 'wipe';
  }

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
  final rampProfile = classifyOptimizationRampProfile(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
    manaCost: manaCost,
    cmc: cmc,
  );

  final isRampByText =
      o.contains('add {') ||
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

  // Keep the player-facing role inclusive without changing the legacy
  // priority of explicit draw/removal/interaction labels. Generic floor
  // decisions use the narrower profile explicitly at their call sites.
  if (rampProfile.isAcceleration) return 'ramp';

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
  if (roles.contains('wipe') || roles.contains('board_wipe')) return 'wipe';
  if (roles.contains('ramp') || roles.contains('ritual')) return 'ramp';
  if (roles.contains('draw') ||
      roles.contains('loot') ||
      roles.contains('exile_value'))
    return 'draw';
  if (roles.contains('removal')) return 'removal';
  if (roles.contains('interaction') ||
      roles.contains('counterspell') ||
      roles.contains('protection'))
    return 'interaction';
  if (roles.contains('wincon') ||
      roles.contains('combo_piece') ||
      roles.contains('alt_win'))
    return 'wincon';
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
      roles.contains('creature'))
    return 'engine';
  return 'utility';
}

bool looksLikeBoardWipe(String oracleText) {
  return looksLikeOptimizationBoardWipeText(oracleText);
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
  final rampProfile = classifyOptimizationRampProfile(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
  );

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
      !basic_lands.isLandTypeLine(normalizedType)) {
    return oracle.contains('land') ? 'ramp' : 'tutor';
  }

  if ((rampProfile.isAcceleration ||
          looksLikeTemporaryManaBurst(
            name: name,
            typeLine: typeLine,
            oracleText: oracleText,
          ) ||
          oracle.contains('add {') ||
          oracle.contains('add one mana')) &&
      !basic_lands.isLandTypeLine(normalizedType)) {
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
  String name = '',
  String? manaCost,
  Object? cmc,
}) {
  final oracle = oracleText.toLowerCase();
  final type = typeLine.toLowerCase();

  return switch (need) {
    'draw' => oracle.contains('draw') || oracle.contains('cards'),
    'removal' =>
      oracle.contains('destroy') ||
          oracle.contains('exile') ||
          oracle.contains('counter'),
    'wipe' => looksLikeBoardWipe(oracleText),
    'ramp' =>
      classifyOptimizationRampProfile(
        name: name,
        typeLine: typeLine,
        oracleText: oracleText,
        manaCost: manaCost,
        cmc: cmc,
      ).countsTowardGenericFloor,
    'tutor' =>
      oracle.contains('search your library') && !oracle.contains('land'),
    'protection' =>
      oracle.contains('hexproof') ||
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
    name: cardName,
    oracleText: oracleText,
    typeLine: typeLine,
    manaCost: manaCost,
    cmc: estimatedCmc,
  );
  final needScore = matchesNeed ? 160 : (functionalNeed == 'utility' ? 40 : 0);
  final preferredScore = preferredNames.contains(normalizedName) ? 120 : 0;
  final popularityScore = (popScore ~/ 10).clamp(0, 90);
  final rejectionPenalty = ((rejectedAdditionCounts[normalizedName] ?? 0) * 35)
      .clamp(0, 175);
  final protectionBonus =
      functionalNeed == 'protection' && normalizedOracle.contains('free')
          ? 15
          : 0;
  final offNeedPenalty = !matchesNeed && functionalNeed != 'utility' ? 90 : 0;
  final landPenalty = basic_lands.isLandTypeLine(normalizedType) ? 220 : 0;
  final temporaryManaPenalty =
      looksLikeTemporaryManaBurst(
            name: cardName,
            typeLine: typeLine,
            oracleText: oracleText,
          )
          ? (functionalNeed == 'ramp' ? 70 : 160)
          : 0;
  final lowCurveBonus =
      preferLowCurve
          ? ((4 - estimatedCmc).clamp(0, 4) * 18).round()
          : ((3 - estimatedCmc).clamp(0, 3) * 6).round();
  final expensiveSpellPenalty =
      preferLowCurve && estimatedCmc > 4
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
