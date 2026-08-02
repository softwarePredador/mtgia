import 'package:postgres/postgres.dart';

import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import 'commander_reference_card_stats_support.dart';
import 'generate_bracket_support.dart';
import 'generate_structural_quality_support.dart';
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';

const commanderReferenceStructuralRepairPolicyVersion =
    'commander_reference_structural_repair_v1';

class CommanderReferenceStructuralRepair {
  const CommanderReferenceStructuralRepair({
    required this.deck,
    required this.diagnostics,
  });

  final Map<String, dynamic> deck;
  final Map<String, dynamic> diagnostics;
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

  final targetLandCount =
      requestedBracket != null && requestedBracket >= 4 ? 34 : 36;
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
  final targetArchetype = inferAiGenerateTargetArchetype(prompt);
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
  for (final card in [...currentNonLands, ...fillerCandidates]) {
    final name = card['name']?.toString().trim() ?? '';
    final normalizedName = normalizeCommanderReferenceCardName(name);
    if (name.isEmpty ||
        normalizedName.isEmpty ||
        !seenCandidates.add(normalizedName)) {
      continue;
    }
    candidates.add({...card, 'name': name, 'quantity': 1});
  }

  final nonLandTarget = 99 - targetLandCount;
  final minimumCounts = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: requestedBracket,
  );
  final selected = <Map<String, dynamic>>[];
  final selectedNames = <String>{};

  bool addCandidate(Map<String, dynamic> candidate) {
    if (selected.length >= nonLandTarget) return false;
    final name = normalizeCommanderReferenceCardName(
      candidate['name']?.toString() ?? '',
    );
    if (name.isEmpty || !selectedNames.add(name)) return false;
    selected.add(candidate);
    return true;
  }

  for (final role in const ['wipe', 'ramp', 'draw', 'interaction']) {
    final minimum = minimumCounts[role] ?? 0;
    while (countOptimizationFunctionalRole(selected, role: role) < minimum) {
      Map<String, dynamic>? next;
      for (final candidate in candidates) {
        final normalizedName = normalizeCommanderReferenceCardName(
          candidate['name']?.toString() ?? '',
        );
        if (selectedNames.contains(normalizedName)) continue;
        if (countOptimizationFunctionalRole([candidate], role: role) <= 0) {
          continue;
        }
        next = candidate;
        break;
      }
      if (next == null || !addCandidate(next)) return null;
    }
  }

  for (final candidate in candidates) {
    if (selected.length >= nonLandTarget) break;
    addCandidate(candidate);
  }
  if (selected.length != nonLandTarget) return null;

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
      'functional_role_counts': roleCounts,
      'functional_role_minimums': minimumCounts,
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
