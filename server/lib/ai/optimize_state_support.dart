import 'package:postgres/postgres.dart';

import '../logger.dart';
import 'optimize_deck_support.dart';

class DeckArchetypeAnalyzerCore {
  final List<Map<String, dynamic>> cards;
  final List<String> colors;

  DeckArchetypeAnalyzerCore(this.cards, this.colors);

  double calculateAverageCMC() {
    if (cards.isEmpty) return 0.0;

    double totalCMC = 0;
    int totalNonLandCopies = 0;

    for (final card in cards) {
      final typeLine = (card['type_line'] as String?) ?? '';
      if (typeLine.toLowerCase().contains('land')) continue;
      final qty = (card['quantity'] as int?) ?? 1;
      totalCMC += ((card['cmc'] as num?)?.toDouble() ?? 0.0) * qty;
      totalNonLandCopies += qty;
    }

    if (totalNonLandCopies == 0) return 0.0;
    return totalCMC / totalNonLandCopies;
  }

  Map<String, int> countCardTypes() {
    final counts = <String, int>{
      'creatures': 0,
      'instants': 0,
      'sorceries': 0,
      'enchantments': 0,
      'artifacts': 0,
      'planeswalkers': 0,
      'lands': 0,
      'battles': 0,
    };

    for (final card in cards) {
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      final qty = (card['quantity'] as int?) ?? 1;

      if (typeLine.contains('land')) counts['lands'] = counts['lands']! + qty;
      if (typeLine.contains('creature')) {
        counts['creatures'] = counts['creatures']! + qty;
      }
      if (typeLine.contains('planeswalker')) {
        counts['planeswalkers'] = counts['planeswalkers']! + qty;
      }
      if (typeLine.contains('instant')) {
        counts['instants'] = counts['instants']! + qty;
      }
      if (typeLine.contains('sorcery')) {
        counts['sorceries'] = counts['sorceries']! + qty;
      }
      if (typeLine.contains('artifact')) {
        counts['artifacts'] = counts['artifacts']! + qty;
      }
      if (typeLine.contains('enchantment')) {
        counts['enchantments'] = counts['enchantments']! + qty;
      }
      if (typeLine.contains('battle')) {
        counts['battles'] = counts['battles']! + qty;
      }
    }

    return counts;
  }

  String detectArchetype() {
    final avgCMC = calculateAverageCMC();
    final typeCounts = countCardTypes();
    final totalCards =
        cards.fold<int>(0, (s, c) => s + ((c['quantity'] as int?) ?? 1));
    final totalNonLands = totalCards - (typeCounts['lands'] ?? 0);

    if (totalNonLands == 0) return 'unknown';

    final creatureRatio = (typeCounts['creatures'] ?? 0) / totalNonLands;
    final instantSorceryRatio =
        ((typeCounts['instants'] ?? 0) + (typeCounts['sorceries'] ?? 0)) /
            totalNonLands;
    final enchantmentRatio = (typeCounts['enchantments'] ?? 0) / totalNonLands;

    if (avgCMC < 2.5 && creatureRatio > 0.4) return 'aggro';
    if (avgCMC > 3.0 && creatureRatio < 0.25 && instantSorceryRatio > 0.35) {
      return 'control';
    }
    if (instantSorceryRatio > 0.4 && creatureRatio < 0.3) return 'combo';
    if (enchantmentRatio > 0.3) return 'stax';
    if (avgCMC >= 2.5 &&
        avgCMC <= 3.5 &&
        creatureRatio >= 0.25 &&
        creatureRatio <= 0.45) {
      return 'midrange';
    }
    return 'midrange';
  }

  Map<String, dynamic> analyzeManaBase() {
    final manaSymbols = {'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0};
    final landSources = {'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'Any': 0};
    var landCount = 0;

    for (final card in cards) {
      final manaCost = (card['mana_cost'] as String?) ?? '';
      final qty = (card['quantity'] as int?) ?? 1;
      for (final color in manaSymbols.keys) {
        manaSymbols[color] =
            manaSymbols[color]! + (manaCost.split(color).length - 1) * qty;
      }
    }

    for (final card in cards) {
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      final qty = (card['quantity'] as int?) ?? 1;
      if (typeLine.contains('land')) {
        landCount += qty;
        final cardColors = (card['colors'] as List?)?.cast<String>() ?? [];
        final oracleText =
            ((card['oracle_text'] as String?) ?? '').toLowerCase();

        if (oracleText.contains('add one mana of any color') ||
            oracleText.contains('add one mana of any type')) {
          landSources['Any'] = landSources['Any']! + qty;
        } else if (oracleText.contains('search your library for') &&
            (oracleText.contains('plains') ||
                oracleText.contains('island') ||
                oracleText.contains('swamp') ||
                oracleText.contains('mountain') ||
                oracleText.contains('forest'))) {
          landSources['Any'] = landSources['Any']! + qty;
        } else {
          final detectedColors = detectManaColorsFromOracleText(oracleText);
          if (detectedColors.isNotEmpty) {
            for (final color in detectedColors) {
              if (landSources.containsKey(color)) {
                landSources[color] = landSources[color]! + qty;
              }
            }
          } else if (cardColors.isNotEmpty) {
            for (final color in cardColors) {
              if (landSources.containsKey(color)) {
                landSources[color] = landSources[color]! + qty;
              }
            }
          }
        }
      }
    }

    return {
      'symbols': manaSymbols,
      'sources': landSources,
      'land_count': landCount,
      'assessment': assessManaBase(manaSymbols, landSources, landCount),
    };
  }

  Map<String, dynamic> generateAnalysis() {
    final avgCMC = calculateAverageCMC();
    final typeCounts = countCardTypes();
    final detectedArchetype = detectArchetype();
    final manaAnalysis = analyzeManaBase();

    int totalCards = 0;
    for (final card in cards) {
      totalCards += (card['quantity'] as int?) ?? 1;
    }

    return {
      'detected_archetype': detectedArchetype,
      'average_cmc': avgCMC.toStringAsFixed(2),
      'type_distribution': typeCounts,
      'total_cards': totalCards,
      'mana_curve_assessment': assessManaCurve(avgCMC, detectedArchetype),
      'mana_base_assessment': manaAnalysis['assessment'],
      'archetype_confidence':
          calculateConfidence(avgCMC, typeCounts, detectedArchetype),
    };
  }

  static Set<String> detectManaColorsFromOracleText(String oracleText) {
    final colors = <String>{};
    final colorMap = {
      'w': 'W',
      'u': 'U',
      'b': 'B',
      'r': 'R',
      'g': 'G',
    };
    final manaSymbolPattern = RegExp(r'\{([wubrgWUBRG])\}');
    for (final match in manaSymbolPattern.allMatches(oracleText)) {
      final symbol = match.group(1)!.toLowerCase();
      if (colorMap.containsKey(symbol)) {
        colors.add(colorMap[symbol]!);
      }
    }
    return colors;
  }

  static String assessManaBase(
    Map<String, int> symbols,
    Map<String, int> sources,
    int landCount,
  ) {
    if (symbols.isEmpty) return 'N/A';
    final totalSymbols = symbols.values.fold<int>(0, (a, b) => a + b);
    if (totalSymbols == 0) return 'N/A';

    final issues = <String>[];

    if (landCount < 26) {
      issues
          .add('Poucos terrenos para Commander (Tem $landCount, ideal >= 34)');
    } else if (landCount > 45) {
      issues.add('Terrenos em excesso (Tem $landCount, ideal <= 40)');
    }

    symbols.forEach((color, count) {
      if (count > 0) {
        final percent = count / totalSymbols;
        final sourceCount = sources[color]! + sources['Any']!;

        if (percent > 0.30 && sourceCount < 15) {
          issues.add('Falta mana $color (Tem $sourceCount fontes, ideal > 15)');
        } else if (percent > 0.10 && sourceCount < 10) {
          issues.add('Falta mana $color (Tem $sourceCount fontes, ideal > 10)');
        }
      }
    });

    if (issues.isEmpty) return 'Base de mana equilibrada';
    return issues.join('. ');
  }

  static String assessManaCurve(double avgCMC, String archetype) {
    switch (archetype) {
      case 'aggro':
        if (avgCMC > 2.5) {
          return 'ALERTA: Curva muito alta para Aggro. Ideal: < 2.5';
        }
        if (avgCMC < 1.8) return 'BOA: Curva agressiva ideal';
        return 'OK: Curva aceitável para Aggro';
      case 'control':
        if (avgCMC < 2.5) {
          return 'ALERTA: Curva muito baixa para Control. Ideal: > 3.0';
        }
        return 'BOA: Curva adequada para Control';
      case 'midrange':
        if (avgCMC < 2.3 || avgCMC > 3.8) {
          return 'ALERTA: Curva fora do ideal para Midrange (2.5-3.5)';
        }
        return 'BOA: Curva equilibrada para Midrange';
      default:
        return 'OK: Curva dentro de parâmetros aceitáveis';
    }
  }

  String calculateConfidence(
    double avgCMC,
    Map<String, int> counts,
    String archetype,
  ) {
    final totalCards =
        cards.fold<int>(0, (s, c) => s + ((c['quantity'] as int?) ?? 1));
    final totalNonLands = totalCards - (counts['lands'] ?? 0);
    if (totalNonLands < 20) return 'baixa';

    final creatureRatio = (counts['creatures'] ?? 0) / totalNonLands;

    switch (archetype) {
      case 'aggro':
        if (avgCMC < 2.2 && creatureRatio > 0.5) return 'alta';
        if (avgCMC < 2.8 && creatureRatio > 0.35) return 'média';
        return 'baixa';
      case 'control':
        if (avgCMC > 3.2 && creatureRatio < 0.2) return 'alta';
        return 'média';
      default:
        return 'média';
    }
  }
}

class DeckThemeProfileResult {
  final String theme;
  final String confidence;
  final double matchScore;
  final List<String> coreCards;

  const DeckThemeProfileResult({
    required this.theme,
    required this.confidence,
    required this.matchScore,
    required this.coreCards,
  });

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'confidence': confidence,
        'match_score': matchScore,
        'core_cards': coreCards,
      };
}

class DeckOptimizationStateResult {
  const DeckOptimizationStateResult({
    required this.status,
    required this.recommendedMode,
    required this.suggestedScope,
    required this.reasons,
    required this.severityScore,
    this.repairPlan = const <String, dynamic>{},
  });

  final String status;
  final String recommendedMode;
  final String suggestedScope;
  final List<String> reasons;
  final int severityScore;
  final Map<String, dynamic> repairPlan;

  Map<String, dynamic> toJson() => {
        'status': status,
        'recommended_mode': recommendedMode,
        'suggested_scope': suggestedScope,
        'severity_score': severityScore,
        'reasons': reasons,
        if (repairPlan.isNotEmpty) 'repair_plan': repairPlan,
      };
}

DeckOptimizationStateResult assessDeckOptimizationStateCore({
  required List<Map<String, dynamic>> cards,
  required Map<String, dynamic> deckAnalysis,
  required String deckFormat,
  required int currentTotalCards,
  required Set<String> commanderColorIdentity,
}) {
  final maxTotal =
      deckFormat == 'commander' ? 100 : (deckFormat == 'brawl' ? 60 : null);
  if (maxTotal != null && currentTotalCards < maxTotal) {
    final missing = maxTotal - currentTotalCards;
    return DeckOptimizationStateResult(
      status: 'incomplete',
      recommendedMode: 'complete',
      suggestedScope: 'fill_missing_slots',
      severityScore: (missing * 3).clamp(0, 100),
      reasons: [
        'O deck ainda está incompleto ($currentTotalCards/$maxTotal cartas).',
      ],
      repairPlan: {
        'missing_cards': missing,
        'summary':
            'Preencha os slots faltantes antes de avaliar micro-otimizações.',
      },
    );
  }

  if (deckFormat != 'commander' && deckFormat != 'brawl') {
    return const DeckOptimizationStateResult(
      status: 'healthy',
      recommendedMode: 'optimize',
      suggestedScope: 'micro_swaps',
      severityScore: 0,
      reasons: <String>[],
    );
  }

  final deckColors = <String>{};
  for (final card in cards) {
    deckColors.addAll((card['colors'] as List?)?.cast<String>() ?? const []);
  }
  final analyzer = DeckArchetypeAnalyzerCore(cards, deckColors.toList());
  final manaBase = analyzer.analyzeManaBase();
  final typeDistribution =
      (deckAnalysis['type_distribution'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

  final commanders = cards
      .where((card) => card['is_commander'] == true)
      .toList(growable: false);
  final commanderText = commanders
      .map((card) => (card['oracle_text'] as String?) ?? '')
      .join(' ')
      .toLowerCase();

  final landCount = (typeDistribution['lands'] as int?) ?? 0;
  final instantCount = (typeDistribution['instants'] as int?) ?? 0;
  final sorceryCount = (typeDistribution['sorceries'] as int?) ?? 0;
  final artifactCount = (typeDistribution['artifacts'] as int?) ?? 0;
  final enchantmentCount = (typeDistribution['enchantments'] as int?) ?? 0;
  final nonLandCount = currentTotalCards - landCount;
  final instantSorceryCount = instantCount + sorceryCount;
  final manaAssessment =
      (deckAnalysis['mana_base_assessment']?.toString() ?? '');
  final manaAssessmentLower = manaAssessment.toLowerCase();
  final archetypeConfidence =
      (deckAnalysis['archetype_confidence']?.toString() ?? '').toLowerCase();
  final sources = (manaBase['sources'] as Map?)?.cast<String, int>() ??
      const <String, int>{};
  final anySource = sources['Any'] ?? 0;

  final reasons = <String>[];
  var severeIssues = 0;
  var moderateIssues = 0;

  void addReason(String message, {required bool severe}) {
    reasons.add(message);
    if (severe) {
      severeIssues++;
    } else {
      moderateIssues++;
    }
  }

  if (commanders.isEmpty) {
    addReason(
      'O deck não tem comandante marcado e não dá para inferir um plano coerente de optimize.',
      severe: true,
    );
  }

  if (landCount >= 55) {
    addReason(
      'O deck está com $landCount terrenos, muito acima do intervalo saudável para $deckFormat.',
      severe: true,
    );
  } else if (landCount > 45) {
    addReason(
      'O deck está com $landCount terrenos e tende a floodar antes de gerar valor.',
      severe: false,
    );
  }

  if (landCount > 0 && nonLandCount < 25) {
    addReason(
      'O deck tem apenas $nonLandCount não-terrenos, insuficiente para sustainar o plano do comandante.',
      severe: true,
    );
  }

  if (landCount > 0 && landCount <= 24) {
    addReason(
      'O deck está com apenas $landCount terrenos, abaixo do mínimo seguro para Commander.',
      severe: true,
    );
  }

  if (manaAssessmentLower.contains('falta mana')) {
    addReason(
      'A base de mana ainda não cobre as cores exigidas pelo comandante.',
      severe: false,
    );
  }

  for (final color in commanderColorIdentity) {
    final sourceCount = (sources[color] ?? 0) + anySource;
    if (sourceCount == 0) {
      addReason(
        'A identidade $color do comandante não possui nenhuma fonte funcional de mana no deck.',
        severe: true,
      );
    }
  }

  if (commanderSignalsSpellslinger(commanderText) && instantSorceryCount < 10) {
    addReason(
      'O comandante pede instants/sorceries, mas o deck só tem $instantSorceryCount cartas desse tipo.',
      severe: true,
    );
  }

  if (commanderSignalsArtifacts(commanderText) && artifactCount < 6) {
    addReason(
      'O comandante depende de artefatos, mas o deck só apresenta $artifactCount artefatos.',
      severe: false,
    );
  }

  if (commanderSignalsEnchantments(commanderText) && enchantmentCount < 6) {
    addReason(
      'O comandante depende de encantamentos, mas o deck só apresenta $enchantmentCount encantamentos.',
      severe: false,
    );
  }

  if (archetypeConfidence == 'baixa' && nonLandCount < 35) {
    addReason(
      'O deck ainda não tem massa crítica suficiente para o arquétipo detectado.',
      severe: false,
    );
  }

  final needsRepair = severeIssues > 0 || moderateIssues >= 3;
  if (!needsRepair) {
    return const DeckOptimizationStateResult(
      status: 'healthy',
      recommendedMode: 'optimize',
      suggestedScope: 'micro_swaps',
      severityScore: 0,
      reasons: <String>[],
    );
  }

  return DeckOptimizationStateResult(
    status: 'needs_repair',
    recommendedMode: 'repair',
    suggestedScope: 'rebuild_core',
    severityScore: (severeIssues * 30 + moderateIssues * 12).clamp(0, 100),
    reasons: reasons.take(6).toList(),
    repairPlan: buildDeckRepairPlan(
      deckFormat: deckFormat,
      landCount: landCount,
      nonLandCount: nonLandCount,
      instantSorceryCount: instantSorceryCount,
      artifactCount: artifactCount,
      enchantmentCount: enchantmentCount,
      commanderColorIdentity: commanderColorIdentity,
      commanderText: commanderText,
      manaAssessment: manaAssessment,
    ),
  );
}

Future<DeckThemeProfileResult> detectThemeProfile(
  List<Map<String, dynamic>> cards, {
  required List<String> commanders,
  required Pool pool,
}) async {
  int qty(Map<String, dynamic> c) => (c['quantity'] as int?) ?? 1;

  final cardNames = cards
      .map((c) => c['name'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toList();
  final metaInsights = <String, Map<String, dynamic>>{};

  if (cardNames.isNotEmpty) {
    try {
      final result = await pool.execute(
        Sql.named(
            'SELECT card_name, usage_count, common_archetypes, learned_role FROM card_meta_insights WHERE LOWER(card_name) IN (${List.generate(cardNames.length, (i) => 'LOWER(@name$i)').join(', ')})'),
        parameters: {
          for (var i = 0; i < cardNames.length; i++) 'name$i': cardNames[i]
        },
      );
      for (final row in result) {
        final name = (row[0] as String).toLowerCase();
        metaInsights[name] = {
          'usage_count': row[1] as int? ?? 0,
          'common_archetypes':
              row[2] is List ? (row[2] as List).cast<String>() : <String>[],
          'learned_role': row[3] as String? ?? '',
        };
      }
    } catch (e) {
      Log.w('[_detectThemeProfile] Falha ao buscar meta insights: $e');
    }
  }

  final commanderLower = commanders.map((e) => e.toLowerCase()).toSet();
  final commanderOracle = cards
      .where((c) => c['is_commander'] == true)
      .map((c) => ((c['oracle_text'] as String?) ?? '').toLowerCase())
      .join(' ');

  var totalNonLands = 0;
  var artifactCount = 0;
  var enchantmentCount = 0;
  var instantSorceryCount = 0;
  var tokenReferences = 0;
  var reanimatorReferences = 0;
  var aristocratReferences = 0;
  var voltronReferences = 0;
  var landfallReferences = 0;
  var wheelReferences = 0;
  var staxReferences = 0;
  var counterReferences = 0;

  final creatureSubtypes = <String, int>{};
  final cardData = <Map<String, dynamic>>[];

  for (final c in cards) {
    final name = (c['name'] as String?) ?? '';
    if (name.isEmpty) continue;
    final typeLine = ((c['type_line'] as String?) ?? '').toLowerCase();
    final oracle = ((c['oracle_text'] as String?) ?? '').toLowerCase();
    final q = qty(c);

    final isLand = typeLine.contains('land');
    if (!isLand) totalNonLands += q;

    cardData.add({
      'name': name,
      'typeLine': typeLine,
      'oracle': oracle,
      'quantity': q,
      'isLand': isLand,
    });

    if (!isLand && typeLine.contains('artifact')) artifactCount += q;
    if (!isLand && typeLine.contains('enchantment')) enchantmentCount += q;
    if (!isLand &&
        (typeLine.contains('instant') || typeLine.contains('sorcery'))) {
      instantSorceryCount += q;
    }

    if (oracle.contains('create') && oracle.contains('token')) {
      tokenReferences += q;
    }
    if (oracle.contains('populate') ||
        (oracle.contains('whenever') && oracle.contains('token'))) {
      tokenReferences += q;
    }
    if ((oracle.contains('return') &&
            oracle.contains('from') &&
            oracle.contains('graveyard')) ||
        oracle.contains('reanimate') ||
        oracle.contains('unearth') ||
        (oracle.contains('put') &&
            oracle.contains('graveyard') &&
            oracle.contains('onto the battlefield'))) {
      reanimatorReferences += q;
    }
    if ((oracle.contains('sacrifice') &&
            (oracle.contains('whenever') || oracle.contains('you may'))) ||
        (oracle.contains('when') && oracle.contains('dies')) ||
        oracle.contains('drain')) {
      aristocratReferences += q;
    }
    if (typeLine.contains('equipment') ||
        (typeLine.contains('aura') && oracle.contains('enchant creature')) ||
        oracle.contains('double strike') ||
        oracle.contains('hexproof') ||
        (oracle.contains('equipped creature') && oracle.contains('+')) ||
        (oracle.contains('enchanted creature') && oracle.contains('+'))) {
      voltronReferences += q;
    }
    if (oracle.contains('landfall') ||
        (oracle.contains('whenever') &&
            oracle.contains('land') &&
            oracle.contains('enters'))) {
      landfallReferences += q;
    }
    if ((oracle.contains('each player') &&
            oracle.contains('discards') &&
            oracle.contains('draws')) ||
        (oracle.contains('discard') &&
            oracle.contains('hand') &&
            oracle.contains('draw')) ||
        (oracle.contains('whenever') && oracle.contains('draws a card'))) {
      wheelReferences += q;
    }
    if (oracle.contains('each opponent') &&
            (oracle.contains('can\'t') ||
                oracle.contains('pays') ||
                oracle.contains('sacrifices')) ||
        (oracle.contains('nonland permanent') &&
            oracle.contains('doesn\'t untap')) ||
        (oracle.contains('players can\'t') &&
            (oracle.contains('cast') || oracle.contains('search')))) {
      staxReferences += q;
    }
    if (oracle.contains('-1/-1 counter') ||
        oracle.contains('proliferate') ||
        oracle.contains('put a counter on') ||
        oracle.contains('remove a counter from')) {
      counterReferences += q;
      if (c['isLand'] == false &&
          commanderLower.contains(name.toLowerCase()) &&
          (oracle.contains('-1/-1 counter') ||
              oracle.contains('proliferate'))) {
        counterReferences += q * 3;
      }
    }

    if (typeLine.contains('creature')) {
      final dashIndex = typeLine.indexOf('—');
      if (dashIndex != -1) {
        final subtypes =
            typeLine.substring(dashIndex + 1).trim().split(RegExp(r'\s+'));
        for (final st in subtypes) {
          if (st.isNotEmpty && st != 'creature') {
            creatureSubtypes[st] = (creatureSubtypes[st] ?? 0) + q;
          }
        }
      }
    }
  }

  String? dominantTribe;
  int tribalCount = 0;
  if (creatureSubtypes.isNotEmpty) {
    final sorted = creatureSubtypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    dominantTribe = sorted.first.key;
    tribalCount = sorted.first.value;
  }

  String theme;
  double score;

  if (totalNonLands <= 0) {
    theme = 'generic';
    score = 0.0;
  } else {
    final themeScores = <String, double>{
      'artifacts': artifactCount / totalNonLands >= 0.30
          ? artifactCount / totalNonLands
          : 0.0,
      'enchantments': enchantmentCount / totalNonLands >= 0.30
          ? enchantmentCount / totalNonLands
          : 0.0,
      'spellslinger': instantSorceryCount / totalNonLands >= 0.35
          ? instantSorceryCount / totalNonLands
          : 0.0,
      'tokens': tokenReferences / totalNonLands >= 0.15
          ? tokenReferences / totalNonLands
          : 0.0,
      'reanimator': reanimatorReferences / totalNonLands >= 0.12
          ? reanimatorReferences / totalNonLands
          : 0.0,
      'aristocrats': aristocratReferences / totalNonLands >= 0.12
          ? aristocratReferences / totalNonLands
          : 0.0,
      'voltron': voltronReferences / totalNonLands >= 0.15
          ? voltronReferences / totalNonLands
          : 0.0,
      'landfall': landfallReferences / totalNonLands >= 0.10
          ? landfallReferences / totalNonLands
          : 0.0,
      'wheels': wheelReferences / totalNonLands >= 0.10
          ? wheelReferences / totalNonLands
          : 0.0,
      'stax': staxReferences / totalNonLands >= 0.10
          ? staxReferences / totalNonLands
          : 0.0,
      'counters': counterReferences / totalNonLands >= 0.12
          ? counterReferences / totalNonLands
          : 0.0,
      'tribal': tribalCount / totalNonLands >= 0.25
          ? tribalCount / totalNonLands
          : 0.0,
    };

    if (commanderOracle.contains('-1/-1 counter') ||
        commanderOracle.contains('proliferate')) {
      themeScores['counters'] = (themeScores['counters'] ?? 0.0) + 0.55;
      if ((themeScores['tribal'] ?? 0.0) < 0.55) {
        themeScores['tribal'] = (themeScores['tribal'] ?? 0.0) * 0.5;
      }
    }
    if (commanderOracle.contains('instant or sorcery')) {
      themeScores['spellslinger'] = (themeScores['spellslinger'] ?? 0.0) + 0.35;
    }
    if (commanderOracle.contains('artifact')) {
      themeScores['artifacts'] = (themeScores['artifacts'] ?? 0.0) + 0.25;
    }
    if (commanderOracle.contains('enchantment')) {
      themeScores['enchantments'] = (themeScores['enchantments'] ?? 0.0) + 0.25;
    }
    if (commanderOracle.contains('landfall') ||
        (commanderOracle.contains('land') &&
            commanderOracle.contains('enters the battlefield'))) {
      themeScores['landfall'] = (themeScores['landfall'] ?? 0.0) + 0.25;
    }

    MapEntry<String, double>? best;
    for (final entry in themeScores.entries) {
      if (best == null || entry.value > best.value) {
        best = entry;
      }
    }

    if (best != null && best.value > 0.0) {
      theme = best.key == 'tribal' && dominantTribe != null
          ? 'tribal-$dominantTribe'
          : best.key;
      score = best.value;
    } else {
      theme = 'generic';
      score = 0.0;
    }
  }

  final confidence = score >= 0.35
      ? 'alta'
      : (score >= 0.20 ? 'média' : (score >= 0.10 ? 'baixa' : 'baixa'));

  final core = <String, int>{};

  for (final c in cardData) {
    final name = c['name'] as String;
    final nameLower = name.toLowerCase();
    final typeLine = c['typeLine'] as String;
    final oracle = c['oracle'] as String;
    final q = c['quantity'] as int;
    final isLand = c['isLand'] as bool;

    if (isLand) continue;

    var impactScore = 0;

    final insight = metaInsights[nameLower];
    if (insight != null) {
      final usageCount = insight['usage_count'] as int;
      final archetypes = insight['common_archetypes'] as List<String>;
      final learnedRole = insight['learned_role'] as String;

      if (usageCount > 0) {
        impactScore += (usageCount * 1.0).clamp(5, 40).round();
      }

      final themeSimplified = theme.replaceAll('tribal-', '');
      for (final arch in archetypes) {
        if (arch.contains(themeSimplified) || themeSimplified.contains(arch)) {
          impactScore += 20;
          break;
        }
      }

      if ((theme == 'spellslinger' && learnedRole.contains('counter')) ||
          (theme == 'reanimator' && learnedRole.contains('reanimate')) ||
          (theme == 'artifacts' && learnedRole.contains('artifact')) ||
          (theme == 'counters' &&
              (learnedRole.contains('counter') ||
                  learnedRole.contains('proliferate'))) ||
          (theme.startsWith('tribal') && learnedRole.contains('tribal'))) {
        impactScore += 15;
      }
    }

    if (commanderLower.contains(nameLower)) impactScore += 100;
    if (q >= 4) impactScore += 15;

    if (oracle.contains('get +') || oracle.contains('gets +')) {
      if (dominantTribe != null && oracle.contains(dominantTribe)) {
        impactScore += 40;
      }
      if (oracle.contains('creatures you control') && oracle.contains('+')) {
        impactScore += 25;
      }
    }

    if (theme.contains('token')) {
      if (oracle.contains('whenever') && oracle.contains('token')) {
        impactScore += 35;
      }
      if (oracle.contains('for each') && oracle.contains('token')) {
        impactScore += 35;
      }
      if (oracle.contains('double') && oracle.contains('token')) {
        impactScore += 50;
      }
    }

    if (theme == 'aristocrats') {
      if (oracle.contains('whenever') && oracle.contains('dies')) {
        impactScore += 35;
      }
      if (oracle.contains('whenever') && oracle.contains('sacrifice')) {
        impactScore += 35;
      }
      if (oracle.contains('drain') || oracle.contains('each opponent loses')) {
        impactScore += 30;
      }
    }

    if (theme == 'reanimator') {
      if (oracle.contains('return') &&
          oracle.contains('graveyard') &&
          oracle.contains('battlefield')) {
        impactScore += 35;
      }
    }

    if (theme == 'spellslinger') {
      if (oracle.contains('whenever you cast') &&
          (oracle.contains('instant') || oracle.contains('sorcery'))) {
        impactScore += 35;
      }
      if (oracle.contains('copy') && oracle.contains('spell')) {
        impactScore += 30;
      }
      if (oracle.contains('storm')) impactScore += 40;
    }

    if (theme == 'landfall' && oracle.contains('landfall')) {
      impactScore += 35;
    }

    if (theme == 'voltron') {
      if (oracle.contains('equipped creature') && oracle.contains('+')) {
        impactScore += 30;
      }
      if (oracle.contains('enchanted creature') && oracle.contains('+')) {
        impactScore += 30;
      }
      if (oracle.contains('double strike') || oracle.contains('hexproof')) {
        impactScore += 25;
      }
    }

    if (theme.startsWith('tribal-') && dominantTribe != null) {
      final isTribalType = typeLine.contains(dominantTribe);
      final mentionsTribe = oracle.contains(dominantTribe);

      if (isTribalType && mentionsTribe) {
        impactScore += 35;
      } else if (mentionsTribe && !isTribalType) {
        impactScore += 25;
      }

      if (oracle.contains('creature type') && oracle.contains('choose')) {
        impactScore += 20;
      }
    }

    if (theme == 'artifacts') {
      if (oracle.contains('whenever') && oracle.contains('artifact')) {
        impactScore += 30;
      }
      if (oracle.contains('for each artifact')) impactScore += 35;
    }

    if (theme == 'enchantments') {
      if (oracle.contains('whenever') && oracle.contains('enchantment')) {
        impactScore += 30;
      }
      if (oracle.contains('constellation')) impactScore += 35;
    }

    if (theme == 'wheels') {
      if (oracle.contains('whenever') && oracle.contains('draws')) {
        impactScore += 35;
      }
      if (oracle.contains('discard') &&
          oracle.contains('hand') &&
          oracle.contains('draw')) {
        impactScore += 40;
      }
    }

    if (theme == 'stax') {
      if (oracle.contains('can\'t') || oracle.contains('doesn\'t untap')) {
        impactScore += 30;
      }
    }

    if (theme == 'counters') {
      if (oracle.contains('-1/-1 counter') || oracle.contains('proliferate')) {
        impactScore += 35;
      }
      if (oracle.contains('put a counter on') ||
          oracle.contains('remove a counter from')) {
        impactScore += 20;
      }
    }

    if (impactScore >= 25) {
      core[name] = impactScore;
    }
  }

  final sortedCore = core.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final coreCards = sortedCore.take(10).map((e) => e.key).toList();

  return DeckThemeProfileResult(
    theme: theme,
    confidence: confidence,
    matchScore: score,
    coreCards: coreCards,
  );
}
