class DeckArchetypeAnalyzer {
  DeckArchetypeAnalyzer(this.cards, this.colors);

  final List<Map<String, dynamic>> cards;
  final List<String> colors;

  double calculateAverageCMC() {
    if (cards.isEmpty) return 0.0;

    double totalCMC = 0;
    var totalNonLandCopies = 0;

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
      if (!typeLine.contains('land')) continue;

      landCount += qty;
      final cardColors = (card['colors'] as List?)?.cast<String>() ?? [];
      final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();

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
        final detectedColors = _detectManaColorsFromOracleText(oracleText);
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

    return {
      'symbols': manaSymbols,
      'sources': landSources,
      'land_count': landCount,
      'assessment': _assessManaBase(manaSymbols, landSources, landCount),
    };
  }

  static Set<String> _detectManaColorsFromOracleText(String oracleText) {
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

  String _assessManaBase(
    Map<String, int> symbols,
    Map<String, int> sources,
    int landCount,
  ) {
    if (symbols.isEmpty) return 'N/A';
    final totalSymbols = symbols.values.fold<int>(0, (a, b) => a + b);
    if (totalSymbols == 0) return 'N/A';

    final issues = <String>[];

    if (landCount < 26) {
      issues.add('Poucos terrenos para Commander (Tem $landCount, ideal >= 34)');
    } else if (landCount > 45) {
      issues.add('Terrenos em excesso (Tem $landCount, ideal <= 40)');
    }

    symbols.forEach((color, count) {
      if (count <= 0) return;
      final percent = count / totalSymbols;
      final sourceCount = sources[color]! + sources['Any']!;

      if (percent > 0.30 && sourceCount < 15) {
        issues.add('Falta mana $color (Tem $sourceCount fontes, ideal > 15)');
      } else if (percent > 0.10 && sourceCount < 10) {
        issues.add('Falta mana $color (Tem $sourceCount fontes, ideal > 10)');
      }
    });

    if (issues.isEmpty) return 'Base de mana equilibrada';
    return issues.join('. ');
  }

  Map<String, dynamic> generateAnalysis() {
    final avgCMC = calculateAverageCMC();
    final typeCounts = countCardTypes();
    final detectedArchetype = detectArchetype();
    final manaAnalysis = analyzeManaBase();

    var totalCards = 0;
    for (final card in cards) {
      totalCards += (card['quantity'] as int?) ?? 1;
    }

    return {
      'detected_archetype': detectedArchetype,
      'average_cmc': avgCMC.toStringAsFixed(2),
      'type_distribution': typeCounts,
      'total_cards': totalCards,
      'mana_curve_assessment': _assessManaCurve(avgCMC, detectedArchetype),
      'mana_base_assessment': manaAnalysis['assessment'],
      'archetype_confidence':
          _calculateConfidence(avgCMC, typeCounts, detectedArchetype),
    };
  }

  String _assessManaCurve(double avgCMC, String archetype) {
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

  String _calculateConfidence(
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

class DeckOptimizationState {
  const DeckOptimizationState({
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

DeckOptimizationState assessDeckOptimizationState({
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
    return DeckOptimizationState(
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
    return const DeckOptimizationState(
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
  final analyzer = DeckArchetypeAnalyzer(cards, deckColors.toList());
  final manaBase = analyzer.analyzeManaBase();
  final typeDistribution =
      (deckAnalysis['type_distribution'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

  final commanders =
      cards.where((card) => card['is_commander'] == true).toList(growable: false);
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
  final manaAssessment = (deckAnalysis['mana_base_assessment']?.toString() ?? '');
  final manaAssessmentLower = manaAssessment.toLowerCase();
  final archetypeConfidence =
      (deckAnalysis['archetype_confidence']?.toString() ?? '').toLowerCase();
  final sources =
      (manaBase['sources'] as Map?)?.cast<String, int>() ?? const <String, int>{};
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

  if (_commanderSignalsSpellslinger(commanderText) && instantSorceryCount < 10) {
    addReason(
      'O comandante pede instants/sorceries, mas o deck só tem $instantSorceryCount cartas desse tipo.',
      severe: true,
    );
  }

  if (_commanderSignalsArtifacts(commanderText) && artifactCount < 6) {
    addReason(
      'O comandante depende de artefatos, mas o deck só apresenta $artifactCount artefatos.',
      severe: false,
    );
  }

  if (_commanderSignalsEnchantments(commanderText) && enchantmentCount < 6) {
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
    return const DeckOptimizationState(
      status: 'healthy',
      recommendedMode: 'optimize',
      suggestedScope: 'micro_swaps',
      severityScore: 0,
      reasons: <String>[],
    );
  }

  return DeckOptimizationState(
    status: 'needs_repair',
    recommendedMode: 'repair',
    suggestedScope: 'rebuild_core',
    severityScore: (severeIssues * 30 + moderateIssues * 12).clamp(0, 100),
    reasons: reasons.take(6).toList(),
    repairPlan: _buildDeckRepairPlan(
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

Map<String, dynamic> _buildDeckRepairPlan({
  required String deckFormat,
  required int landCount,
  required int nonLandCount,
  required int instantSorceryCount,
  required int artifactCount,
  required int enchantmentCount,
  required Set<String> commanderColorIdentity,
  required String commanderText,
  required String manaAssessment,
}) {
  final targetLandCount = deckFormat == 'brawl' ? 25 : 36;
  final priorityRepairs = <String>[];
  final roleTargets = <String, int>{};

  if (landCount > targetLandCount) {
    priorityRepairs.add(
      'Cortar aproximadamente ${landCount - targetLandCount} terrenos excedentes antes de avaliar upgrades finos.',
    );
  }

  if (commanderColorIdentity.isNotEmpty &&
      manaAssessment.toLowerCase().contains('falta mana')) {
    priorityRepairs.add(
      'Trocar terrenos incolores por fontes ${commanderColorIdentity.join('/')} até estabilizar a base.',
    );
  }

  if (_commanderSignalsSpellslinger(commanderText) && instantSorceryCount < 24) {
    roleTargets['instants_or_sorceries_to_add'] = 24 - instantSorceryCount;
    priorityRepairs.add(
      'Reconstruir o core de spells para alinhar o deck ao plano spellslinger do comandante.',
    );
  }

  if (_commanderSignalsArtifacts(commanderText) && artifactCount < 12) {
    roleTargets['artifacts_to_add'] = 12 - artifactCount;
  }

  if (_commanderSignalsEnchantments(commanderText) && enchantmentCount < 10) {
    roleTargets['enchantments_to_add'] = 10 - enchantmentCount;
  }

  if (nonLandCount < 30) {
    priorityRepairs.add(
      'Aumentar a densidade de mágicas úteis antes de tentar micro-otimizações.',
    );
  }

  return {
    'summary':
        'O deck precisa de reconstrução estrutural antes de trocas pontuais.',
    'target_land_count': targetLandCount,
    'priority_repairs': priorityRepairs,
    'role_targets': roleTargets,
    'preserve': const ['commander', 'cartas core realmente sinérgicas'],
  };
}

bool _commanderSignalsSpellslinger(String commanderText) {
  return commanderText.contains('instant or sorcery') ||
      commanderText.contains('instant or sorcery spell') ||
      commanderText.contains('whenever you cast an instant') ||
      commanderText.contains('whenever you cast a sorcery');
}

bool _commanderSignalsArtifacts(String commanderText) {
  return commanderText.contains('artifact');
}

bool _commanderSignalsEnchantments(String commanderText) {
  return commanderText.contains('enchantment');
}

String resolveOptimizeArchetype({
  required String? requestedArchetype,
  required String? detectedArchetype,
}) {
  final requested = requestedArchetype?.trim().toLowerCase();
  final detected = detectedArchetype?.trim().toLowerCase();

  const generic = {'midrange', 'general', 'value', 'tempo'};
  if (requested == null || requested.isEmpty) return detected ?? 'midrange';
  if (detected == null || detected.isEmpty) return requested;
  if (generic.contains(requested)) return detected;
  return requested;
}
