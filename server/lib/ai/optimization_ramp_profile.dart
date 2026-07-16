import '../basic_land_utils.dart' as land_utils;
import 'optimization_functional_roles.dart';

const optimizationRampProfileSchemaVersion =
    'optimization_ramp_profile_v1_2026_07_16';

/// A narrower acceleration contract layered on top of the inclusive `ramp`
/// role.
///
/// The player-facing role may continue to describe cost reducers, rituals,
/// Treasure engines, and other contextual acceleration as ramp. Generic deck
/// construction floors need a stricter signal: a reusable nonland mana source
/// or an effect that advances land development for its controller.
enum OptimizationRampProfileKind {
  none,
  landManaBase,
  manaRock,
  manaDork,
  landToBattlefield,
  extraLand,
  manaFixingOnly,
  costReduction,
  ritual,
  consumableMana,
  landUntap,
  treasureCreation,
  treasureMultiplier,
  manaMultiplier,
  conditionalMana,
}

extension OptimizationRampProfileKindWire on OptimizationRampProfileKind {
  String get wireValue => switch (this) {
    OptimizationRampProfileKind.none => 'none',
    OptimizationRampProfileKind.landManaBase => 'land_mana_base',
    OptimizationRampProfileKind.manaRock => 'mana_rock',
    OptimizationRampProfileKind.manaDork => 'mana_dork',
    OptimizationRampProfileKind.landToBattlefield => 'land_to_battlefield',
    OptimizationRampProfileKind.extraLand => 'extra_land',
    OptimizationRampProfileKind.manaFixingOnly => 'mana_fixing_only',
    OptimizationRampProfileKind.costReduction => 'cost_reduction',
    OptimizationRampProfileKind.ritual => 'ritual',
    OptimizationRampProfileKind.consumableMana => 'consumable_mana',
    OptimizationRampProfileKind.landUntap => 'land_untap',
    OptimizationRampProfileKind.treasureCreation => 'treasure_creation',
    OptimizationRampProfileKind.treasureMultiplier => 'treasure_multiplier',
    OptimizationRampProfileKind.manaMultiplier => 'mana_multiplier',
    OptimizationRampProfileKind.conditionalMana => 'conditional_mana',
  };

  bool get countsTowardGenericFloor => switch (this) {
    OptimizationRampProfileKind.manaRock ||
    OptimizationRampProfileKind.manaDork ||
    OptimizationRampProfileKind.landToBattlefield ||
    OptimizationRampProfileKind.extraLand => true,
    _ => false,
  };

  bool get isAcceleration => switch (this) {
    OptimizationRampProfileKind.manaRock ||
    OptimizationRampProfileKind.manaDork ||
    OptimizationRampProfileKind.landToBattlefield ||
    OptimizationRampProfileKind.extraLand ||
    OptimizationRampProfileKind.costReduction ||
    OptimizationRampProfileKind.ritual ||
    OptimizationRampProfileKind.consumableMana ||
    OptimizationRampProfileKind.landUntap ||
    OptimizationRampProfileKind.treasureCreation ||
    OptimizationRampProfileKind.treasureMultiplier ||
    OptimizationRampProfileKind.manaMultiplier ||
    OptimizationRampProfileKind.conditionalMana => true,
    OptimizationRampProfileKind.none ||
    OptimizationRampProfileKind.landManaBase ||
    OptimizationRampProfileKind.manaFixingOnly => false,
  };
}

class OptimizationRampProfile {
  const OptimizationRampProfile({
    required this.primaryKind,
    required this.kinds,
    required this.evidence,
  });

  final OptimizationRampProfileKind primaryKind;
  final Set<OptimizationRampProfileKind> kinds;
  final List<String> evidence;

  bool get countsTowardGenericFloor =>
      kinds.any((kind) => kind.countsTowardGenericFloor);

  bool get isAcceleration => kinds.any((kind) => kind.isAcceleration);

  bool get requiresContextualPolicy =>
      isAcceleration && !countsTowardGenericFloor;

  Map<String, dynamic> toJson() => {
    'schema_version': optimizationRampProfileSchemaVersion,
    'primary_kind': primaryKind.wireValue,
    'kinds': kinds.map((kind) => kind.wireValue).toList(growable: false)
      ..sort(),
    'counts_toward_generic_floor': countsTowardGenericFloor,
    'is_acceleration': isAcceleration,
    'requires_contextual_policy': requiresContextualPolicy,
    'evidence': evidence,
  };
}

/// Quantity-aware deck aggregation for the split between generic structural
/// ramp and acceleration that needs a deck-specific policy.
class OptimizationRampDeckSummary {
  const OptimizationRampDeckSummary({
    required this.rampFloor,
    required this.rampContextual,
    required this.rampProfiled,
    required this.kindCounts,
  });

  final int rampFloor;
  final int rampContextual;
  final int rampProfiled;
  final Map<String, int> kindCounts;

  Map<String, dynamic> toJson() => {
    'schema_version': optimizationRampProfileSchemaVersion,
    'ramp_floor': rampFloor,
    'ramp_contextual': rampContextual,
    'ramp_profiled': rampProfiled,
    'kind_counts': Map<String, int>.from(kindCounts),
  };
}

OptimizationRampDeckSummary summarizeOptimizationRampProfilesForDeck(
  Iterable<Map<String, dynamic>> cards,
) {
  var rampFloor = 0;
  var rampContextual = 0;
  var rampProfiled = 0;
  final kindCounts = <String, int>{};

  for (final card in cards) {
    final rawQuantity = card['quantity'];
    final quantity = switch (rawQuantity) {
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 1,
      _ => 1,
    };
    if (quantity <= 0) continue;

    final profile = optimizationRampProfileForCard(card);
    if (profile.countsTowardGenericFloor) rampFloor += quantity;
    if (profile.requiresContextualPolicy) rampContextual += quantity;
    if (profile.isAcceleration) rampProfiled += quantity;
    for (final kind in profile.kinds) {
      if (kind == OptimizationRampProfileKind.none ||
          kind == OptimizationRampProfileKind.landManaBase) {
        continue;
      }
      final key = kind.wireValue;
      kindCounts[key] = (kindCounts[key] ?? 0) + quantity;
    }
  }

  return OptimizationRampDeckSummary(
    rampFloor: rampFloor,
    rampContextual: rampContextual,
    rampProfiled: rampProfiled,
    kindCounts: Map.unmodifiable(kindCounts),
  );
}

OptimizationRampProfile optimizationRampProfileForCard(
  Map<String, dynamic> card,
) {
  return classifyOptimizationRampProfile(
    name: card['name']?.toString() ?? '',
    typeLine: card['type_line']?.toString() ?? '',
    oracleText: card['oracle_text']?.toString() ?? '',
    manaCost: card['mana_cost']?.toString(),
    cmc: card['cmc'],
  );
}

OptimizationRampProfile classifyOptimizationRampProfile({
  required String name,
  required String typeLine,
  required String oracleText,
  String? manaCost,
  Object? cmc,
}) {
  final normalizedType = typeLine.toLowerCase();
  final withoutReminder = optimizationOracleWithoutReminderText(
    oracleText,
  ).toLowerCase().replaceAll('search you library', 'search your library');
  final direct = optimizationOracleDirectEffectText(withoutReminder);
  final kinds = <OptimizationRampProfileKind>{};
  final evidence = <String>[];

  void add(OptimizationRampProfileKind kind, String reason) {
    if (kinds.add(kind)) evidence.add(reason);
  }

  if (land_utils.isLandTypeLine(typeLine)) {
    return const OptimizationRampProfile(
      primaryKind: OptimizationRampProfileKind.landManaBase,
      kinds: {OptimizationRampProfileKind.landManaBase},
      evidence: ['type_line_land_is_mana_base_not_nonland_ramp'],
    );
  }

  final putsLandOntoBattlefield = _putsOwnedLandOntoBattlefield(
    withoutReminder,
  );
  if (putsLandOntoBattlefield) {
    add(
      OptimizationRampProfileKind.landToBattlefield,
      'advances_controller_land_development',
    );
  }

  if (_allowsAdditionalLandPlay(withoutReminder)) {
    add(
      OptimizationRampProfileKind.extraLand,
      'allows_controller_additional_land_play',
    );
  }

  if (_looksLikeCostReduction(withoutReminder)) {
    add(
      OptimizationRampProfileKind.costReduction,
      'reduces_cost_without_creating_generic_mana_source',
    );
  }

  if (_looksLikeLandUntap(withoutReminder)) {
    add(
      OptimizationRampProfileKind.landUntap,
      'depends_on_existing_lands_or_timing_window',
    );
  }

  if (_looksLikeTreasureMultiplier(direct)) {
    add(
      OptimizationRampProfileKind.treasureMultiplier,
      'multiplies_a_separate_treasure_event',
    );
  }

  if (_looksLikeManaMultiplier(direct)) {
    add(
      OptimizationRampProfileKind.manaMultiplier,
      'multiplies_existing_mana_sources',
    );
  }

  final treasureSignal = classifyOptimizationTreasureRampText(withoutReminder);
  if (treasureSignal.isRamp) {
    add(
      OptimizationRampProfileKind.treasureCreation,
      'creates_controller_accessible_treasure_but_requires_context',
    );
  }

  final producesMana = _looksLikeDirectManaProduction(direct);
  final hasActivatedManaAbility = _looksLikeActivatedManaAbility(direct);
  final consumesSource = _manaAbilityConsumesSource(direct);
  final isInstantOrSorcery =
      normalizedType.contains('instant') || normalizedType.contains('sorcery');
  final isArtifact = normalizedType.contains('artifact');
  final isCreature = normalizedType.contains('creature');

  if (producesMana && isInstantOrSorcery) {
    add(OptimizationRampProfileKind.ritual, 'one_shot_instant_or_sorcery_mana');
  } else if (producesMana && consumesSource) {
    add(
      OptimizationRampProfileKind.consumableMana,
      'mana_ability_consumes_its_own_source',
    );
  } else if (producesMana && hasActivatedManaAbility && isArtifact) {
    add(OptimizationRampProfileKind.manaRock, 'reusable_artifact_mana_ability');
  } else if (producesMana && hasActivatedManaAbility && isCreature) {
    add(OptimizationRampProfileKind.manaDork, 'reusable_creature_mana_ability');
  } else if (producesMana) {
    add(
      OptimizationRampProfileKind.conditionalMana,
      'mana_production_without_generic_reusable_source_proof',
    );
  }

  if (!producesMana && _looksLikeManaFixingOnly(withoutReminder)) {
    add(
      OptimizationRampProfileKind.manaFixingOnly,
      'changes_mana_colors_or_spending_without_acceleration',
    );
  }

  if (kinds.isEmpty) {
    kinds.add(OptimizationRampProfileKind.none);
    evidence.add('no_generic_or_contextual_acceleration_signal');
  }

  return OptimizationRampProfile(
    primaryKind: _selectPrimaryRampProfileKind(kinds),
    kinds: Set.unmodifiable(kinds),
    evidence: List.unmodifiable(evidence),
  );
}

OptimizationRampProfileKind _selectPrimaryRampProfileKind(
  Set<OptimizationRampProfileKind> kinds,
) {
  for (final kind in const [
    OptimizationRampProfileKind.manaRock,
    OptimizationRampProfileKind.manaDork,
    OptimizationRampProfileKind.landToBattlefield,
    OptimizationRampProfileKind.extraLand,
    OptimizationRampProfileKind.ritual,
    OptimizationRampProfileKind.consumableMana,
    OptimizationRampProfileKind.costReduction,
    OptimizationRampProfileKind.landUntap,
    OptimizationRampProfileKind.treasureCreation,
    OptimizationRampProfileKind.treasureMultiplier,
    OptimizationRampProfileKind.manaMultiplier,
    OptimizationRampProfileKind.conditionalMana,
    OptimizationRampProfileKind.manaFixingOnly,
    OptimizationRampProfileKind.landManaBase,
    OptimizationRampProfileKind.none,
  ]) {
    if (kinds.contains(kind)) return kind;
  }
  return OptimizationRampProfileKind.none;
}

bool _putsOwnedLandOntoBattlefield(String oracle) {
  final searchIndex = oracle.indexOf('search your library');
  if (searchIndex >= 0) {
    final nextParagraph = oracle.indexOf('\n', searchIndex);
    final instruction = oracle.substring(
      searchIndex,
      nextParagraph < 0 ? oracle.length : nextParagraph,
    );
    if (looksLikeOptimizationLandSearchText(instruction) &&
        instruction.contains('onto the battlefield')) {
      return true;
    }
  }

  return RegExp(
        r'\bput\b[^.\n;]{0,96}\bland cards?\b[^.\n;]{0,96}'
        r'\bfrom your hand onto the battlefield\b',
      ).hasMatch(oracle) ||
      RegExp(
        r'\bput (?:up to |one |two |three |x )?[^.\n;]{0,48}'
        r'\bland cards?\b[^.\n;]{0,96}\bonto the battlefield\b',
      ).hasMatch(oracle);
}

bool _allowsAdditionalLandPlay(String oracle) {
  return RegExp(
        r'\byou may play (?:an?|one|two|three) additional lands?\b',
      ).hasMatch(oracle) ||
      RegExp(
        r'\byou can play (?:an?|one|two|three) additional lands?\b',
      ).hasMatch(oracle) ||
      oracle.contains('additional land this turn') ||
      oracle.contains('additional land on each of your turns');
}

bool _looksLikeCostReduction(String oracle) {
  return RegExp(
        r'\b(?:spells?|abilities)\b[^.\n]{0,96}\bcosts?\b'
        r'[^.\n]{0,48}\bless(?: to cast| to activate)?\b',
      ).hasMatch(oracle) ||
      oracle.contains('spells you cast have convoke') ||
      oracle.contains('affinity for');
}

bool _looksLikeLandUntap(String oracle) {
  return RegExp(
        r'\buntaps?\b[^.\n;]{0,80}\b(?:target |all |those )?lands?\b',
      ).hasMatch(oracle) ||
      RegExp(r'\b(?:land|lands)\b[^.\n;]{0,80}\buntaps?\b').hasMatch(oracle);
}

bool _looksLikeTreasureMultiplier(String direct) {
  if (!direct.contains('treasure')) return false;
  return RegExp(
        r'\b(?:twice|double|additional)\b[^.\n;]{0,96}\btreasure',
      ).hasMatch(direct) ||
      RegExp(
        r'\bwould create\b[^.\n;]{0,96}\btreasure\b'
        r'[^.\n;]{0,96}\binstead\b',
      ).hasMatch(direct) ||
      RegExp(
        r'\binstead create\b[^.\n;]{0,96}\badditional treasure\b',
      ).hasMatch(direct);
}

bool _looksLikeManaMultiplier(String direct) {
  return RegExp(
        r'\b(?:adds?|produces?)\b[^.\n;]{0,96}'
        r'\b(?:additional|twice|double|three times)\b[^.\n;]{0,64}\bmana\b',
      ).hasMatch(direct) ||
      RegExp(
        r'\bwhenever\b[^.\n;]{0,96}\btapped for mana\b'
        r'[^.\n;]{0,96}\badd\b',
      ).hasMatch(direct);
}

bool _looksLikeDirectManaProduction(String direct) {
  return direct.contains('add {') ||
      RegExp(
        r'\badds?\b[^.\n;]{0,96}\bmana of any(?:\s+one)?\b',
      ).hasMatch(direct) ||
      RegExp(
        r'\badds?\b[^.\n;]{0,96}'
        r'\b(?:one|two|three|four|five|six|seven|eight|nine|ten|x|'
        r'that much|an amount of)\s+mana\b',
      ).hasMatch(direct);
}

bool _looksLikeActivatedManaAbility(String direct) {
  for (final line in direct.split(RegExp(r'[\r\n]+'))) {
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final effect = line.substring(colon + 1);
    if (_looksLikeDirectManaProduction(effect)) return true;
  }
  return false;
}

bool _manaAbilityConsumesSource(String direct) {
  for (final line in direct.split(RegExp(r'[\r\n]+'))) {
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final effect = line.substring(colon + 1);
    if (!_looksLikeDirectManaProduction(effect)) continue;
    final cost = line.substring(0, colon);
    if (RegExp(
      r'\b(?:sacrifice|exile) (?:this|~|[a-z][a-z0-9\x27 -]{0,80})\b',
    ).hasMatch(cost)) {
      return true;
    }
  }
  return false;
}

bool _looksLikeManaFixingOnly(String oracle) {
  return oracle.contains('mana of any type can be spent') ||
      oracle.contains('spend mana as though it were mana of any color') ||
      oracle.contains('spend mana as though it were mana of any type') ||
      RegExp(
        r'\blands? you control\b[^.\n]{0,96}\b(?:has|have)\b'
        r'[^.\n]{0,96}\badd (?:one )?mana of any color\b',
      ).hasMatch(oracle) ||
      RegExp(
        r'\b(?:land|lands)\b[^.\n]{0,96}\b(?:becomes?|are)\b'
        r'[^.\n]{0,96}\bbasic land type\b',
      ).hasMatch(oracle);
}
