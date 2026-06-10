import 'optimization_functional_roles.dart';

// ============================================================================
// DECK ADVANCED ANALYSIS — lógicas de auditoria antes ausentes
//
// Implementa quatro análises que faltavam no pipeline de fraquezas:
//   1. Win-condition diversity (eixos: speed / resilience / stealth)
//   2. Removal-to-threat ratio (balanço pró-ativo x reativo)
//   3. Draw tag completeness (qualidade/cobertura das fontes de compra)
//   4. Post-resolution viability (recuperação pós board wipe / Worldfire)
//
// Cada função recebe a mesma lista de cartas usada pela weakness-analysis
// (mapas com name/type_line/oracle_text/mana_cost/colors/quantity/cmc, com
// oracle_text já em lowercase) e devolve um resultado serializável + uma
// eventual fraqueza acionável.
// ============================================================================

/// Carta normalizada para as heurísticas deste módulo.
class _Card {
  final String name; // lowercase
  final String typeLine; // lowercase
  final String oracleText; // lowercase
  final String manaCost;
  final double cmc;
  final int quantity;
  final Set<String> roles;

  _Card({
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.cmc,
    required this.quantity,
    required this.roles,
  });

  bool get isCreature => typeLine.contains('creature');
  bool get isInstantSpeed =>
      typeLine.contains('instant') || oracleText.contains('flash');
}

List<_Card> _normalize(List<Map<String, dynamic>> cards) {
  return cards.map((card) {
    final name = ((card['name'] as String?) ?? '').toLowerCase();
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();
    final manaCost = (card['mana_cost'] as String?) ?? '';
    final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
    final quantity = (card['quantity'] as int?) ?? 1;
    final roles = resolveCardFunctionalRoles(
      oracleText: oracleText,
      typeLine: typeLine,
      name: name,
      manaCost: manaCost,
      cmc: cmc,
    ).roles;
    return _Card(
      name: name,
      typeLine: typeLine,
      oracleText: oracleText,
      manaCost: manaCost,
      cmc: cmc,
      quantity: quantity,
      roles: roles,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Resultado genérico de uma análise
//
class AdvancedAnalysisResult {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? weakness;

  const AdvancedAnalysisResult({required this.data, this.weakness});
}

// ===========================================================================
// 1. WIN-CONDITION DIVERSITY (speed / resilience / stealth)
// ===========================================================================

/// Categorias de caminho de vitória.
enum WinconCategory { combat, directDamage, drain, mill, altWin, combo }

String _winconCategoryName(WinconCategory c) {
  switch (c) {
    case WinconCategory.combat:
      return 'combat';
    case WinconCategory.directDamage:
      return 'direct_damage';
    case WinconCategory.drain:
      return 'drain';
    case WinconCategory.mill:
      return 'mill';
    case WinconCategory.altWin:
      return 'alt_win';
    case WinconCategory.combo:
      return 'combo';
  }
}

bool _isAltWin(_Card c) =>
    c.oracleText.contains('you win the game') ||
    c.oracleText.contains('wins the game') ||
    c.oracleText.contains('each opponent loses the game') ||
    c.oracleText.contains('opponents lose the game') ||
    c.name.contains("thassa's oracle") ||
    c.name.contains('laboratory maniac') ||
    c.name.contains('approach of the second sun') ||
    c.name.contains('jace, wielder of mysteries');

bool _isDirectDamage(_Card c) =>
    (c.oracleText.contains('deals') &&
        c.oracleText.contains('damage') &&
        (c.oracleText.contains('to each opponent') ||
            c.oracleText.contains('to any target') ||
            c.oracleText.contains('to target player') ||
            c.oracleText.contains('to target opponent'))) ||
    c.name.contains('aetherflux reservoir');

bool _isDrain(_Card c) =>
    ((c.oracleText.contains('loses life') ||
                c.oracleText.contains('lose life')) &&
            (c.oracleText.contains('each opponent') ||
                c.oracleText.contains('target opponent') ||
                c.oracleText.contains('target player'))) ||
    c.name.contains('blood artist') ||
    c.name.contains('zulaport cutthroat') ||
    c.name.contains('exquisite blood');

bool _isMill(_Card c) =>
    c.oracleText.contains('mill') &&
    (c.oracleText.contains('target opponent') ||
        c.oracleText.contains('each opponent') ||
        c.oracleText.contains('target player'));

bool _isCombatFinisher(_Card c) {
  if (!c.isCreature) return false;
  // Heurística: criatura com efeito agressivo de fechar jogo.
  return (c.oracleText.contains('double') &&
          (c.oracleText.contains('power') ||
              c.oracleText.contains('damage'))) ||
      c.oracleText.contains('can\'t be blocked') ||
      c.oracleText.contains('infect') ||
      c.oracleText.contains('commander damage') ||
      c.oracleText.contains('extra combat') ||
      c.oracleText.contains('additional combat') ||
      c.oracleText.contains('annihilator') ||
      c.oracleText.contains('deals combat damage to a player') ||
      (c.oracleText.contains('whenever') &&
          c.oracleText.contains('attacks') &&
          c.cmc >= 4);
}

Set<WinconCategory> _winconCategories(_Card c) {
  final cats = <WinconCategory>{};
  if (_isAltWin(c)) cats.add(WinconCategory.altWin);
  if (c.roles.contains('combo_piece') || c.oracleText.contains('infinite')) {
    cats.add(WinconCategory.combo);
  }
  if (_isDirectDamage(c)) cats.add(WinconCategory.directDamage);
  if (_isDrain(c)) cats.add(WinconCategory.drain);
  if (_isMill(c)) cats.add(WinconCategory.mill);
  if (_isCombatFinisher(c)) cats.add(WinconCategory.combat);
  // Carta marcada como wincon mas sem categoria específica → assume combat se
  // for criatura grande, caso contrário trata como finisher genérico (combat).
  if (cats.isEmpty && c.roles.contains('wincon')) {
    cats.add(c.isCreature ? WinconCategory.combat : WinconCategory.directDamage);
  }
  return cats;
}

/// `completeCombos` = nº de combos completos detectados (Commander Spellbook),
/// que entram como caminho de vitória resiliente extra.
AdvancedAnalysisResult analyzeWinconDiversity(
  List<Map<String, dynamic>> rawCards, {
  int completeCombos = 0,
  bool isCommander = true,
}) {
  final cards = _normalize(rawCards);

  final categoryCounts = <String, int>{};
  var winconCards = 0;
  var fast = 0;
  var slow = 0;
  var stealthy = 0;
  var telegraphed = 0;
  var protectedWincons = 0;

  for (final c in cards) {
    final cats = _winconCategories(c);
    if (cats.isEmpty) continue;
    winconCards += c.quantity;

    for (final cat in cats) {
      categoryCounts.update(
        _winconCategoryName(cat),
        (v) => v + c.quantity,
        ifAbsent: () => c.quantity,
      );
    }

    // Eixo SPEED: rápido = alt-win/combo, instant-speed, ou baixo custo.
    final isFast = cats.contains(WinconCategory.altWin) ||
        cats.contains(WinconCategory.combo) ||
        c.isInstantSpeed ||
        c.cmc <= 3;
    if (isFast) {
      fast += c.quantity;
    } else {
      slow += c.quantity;
    }

    // Eixo STEALTH: difícil de interagir = vence em instant-speed, "you win",
    // não precisa atacar, ou tem hexproof/shroud próprio.
    final isStealthy = cats.contains(WinconCategory.altWin) ||
        c.isInstantSpeed ||
        c.oracleText.contains('hexproof') ||
        c.oracleText.contains('shroud') ||
        (cats.contains(WinconCategory.combo) && !c.isCreature);
    if (isStealthy) {
      stealthy += c.quantity;
    } else {
      telegraphed += c.quantity;
    }

    // Resiliência individual: wincon com proteção embutida.
    if (c.oracleText.contains('hexproof') ||
        c.oracleText.contains('indestructible') ||
        c.oracleText.contains('protection from') ||
        c.oracleText.contains('ward')) {
      protectedWincons += c.quantity;
    }
  }

  final distinctCategories = categoryCounts.length + (completeCombos > 0 ? 1 : 0);
  final effectiveWinconCount = winconCards + completeCombos;

  // Resiliência de DECK: redundância (>=3 wincons OU >=2 categorias distintas)
  // e capacidade de reapresentar (proteção ou combos completos).
  final hasRedundancy = effectiveWinconCount >= 3 || distinctCategories >= 2;
  final hasProtection = protectedWincons > 0 || completeCombos > 0;
  final resilient = hasRedundancy && (hasProtection || distinctCategories >= 2);

  // Score de diversidade 0..1: combina nº de categorias distintas (até 3),
  // presença dos dois lados do eixo speed e do eixo stealth.
  var score = 0.0;
  score += (distinctCategories.clamp(0, 3)) / 3 * 0.5;
  if (fast > 0 && slow > 0) score += 0.15;
  if (stealthy > 0) score += 0.15;
  if (resilient) score += 0.20;
  score = double.parse(score.clamp(0.0, 1.0).toStringAsFixed(3));

  final data = {
    'wincon_count': winconCards,
    'effective_wincon_count': effectiveWinconCount,
    'complete_combos': completeCombos,
    'categories': categoryCounts,
    'distinct_categories': distinctCategories,
    'axes': {
      'fast': fast,
      'slow': slow,
      'stealthy': stealthy,
      'telegraphed': telegraphed,
      'protected': protectedWincons,
      'resilient': resilient,
    },
    'diversity_score': score,
  };

  Map<String, dynamic>? weakness;
  // Fraqueza: caminho único e frágil → um único removal/board wipe desliga o
  // plano de vitória. Só dispara se já houver pelo menos algum wincon (a
  // ausência total já é coberta por `insufficient_win_conditions`).
  if (effectiveWinconCount >= 1 && (distinctCategories <= 1 && !resilient)) {
    final onlyTelegraphed = stealthy == 0 && telegraphed > 0;
    weakness = {
      'type': 'fragile_win_path',
      'severity': effectiveWinconCount <= 2 ? 'high' : 'medium',
      'description':
          'Plano de vitória pouco diversificado (${distinctCategories} categoria(s), '
              'score ${(score * 100).toStringAsFixed(0)}%). '
              '${onlyTelegraphed ? 'Todos os finalizadores são telegrafados e fáceis de interagir. ' : ''}'
              'Um único removal ou board wipe pode desligar o caminho de vitória.',
      'recommendations': [
        'Adicionar um caminho de vitória de categoria diferente (ex.: drain, combo, alt-win)',
        if (stealthy == 0)
          'Incluir um finalizador instant-speed ou à prova de interação',
        if (!hasProtection)
          'Proteger o finalizador principal (hexproof/indestructible)',
      ],
      'current_value': distinctCategories,
      'recommended_value': 2,
    };
  }

  return AdvancedAnalysisResult(data: data, weakness: weakness);
}

// ===========================================================================
// 2. REMOVAL-TO-THREAT RATIO
// ===========================================================================

/// Mede o balanço entre interação (removal + board wipes) e ameaças próprias
/// (permanentes que o oponente é obrigado a responder). Um deck saudável tem
/// interação suficiente para o nível de ameaça do formato sem ser tão reativo
/// a ponto de não ter o que vencer.
AdvancedAnalysisResult analyzeRemovalToThreatRatio(
  List<Map<String, dynamic>> rawCards, {
  bool isCommander = true,
}) {
  final cards = _normalize(rawCards);

  var removal = 0;
  var threats = 0;

  for (final c in cards) {
    if (c.roles.contains('removal') || c.roles.contains('wipe') ||
        c.roles.contains('board_wipe')) {
      removal += c.quantity;
    }

    // Ameaça = permanente de alto impacto que pressiona o oponente.
    final isThreat = c.roles.contains('wincon') ||
        c.roles.contains('payoff') ||
        c.roles.contains('engine') ||
        c.typeLine.contains('planeswalker') ||
        (c.isCreature && c.cmc >= 4) ||
        c.oracleText.contains('infinite') ||
        c.oracleText.contains('extra turn');
    if (isThreat) threats += c.quantity;
  }

  final ratio = threats > 0
      ? double.parse((removal / threats).toStringAsFixed(3))
      : (removal > 0 ? 99.0 : 0.0);

  // Banda saudável em Commander: ~0.4 a 1.5 removal por ameaça própria.
  const lowBand = 0.4;
  const highBand = 2.5;

  final data = {
    'removal_count': removal,
    'threat_count': threats,
    'ratio': ratio,
    'healthy_band': {'min': lowBand, 'max': highBand},
  };

  Map<String, dynamic>? weakness;
  if (threats >= 3 && ratio < lowBand) {
    weakness = {
      'type': 'low_removal_to_threat_ratio',
      'severity': ratio < 0.2 ? 'high' : 'medium',
      'description':
          'Deck tem $threats ameaças próprias mas apenas $removal interações '
              '(ratio ${ratio.toStringAsFixed(2)}). Pouca capacidade de responder às '
              'ameaças dos oponentes em multiplayer.',
      'recommendations': [
        'Adicionar removal pontual instant-speed',
        'Incluir 1-2 board wipes',
        'Equilibrar cartas pró-ativas com interação reativa',
      ],
      'current_value': ratio,
      'recommended_value': lowBand,
    };
  } else if (threats <= 1 && removal >= 8) {
    weakness = {
      'type': 'overly_reactive',
      'severity': 'medium',
      'description':
          'Deck é muito reativo ($removal interações) mas tem apenas $threats '
              'ameaças próprias. Risco de controlar o jogo sem conseguir fechá-lo.',
      'recommendations': [
        'Adicionar finalizadores/ameaças resilientes',
        'Trocar parte da interação redundante por win conditions',
      ],
      'current_value': threats,
      'recommended_value': 3,
    };
  }

  return AdvancedAnalysisResult(data: data, weakness: weakness);
}

// ===========================================================================
// 3. DRAW TAG COMPLETENESS
// ===========================================================================

/// Avalia não só a quantidade mas a QUALIDADE das fontes de compra: engines
/// repetíveis valem mais que cantrips one-shot, e fontes condicionais valem
/// menos. Detecta o caso "tem 8 fontes mas todas one-shot/condicionais".
AdvancedAnalysisResult analyzeDrawCompleteness(
  List<Map<String, dynamic>> rawCards,
) {
  final cards = _normalize(rawCards);

  var repeatableEngines = 0;
  var burst = 0; // compra 2+ de uma vez (one-shot)
  var cantrip = 0; // compra 1
  var conditional = 0;
  var totalDrawSources = 0;

  for (final c in cards) {
    final isDraw = c.roles.contains('draw') || c.roles.contains('loot');
    if (!isDraw) continue;
    totalDrawSources += c.quantity;

    final o = c.oracleText;
    final isRepeatable = c.roles.contains('engine') ||
        o.contains('at the beginning of your') ||
        o.contains('at the beginning of each') ||
        (o.contains('whenever') && o.contains('draw')) ||
        o.contains('draw a card for each') ||
        o.contains('end step, draw');
    final isBurst = o.contains('draw two') ||
        o.contains('draw three') ||
        o.contains('draw four') ||
        o.contains('draw cards equal to') ||
        RegExp(r'draw (two|three|four|five|x) cards').hasMatch(o);
    final isConditional = o.contains('if you') ||
        o.contains('whenever') ||
        o.contains('only') ||
        o.contains('sacrifice');

    if (isRepeatable) {
      repeatableEngines += c.quantity;
    } else if (isBurst) {
      burst += c.quantity;
    } else if (isConditional) {
      conditional += c.quantity;
    } else {
      cantrip += c.quantity;
    }
  }

  // Score ponderado: engine=1.0, burst=0.7, cantrip=0.4, conditional=0.3.
  final weighted = repeatableEngines * 1.0 +
      burst * 0.7 +
      cantrip * 0.4 +
      conditional * 0.3;
  // Normaliza contra a meta de ~10 fontes de qualidade.
  final completeness =
      double.parse((weighted / 10.0).clamp(0.0, 1.0).toStringAsFixed(3));

  final data = {
    'total_draw_sources': totalDrawSources,
    'repeatable_engines': repeatableEngines,
    'burst': burst,
    'cantrip': cantrip,
    'conditional': conditional,
    'weighted_score': double.parse(weighted.toStringAsFixed(2)),
    'completeness': completeness,
  };

  Map<String, dynamic>? weakness;
  // Caso clássico: contagem bruta ok (>=8) mas sem motores repetíveis →
  // vantagem de cartas não sustentável no longo jogo de Commander.
  if (totalDrawSources >= 6 && repeatableEngines < 2) {
    weakness = {
      'type': 'shallow_card_advantage',
      'severity': repeatableEngines == 0 ? 'high' : 'medium',
      'description':
          'Deck tem $totalDrawSources fontes de compra mas apenas '
              '$repeatableEngines motor(es) repetível(is). A vantagem de cartas '
              'não se sustenta no longo jogo.',
      'recommendations': [
        'Rhystic Study',
        'Mystic Remora',
        'The One Ring',
        'Beast Whisperer',
        'Sylvan Library',
      ],
      'current_value': repeatableEngines,
      'recommended_value': 3,
    };
  }

  return AdvancedAnalysisResult(data: data, weakness: weakness);
}

// ===========================================================================
// 4. POST-RESOLUTION VIABILITY (recuperação pós board wipe / Worldfire)
// ===========================================================================

/// Avalia se o deck consegue se recuperar depois que o board é resetado
/// (wipe próprio ou do oponente, ou efeitos tipo Worldfire). Decks que põem
/// todos os ovos em criaturas, sem proteção instant-speed nem recursão, dobram
/// para o primeiro Wrath.
AdvancedAnalysisResult analyzePostResolutionViability(
  List<Map<String, dynamic>> rawCards, {
  bool isCommander = true,
}) {
  final cards = _normalize(rawCards);

  var instantProtection = 0; // proteção instant-speed contra wipe
  var recursion = 0; // recompra/reanimação após wipe
  var resilientEngines = 0; // vantagem que sobrevive a wipe (não-criatura)
  var creatureThreats = 0;
  var nonCreaturePermanentThreats = 0;
  var fastRebuild = 0; // ameaças baratas para reconstruir (cmc<=2)

  for (final c in cards) {
    final o = c.oracleText;

    final isInstantProtection = c.isInstantSpeed &&
        (o.contains('indestructible') ||
            o.contains('hexproof') ||
            o.contains('protection from') ||
            o.contains('phase out') ||
            (o.contains('return') && o.contains('to their owners')) ||
            c.name.contains("teferi's protection") ||
            c.name.contains('heroic intervention') ||
            c.name.contains('boros charm') ||
            c.name.contains('clever concealment'));
    if (isInstantProtection) instantProtection += c.quantity;

    final isRecursion = c.roles.contains('recursion') ||
        (o.contains('return') &&
            o.contains('from your graveyard') &&
            o.contains('battlefield')) ||
        o.contains('reanimate') ||
        c.name.contains('the one ring');
    if (isRecursion) recursion += c.quantity;

    // Engine resiliente: vantagem de cartas que NÃO é criatura (sobrevive a
    // board wipe de criaturas).
    final isResilientEngine = (c.roles.contains('engine') ||
            c.roles.contains('draw')) &&
        !c.isCreature &&
        (c.typeLine.contains('artifact') ||
            c.typeLine.contains('enchantment') ||
            c.typeLine.contains('planeswalker'));
    if (isResilientEngine) resilientEngines += c.quantity;

    final isThreat = c.roles.contains('wincon') ||
        c.roles.contains('payoff') ||
        (c.isCreature && c.cmc >= 3) ||
        c.typeLine.contains('planeswalker');
    if (isThreat) {
      if (c.isCreature) {
        creatureThreats += c.quantity;
      } else {
        nonCreaturePermanentThreats += c.quantity;
      }
    }
    if (isThreat && c.cmc <= 2) fastRebuild += c.quantity;
  }

  // Viabilidade 0..1: combina proteção instant, recursão, engines resilientes,
  // diversidade de tipo de ameaça e capacidade de reconstrução barata.
  var score = 0.0;
  if (instantProtection >= 1) score += 0.25;
  if (instantProtection >= 2) score += 0.10;
  if (recursion >= 2) score += 0.20;
  if (resilientEngines >= 2) score += 0.20;
  if (nonCreaturePermanentThreats >= 2) score += 0.15;
  if (fastRebuild >= 4) score += 0.10;
  score = double.parse(score.clamp(0.0, 1.0).toStringAsFixed(3));

  final creatureDependency = (creatureThreats + nonCreaturePermanentThreats) > 0
      ? double.parse((creatureThreats /
              (creatureThreats + nonCreaturePermanentThreats))
          .toStringAsFixed(3))
      : 0.0;

  final data = {
    'instant_protection': instantProtection,
    'recursion': recursion,
    'resilient_engines': resilientEngines,
    'creature_threats': creatureThreats,
    'noncreature_permanent_threats': nonCreaturePermanentThreats,
    'fast_rebuild_threats': fastRebuild,
    'creature_dependency': creatureDependency,
    'viability_score': score,
  };

  Map<String, dynamic>? weakness;
  // Folda para o primeiro wipe: depende fortemente de criaturas, sem proteção
  // instant-speed nem recursão e sem engines não-criatura.
  final foldsToWipe = creatureDependency >= 0.75 &&
      instantProtection == 0 &&
      recursion < 2 &&
      resilientEngines < 2;
  if (foldsToWipe && creatureThreats >= 4) {
    weakness = {
      'type': 'folds_to_board_wipe',
      'severity': score < 0.2 ? 'high' : 'medium',
      'description':
          'Deck depende fortemente de criaturas (${(creatureDependency * 100).toStringAsFixed(0)}% das ameaças) '
              'sem proteção instant-speed nem recursão. Um único board wipe pode '
              'desfazer o jogo sem recuperação (viabilidade ${(score * 100).toStringAsFixed(0)}%).',
      'recommendations': [
        "Teferi's Protection",
        'Heroic Intervention',
        'Adicionar recursão (reanimação / recompra)',
        'Incluir engines não-criatura (artefato/encantamento) que sobrevivem a wipes',
      ],
      'current_value': score,
      'recommended_value': 0.5,
    };
  }

  return AdvancedAnalysisResult(data: data, weakness: weakness);
}
