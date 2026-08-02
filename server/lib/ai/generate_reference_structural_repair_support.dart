import 'package:postgres/postgres.dart';

import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import '../edh_bracket_policy.dart';
import 'commander_reference_card_stats_support.dart';
import 'generate_bracket_support.dart';
import 'generate_structural_quality_support.dart';
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';

const commanderReferenceStructuralRepairPolicyVersion =
    'commander_reference_structural_repair_v2';

class CommanderReferenceStructuralRepair {
  const CommanderReferenceStructuralRepair({
    required this.deck,
    required this.diagnostics,
  });

  final Map<String, dynamic> deck;
  final Map<String, dynamic> diagnostics;
}

class CommanderReferenceStructuralNonLandSelection {
  const CommanderReferenceStructuralNonLandSelection({
    required this.cards,
    required this.intentCounts,
    required this.intentLimits,
  });

  final List<Map<String, dynamic>> cards;
  final Map<String, int> intentCounts;
  final Map<String, int> intentLimits;
}

int commanderReferenceStructuralTargetLandCount(int? requestedBracket) {
  return switch (requestedBracket) {
    1 => 38,
    4 || 5 => 34,
    _ => 36,
  };
}

Map<BracketCategory, int> _commanderStructuralIntentLimits(
  int? requestedBracket,
) {
  return switch (requestedBracket) {
    1 => const {
      BracketCategory.fastMana: 0,
      BracketCategory.freeInteraction: 0,
      BracketCategory.extraTurns: 0,
      BracketCategory.infiniteCombo: 0,
      BracketCategory.stax: 0,
    },
    2 => const {
      BracketCategory.fastMana: 1,
      BracketCategory.freeInteraction: 0,
      BracketCategory.extraTurns: 0,
      BracketCategory.infiniteCombo: 0,
      BracketCategory.stax: 0,
    },
    _ => const {},
  };
}

CommanderReferenceStructuralNonLandSelection?
selectCommanderReferenceStructuralNonLands({
  required Iterable<Map<String, dynamic>> candidates,
  required int nonLandTarget,
  required String targetArchetype,
  required int? requestedBracket,
}) {
  if (nonLandTarget <= 0) {
    return const CommanderReferenceStructuralNonLandSelection(
      cards: [],
      intentCounts: {},
      intentLimits: {},
    );
  }

  final ordered = candidates
      .toList(growable: false)
      .asMap()
      .entries
      .map(
        (entry) => <String, dynamic>{
          ...entry.value,
          '_structural_order': entry.key,
        },
      )
      .toList(growable: true);
  ordered.sort(
    (a, b) => _compareCommanderStructuralCandidates(
      a,
      b,
      requestedBracket: requestedBracket,
    ),
  );

  final minimumCounts = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: requestedBracket,
  );
  final intentLimits = _commanderStructuralIntentLimits(requestedBracket);
  final categoryCounts = <BracketCategory, int>{
    for (final category in BracketCategory.values) category: 0,
  };
  final selected = <Map<String, dynamic>>[];
  final selectedNames = <String>{};

  bool fitsIntent(Map<String, dynamic> candidate) {
    if (intentLimits.isEmpty) return true;
    final tags = _candidateBracketTags(candidate);
    for (final entry in intentLimits.entries) {
      final addition = tags.contains(entry.key) ? 1 : 0;
      if ((categoryCounts[entry.key] ?? 0) + addition > entry.value) {
        return false;
      }
    }
    return true;
  }

  bool addCandidate(Map<String, dynamic> candidate) {
    if (selected.length >= nonLandTarget || !fitsIntent(candidate)) {
      return false;
    }
    final name = normalizeCommanderReferenceCardName(
      candidate['name']?.toString() ?? '',
    );
    if (name.isEmpty || !selectedNames.add(name)) return false;
    final clean =
        Map<String, dynamic>.from(candidate)
          ..remove('_structural_order')
          ..remove('_structural_preferred')
          ..remove('_structural_source_rank');
    selected.add(clean);
    for (final category in _candidateBracketTags(candidate)) {
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    return true;
  }

  for (final role in const ['wipe', 'ramp', 'draw', 'interaction']) {
    final minimum = minimumCounts[role] ?? 0;
    while (countOptimizationFunctionalRole(selected, role: role) < minimum) {
      Map<String, dynamic>? next;
      for (final candidate in ordered) {
        final normalizedName = normalizeCommanderReferenceCardName(
          candidate['name']?.toString() ?? '',
        );
        if (selectedNames.contains(normalizedName) ||
            !fitsIntent(candidate) ||
            countOptimizationFunctionalRole([candidate], role: role) <= 0) {
          continue;
        }
        next = candidate;
        break;
      }
      if (next == null || !addCandidate(next)) return null;
    }
  }

  for (final candidate in ordered) {
    if (selected.length >= nonLandTarget) break;
    addCandidate(candidate);
  }
  if (selected.length != nonLandTarget) return null;

  return CommanderReferenceStructuralNonLandSelection(
    cards: List<Map<String, dynamic>>.unmodifiable(selected),
    intentCounts: Map<String, int>.unmodifiable({
      for (final entry in categoryCounts.entries)
        if (entry.value > 0) entry.key.name: entry.value,
    }),
    intentLimits: Map<String, int>.unmodifiable({
      for (final entry in intentLimits.entries) entry.key.name: entry.value,
    }),
  );
}

int _compareCommanderStructuralCandidates(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  required int? requestedBracket,
}) {
  if (requestedBracket != null && requestedBracket <= 2) {
    final byIntent = commanderBracketIntentPenalty(
      a,
      bracket: requestedBracket,
    ).compareTo(commanderBracketIntentPenalty(b, bracket: requestedBracket));
    if (byIntent != 0) return byIntent;
  } else if (requestedBracket == 5) {
    final byCompetitivePower = _commanderStructuralCompetitivePowerScore(
      b,
    ).compareTo(_commanderStructuralCompetitivePowerScore(a));
    if (byCompetitivePower != 0) return byCompetitivePower;
  }

  final preferredA = a['_structural_preferred'] == true ? 1 : 0;
  final preferredB = b['_structural_preferred'] == true ? 1 : 0;
  final byPreferred = preferredB.compareTo(preferredA);
  if (byPreferred != 0) return byPreferred;

  final sourceA = (a['_structural_source_rank'] as int?) ?? 1;
  final sourceB = (b['_structural_source_rank'] as int?) ?? 1;
  final bySource = sourceA.compareTo(sourceB);
  if (bySource != 0) return bySource;

  final orderA = (a['_structural_order'] as int?) ?? 0;
  final orderB = (b['_structural_order'] as int?) ?? 0;
  final byOrder = orderA.compareTo(orderB);
  if (byOrder != 0) return byOrder;
  return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
}

int _commanderStructuralCompetitivePowerScore(Map<String, dynamic> card) {
  final tags = _candidateBracketTags(card);
  var score = 0;
  if (tags.contains(BracketCategory.gameChanger)) score += 1000;
  if (tags.contains(BracketCategory.fastMana)) score += 350;
  if (tags.contains(BracketCategory.infiniteCombo)) score += 300;
  if (tags.contains(BracketCategory.tutor)) score += 240;
  if (tags.contains(BracketCategory.freeInteraction)) score += 220;
  if (tags.contains(BracketCategory.cardAdvantage)) score += 140;
  if (tags.contains(BracketCategory.protection)) score += 120;
  if (tags.contains(BracketCategory.stax)) score += 100;
  if (tags.contains(BracketCategory.valueEngine)) score += 80;
  final cmc = switch (card['cmc']) {
    num value => value.toDouble(),
    String value => double.tryParse(value.trim()),
    _ => null,
  };
  if (cmc != null) {
    if (cmc <= 1) {
      score += 60;
    } else if (cmc <= 2) {
      score += 40;
    } else if (cmc <= 3) {
      score += 20;
    }
  }
  return score;
}

Set<BracketCategory> _candidateBracketTags(Map<String, dynamic> candidate) {
  return tagCardForBracket(
    name: candidate['name']?.toString() ?? '',
    typeLine: candidate['type_line']?.toString() ?? '',
    oracleText: candidate['oracle_text']?.toString() ?? '',
  ).categories;
}

Future<CommanderReferenceStructuralRepair?>
buildCommanderReferenceStructuralRepair({
  required Pool pool,
  required String format,
  required int? requestedBracket,
  required String prompt,
  required String commanderName,
  required Iterable<Map<String, dynamic>> resolvedCards,
  required Iterable<String> preferredCardNames,
}) async {
  if (!isAiGenerateCommanderFormat(format)) return null;

  Map<String, dynamic>? commander;
  for (final card in resolvedCards) {
    if (card['is_commander'] == true) {
      commander = card;
      break;
    }
  }
  if (commander == null) return null;

  final commanderOnlyEvaluation = evaluateAiGenerateCommanderBracket(
    format: format,
    requestedBracket: requestedBracket,
    generatedDeck: {
      'commander': {'name': commanderName},
      'cards': const <Map<String, dynamic>>[],
    },
  );
  if (!commanderOnlyEvaluation.hardCompliant) return null;

  final currentMain = resolvedCards
      .where((card) => card['is_commander'] != true)
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
  final bracketSafeMain = filterCandidatesByBracketPolicy(
    candidates: currentMain,
    bracket: requestedBracket,
    currentDeckCards: [commander],
  );
  final removedByBracket = currentMain
    .map((card) => card['name']?.toString().trim() ?? '')
    .where((name) => name.isNotEmpty)
    .toSet()
    .difference(
      bracketSafeMain
          .map((card) => card['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet(),
    )
    .toList(growable: false)..sort();

  final targetLandCount = commanderReferenceStructuralTargetLandCount(
    requestedBracket,
  );
  final nonBasicLands = bracketSafeMain
      .where((card) {
        final name = card['name']?.toString() ?? '';
        final typeLine = card['type_line']?.toString() ?? '';
        return basic_lands.isLandTypeLine(typeLine) &&
            !basic_lands.isBasicLandCard(name: name, typeLine: typeLine);
      })
      .take(targetLandCount)
      .map((card) => {...card, 'quantity': 1})
      .toList(growable: false);
  final basicLandQuantity = targetLandCount - nonBasicLands.length;

  final commanderIdentity =
      resolveCardColorIdentity(
        colorIdentity: _stringIterable(commander['color_identity']),
        colors: _stringIterable(commander['colors']),
        oracleText: commander['oracle_text']?.toString(),
        manaCost: commander['mana_cost']?.toString(),
      ).toSet();
  final currentNonLands = bracketSafeMain
      .where(
        (card) =>
            !basic_lands.isLandTypeLine(card['type_line']?.toString() ?? ''),
      )
      .map((card) => {...card, 'quantity': 1})
      .toList(growable: false);
  final excludedNames = <String>{
    commanderName.trim().toLowerCase(),
    for (final card in bracketSafeMain)
      if ((card['name']?.toString().trim() ?? '').isNotEmpty)
        card['name'].toString().trim().toLowerCase(),
  };
  final preferredNames =
      preferredCardNames
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
  final targetArchetype = inferAiGenerateTargetArchetype(
    prompt,
    requestedBracket: requestedBracket,
  );
  final fillerCandidates = await loadDeterministicSlotFillers(
    pool: pool,
    currentDeckCards: [commander, ...bracketSafeMain],
    targetArchetype: targetArchetype,
    commanderColorIdentity: commanderIdentity,
    bracket: requestedBracket,
    excludeNames: excludedNames,
    preferredNames: preferredNames,
    limit: 99,
    deckFormat: format,
  );

  final candidates = <Map<String, dynamic>>[];
  final seenCandidates = <String>{};
  final currentNonLandNames =
      currentNonLands
          .map(
            (card) => normalizeCommanderReferenceCardName(
              card['name']?.toString() ?? '',
            ),
          )
          .where((name) => name.isNotEmpty)
          .toSet();
  var structuralOrder = 0;
  for (final card in [...currentNonLands, ...fillerCandidates]) {
    final name = card['name']?.toString().trim() ?? '';
    final normalizedName = normalizeCommanderReferenceCardName(name);
    if (name.isEmpty ||
        normalizedName.isEmpty ||
        !seenCandidates.add(normalizedName)) {
      continue;
    }
    final normalizedPreferredName = name.trim().toLowerCase();
    candidates.add({
      ...card,
      'name': name,
      'quantity': 1,
      '_structural_order': structuralOrder,
      '_structural_source_rank':
          currentNonLandNames.contains(normalizedName) ? 0 : 1,
      '_structural_preferred': preferredNames.contains(normalizedPreferredName),
    });
    structuralOrder += 1;
  }

  final nonLandTarget = 99 - targetLandCount;
  final minimumCounts = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: requestedBracket,
  );
  final selection = selectCommanderReferenceStructuralNonLands(
    candidates: candidates,
    nonLandTarget: nonLandTarget,
    targetArchetype: targetArchetype,
    requestedBracket: requestedBracket,
  );
  if (selection == null) return null;
  final selected = selection.cards;

  final colors = commanderIdentity.toList(growable: false)..sort();
  final basicLands = _buildBasicLandCards(
    total: basicLandQuantity,
    colors: colors,
  );
  final cards = <Map<String, dynamic>>[
    for (final card in selected) {'name': card['name'], 'quantity': 1},
    for (final card in nonBasicLands) {'name': card['name'], 'quantity': 1},
    ...basicLands,
  ];
  final roleCounts = {
    for (final role in minimumCounts.keys)
      role: countOptimizationFunctionalRole(selected, role: role),
  };

  return CommanderReferenceStructuralRepair(
    deck: {
      'commander': {'name': commanderName},
      'cards': cards,
    },
    diagnostics: {
      'applied': true,
      'policy': commanderReferenceStructuralRepairPolicyVersion,
      'target_land_count': targetLandCount,
      'non_basic_land_count': nonBasicLands.length,
      'basic_land_quantity': basicLandQuantity,
      'non_land_count': selected.length,
      'target_archetype': targetArchetype,
      'functional_role_counts': roleCounts,
      'functional_role_minimums': minimumCounts,
      'intent_counts': selection.intentCounts,
      'intent_limits': selection.intentLimits,
      'intent_target_satisfied': true,
      'competitive_lane_targeted': requestedBracket == 5,
      'bracket_filtered_cards': removedByBracket,
      'candidate_count': candidates.length,
    },
  );
}

Iterable<String> _stringIterable(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString());
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((item) => item.trim());
  }
  return const [];
}

List<Map<String, dynamic>> _buildBasicLandCards({
  required int total,
  required List<String> colors,
}) {
  if (total <= 0) return const [];
  const colorToBasic = <String, String>{
    'W': 'Plains',
    'U': 'Island',
    'B': 'Swamp',
    'R': 'Mountain',
    'G': 'Forest',
  };
  final selectedBasics = <String>[
    for (final color in colors)
      if (colorToBasic[color.toUpperCase()] case final land?) land,
  ];
  final basics = selectedBasics.isEmpty ? const ['Wastes'] : selectedBasics;
  final per = (total / basics.length).floor();
  final cards = <Map<String, dynamic>>[
    for (final land in basics) {'name': land, 'quantity': per},
  ];
  var current = cards.fold<int>(
    0,
    (sum, card) => sum + (card['quantity'] as int),
  );
  var index = 0;
  while (current < total) {
    cards[index % basics.length]['quantity'] =
        (cards[index % basics.length]['quantity'] as int) + 1;
    current += 1;
    index += 1;
  }
  return cards;
}
