import 'ai/edhrec_trend_service.dart';
import 'ai/optimization_functional_roles.dart';
import 'basic_land_utils.dart' as basic_lands;
import 'deck_recommendations_power_level_support.dart';

const heuristicRecommendationsSource = 'heuristic';
const recommendationCommanderFallbackLandFloor = 33;
const recommendationCommanderLandTargetBand = '33-38';

typedef RecommendationCandidateFinder =
    Future<List<String>> Function({
      required List<String> roles,
      required List<String> oraclePatterns,
      required Set<String> deckColors,
      required Set<String> excludeNames,
      required int limit,
      required String format,
      bool landOnly,
    });

typedef RecommendationTrendFinder =
    Future<List<EdhrecCardTrend>> Function(String commanderName);

class RecommendationDeckSummary {
  const RecommendationDeckSummary({
    required this.deckCards,
    required this.deckCardNames,
    required this.deckColors,
    required this.commanderColorIdentity,
    required this.commanderNames,
    required this.candidateColorIdentity,
    required this.colorIdentitySource,
    required this.totalCards,
    required this.landCount,
    required this.creatureCount,
    required this.nonLandCards,
    required this.averageCmc,
    required this.creatureRatio,
    required this.rampCount,
    required this.drawCount,
    required this.removalCount,
    required this.boardWipeCount,
    required this.protectionCount,
    required this.archetype,
    required this.powerLevel,
  });

  final List<Map<String, dynamic>> deckCards;
  final Set<String> deckCardNames;
  final Set<String> deckColors;
  final Set<String> commanderColorIdentity;
  final List<String> commanderNames;
  final Set<String> candidateColorIdentity;
  final String colorIdentitySource;
  final int totalCards;
  final int landCount;
  final int creatureCount;
  final int nonLandCards;
  final double averageCmc;
  final double creatureRatio;
  final int rampCount;
  final int drawCount;
  final int removalCount;
  final int boardWipeCount;
  final int protectionCount;
  final String archetype;
  final int powerLevel;
}

RecommendationDeckSummary summarizeRecommendationDeck({
  required List<Map<String, dynamic>> deckCards,
  required String format,
}) {
  final deckCardNames = <String>{};
  final deckColors = <String>{};
  final commanderColorIdentity = <String>{};
  final commanderNames = <String>[];
  var totalCards = 0;
  var landCount = 0;
  var creatureCount = 0;
  var nonLandCards = 0;
  var totalCmc = 0.0;
  var rampCount = 0;
  var drawCount = 0;
  var removalCount = 0;
  var boardWipeCount = 0;
  var protectionCount = 0;

  for (final card in deckCards) {
    final name = card['name'] as String? ?? '';
    final typeLine = card['type_line'] as String? ?? '';
    final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();
    final manaCost = card['mana_cost'] as String? ?? '';
    final colors = (card['colors'] as List?)?.cast<String>() ?? const [];
    final colorIdentity =
        (card['color_identity'] as List?)?.cast<String>() ?? const [];
    final quantity = (card['quantity'] as int?) ?? 0;
    final isCommander = card['is_commander'] == true;
    final cmc = (card['cmc'] as num?)?.toDouble() ?? 0;
    final resolvedRoles =
        resolveCardFunctionalRoles(
          functionalTags: card['functional_tags'],
          semanticTagsV2: card['semantic_tags_v2'],
          oracleText: oracleText,
          typeLine: typeLine,
          name: name,
          manaCost: manaCost,
          cmc: cmc,
        ).roles;

    deckColors.addAll(colorIdentity.isNotEmpty ? colorIdentity : colors);
    if (name.isNotEmpty) deckCardNames.add(name.toLowerCase());
    totalCards += quantity;
    if (isCommander) {
      if (name.isNotEmpty) commanderNames.add(name);
      commanderColorIdentity.addAll(
        colorIdentity.isNotEmpty ? colorIdentity : colors,
      );
    }

    final tl = typeLine.toLowerCase();
    if (basic_lands.isLandTypeLine(tl)) {
      landCount += quantity;
    } else {
      nonLandCards += quantity;
      totalCmc += cmc * quantity;
    }
    if (tl.contains('creature')) creatureCount += quantity;

    final heuristicRamp =
        oracleText.contains('add {') ||
        (oracleText.contains('search your library for a') &&
            oracleText.contains('land')) ||
        oracleText.contains('put a land card');
    final heuristicDraw =
        oracleText.contains('draw') && oracleText.contains('card');
    final heuristicRemoval =
        oracleText.contains('destroy target') ||
        oracleText.contains('exile target') ||
        (oracleText.contains('deal') &&
            oracleText.contains('damage to target'));
    final heuristicBoardWipe =
        oracleText.contains('destroy all') || oracleText.contains('exile all');
    final heuristicProtection =
        oracleText.contains('hexproof') ||
        oracleText.contains('indestructible') ||
        oracleText.contains('protection from');

    if (resolvedRoles.contains('ramp') || heuristicRamp) {
      rampCount += quantity;
    }
    if (resolvedRoles.contains('draw') || heuristicDraw) {
      drawCount += quantity;
    }
    if (resolvedRoles.contains('removal') || heuristicRemoval) {
      removalCount += quantity;
    }
    if (resolvedRoles.contains('wipe') ||
        resolvedRoles.contains('board_wipe') ||
        heuristicBoardWipe) {
      boardWipeCount += quantity;
    }
    if (resolvedRoles.contains('protection') || heuristicProtection) {
      protectionCount += quantity;
    }
  }

  final averageCmc = nonLandCards > 0 ? totalCmc / nonLandCards : 0.0;
  final creatureRatio = nonLandCards > 0 ? creatureCount / nonLandCards : 0.0;
  final isCommander = format.toLowerCase() == 'commander';
  final candidateColorIdentity =
      isCommander && commanderColorIdentity.isNotEmpty
          ? commanderColorIdentity
          : deckColors;
  final colorIdentitySource =
      isCommander && commanderColorIdentity.isNotEmpty
          ? 'commander_color_identity'
          : 'observed_deck_colors';

  var archetype = 'midrange';
  if (averageCmc < 2.5 && creatureRatio > 0.4) {
    archetype = 'aggro';
  } else if (averageCmc > 3.0 && creatureRatio < 0.25) {
    archetype = 'control';
  } else if (creatureRatio < 0.3) {
    archetype = 'combo';
  }

  final powerLevel = estimateRecommendationBracketPowerLevel(
    totalCards: totalCards,
    rampCount: rampCount,
    drawCount: drawCount,
    removalCount: removalCount,
    averageCmc: averageCmc,
  );

  return RecommendationDeckSummary(
    deckCards: deckCards,
    deckCardNames: deckCardNames,
    deckColors: deckColors,
    commanderColorIdentity: commanderColorIdentity,
    commanderNames: commanderNames,
    candidateColorIdentity: candidateColorIdentity,
    colorIdentitySource: colorIdentitySource,
    totalCards: totalCards,
    landCount: landCount,
    creatureCount: creatureCount,
    nonLandCards: nonLandCards,
    averageCmc: averageCmc,
    creatureRatio: creatureRatio,
    rampCount: rampCount,
    drawCount: drawCount,
    removalCount: removalCount,
    boardWipeCount: boardWipeCount,
    protectionCount: protectionCount,
    archetype: archetype,
    powerLevel: powerLevel,
  );
}

Map<String, dynamic> buildOpenAiRecommendationFallbackShape(
  RecommendationDeckSummary summary,
) {
  return {
    'power_level': summary.powerLevel,
    'statistics': buildRecommendationStatistics(
      totalCards: summary.totalCards,
      landCount: summary.landCount,
      creatureCount: summary.creatureCount,
      rampCount: summary.rampCount,
      drawCount: summary.drawCount,
      removalCount: summary.removalCount,
      boardWipeCount: summary.boardWipeCount,
      protectionCount: summary.protectionCount,
      averageCmc: summary.averageCmc,
    ),
    'colors': summary.deckColors.toList()..sort(),
    'candidate_color_identity': summary.candidateColorIdentity.toList()..sort(),
    'color_identity_source': summary.colorIdentitySource,
    'trending': const <Map<String, dynamic>>[],
    'message':
        'OpenAI recommendations are advisory AI text; validate before use.',
  };
}

Future<Map<String, dynamic>> buildHeuristicRecommendationsForDeck({
  required String deckName,
  required String format,
  required List<Map<String, dynamic>> deckCards,
  required RecommendationCandidateFinder candidateFinder,
  RecommendationTrendFinder? trendFinder,
}) async {
  final summary = summarizeRecommendationDeck(
    deckCards: deckCards,
    format: format,
  );
  final addRecommendations = <Map<String, String>>[];
  final removeRecommendations = <Map<String, String>>[];

  Future<void> addCandidates({
    required List<String> roles,
    required List<String> oraclePatterns,
    required int limit,
    required String Function(String cardName) reasonFor,
    bool landOnly = false,
  }) async {
    final cards = await candidateFinder(
      roles: roles,
      oraclePatterns: oraclePatterns,
      deckColors: summary.candidateColorIdentity,
      excludeNames: summary.deckCardNames,
      limit: limit,
      format: format,
      landOnly: landOnly,
    );
    for (final cardName in cards) {
      addRecommendations.add({
        'card_name': cardName,
        'reason': reasonFor(cardName),
      });
    }
  }

  if (summary.rampCount < 10) {
    await addCandidates(
      roles: const ['ramp', 'ritual', 'mana_fixing'],
      oraclePatterns: const [
        '%add {%',
        '%add one mana%',
        '%search your library%land%',
        '%put%land%onto the battlefield%',
      ],
      limit: (10 - summary.rampCount).clamp(1, 5),
      reasonFor:
          (_) =>
              'Ramp — deck tem apenas ${summary.rampCount} fontes (recomendado: 10+)',
    );
  }

  if (summary.drawCount < 8) {
    await addCandidates(
      roles: const ['draw', 'card_selection'],
      oraclePatterns: const ['%draw%card%'],
      limit: (8 - summary.drawCount).clamp(1, 4),
      reasonFor:
          (_) =>
              'Card draw — deck tem apenas ${summary.drawCount} fontes (recomendado: 8+)',
    );
  }

  if (summary.removalCount < 6) {
    await addCandidates(
      roles: const ['removal'],
      oraclePatterns: const [
        '%destroy target%',
        '%exile target%',
        '%damage%target%',
      ],
      limit: (6 - summary.removalCount).clamp(1, 4),
      reasonFor:
          (_) =>
              'Remoção — deck tem apenas ${summary.removalCount} (recomendado: 6+)',
    );
  }

  if (summary.boardWipeCount < 2) {
    await addCandidates(
      roles: const ['wipe', 'board_wipe'],
      oraclePatterns: const [
        '%destroy all%creature%',
        '%exile all%',
        '%each creature%',
      ],
      limit: (3 - summary.boardWipeCount).clamp(1, 2),
      reasonFor:
          (_) =>
              'Board wipe — deck tem apenas ${summary.boardWipeCount} (recomendado: 2-3)',
    );
  }

  if (summary.protectionCount < 3) {
    await addCandidates(
      roles: const ['protection'],
      oraclePatterns: const [
        '%hexproof%',
        '%indestructible%',
        '%protection from%',
        '%ward%',
      ],
      limit: (3 - summary.protectionCount).clamp(1, 2),
      reasonFor:
          (_) => 'Proteção — deck tem apenas ${summary.protectionCount} fontes',
    );
  }

  if (format.toLowerCase() == 'commander' &&
      summary.landCount < recommendationCommanderFallbackLandFloor) {
    await addCandidates(
      roles: const ['mana_fixing', 'land', 'ramp'],
      oraclePatterns: const [
        '%add one mana of any color%',
        '%add one mana of any colour%',
        '%mana of any color%',
        '%mana of any colour%',
      ],
      limit: (recommendationCommanderFallbackLandFloor - summary.landCount)
          .clamp(1, 3),
      landOnly: true,
      reasonFor:
          (_) =>
              'Terreno/fixing — deck tem apenas ${summary.landCount} terrenos (recomendado: $recommendationCommanderLandTargetBand)',
    );
  }

  if (addRecommendations.isEmpty) {
    await addCandidates(
      roles: const [
        'engine',
        'wincon',
        'payoff',
        'enabler',
        'draw',
        'removal',
        'protection',
      ],
      oraclePatterns: const [
        '%whenever%',
        '%you may%',
        '%draw%card%',
        '%destroy target%',
        '%exile target%',
      ],
      limit: 3,
      reasonFor: (_) => 'Staple de alto impacto para $format',
    );
  }

  for (final card in summary.deckCards) {
    if (removeRecommendations.length >= 3) break;
    final typeLine = (card['type_line'] as String? ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine) || card['is_commander'] == true) {
      continue;
    }
    final cmc = (card['cmc'] as num?)?.toDouble() ?? 0;

    if (summary.archetype == 'aggro' && cmc > 5) {
      removeRecommendations.add({
        'card_name': card['name'] as String? ?? '',
        'reason':
            'CMC ${cmc.toInt()} é alto para aggro — considere alternativas mais baratas',
      });
    } else if (summary.archetype == 'control' &&
        cmc <= 1 &&
        summary.creatureRatio > 0.3) {
      final oracle = card['oracle_text'] as String? ?? '';
      if (!oracle.contains('draw') &&
          !oracle.contains('counter') &&
          !oracle.contains('destroy')) {
        removeRecommendations.add({
          'card_name': card['name'] as String? ?? '',
          'reason':
              'Criatura fraca para control — slot melhor usado com remoção/draw',
        });
      }
    }
  }

  if (summary.deckColors.length >= 3 && summary.landCount > 38) {
    final basicLands =
        summary.deckCards.where((card) {
          return basic_lands.isBasicLandCard(
            name: card['name'] as String? ?? '',
            typeLine: card['type_line'] as String? ?? '',
          );
        }).toList();
    if (basicLands.isNotEmpty && removeRecommendations.length < 5) {
      removeRecommendations.add({
        'card_name': basicLands.last['name'] as String? ?? '',
        'reason':
            'Terreno básico em excesso — trocar por terreno utilitário ou dual',
      });
    }
  }

  final trendingCards = <Map<String, dynamic>>[];
  if (trendFinder != null && summary.commanderNames.isNotEmpty) {
    final seen = <String>{};
    for (final commander in summary.commanderNames) {
      try {
        final trends = await trendFinder(commander);
        for (final trend in trends) {
          if (trend.direction != TrendDirection.rising) continue;
          final lower = trend.cardName.toLowerCase();
          if (summary.deckCardNames.contains(lower)) continue;
          if (!seen.add(lower)) continue;
          trendingCards.add({...trend.toJson(), 'commander': commander});
          if (trendingCards.length >= 8) break;
        }
      } catch (_) {
        // Trend snapshots are advisory. A failure must not break the fallback.
      }
      if (trendingCards.length >= 8) break;
    }

    for (final trend in trendingCards.take(2)) {
      final name = trend['card_name'] as String;
      if (addRecommendations.any((rec) => rec['card_name'] == name)) continue;
      final pct = ((trend['delta_inclusion'] as num) * 100).toStringAsFixed(1);
      addRecommendations.add({
        'card_name': name,
        'reason':
            'Em alta no EDHREC para ${trend['commander']} (+$pct% de inclusão recente)',
      });
    }
  }

  return buildHeuristicRecommendationsBody(
    deckName: deckName,
    format: format,
    archetype: summary.archetype,
    powerLevel: summary.powerLevel,
    totalCards: summary.totalCards,
    landCount: summary.landCount,
    creatureCount: summary.creatureCount,
    rampCount: summary.rampCount,
    drawCount: summary.drawCount,
    removalCount: summary.removalCount,
    boardWipeCount: summary.boardWipeCount,
    protectionCount: summary.protectionCount,
    averageCmc: summary.averageCmc,
    deckColors: summary.deckColors,
    candidateColorIdentity: summary.candidateColorIdentity,
    colorIdentitySource: summary.colorIdentitySource,
    addRecommendations: addRecommendations,
    removeRecommendations: removeRecommendations,
    trendingCards: trendingCards,
  );
}

Map<String, dynamic> buildHeuristicRecommendationsBody({
  required String deckName,
  required String format,
  required String archetype,
  required int powerLevel,
  required int totalCards,
  required int landCount,
  required int creatureCount,
  required int rampCount,
  required int drawCount,
  required int removalCount,
  required int boardWipeCount,
  required int protectionCount,
  required double averageCmc,
  required Iterable<String> deckColors,
  required Iterable<String> candidateColorIdentity,
  required String colorIdentitySource,
  required Iterable<Map<String, String>> addRecommendations,
  required Iterable<Map<String, String>> removeRecommendations,
  required Iterable<Map<String, dynamic>> trendingCards,
}) {
  final colors = deckColors.toList()..sort();
  final candidates = candidateColorIdentity.toList()..sort();
  final add = addRecommendations.take(5).toList();
  final remove = removeRecommendations.take(5).toList();
  final trending = trendingCards.toList();

  return {
    'archetype': archetype,
    'power_level': powerLevel,
    'analysis': buildHeuristicRecommendationsAnalysis(
      deckName: deckName,
      format: format,
      archetype: archetype,
      totalCards: totalCards,
      landCount: landCount,
      creatureCount: creatureCount,
      rampCount: rampCount,
      drawCount: drawCount,
      removalCount: removalCount,
      averageCmc: averageCmc,
    ),
    'recommendations': {'add': add, 'remove': remove},
    'statistics': buildRecommendationStatistics(
      totalCards: totalCards,
      landCount: landCount,
      creatureCount: creatureCount,
      rampCount: rampCount,
      drawCount: drawCount,
      removalCount: removalCount,
      boardWipeCount: boardWipeCount,
      protectionCount: protectionCount,
      averageCmc: averageCmc,
    ),
    'colors': colors,
    'candidate_color_identity': candidates,
    'color_identity_source': colorIdentitySource,
    'trending': trending,
    'source': heuristicRecommendationsSource,
    'message':
        'Análise baseada em heurísticas — configure OPENAI_API_KEY para IA generativa.',
  };
}

Map<String, dynamic> buildRecommendationStatistics({
  required int totalCards,
  required int landCount,
  required int creatureCount,
  required int rampCount,
  required int drawCount,
  required int removalCount,
  required int boardWipeCount,
  required int protectionCount,
  required double averageCmc,
}) {
  return {
    'total_cards': totalCards,
    'lands': landCount,
    'creatures': creatureCount,
    'ramp_sources': rampCount,
    'card_draw': drawCount,
    'removal': removalCount,
    'board_wipes': boardWipeCount,
    'protection': protectionCount,
    'average_cmc': averageCmc.toStringAsFixed(2),
  };
}

String buildHeuristicRecommendationsAnalysis({
  required String deckName,
  required String format,
  required String archetype,
  required int totalCards,
  required int landCount,
  required int creatureCount,
  required int rampCount,
  required int drawCount,
  required int removalCount,
  required double averageCmc,
}) {
  final analysis = StringBuffer();
  analysis.write('Deck "$deckName" ($format) — Arquétipo: $archetype. ');
  analysis.write('CMC médio: ${averageCmc.toStringAsFixed(1)}. ');
  analysis.write('$totalCards cartas ($landCount terrenos, ');
  analysis.write('$creatureCount criaturas). ');
  if (rampCount < 8) analysis.write('⚠️ Ramp insuficiente. ');
  if (drawCount < 8) analysis.write('⚠️ Card draw baixo. ');
  if (removalCount < 5) analysis.write('⚠️ Pouca remoção. ');
  return analysis.toString();
}
