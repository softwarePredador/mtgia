import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';
import '../logger.dart';
import '../openai_runtime_config.dart';
import 'goldfish_simulator.dart';
import 'optimization_functional_roles.dart';

/// Motor de Validação Pós-Otimização
///
/// FILOSOFIA: A IA sugere trocas, mas elas precisam ser PROVADAS boas.
/// Este módulo é a "segunda opinião" — roda testes automatizados no deck
/// antes e depois das trocas e retorna um veredito baseado em dados.
///
/// 3 camadas de validação:
/// 1. Monte Carlo (Goldfish) — Roda 1000 mãos ANTES e DEPOIS e compara
/// 2. Análise Funcional — Verifica se cada troca preserva o papel funcional
/// 3. Critic IA — Segunda chamada à IA que CRITICA as trocas (auto-revisão)
class OptimizationValidator {
  final String? openAiKey;

  OptimizationValidator({this.openAiKey});

  /// Executa TODAS as camadas de validação e retorna um veredito unificado
  Future<ValidationReport> validate({
    required List<Map<String, dynamic>> originalDeck,
    required List<Map<String, dynamic>> optimizedDeck,
    required List<String> removals,
    required List<String> additions,
    required List<String> commanders,
    required String archetype,
  }) async {
    // 1. SIMULAÇÃO MONTE CARLO (ANTES vs DEPOIS)
    final monteCarloReport = _runMonteCarloComparison(
      originalDeck: originalDeck,
      optimizedDeck: optimizedDeck,
    );

    // 2. ANÁLISE FUNCIONAL DAS TROCAS
    final functionalReport = _analyzeFunctionalSwaps(
      originalDeck: originalDeck,
      removals: removals,
      additions: additions,
      optimizedDeck: optimizedDeck,
    );

    // 3. SEGUNDA OPINIÃO (CRITIC IA)
    Map<String, dynamic>? criticReport;
    if (openAiKey != null && openAiKey!.isNotEmpty) {
      criticReport = await _runCriticAI(
        removals: removals,
        additions: additions,
        commanders: commanders,
        archetype: archetype,
        monteCarloReport: monteCarloReport,
        functionalReport: functionalReport,
      );
    }

    // 4. CALCULAR VEREDITO FINAL
    return _computeVerdict(
      monteCarlo: monteCarloReport,
      functional: functionalReport,
      archetype: archetype,
      critic: criticReport,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMADA 1: MONTE CARLO COMPARISON (Goldfish Before vs After)
  // ═══════════════════════════════════════════════════════════════

  MonteCarloComparison _runMonteCarloComparison({
    required List<Map<String, dynamic>> originalDeck,
    required List<Map<String, dynamic>> optimizedDeck,
  }) {
    // Simular Deck ORIGINAL
    final beforeSim = GoldfishSimulator(originalDeck, simulations: 1000);
    final beforeResult = beforeSim.simulate();

    // Simular Deck OTIMIZADO
    final afterSim = GoldfishSimulator(optimizedDeck, simulations: 1000);
    final afterResult = afterSim.simulate();

    // London Mulligan Analysis
    final beforeMulligan = _simulateLondonMulligan(originalDeck, runs: 500);
    final afterMulligan = _simulateLondonMulligan(optimizedDeck, runs: 500);

    return MonteCarloComparison(
      before: beforeResult,
      after: afterResult,
      beforeMulligan: beforeMulligan,
      afterMulligan: afterMulligan,
    );
  }

  /// Simula London Mulligan (Commander: free first mulligan)
  ///
  /// Regra: Compra 7, decide keep/mull. Se mull, compra 7 de novo e coloca
  /// 1 no fundo. Repete até manter ou chegar a 4 cartas.
  ///
  /// Heurística de keep: 2-5 lands + pelo menos 1 carta jogável nos turnos 1-3
  MulliganReport _simulateLondonMulligan(
    List<Map<String, dynamic>> deck, {
    int runs = 500,
  }) {
    final random = Random();
    var totalMulligans = 0;
    var keptAt7 = 0;
    var keptAt6 = 0;
    var keptAt5 = 0;
    var keptAt4OrLess = 0;
    var totalKeepableAfterMull = 0;

    // Expandir deck
    final expandedDeck = <Map<String, dynamic>>[];
    for (final card in deck) {
      final qty = (card['quantity'] as int?) ?? 1;
      for (var i = 0; i < qty; i++) {
        expandedDeck.add(card);
      }
    }

    for (var run = 0; run < runs; run++) {
      var mulligans = 0;
      var kept = false;

      for (var attempt = 0; attempt < 4 && !kept; attempt++) {
        final shuffled = List<Map<String, dynamic>>.from(expandedDeck)
          ..shuffle(random);
        final hand = shuffled.take(7).toList();
        final handSize = 7 - attempt; // Commander: free first, then -1 each

        // Heurística de keep melhorada:
        // Mana rocks contam como "meios terrenos" para avaliar keepability
        final landsInHand = hand.where(_isLand).length;
        final manaRocksInHand = hand.where((c) {
          if (_isLand(c)) return false;
          final t = ((c['type_line'] as String?) ?? '').toLowerCase();
          final o = ((c['oracle_text'] as String?) ?? '').toLowerCase();
          return t.contains('artifact') && o.contains('add') && _getCmc(c) <= 2;
        }).length;
        // effectiveLands = terras reais + (mana rocks × 0.5)
        final effectiveLands = landsInHand + (manaRocksInHand * 0.5);
        final hasEarlyPlay = hand.any(
          (c) => !_isLand(c) && _getCmc(c) <= 3,
        );

        // Keep se: 2-5 effective lands E tem jogada early (ou hand size <= 5)
        final shouldKeep =
            (effectiveLands >= 1.5 && effectiveLands <= 5.5 && hasEarlyPlay) ||
                handSize <= 5; // Keep at 5 cards regardless

        if (shouldKeep || attempt == 3) {
          // Kept
          kept = true;
          mulligans = attempt;

          if (attempt == 0) {
            keptAt7++;
          } else if (attempt == 1) {
            keptAt6++;
          } else if (attempt == 2) {
            keptAt5++;
          } else {
            keptAt4OrLess++;
          }

          // A mão final era jogável?
          if (landsInHand >= 2 && landsInHand <= 5 && hasEarlyPlay) {
            totalKeepableAfterMull++;
          }
        }

        totalMulligans += mulligans;
      }
    }

    return MulliganReport(
      runs: runs,
      avgMulligans: totalMulligans / runs,
      keepAt7Rate: keptAt7 / runs,
      keepAt6Rate: keptAt6 / runs,
      keepAt5Rate: keptAt5 / runs,
      keepAt4OrLessRate: keptAt4OrLess / runs,
      keepableAfterMullRate: totalKeepableAfterMull / runs,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMADA 2: ANÁLISE FUNCIONAL DAS TROCAS
  // ═══════════════════════════════════════════════════════════════

  FunctionalReport _analyzeFunctionalSwaps({
    required List<Map<String, dynamic>> originalDeck,
    required List<String> removals,
    required List<String> additions,
    required List<Map<String, dynamic>> optimizedDeck,
  }) {
    final swapAnalysis = <SwapFunctionalAnalysis>[];

    // Para cada par (removal, addition)
    for (var i = 0; i < removals.length && i < additions.length; i++) {
      final removedName = removals[i];
      final addedName = additions[i];

      // Encontrar dados da carta removida
      final removedCard =
          _findCardByName(originalDeck, removedName) ?? <String, dynamic>{};

      // Encontrar dados da carta adicionada
      final addedCard =
          _findCardByName(optimizedDeck, addedName) ?? <String, dynamic>{};

      if (removedCard.isEmpty || addedCard.isEmpty) {
        swapAnalysis.add(SwapFunctionalAnalysis(
          removed: removedName,
          added: addedName,
          removedRole: 'unknown',
          addedRole: 'unknown',
          rolePreserved: false,
          cmcDelta: 0,
          verdict: 'indeterminado',
        ));
        continue;
      }

      // Classificar papel funcional
      final removedRole = classifyOptimizationFunctionalRole(removedCard);
      final addedRole = classifyOptimizationFunctionalRole(addedCard);

      // CMC comparison
      final removedCmc = _getCmc(removedCard);
      final addedCmc = _getCmc(addedCard);
      final cmcDelta = addedCmc - removedCmc;

      // Verificar se o papel foi preservado.
      // Regra: role preservado quando os papéis são iguais OU ambos são 'utility'
      // (que representa cartas sem papel funcional claro).
      // ATENÇÃO: a condição anterior era `(removedRole == 'utility' || addedRole == 'utility')`,
      // o que avaliava como verdadeiro sempre que QUALQUER card fosse 'utility' — bug de precedência.
      final rolePreserved = removedRole == addedRole ||
          (removedRole == 'utility' && addedRole == 'utility');

      // Gerar veredito
      String verdict;
      if (rolePreserved && cmcDelta <= 0) {
        verdict = 'upgrade'; // Mesma função, custo menor/igual
      } else if (rolePreserved && cmcDelta > 0) {
        verdict = 'sidegrade'; // Mesma função, custo maior
      } else if (!rolePreserved && cmcDelta <= 0) {
        verdict = 'tradeoff'; // Mudou função mas é mais barato
      } else {
        verdict = 'questionável'; // Mudou função E ficou mais caro
      }

      swapAnalysis.add(SwapFunctionalAnalysis(
        removed: removedName,
        added: addedName,
        removedRole: removedRole,
        addedRole: addedRole,
        rolePreserved: rolePreserved,
        cmcDelta: cmcDelta,
        verdict: verdict,
      ));
    }

    // Contagem global
    final upgrades = swapAnalysis.where((s) => s.verdict == 'upgrade').length;
    final sidegrades =
        swapAnalysis.where((s) => s.verdict == 'sidegrade').length;
    final tradeoffs = swapAnalysis.where((s) => s.verdict == 'tradeoff').length;
    final questionable =
        swapAnalysis.where((s) => s.verdict == 'questionável').length;

    // Análise de categorias (deck perde removal? perde draw?)
    final removedRoles = swapAnalysis.map((s) => s.removedRole).toList();
    final addedRoles = swapAnalysis.map((s) => s.addedRole).toList();

    final roleDelta = <String, int>{};
    for (final role in [
      'draw',
      'removal',
      'ramp',
      'creature',
      'artifact',
      'enchantment',
      'land',
      'utility',
      'wipe',
      'tutor',
      'protection'
    ]) {
      final lost = removedRoles.where((r) => r == role).length;
      final gained = addedRoles.where((r) => r == role).length;
      roleDelta[role] = gained - lost;
    }

    return FunctionalReport(
      swaps: swapAnalysis,
      upgrades: upgrades,
      sidegrades: sidegrades,
      tradeoffs: tradeoffs,
      questionable: questionable,
      roleDelta: roleDelta,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMADA 3: SEGUNDA OPINIÃO (CRITIC AI)
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _runCriticAI({
    required List<String> removals,
    required List<String> additions,
    required List<String> commanders,
    required String archetype,
    required MonteCarloComparison monteCarloReport,
    required FunctionalReport functionalReport,
  }) async {
    if (openAiKey == null || openAiKey!.isEmpty) return null;

    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
    final aiConfig = OpenAiRuntimeConfig(env);
    final model = aiConfig.modelFor(
      key: 'OPENAI_MODEL_OPTIMIZATION_CRITIC',
      fallback: 'gpt-4o-mini',
      devFallback: 'gpt-4o-mini',
      stagingFallback: 'gpt-4o-mini',
      prodFallback: 'gpt-4o-mini',
    );
    final temperature = aiConfig.temperatureFor(
      key: 'OPENAI_TEMP_OPTIMIZATION_CRITIC',
      fallback: 0.2,
      devFallback: 0.25,
      stagingFallback: 0.2,
      prodFallback: 0.15,
    );

    try {
      final criticPrompt =
          '''Você é um revisor crítico de otimizações de deck de Magic: The Gathering (Commander).

Outro sistema de IA sugeriu estas trocas para um deck de ${commanders.join(' & ')} ($archetype):

${_formatSwapsForCritic(removals, additions, functionalReport)}

DADOS DE SIMULAÇÃO (Monte Carlo, 1000 mãos):
- Score de Consistência: ${monteCarloReport.before.consistencyScore} → ${monteCarloReport.after.consistencyScore} ${monteCarloReport.after.consistencyScore > monteCarloReport.before.consistencyScore ? '✅ (melhorou)' : (monteCarloReport.after.consistencyScore < monteCarloReport.before.consistencyScore ? '❌ (piorou)' : '➡️ (igual)')}
- Taxa de Mull-free keep: ${(monteCarloReport.beforeMulligan.keepAt7Rate * 100).toStringAsFixed(1)}% → ${(monteCarloReport.afterMulligan.keepAt7Rate * 100).toStringAsFixed(1)}%
- Mana Screw: ${(monteCarloReport.before.screwRate * 100).toStringAsFixed(1)}% → ${(monteCarloReport.after.screwRate * 100).toStringAsFixed(1)}%
- Mana Flood: ${(monteCarloReport.before.floodRate * 100).toStringAsFixed(1)}% → ${(monteCarloReport.after.floodRate * 100).toStringAsFixed(1)}%
- Jogada no T2: ${(monteCarloReport.before.turn2PlayRate * 100).toStringAsFixed(1)}% → ${(monteCarloReport.after.turn2PlayRate * 100).toStringAsFixed(1)}%

ANÁLISE FUNCIONAL:
- Upgrades claros: ${functionalReport.upgrades}
- Sidegrades: ${functionalReport.sidegrades}
- Tradeoffs: ${functionalReport.tradeoffs}
- Questionáveis: ${functionalReport.questionable}
- Delta de papéis: ${functionalReport.roleDelta.entries.where((e) => e.value != 0).map((e) => '${e.key}: ${e.value > 0 ? '+' : ''}${e.value}').join(', ')}

SUA TAREFA: Avaliar se as trocas são REALMENTE boas. Retorne apenas JSON:
{
  "approval_score": 0-100,
  "verdict": "aprovado" | "aprovado_com_ressalvas" | "reprovado",
  "concerns": ["lista de preocupações específicas"],
  "strong_swaps": ["lista de trocas que são claramente boas"],
  "weak_swaps": ["lista de trocas questionáveis com justificativa"],
  "overall_assessment": "Frase resumo de 1-2 linhas"
}''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': criticPrompt},
          ],
          'temperature': temperature,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonDecode(data['choices'][0]['message']['content'])
            as Map<String, dynamic>;
      }

      Log.w('Critic AI failed: HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      Log.w('Critic AI error: $e');
      return null;
    }
  }

  String _formatSwapsForCritic(
    List<String> removals,
    List<String> additions,
    FunctionalReport report,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < removals.length && i < additions.length; i++) {
      final swap = i < report.swaps.length ? report.swaps[i] : null;
      buffer.writeln(
        '${i + 1}. OUT: ${removals[i]} (${swap?.removedRole ?? '?'}) → IN: ${additions[i]} (${swap?.addedRole ?? '?'}) [${swap?.verdict ?? '?'}]',
      );
    }
    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // VEREDITO FINAL
  // ═══════════════════════════════════════════════════════════════

  ValidationReport _computeVerdict({
    required MonteCarloComparison monteCarlo,
    required FunctionalReport functional,
    required String archetype,
    Map<String, dynamic>? critic,
  }) {
    final healthScore = _computeDeckHealthScore(
      monteCarlo: monteCarlo,
      archetype: archetype,
    );
    final improvementScore = _computeImprovementScore(
      monteCarlo: monteCarlo,
      functional: functional,
      archetype: archetype,
      critic: critic,
    );

    // Role preservation: perder removal, draw, wipe ou ramp é muito ruim.
    // Essas perdas impactam tanto o score final quanto o veredito.
    final lostRemoval = (functional.roleDelta['removal'] ?? 0) < 0;
    final lostDraw = (functional.roleDelta['draw'] ?? 0) < 0;
    final lostWipe = (functional.roleDelta['wipe'] ?? 0) < 0;
    final lostRamp = (functional.roleDelta['ramp'] ?? 0) < 0;
    final hasCriticalRoleLoss = lostRemoval || lostDraw || lostWipe || lostRamp;
    final consistencyDelta =
        monteCarlo.after.consistencyScore - monteCarlo.before.consistencyScore;

    var score = (healthScore * 0.6) + (improvementScore * 0.4);
    if (hasCriticalRoleLoss) {
      score -= 6;
    }
    final cleanUpgradeBonus = healthScore >= 70 &&
        improvementScore >= 55 &&
        functional.questionable == 0 &&
        !hasCriticalRoleLoss;
    if (cleanUpgradeBonus) {
      score += 3;
    }
    score = score.clamp(0, 100);

    // Veredito
    String verdict;
    if (healthScore < 45) {
      verdict = 'reprovado';
    } else if (score >= 70 &&
        healthScore >= 70 &&
        improvementScore >= 55 &&
        !hasCriticalRoleLoss) {
      verdict = 'aprovado';
    } else if (score >= 45) {
      verdict = 'aprovado_com_ressalvas';
    } else {
      verdict = 'reprovado';
    }

    // Warnings
    final warnings = <String>[];
    if (consistencyDelta < -3) {
      warnings.add(
          'Consistência do deck diminuiu (${monteCarlo.before.consistencyScore} → ${monteCarlo.after.consistencyScore})');
    }
    if (lostRemoval) {
      warnings.add('O deck perdeu cartas de remoção. Pode ficar vulnerável.');
    }
    if (lostDraw) {
      warnings.add('O deck perdeu card draw. Pode perder gás no late game.');
    }
    if (lostWipe) {
      warnings.add(
          'O deck perdeu board wipe(s). Pode ter dificuldade contra ameaças múltiplas.');
    }
    if (lostRamp) {
      warnings
          .add('O deck perdeu cartas de ramp. Pode ficar lento no early game.');
    }
    if (functional.questionable > 0) {
      warnings.add(
          '${functional.questionable} troca(s) questionável(is) — mudou função E ficou mais cara.');
    }
    if (monteCarlo.after.screwRate > monteCarlo.before.screwRate + 0.03) {
      warnings.add('Risco de mana screw aumentou significativamente.');
    }
    if (healthScore < 60) {
      warnings.add(
          'Saúde absoluta do deck final ainda está baixa (${healthScore.round()}/100).');
    }
    if (improvementScore < 50) {
      warnings.add(
          'A melhoria incremental foi pequena (${improvementScore.round()}/100).');
    }

    return ValidationReport(
      score: score.round(),
      healthScore: healthScore.round(),
      improvementScore: improvementScore.round(),
      verdict: verdict,
      monteCarlo: monteCarlo,
      functional: functional,
      critic: critic,
      warnings: warnings,
    );
  }

  double _computeDeckHealthScore({
    required MonteCarloComparison monteCarlo,
    required String archetype,
  }) {
    final after = monteCarlo.after;
    final afterMulligan = monteCarlo.afterMulligan;
    final pressureRate = _pressureRateForArchetype(after, archetype);
    final stableManaRate =
        (1 - after.screwRate - after.floodRate).clamp(0.0, 1.0);

    var score = 0.0;
    score += after.consistencyScore * 0.35;
    score += (after.keepableRate * 100) * 0.20;
    score += (afterMulligan.keepableAfterMullRate * 100) * 0.15;
    score += (stableManaRate * 100) * 0.20;
    score += (pressureRate * 100) * 0.10;
    return score.clamp(0, 100).toDouble();
  }

  double _computeImprovementScore({
    required MonteCarloComparison monteCarlo,
    required FunctionalReport functional,
    required String archetype,
    required Map<String, dynamic>? critic,
  }) {
    final before = monteCarlo.before;
    final after = monteCarlo.after;
    final beforeMulligan = monteCarlo.beforeMulligan;
    final afterMulligan = monteCarlo.afterMulligan;

    final consistencyDelta = after.consistencyScore - before.consistencyScore;
    final keepableDelta = after.keepableRate - before.keepableRate;
    final keepAfterMullDelta = afterMulligan.keepableAfterMullRate -
        beforeMulligan.keepableAfterMullRate;
    final keepAt7Delta = afterMulligan.keepAt7Rate - beforeMulligan.keepAt7Rate;
    final screwDelta = before.screwRate - after.screwRate;
    final floodDelta = before.floodRate - after.floodRate;
    final pressureDelta = _pressureRateForArchetype(after, archetype) -
        _pressureRateForArchetype(before, archetype);

    var score = 40.0;
    score += consistencyDelta * 5.0;
    score += keepableDelta * 300.0;
    score += keepAfterMullDelta * 180.0;
    score += keepAt7Delta * 120.0;
    score += screwDelta * 300.0;
    score += floodDelta * 100.0;
    score += pressureDelta * 250.0;

    score += functional.upgrades * 5.0;
    score += functional.sidegrades * 2.0;
    score -= functional.tradeoffs * 3.0;
    score -= functional.questionable * 8.0;

    if ((functional.roleDelta['removal'] ?? 0) < 0) score -= 12.0;
    if ((functional.roleDelta['draw'] ?? 0) < 0) score -= 10.0;
    if ((functional.roleDelta['wipe'] ?? 0) < 0) score -= 8.0;
    if ((functional.roleDelta['ramp'] ?? 0) < 0) score -= 8.0;
    if ((functional.roleDelta['protection'] ?? 0) < 0) score -= 6.0;

    final cleanIncrementalUpgrade = functional.upgrades >= 1 &&
        functional.questionable == 0 &&
        consistencyDelta >= 0 &&
        keepAfterMullDelta >= -0.01 &&
        screwDelta >= -0.01;
    if (cleanIncrementalUpgrade) {
      score += 4.0;
    }

    score = score.clamp(0, 100).toDouble();

    if (critic != null) {
      final criticScore = (critic['approval_score'] as num?)?.toDouble() ?? 50;
      score = (score * 0.8) + (criticScore * 0.2);
    }

    return score.clamp(0, 100).toDouble();
  }

  double _pressureRateForArchetype(GoldfishResult result, String archetype) {
    return switch (archetype.trim().toLowerCase()) {
      'control' => result.turn4PlayRate,
      'combo' => result.turn3PlayRate,
      _ => result.turn2PlayRate,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  bool _isLand(Map<String, dynamic> card) {
    return ((card['type_line'] as String?) ?? '')
        .toLowerCase()
        .contains('land');
  }

  Map<String, dynamic>? _findCardByName(
    List<Map<String, dynamic>> deck,
    String name,
  ) {
    final normalized = name.trim().toLowerCase();
    for (final card in deck) {
      final candidate = ((card['name'] as String?) ?? '').trim().toLowerCase();
      if (candidate == normalized) return card;
    }
    return null;
  }

  int _getCmc(Map<String, dynamic> card) {
    final cmc = card['cmc'];
    if (cmc == null) return 0;
    if (cmc is int) return cmc;
    if (cmc is double) return cmc.toInt();
    return int.tryParse(cmc.toString()) ?? 0;
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

class MonteCarloComparison {
  final GoldfishResult before;
  final GoldfishResult after;
  final MulliganReport beforeMulligan;
  final MulliganReport afterMulligan;

  MonteCarloComparison({
    required this.before,
    required this.after,
    required this.beforeMulligan,
    required this.afterMulligan,
  });

  Map<String, dynamic> toJson() => {
        'before': before.toJson(),
        'after': after.toJson(),
        'mulligan_before': beforeMulligan.toJson(),
        'mulligan_after': afterMulligan.toJson(),
        'deltas': {
          'consistency_score': after.consistencyScore - before.consistencyScore,
          'screw_rate_delta': double.parse(
              (after.screwRate - before.screwRate).toStringAsFixed(3)),
          'flood_rate_delta': double.parse(
              (after.floodRate - before.floodRate).toStringAsFixed(3)),
          'keepable_rate_delta': double.parse(
              (after.keepableRate - before.keepableRate).toStringAsFixed(3)),
          'turn2_play_delta': double.parse(
              (after.turn2PlayRate - before.turn2PlayRate).toStringAsFixed(3)),
          'mulligan_keep7_delta': double.parse(
              (afterMulligan.keepAt7Rate - beforeMulligan.keepAt7Rate)
                  .toStringAsFixed(3)),
        },
      };
}

class MulliganReport {
  final int runs;
  final double avgMulligans;
  final double keepAt7Rate;
  final double keepAt6Rate;
  final double keepAt5Rate;
  final double keepAt4OrLessRate;
  final double keepableAfterMullRate;

  MulliganReport({
    required this.runs,
    required this.avgMulligans,
    required this.keepAt7Rate,
    required this.keepAt6Rate,
    required this.keepAt5Rate,
    required this.keepAt4OrLessRate,
    required this.keepableAfterMullRate,
  });

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'avg_mulligans': double.parse(avgMulligans.toStringAsFixed(2)),
        'keep_at_7': double.parse(keepAt7Rate.toStringAsFixed(3)),
        'keep_at_6': double.parse(keepAt6Rate.toStringAsFixed(3)),
        'keep_at_5': double.parse(keepAt5Rate.toStringAsFixed(3)),
        'keep_at_4_or_less': double.parse(keepAt4OrLessRate.toStringAsFixed(3)),
        'keepable_after_mull':
            double.parse(keepableAfterMullRate.toStringAsFixed(3)),
      };
}

class SwapFunctionalAnalysis {
  final String removed;
  final String added;
  final String removedRole;
  final String addedRole;
  final bool rolePreserved;
  final int cmcDelta;
  final String verdict; // 'upgrade', 'sidegrade', 'tradeoff', 'questionável'

  SwapFunctionalAnalysis({
    required this.removed,
    required this.added,
    required this.removedRole,
    required this.addedRole,
    required this.rolePreserved,
    required this.cmcDelta,
    required this.verdict,
  });

  Map<String, dynamic> toJson() => {
        'removed': removed,
        'added': added,
        'removed_role': removedRole,
        'added_role': addedRole,
        'role_preserved': rolePreserved,
        'cmc_delta': cmcDelta,
        'verdict': verdict,
      };
}

class FunctionalReport {
  final List<SwapFunctionalAnalysis> swaps;
  final int upgrades;
  final int sidegrades;
  final int tradeoffs;
  final int questionable;
  final Map<String, int> roleDelta;

  FunctionalReport({
    required this.swaps,
    required this.upgrades,
    required this.sidegrades,
    required this.tradeoffs,
    required this.questionable,
    required this.roleDelta,
  });

  Map<String, dynamic> toJson() => {
        'swaps': swaps.map((s) => s.toJson()).toList(),
        'summary': {
          'upgrades': upgrades,
          'sidegrades': sidegrades,
          'tradeoffs': tradeoffs,
          'questionable': questionable,
        },
        'role_delta': roleDelta,
      };
}

class ValidationReport {
  final int score; // 0-100
  final int healthScore; // 0-100
  final int improvementScore; // 0-100
  final String verdict; // 'aprovado', 'aprovado_com_ressalvas', 'reprovado'
  final MonteCarloComparison monteCarlo;
  final FunctionalReport functional;
  final Map<String, dynamic>? critic;
  final List<String> warnings;

  ValidationReport({
    required this.score,
    this.healthScore = 0,
    this.improvementScore = 0,
    required this.verdict,
    required this.monteCarlo,
    required this.functional,
    this.critic,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
        'validation_score': score,
        'deck_health_score': healthScore,
        'improvement_score': improvementScore,
        'verdict': verdict,
        'monte_carlo': monteCarlo.toJson(),
        'functional_analysis': functional.toJson(),
        if (critic != null) 'critic_ai': critic,
        'warnings': warnings,
      };
}
