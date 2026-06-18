import 'optimize_filler_candidate_support.dart' show resolvedCardIdentity;
import 'optimize_runtime_support.dart' show basicLandNameForColor;
import 'optimize_state_support.dart';

int calculateCompleteMaxBasicAdditions(int? commanderRecommendedLands) {
  final recommended = (commanderRecommendedLands ?? 38).clamp(28, 42);
  final buffered = recommended + 4;
  return buffered > 40 ? 40 : buffered;
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
    if (typeLine.contains('land')) continue;

    final quantity = (card['quantity'] as int?) ?? 1;
    final manaCost = (card['mana_cost'] as String?) ?? '';
    final explicitSymbols = <String, int>{};
    for (final color in commanderColorIdentity) {
      final symbolCount = RegExp(
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

    final fallbackIdentity = resolvedCardIdentity(card)
        .where(commanderColorIdentity.contains)
        .toSet();
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
  final rawSources = (manaBase['sources'] as Map?)?.cast<String, int>() ??
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
      final targetSources = symbolCount <= 0
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
