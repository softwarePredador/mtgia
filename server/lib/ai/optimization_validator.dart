import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../ai_provider_runtime_support.dart';
import '../ai_provider_usage_support.dart';
import '../logger.dart';
import '../openai_runtime_config.dart';
import '../basic_land_utils.dart' as land_utils;
import '../openai_structured_output_support.dart';
import '../runtime_environment.dart';
import 'cmc_safety.dart';
import 'goldfish_simulator.dart';
import 'optimization_functional_roles.dart';
import 'optimization_ramp_profile.dart';
import 'theme_contextual_rules_service.dart';

typedef ThemeDeckValidationCallback =
    Future<ThemeValidationResult> Function({
      required String archetype,
      required List<Map<String, dynamic>> cards,
    });

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
  final String? safetyIdentifierSource;
  final ThemeContextualRulesService? themeService;
  final ThemeDeckValidationCallback? themeValidator;
  final dynamic providerLogDb;
  final String? providerUserId;
  final String? providerDeckId;

  OptimizationValidator({
    this.openAiKey,
    this.safetyIdentifierSource,
    this.themeService,
    this.themeValidator,
    this.providerLogDb,
    this.providerUserId,
    this.providerDeckId,
  });

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

    // 2.5 VALIDAÇÃO TEMÁTICA (theme_contextual_rules do PostgreSQL)
    ThemeValidationResult? themeValidation;
    if (themeValidator != null || themeService != null) {
      try {
        themeValidation =
            themeValidator != null
                ? await themeValidator!(
                  archetype: archetype,
                  cards: optimizedDeck,
                )
                : await themeService!.validateDeck(
                  archetype: archetype,
                  cards: optimizedDeck,
                );
        Log.i(
          'ThemeValidation: ${themeValidation.theme}, '
          '${themeValidation.checks.length} checks, '
          'critical=${themeValidation.hasCriticalViolation}',
        );
      } catch (e) {
        Log.w('ThemeValidation unavailable type=${e.runtimeType}');
      }
    }

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
      themeValidation: themeValidation,
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
  /// Regra: compra 7 em toda tentativa. O primeiro mulligan de multiplayer é
  /// grátis; somente a partir do segundo uma carta adicional vai ao fundo.
  ///
  /// Heurística de keep: 2-5 lands + pelo menos 1 carta jogável nos turnos 1-3
  MulliganReport _simulateLondonMulligan(
    List<Map<String, dynamic>> deck, {
    int runs = 500,
  }) {
    final random = Random(_stableDeckSeed(deck, runs));
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
        final bottomCount = max(0, attempt - 1);
        final handSize = 7 - bottomCount;

        // Heurística de keep melhorada:
        // Mana rocks contam como "meios terrenos" para avaliar keepability
        final landsInHand = hand.where(_isLand).length;
        final manaRocksInHand =
            hand.where((c) {
              if (_isLand(c)) return false;
              final t = ((c['type_line'] as String?) ?? '').toLowerCase();
              final o = ((c['oracle_text'] as String?) ?? '').toLowerCase();
              return t.contains('artifact') &&
                  o.contains('add') &&
                  _getCmc(c) <= 2;
            }).length;
        // effectiveLands = terras reais + (mana rocks × 0.5)
        final effectiveLands = landsInHand + (manaRocksInHand * 0.5);
        final hasEarlyPlay = hand.any((c) => !_isLand(c) && _getCmc(c) <= 3);

        // Keep se: 2-5 effective lands E tem jogada early (ou hand size <= 5)
        final shouldKeep =
            (effectiveLands >= 1.5 && effectiveLands <= 5.5 && hasEarlyPlay) ||
            handSize <= 5; // Keep at 5 cards regardless

        if (shouldKeep || attempt == 3) {
          // Kept
          kept = true;
          mulligans = attempt;

          if (handSize == 7) {
            keptAt7++;
          } else if (handSize == 6) {
            keptAt6++;
          } else if (handSize == 5) {
            keptAt5++;
          } else {
            keptAt4OrLess++;
          }

          // A mão final era jogável?
          if (landsInHand >= 2 && landsInHand <= 5 && hasEarlyPlay) {
            totalKeepableAfterMull++;
          }
        }
      }

      totalMulligans += mulligans;
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

  int _stableDeckSeed(List<Map<String, dynamic>> deck, int runs) {
    var hash = 17;

    for (final card in deck) {
      final name = (card['name'] as String? ?? '').toLowerCase();
      final quantity = (card['quantity'] as int?) ?? 1;
      final typeLine = (card['type_line'] as String? ?? '').toLowerCase();
      final manaCost = (card['mana_cost'] as String? ?? '').toLowerCase();

      hash = 31 * hash + name.hashCode;
      hash = 31 * hash + quantity.hashCode;
      hash = 31 * hash + typeLine.hashCode;
      hash = 31 * hash + manaCost.hashCode;
    }

    return hash ^ runs.hashCode;
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
        swapAnalysis.add(
          SwapFunctionalAnalysis(
            removed: removedName,
            added: addedName,
            removedRole: 'unknown',
            addedRole: 'unknown',
            rolePreserved: false,
            cmcDelta: 0,
            verdict: 'indeterminado',
          ),
        );
        continue;
      }

      // Classificar papel funcional
      final removedRole = classifyOptimizationFunctionalRole(removedCard);
      final addedRole = classifyOptimizationFunctionalRole(addedCard);
      final removedRoles = optimizationFunctionalRolesForCard(removedCard);
      final addedRoles = optimizationFunctionalRolesForCard(addedCard);
      final removedIsLand = _isLand(removedCard);
      final addedIsLand = _isLand(addedCard);

      // CMC comparison
      final removedCmc = _getCmc(removedCard);
      final addedCmc = _getCmc(addedCard);
      final cmcDelta = addedCmc - removedCmc;

      // Verificar se o papel foi preservado.
      // Regra: role preservado quando os papéis são iguais OU ambos são 'utility'
      // (que representa cartas sem papel funcional claro).
      // ATENÇÃO: a condição anterior era `(removedRole == 'utility' || addedRole == 'utility')`,
      // o que avaliava como verdadeiro sempre que QUALQUER card fosse 'utility' — bug de precedência.
      final rolePreserved =
          removedIsLand == addedIsLand &&
          (removedRole == addedRole ||
              (removedRole == 'utility' && addedRole == 'utility') ||
              removedRoles.intersection(addedRoles).isNotEmpty);

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

      swapAnalysis.add(
        SwapFunctionalAnalysis(
          removed: removedName,
          added: addedName,
          removedRole: removedRole,
          addedRole: addedRole,
          rolePreserved: rolePreserved,
          cmcDelta: cmcDelta,
          verdict: verdict,
        ),
      );
    }

    // Contagem global
    final upgrades = swapAnalysis.where((s) => s.verdict == 'upgrade').length;
    final sidegrades =
        swapAnalysis.where((s) => s.verdict == 'sidegrade').length;
    final tradeoffs = swapAnalysis.where((s) => s.verdict == 'tradeoff').length;
    final questionable =
        swapAnalysis.where((s) => s.verdict == 'questionável').length;

    // Análise de categorias (deck perde removal? perde draw?)
    final roleDelta = <String, int>{};
    for (final role in [
      'draw',
      'removal',
      'ramp',
      'ramp_floor',
      'creature',
      'artifact',
      'enchantment',
      'land',
      'utility',
      'wipe',
      'tutor',
      'protection',
      'recursion',
      'wincon',
      'combo_piece',
      'engine',
      'payoff',
      'enabler',
    ]) {
      var lost = 0;
      var gained = 0;
      for (final swap in swapAnalysis) {
        final removedCard =
            _findCardByName(originalDeck, swap.removed) ?? <String, dynamic>{};
        final addedCard =
            _findCardByName(optimizedDeck, swap.added) ?? <String, dynamic>{};
        final removedHasRole =
            removedCard.isNotEmpty &&
            switch (role) {
              'land' => _isLand(removedCard),
              'ramp_floor' =>
                optimizationRampProfileForCard(
                  removedCard,
                ).countsTowardGenericFloor,
              _ => optimizationFunctionalRolesForCard(
                removedCard,
              ).contains(role),
            };
        final addedHasRole =
            addedCard.isNotEmpty &&
            switch (role) {
              'land' => _isLand(addedCard),
              'ramp_floor' =>
                optimizationRampProfileForCard(
                  addedCard,
                ).countsTowardGenericFloor,
              _ => optimizationFunctionalRolesForCard(addedCard).contains(role),
            };
        if (removedHasRole) {
          lost++;
        }
        if (addedHasRole) {
          gained++;
        }
      }
      roleDelta[role] = gained - lost;
    }

    final semanticLayerV2 = buildOptimizationSemanticV2Diagnostics(
      originalDeck: originalDeck,
      optimizedDeck: optimizedDeck,
      removals: removals,
      additions: additions,
    );

    return FunctionalReport(
      swaps: swapAnalysis,
      upgrades: upgrades,
      sidegrades: sidegrades,
      tradeoffs: tradeoffs,
      questionable: questionable,
      roleDelta: roleDelta,
      semanticLayerV2: semanticLayerV2,
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

    final env = loadRuntimeEnvironment();
    final aiConfig = OpenAiRuntimeConfig(env);
    final model = aiConfig.optimizationCriticModel;
    final temperature = aiConfig.temperatureFor(
      key: 'OPENAI_TEMP_OPTIMIZATION_CRITIC',
      fallback: 0.2,
      devFallback: 0.25,
      stagingFallback: 0.2,
      prodFallback: 0.15,
    );
    final providerStopwatch = Stopwatch()..start();
    var providerCallRecorded = false;

    try {
      final criticPrompt =
          '''Você é um revisor crítico de otimizações de deck de Magic: The Gathering (Commander).

Outro sistema de IA sugeriu estas trocas para um deck de ${commanders.join(' & ')} ($archetype):

${_formatSwapsForCritic(removals, additions, functionalReport)}

DADOS DE SIMULAÇÃO (Monte Carlo, 1000 mãos):
- Score de Consistência: ${monteCarloReport.before.consistencyScore} → ${monteCarloReport.after.consistencyScore} ${monteCarloReport.after.consistencyScore > monteCarloReport.before.consistencyScore ? '✅ (melhorou)' : (monteCarloReport.after.consistencyScore < monteCarloReport.before.consistencyScore ? '❌ (piorou)' : '➡️ (igual)')}
- Taxa de keep com 7 cartas: ${(monteCarloReport.beforeMulligan.keepAt7Rate * 100).toStringAsFixed(1)}% → ${(monteCarloReport.afterMulligan.keepAt7Rate * 100).toStringAsFixed(1)}%
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

      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiKey',
            },
            body: jsonEncode({
              ...aiSafetyIdentifierPayload(safetyIdentifierSource),
              'model': model,
              'messages': [
                {'role': 'user', 'content': criticPrompt},
              ],
              'temperature': temperature,
              ...openAiTokenLimitPayload(model: model, maxTokens: 900),
              'response_format': openAiStructuredResponseFormat(
                model: model,
                name: 'optimization_critic',
                schema: openAiOptimizationCriticSchema,
              ),
            }),
          )
          .timeout(
            aiConfig.timeoutFor(
              key: 'OPENAI_TIMEOUT_OPTIMIZATION_CRITIC_SECONDS',
              fallback: const Duration(seconds: 12),
              prodFallback: const Duration(seconds: 15),
              min: const Duration(seconds: 3),
              max: const Duration(seconds: 30),
            ),
          );

      if (providerLogDb != null) {
        await recordAiProviderCall(
          db: providerLogDb,
          endpoint: 'optimization_critic',
          model: model,
          latencyMs: providerStopwatch.elapsedMilliseconds,
          success: response.statusCode == 200,
          userId: providerUserId,
          deckId: providerDeckId,
          responseBodyBytes: response.bodyBytes,
          failureCode: 'provider_http_${response.statusCode}',
        );
        providerCallRecorded = true;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonDecode(data['choices'][0]['message']['content'])
            as Map<String, dynamic>;
      }

      Log.w('Critic AI failed: HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      if (providerLogDb != null && !providerCallRecorded) {
        await recordAiProviderCall(
          db: providerLogDb,
          endpoint: 'optimization_critic',
          model: model,
          latencyMs: providerStopwatch.elapsedMilliseconds,
          success: false,
          userId: providerUserId,
          deckId: providerDeckId,
          failureCode: 'provider_transport_${e.runtimeType}',
        );
      }
      Log.w('Critic AI unavailable type=${e.runtimeType}');
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
    ThemeValidationResult? themeValidation,
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

    // Role preservation: perder removal, draw, wipe ou ramp estrutural é muito ruim.
    // Essas perdas impactam tanto o score final quanto o veredito.
    final lostRemoval = (functional.roleDelta['removal'] ?? 0) < 0;
    final lostDraw = (functional.roleDelta['draw'] ?? 0) < 0;
    final lostWipe = (functional.roleDelta['wipe'] ?? 0) < 0;
    final lostRampFloor = (functional.roleDelta['ramp_floor'] ?? 0) < 0;
    final lostLand = (functional.roleDelta['land'] ?? 0) < 0;
    final hasCriticalRoleLoss =
        lostRemoval || lostDraw || lostWipe || lostRampFloor || lostLand;
    final hasCriticalThemeViolation =
        themeValidation?.hasCriticalViolation == true;
    final consistencyDelta =
        monteCarlo.after.consistencyScore - monteCarlo.before.consistencyScore;

    var score = (healthScore * 0.6) + (improvementScore * 0.4);
    if (hasCriticalRoleLoss) {
      score -= 6;
    }
    // Penalidade por violação temática crítica
    if (hasCriticalThemeViolation) {
      score -= 8;
    }
    final cleanUpgradeBonus =
        healthScore >= 70 &&
        improvementScore >= 55 &&
        functional.questionable == 0 &&
        !hasCriticalRoleLoss &&
        !hasCriticalThemeViolation;
    if (cleanUpgradeBonus) {
      score += 3;
    }
    score = score.clamp(0, 100);

    // Veredito
    String verdict;
    if (healthScore < 45 || lostLand || hasCriticalThemeViolation) {
      verdict = 'reprovado';
    } else if (score >= 70 &&
        healthScore >= 70 &&
        improvementScore >= 55 &&
        !hasCriticalRoleLoss &&
        !hasCriticalThemeViolation) {
      verdict = 'aprovado';
    } else if (score >= 70 &&
        healthScore >= 80 &&
        functional.questionable <= 1 &&
        !hasCriticalRoleLoss &&
        !hasCriticalThemeViolation) {
      // Para decks já saudáveis, um score >= 70 geralmente indica melhora real.
      // Permitimos até 1 swap "questionável" desde que não haja perda crítica.
      verdict = 'aprovado';
    } else if (score >= 65 &&
        healthScore >= 80 &&
        functional.questionable <= 1 &&
        !hasCriticalRoleLoss &&
        !hasCriticalThemeViolation) {
      // Para decks já saudáveis, score >= 65 é um threshold aceitável para
      // micro-upgrades (evita bloquear melhorias pequenas mas seguras).
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
        'Consistência do deck diminuiu (${monteCarlo.before.consistencyScore} → ${monteCarlo.after.consistencyScore})',
      );
    }
    if (lostRemoval) {
      warnings.add('O deck perdeu cartas de remoção. Pode ficar vulnerável.');
    }
    if (lostDraw) {
      warnings.add('O deck perdeu card draw. Pode perder gás no late game.');
    }
    if (lostWipe) {
      warnings.add(
        'O deck perdeu board wipe(s). Pode ter dificuldade contra ameaças múltiplas.',
      );
    }
    if (lostRampFloor) {
      warnings.add(
        'O deck perdeu ramp estrutural. Pode ficar lento no early game.',
      );
    }
    if (lostLand) {
      warnings.add(
        'O deck perdeu terrenos e degradou a estrutura mínima da base de mana.',
      );
    }
    if (functional.questionable > 0) {
      warnings.add(
        '${functional.questionable} troca(s) questionável(is) — mudou função E ficou mais cara.',
      );
    }
    if (monteCarlo.after.screwRate > monteCarlo.before.screwRate + 0.03) {
      warnings.add('Risco de mana screw aumentou significativamente.');
    }
    if (healthScore < 60) {
      warnings.add(
        'Saúde absoluta do deck final ainda está baixa (${healthScore.round()}/100).',
      );
    }
    if (improvementScore < 50) {
      warnings.add(
        'A melhoria incremental foi pequena (${improvementScore.round()}/100).',
      );
    }

    // Adicionar warnings de validação temática
    if (themeValidation != null) {
      for (final check in themeValidation.checks) {
        if (check.status != "ok" &&
            (check.priority == 'essential' || check.priority == 'high')) {
          if (check.status == 'below_min') {
            warnings.add(
              'Tema ${themeValidation.theme}: ${check.function} abaixo do mínimo '
              '(${check.current}/${check.min}). ${check.description}',
            );
          } else if (check.status == 'above_max') {
            warnings.add(
              'Tema ${themeValidation.theme}: ${check.function} acima do máximo '
              '(${check.current}/${check.max}). ${check.description}',
            );
          }
        }
      }
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
      themeValidation: themeValidation,
    );
  }

  double _computeDeckHealthScore({
    required MonteCarloComparison monteCarlo,
    required String archetype,
  }) {
    final after = monteCarlo.after;
    final afterMulligan = monteCarlo.afterMulligan;
    final pressureRate = _pressureRateForArchetype(after, archetype);
    final stableManaRate = (1 - after.screwRate - after.floodRate).clamp(
      0.0,
      1.0,
    );

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
    final keepAfterMullDelta =
        afterMulligan.keepableAfterMullRate -
        beforeMulligan.keepableAfterMullRate;
    final keepAt7Delta = afterMulligan.keepAt7Rate - beforeMulligan.keepAt7Rate;
    final screwDelta = before.screwRate - after.screwRate;
    final floodDelta = before.floodRate - after.floodRate;
    final pressureDelta =
        _pressureRateForArchetype(after, archetype) -
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
    if ((functional.roleDelta['ramp_floor'] ?? 0) < 0) score -= 8.0;
    final landLoss = -(functional.roleDelta['land'] ?? 0);
    if (landLoss > 0) score -= landLoss * 12.0;
    if ((functional.roleDelta['protection'] ?? 0) < 0) score -= 6.0;

    final cleanIncrementalUpgrade =
        functional.upgrades >= 1 &&
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
    return land_utils.isLandTypeLine((card['type_line'] as String?) ?? '');
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
    return safeCmcForOptimization(card);
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
        (after.screwRate - before.screwRate).toStringAsFixed(3),
      ),
      'flood_rate_delta': double.parse(
        (after.floodRate - before.floodRate).toStringAsFixed(3),
      ),
      'keepable_rate_delta': double.parse(
        (after.keepableRate - before.keepableRate).toStringAsFixed(3),
      ),
      'turn2_play_delta': double.parse(
        (after.turn2PlayRate - before.turn2PlayRate).toStringAsFixed(3),
      ),
      'mulligan_keep7_delta': double.parse(
        (afterMulligan.keepAt7Rate - beforeMulligan.keepAt7Rate)
            .toStringAsFixed(3),
      ),
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
    'keepable_after_mull': double.parse(
      keepableAfterMullRate.toStringAsFixed(3),
    ),
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
  final Map<String, dynamic> semanticLayerV2;

  FunctionalReport({
    required this.swaps,
    required this.upgrades,
    required this.sidegrades,
    required this.tradeoffs,
    required this.questionable,
    required this.roleDelta,
    this.semanticLayerV2 = const <String, dynamic>{},
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
    if (semanticLayerV2.isNotEmpty) 'semantic_layer_v2': semanticLayerV2,
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
  final ThemeValidationResult? themeValidation;

  ValidationReport({
    required this.score,
    this.healthScore = 0,
    this.improvementScore = 0,
    required this.verdict,
    required this.monteCarlo,
    required this.functional,
    this.critic,
    required this.warnings,
    this.themeValidation,
  });

  Map<String, dynamic> toJson() => {
    'validation_score': score,
    'deck_health_score': healthScore,
    'improvement_score': improvementScore,
    'verdict': verdict,
    'monte_carlo': monteCarlo.toJson(),
    'functional_analysis': functional.toJson(),
    if (critic != null) 'critic_ai': critic,
    if (themeValidation != null) 'theme_validation': themeValidation!.toJson(),
    'warnings': warnings,
  };
}
