import '../basic_land_utils.dart' as basic_lands;
import '../commander_mana_floor.dart';
import 'optimize_filler_candidate_support.dart' show resolvedCardIdentity;
import 'optimize_runtime_support.dart' show basicLandNameForColor;
import 'optimize_state_support.dart';

int calculateCompleteMaxBasicAdditions(
  int? commanderRecommendedLands, {
  String deckFormat = 'commander',
}) {
  if (deckFormat.trim().toLowerCase() == 'brawl') {
    final recommended = (commanderRecommendedLands ?? 25).clamp(24, 27);
    return (recommended + 3).clamp(24, 30);
  }
  final recommended = (commanderRecommendedLands ?? 38).clamp(28, 42);
  return (recommended + 4).clamp(28, 40);
}

int resolveCompleteTargetLandCount({
  required String deckFormat,
  int? recommendedLandCount,
  double? averageNonLandCmc,
}) {
  final normalized = deckFormat.trim().toLowerCase();
  if (normalized == 'brawl') {
    final fallback = switch (averageNonLandCmc) {
      null => 25,
      < 2.0 => 24,
      < 3.0 => 25,
      < 4.0 => 26,
      _ => 27,
    };
    return (recommendedLandCount ?? fallback).clamp(
      brawlStrategicMinimumLandCount,
      27,
    );
  }

  final fallback = switch (averageNonLandCmc) {
    null => 36,
    < 2.0 => 34,
    < 3.0 => 35,
    < 4.0 => 37,
    _ => 39,
  };
  final minimum =
      strategicMinimumLandCountForFormat(normalized) ??
      commanderStrategicMinimumLandCount;
  return (recommendedLandCount ?? fallback).clamp(minimum, 42);
}

Map<String, dynamic> buildVirtualBasicLandMetadata(String name) {
  final normalizedName = name.trim().toLowerCase();
  final color = switch (normalizedName) {
    'plains' => 'W',
    'island' => 'U',
    'swamp' => 'B',
    'mountain' => 'R',
    'forest' => 'G',
    _ => null,
  };
  final canonicalName = switch (normalizedName) {
    'plains' => 'Plains',
    'island' => 'Island',
    'swamp' => 'Swamp',
    'mountain' => 'Mountain',
    'forest' => 'Forest',
    'wastes' => 'Wastes',
    _ => name.trim(),
  };

  return {
    'type_line':
        canonicalName.isEmpty ? 'Basic Land' : 'Basic Land — $canonicalName',
    'oracle_text': color == null ? '{T}: Add {C}.' : '{T}: Add {$color}.',
    'colors': const <String>[],
    'color_identity': color == null ? const <String>[] : <String>[color],
  };
}

Map<String, int> buildCompleteColorDemandMap({
  required List<Map<String, dynamic>> currentDeck,
  required Set<String> commanderColorIdentity,
}) {
  final demand = <String, int>{};
  for (final color in commanderColorIdentity) {
    demand[color] = 0;
  }

  for (final card in currentDeck) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) continue;

    final quantity = (card['quantity'] as int?) ?? 1;
    final manaCost = (card['mana_cost'] as String?) ?? '';
    final explicitSymbols = <String, int>{};
    for (final color in commanderColorIdentity) {
      final symbolCount =
          RegExp(
            '\\{${color.toLowerCase()}\\}',
            caseSensitive: false,
          ).allMatches(manaCost).length;
      if (symbolCount > 0) {
        explicitSymbols[color] = symbolCount * quantity;
      }
    }

    if (explicitSymbols.isNotEmpty) {
      for (final entry in explicitSymbols.entries) {
        demand[entry.key] = (demand[entry.key] ?? 0) + entry.value;
      }
      continue;
    }

    final fallbackIdentity =
        resolvedCardIdentity(
          card,
        ).where(commanderColorIdentity.contains).toSet();
    if (fallbackIdentity.isEmpty) continue;

    final fallbackWeight =
        fallbackIdentity.length == 1 ? 2 * quantity : quantity;
    for (final color in fallbackIdentity) {
      demand[color] = (demand[color] ?? 0) + fallbackWeight;
    }
  }

  return demand;
}

List<String> buildWeightedBasicLandPlan({
  required List<Map<String, dynamic>> currentDeck,
  required Set<String> commanderColorIdentity,
  required int slotsToAdd,
}) {
  if (slotsToAdd <= 0) return const [];
  if (commanderColorIdentity.isEmpty) {
    return List<String>.filled(slotsToAdd, 'Wastes');
  }

  final colors = commanderColorIdentity.toList()..sort();
  final analyzer = DeckArchetypeAnalyzerCore(currentDeck, colors);
  final manaBase = analyzer.analyzeManaBase();
  final rawSymbols = buildCompleteColorDemandMap(
    currentDeck: currentDeck,
    commanderColorIdentity: commanderColorIdentity,
  );
  final rawSources =
      (manaBase['sources'] as Map?)?.cast<String, int>() ??
      const <String, int>{};
  final projectedSources = <String, int>{};
  for (final color in colors) {
    projectedSources[color] = rawSources[color] ?? 0;
  }
  final anySource = rawSources['Any'] ?? 0;
  final totalSymbols = colors.fold<int>(
    0,
    (sum, color) => sum + (rawSymbols[color] ?? 0),
  );
  final plan = <String>[];

  for (var i = 0; i < slotsToAdd; i++) {
    String? bestColor;
    var bestScore = -1 << 30;

    for (final color in colors) {
      final symbolCount = rawSymbols[color] ?? 0;
      final sourceCount = (projectedSources[color] ?? 0) + anySource;
      final percent = totalSymbols > 0 ? symbolCount / totalSymbols : 0.0;
      final targetSources =
          symbolCount <= 0
              ? 6
              : percent > 0.30
              ? 15
              : percent > 0.10
              ? 10
              : 8;
      final deficit = targetSources - sourceCount;
      final score = (deficit * 100) + (symbolCount * 3) - sourceCount;
      if (bestColor == null || score > bestScore) {
        bestColor = color;
        bestScore = score;
      }
    }

    final chosenColor = bestColor ?? colors.first;
    plan.add(basicLandNameForColor(chosenColor));
    projectedSources[chosenColor] = (projectedSources[chosenColor] ?? 0) + 1;
  }

  return plan;
}
