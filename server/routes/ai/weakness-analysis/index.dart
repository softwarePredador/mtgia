import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/archetype_counters_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/ai/optimization_functional_roles.dart';
import '../../../lib/ai/commander_spellbook_service.dart';
import '../../../lib/ai/deck_advanced_analysis.dart';

/// Endpoint para análise de fraquezas do deck
///
/// POST /ai/weakness-analysis
/// Body: { "deck_id": "uuid" }
///
/// Retorna lista de fraquezas identificadas com recomendações
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final deckId = body['deck_id'] as String?;
    final userId = context.read<String>();

    if (deckId == null) {
      return badRequest('deck_id is required');
    }

    final pool = context.read<Pool>();
    final countersService = ArchetypeCountersService(pool);
    final hasCardIntelligenceSnapshot = await _hasTable(
      pool,
      'card_intelligence_snapshot',
    );
    final cardSourceJoin =
        hasCardIntelligenceSnapshot
            ? 'JOIN card_intelligence_snapshot c ON c.card_id = dc.card_id'
            : 'JOIN cards c ON c.id = dc.card_id';
    final functionalTagsSelect =
        hasCardIntelligenceSnapshot
            ? 'c.function_tag_details AS functional_tags'
            : await _functionalTagsSelectSql(pool);
    final semanticV2Select =
        hasCardIntelligenceSnapshot
            ? 'c.semantic_tags_v2 AS semantic_tags_v2'
            : await _semanticV2SelectSql(pool);

    // 1. Buscar informações do deck
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT name, format
        FROM decks
        WHERE id = CAST(@id AS uuid)
          AND user_id = CAST(@user_id AS uuid)
      '''),
      parameters: {'id': deckId, 'user_id': userId},
    );

    if (deckResult.isEmpty) {
      return notFound('Deck not found');
    }

    final deckName = deckResult.first[0] as String;
    final deckFormat = deckResult.first[1] as String;

    // 2. Buscar todas as cartas do deck com detalhes
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, dc.quantity,
               COALESCE(
                 (SELECT SUM(
                   CASE 
                     WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                     WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                     WHEN m[1] = 'X' THEN 0
                     ELSE 1
                   END
                 ) FROM regexp_matches(c.mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
                 0
               ) as cmc,
               c.oracle_id::text as oracle_id,
               c.color_identity,
               dc.is_commander,
               $functionalTagsSelect,
               $semanticV2Select
        FROM deck_cards dc 
        $cardSourceJoin
        WHERE dc.deck_id = @id
      '''),
      parameters: {'id': deckId},
    );

    final cards = <Map<String, dynamic>>[];
    final observedDeckColors = <String>{};
    final commanderColorIdentity = <String>{};
    final deckOracleIds = <String>{};
    final commanderOracleIds = <String>{};
    final deckCardNames = <String>{};

    int totalCards = 0;
    int landCount = 0;
    int creatureCount = 0;
    int rampCount = 0;
    int drawCount = 0;
    int removalCount = 0;
    int boardWipeCount = 0;
    int protectionCount = 0;
    int graveyardInteractionCount = 0;
    double totalCMC = 0;
    int nonLandCards = 0;

    for (final row in cardsResult) {
      final name = row[0] as String;
      final typeLine = (row[1] as String?) ?? '';
      final oracleText = ((row[2] as String?) ?? '').toLowerCase();
      final manaCost = (row[3] as String?) ?? '';
      final colors = (row[4] as List?)?.cast<String>() ?? [];
      final quantity = row[5] as int;
      final cmc = (row[6] as num?)?.toDouble() ?? 0;
      final oracleId = (row[7] as String?) ?? '';
      final colorIdentity = (row[8] as List?)?.cast<String>() ?? [];
      final isCommanderCard = row[9] == true;
      final functionalTags = row[10];
      final semanticTagsV2 = row[11];

      observedDeckColors.addAll(colors);
      if (isCommanderCard) {
        commanderColorIdentity.addAll(colorIdentity);
        if (oracleId.isNotEmpty) commanderOracleIds.add(oracleId);
      }
      if (oracleId.isNotEmpty) deckOracleIds.add(oracleId);
      deckCardNames.add(name.toLowerCase());
      totalCards += quantity;

      cards.add({
        'name': name,
        'type_line': typeLine,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
        'colors': colors,
        'quantity': quantity,
        'cmc': cmc,
        'functional_tags': functionalTags,
        'semantic_tags_v2': semanticTagsV2,
      });

      final typeLineLower = typeLine.toLowerCase();

      // Usar adapter F1 (resolveCardFunctionalRoles) em vez de heuristicas oracle_text
      final cardRoles = resolveCardFunctionalRoles(
        functionalTags: functionalTags,
        semanticTagsV2: semanticTagsV2,
        oracleText: oracleText,
        typeLine: typeLine,
        name: name,
        manaCost: manaCost,
        cmc: cmc,
      );

      if (typeLineLower.contains('land')) {
        landCount += quantity;
      } else {
        nonLandCards += quantity;
        totalCMC += cmc * quantity;
      }

      if (typeLineLower.contains('creature')) {
        creatureCount += quantity;
      }

      // Contagem via adapter F1
      if (cardRoles.contains('ramp') || cardRoles.contains('ritual'))
        rampCount += quantity;
      if (cardRoles.contains('draw') || cardRoles.contains('loot'))
        drawCount += quantity;
      if (cardRoles.contains('removal')) removalCount += quantity;
      if (cardRoles.contains('wipe') || cardRoles.contains('board_wipe'))
        boardWipeCount += quantity;
      if (cardRoles.contains('protection')) protectionCount += quantity;
      if (cardRoles.contains('recursion') || cardRoles.contains('graveyard'))
        graveyardInteractionCount += quantity;
    }
    final recommendationColors =
        commanderColorIdentity.isNotEmpty
            ? commanderColorIdentity
            : observedDeckColors;
    final colorIdentitySource =
        commanderColorIdentity.isNotEmpty
            ? 'commander_color_identity'
            : 'observed_card_colors';

    // 3. Detectar arquétipo do deck
    final archetypeAnalysis = await countersService.detectDeckArchetype(
      cards: cards,
    );
    final detectedArchetype = archetypeAnalysis['archetype'] as String;

    // 4. Calcular métricas
    final avgCMC = nonLandCards > 0 ? totalCMC / nonLandCards : 0.0;
    final isCommander = deckFormat.toLowerCase() == 'commander';

    // 5. Identificar fraquezas
    final weaknesses = <Map<String, dynamic>>[];

    // Verificar quantidade de terrenos
    if (isCommander) {
      if (landCount < 33) {
        weaknesses.add({
          'type': 'low_land_count',
          'severity': 'high',
          'description':
              'Deck tem apenas $landCount terrenos. Commander decks geralmente precisam de 33-38 conforme perfil, curva e ramp.',
          'recommendations': [
            'Adicionar ${33 - landCount} terrenos',
            'Considerar terrenos que produzem múltiplas cores',
          ],
          'current_value': landCount,
          'recommended_value': 33,
        });
      } else if (landCount > 40) {
        weaknesses.add({
          'type': 'high_land_count',
          'severity': 'low',
          'description':
              'Deck tem $landCount terrenos. Pode ser excessivo para alguns arquétipos.',
          'recommendations': [
            'Considerar reduzir terrenos se tiver muito ramp',
          ],
          'current_value': landCount,
          'recommended_value': 37,
        });
      }
    }

    // Verificar ramp
    if (rampCount < 8) {
      weaknesses.add({
        'type': 'insufficient_ramp',
        'severity': rampCount < 5 ? 'critical' : 'high',
        'description':
            'Deck tem apenas $rampCount fontes de ramp. Recomendado: 10-12.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['ramp', 'ritual'],
          oraclePatterns: const [
            'add {%',
            '%search your library%land%',
            '%put%land%onto the battlefield%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 5,
          fallback: const [
            'Buscar ramp legal nas cores do deck',
            'Priorizar rocks, dorks ou ramp de terrenos conforme a identidade',
          ],
        ),
        'current_value': rampCount,
        'recommended_value': 10,
      });
    }

    // Verificar card draw
    if (drawCount < 8) {
      weaknesses.add({
        'type': 'insufficient_card_draw',
        'severity': drawCount < 4 ? 'critical' : 'high',
        'description':
            'Deck tem apenas $drawCount fontes de draw. Recomendado: 10+.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['draw', 'loot'],
          oraclePatterns: const ['%draw%card%', '%draw%cards%'],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 4,
          fallback: const [
            'Buscar draw legal nas cores do deck',
            'Priorizar peças de compra recorrente ou cantrips eficientes',
          ],
        ),
        'current_value': drawCount,
        'recommended_value': 10,
      });
    }

    // Verificar removal
    if (removalCount < 6) {
      weaknesses.add({
        'type': 'insufficient_removal',
        'severity': removalCount < 3 ? 'critical' : 'medium',
        'description':
            'Deck tem apenas $removalCount remoções pontuais. Recomendado: 8-10.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['removal'],
          oraclePatterns: const [
            '%destroy target%',
            '%exile target%',
            '%damage%target%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 4,
          fallback: const [
            'Buscar remoção pontual legal nas cores do deck',
            'Priorizar respostas baratas para criaturas e permanentes-chave',
          ],
        ),
        'current_value': removalCount,
        'recommended_value': 8,
      });
    }

    // Verificar board wipes
    if (boardWipeCount < 2) {
      weaknesses.add({
        'type': 'insufficient_board_wipes',
        'severity': 'medium',
        'description':
            'Deck tem apenas $boardWipeCount board wipes. Recomendado: 3-4.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['wipe', 'board_wipe'],
          oraclePatterns: const [
            '%destroy all%',
            '%exile all%',
            '%each creature%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 4,
          fallback: const [
            'Buscar sweeper legal nas cores do deck',
            'Priorizar wipes assimétricos ou de baixo custo quando possível',
          ],
        ),
        'current_value': boardWipeCount,
        'recommended_value': 3,
      });
    }

    // Verificar curva de mana
    if (avgCMC > 3.5 && detectedArchetype != 'control') {
      weaknesses.add({
        'type': 'high_mana_curve',
        'severity': avgCMC > 4.0 ? 'high' : 'medium',
        'description':
            'CMC médio de ${avgCMC.toStringAsFixed(2)} é alto para $detectedArchetype.',
        'recommendations': [
          'Reduzir cartas com CMC > 5',
          'Adicionar mais cartas de custo 1-3',
        ],
        'current_value': avgCMC,
        'recommended_value': 2.5,
      });
    }

    // Verificar vulnerabilidade a graveyard hate
    if (graveyardInteractionCount > 10 && protectionCount < 3) {
      weaknesses.add({
        'type': 'graveyard_vulnerability',
        'severity': 'high',
        'description':
            'Deck depende muito do cemitério ($graveyardInteractionCount cartas) mas tem pouca proteção.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['protection', 'graveyard_hate'],
          oraclePatterns: const [
            '%graveyard%',
            '%hexproof%',
            '%indestructible%',
            '%protection from%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 4,
          fallback: const [
            'Buscar proteção ou hate de cemitério legal nas cores do deck',
            'Adicionar redundância para proteger plano baseado em cemitério',
          ],
        ),
        'current_value': graveyardInteractionCount,
        'recommended_value': 0,
      });
    }

    // Verificar proteção geral
    if (protectionCount < 3) {
      weaknesses.add({
        'type': 'low_protection',
        'severity': 'medium',
        'description': 'Deck tem apenas $protectionCount fontes de proteção.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['protection'],
          oraclePatterns: const [
            '%hexproof%',
            '%indestructible%',
            '%protection from%',
            '%ward%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 4,
          fallback: const [
            'Buscar proteção legal nas cores do deck',
            'Priorizar proteção barata para comandante e engines',
          ],
        ),
        'current_value': protectionCount,
        'recommended_value': 5,
      });
    }

    // Verificar remoção de artefatos/encantamentos
    int artifactEnchantmentRemovalCount = 0;
    for (final card in cards) {
      final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
      if (oracle.contains('destroy target artifact') ||
          oracle.contains('destroy target enchantment') ||
          oracle.contains('exile target artifact') ||
          oracle.contains('exile target enchantment') ||
          oracle.contains('destroy target nonland permanent') ||
          oracle.contains('exile target nonland permanent') ||
          oracle.contains('destroy target permanent')) {
        artifactEnchantmentRemovalCount += (card['quantity'] as int);
      }
    }
    if (artifactEnchantmentRemovalCount < 3) {
      weaknesses.add({
        'type': 'insufficient_artifact_enchantment_removal',
        'severity':
            artifactEnchantmentRemovalCount == 0 ? 'critical' : 'medium',
        'description':
            'Deck tem apenas $artifactEnchantmentRemovalCount remoções de artefatos/encantamentos. Recomendado: 4-6.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['removal'],
          oraclePatterns: const [
            '%destroy target artifact%',
            '%destroy target enchantment%',
            '%exile target artifact%',
            '%exile target enchantment%',
            '%destroy target nonland permanent%',
            '%exile target nonland permanent%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 5,
          fallback: const [
            'Buscar remoção de artefato/encantamento legal nas cores do deck',
            'Priorizar respostas flexíveis para permanentes não-terreno',
          ],
        ),
        'current_value': artifactEnchantmentRemovalCount,
        'recommended_value': 5,
      });
    }

    // Verificar win conditions (cartas que podem fechar o jogo)
    int winConditionCount = 0;
    for (final card in cards) {
      final name = (card['name'] as String?) ?? '';
      final oracle = ((card['oracle_text'] as String?) ?? '');
      final typeLine = ((card['type_line'] as String?) ?? '');
      final manaCost = (card['mana_cost'] as String?) ?? '';
      final cmc = card['cmc'];
      final roles = resolveCardFunctionalRoles(
        functionalTags: card['functional_tags'],
        semanticTagsV2: card['semantic_tags_v2'],
        oracleText: oracle,
        typeLine: typeLine,
        name: name,
        manaCost: manaCost,
        cmc: cmc,
      );
      if (roles.contains('wincon') || roles.contains('combo_piece')) {
        winConditionCount += (card['quantity'] as int);
      }
    }

    // Detectar combos reais (Commander Spellbook) presentes/próximos no deck.
    // Combos completos contam como caminhos de vitória adicionais; combos a 1
    // carta viram oportunidades acionáveis.
    DeckCombosResult comboResult = const DeckCombosResult(
      complete: [],
      nearMisses: [],
    );
    try {
      comboResult = await CommanderSpellbookService().findDeckCombos(
        pool: pool,
        deckOracleIds: deckOracleIds,
        commanderOracleIds: commanderOracleIds,
        commanderColorIdentity: recommendationColors,
      );
    } catch (e) {
      print('[weakness-analysis] combo detection falhou: $e');
    }

    final completeCombos = comboResult.complete;
    final nearMissCombos = comboResult.nearMisses;

    // Combos completos são caminhos de vitória legítimos.
    final effectiveWinConditions = winConditionCount + completeCombos.length;

    if (nearMissCombos.isNotEmpty) {
      final top = nearMissCombos.take(5).toList();
      final missingCardSuggestions = <String>[];
      for (final m in top) {
        if (m.missingCardNames.isNotEmpty) {
          missingCardSuggestions.add(m.missingCardNames.first);
        }
      }
      weaknesses.add({
        'type': 'combo_opportunity',
        'severity': 'low',
        'description':
            'Deck está a 1 carta de completar ${nearMissCombos.length} combo(s) conhecido(s). '
            'Adicionar a peça que falta pode criar um caminho de vitória direto.',
        'recommendations':
            missingCardSuggestions.isNotEmpty
                ? missingCardSuggestions
                : ['Revisar combos próximos na seção "combos"'],
        'current_value': completeCombos.length,
        'recommended_value': completeCombos.length + 1,
      });
    }

    if (effectiveWinConditions < 2) {
      weaknesses.add({
        'type': 'insufficient_win_conditions',
        'severity': effectiveWinConditions == 0 ? 'critical' : 'high',
        'description':
            'Deck tem apenas $effectiveWinConditions condições de vitória claras. Recomendado: 2-3 caminhos distintos para vencer.',
        'recommendations': [
          'Adicionar finalizadores que fechem o jogo',
          'Considerar combos de 2-3 cartas',
          'Incluir dano direto ou drain effects',
        ],
        'current_value': effectiveWinConditions,
        'recommended_value': 3,
      });
    }

    // ── Análises avançadas (F3): diversidade de wincon, removal-to-threat,
    //    qualidade de draw e viabilidade pós board wipe. ──────────────────
    final winconDiversity = analyzeWinconDiversity(
      cards,
      completeCombos: completeCombos.length,
      isCommander: isCommander,
    );
    final removalToThreat = analyzeRemovalToThreatRatio(
      cards,
      isCommander: isCommander,
    );
    final drawCompleteness = analyzeDrawCompleteness(cards);
    final postResolution = analyzePostResolutionViability(
      cards,
      isCommander: isCommander,
    );

    for (final analysis in [
      winconDiversity,
      removalToThreat,
      drawCompleteness,
      postResolution,
    ]) {
      if (analysis.weakness != null) weaknesses.add(analysis.weakness!);
    }

    // Verificar se o deck tem interação no turno dos oponentes (instant-speed)
    int instantSpeedCount = 0;
    for (final card in cards) {
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
      if (typeLine.contains('instant') || oracle.contains('flash')) {
        instantSpeedCount += (card['quantity'] as int);
      }
    }
    if (isCommander && instantSpeedCount < 8) {
      weaknesses.add({
        'type': 'low_instant_speed_interaction',
        'severity': instantSpeedCount < 4 ? 'high' : 'medium',
        'description':
            'Deck tem apenas $instantSpeedCount cartas instant-speed. Em multiplayer, interação nos turnos dos oponentes é crucial.',
        'recommendations': await _findWeaknessRecommendations(
          pool: pool,
          roles: const ['removal', 'protection'],
          oraclePatterns: const [
            '%counter target%',
            '%destroy target%',
            '%exile target%',
            '%instant%',
            '%flash%',
          ],
          deckColors: recommendationColors,
          excludeNames: deckCardNames,
          format: deckFormat,
          limit: 5,
          instantSpeedOnly: true,
          fallback: const [
            'Priorizar instants sobre sorceries',
            'Buscar interação instant-speed legal nas cores do deck',
          ],
        ),
        'current_value': instantSpeedCount,
        'recommended_value': 10,
      });
    }

    // 6. Buscar hate cards recomendados para o arquétipo detectado
    final hateCards = await countersService.getHateCards(
      archetype: detectedArchetype,
      colors: recommendationColors.toList(),
    );

    // 7. Salvar análise no banco (opcional)
    try {
      for (final weakness in weaknesses) {
        await pool.execute(
          Sql.named('''
            INSERT INTO deck_weakness_reports 
              (deck_id, weakness_type, severity, description, recommendations, auto_detected)
            VALUES 
              (@deck_id, @type, @severity, @description, @recommendations, TRUE)
            ON CONFLICT DO NOTHING
          '''),
          parameters: {
            'deck_id': deckId,
            'type': weakness['type'],
            'severity': weakness['severity'],
            'description': weakness['description'],
            'recommendations': TypedValue(
              Type.textArray,
              weakness['recommendations'] as List<String>,
            ),
          },
        );
      }
    } catch (e) {
      print('[ERROR] handler: $e');
      // Não falha se não conseguir salvar
      print('Aviso: Não foi possível salvar relatório de fraquezas: $e');
    }

    final weaknessHistory = await _loadWeaknessHistory(pool, deckId);

    // 8. Retornar análise completa
    return Response.json(
      body: {
        'deck_id': deckId,
        'deck_name': deckName,
        'format': deckFormat,
        'detected_archetype': detectedArchetype,
        'archetype_confidence': archetypeAnalysis['confidence'],
        'statistics': {
          'total_cards': totalCards,
          'lands': landCount,
          'creatures': creatureCount,
          'ramp_sources': rampCount,
          'card_draw': drawCount,
          'removal': removalCount,
          'board_wipes': boardWipeCount,
          'protection': protectionCount,
          'average_cmc': avgCMC.toStringAsFixed(2),
        },
        'weaknesses': weaknesses,
        'weakness_count': weaknesses.length,
        'critical_count':
            weaknesses.where((w) => w['severity'] == 'critical').length,
        'combos': {
          'complete_count': completeCombos.length,
          'near_miss_count': nearMissCombos.length,
          'complete':
              completeCombos
                  .map(
                    (m) => {
                      'id': m.combo.id,
                      'cards': m.combo.cardNames,
                      'produces': m.combo.produces,
                      'color_identity': m.combo.colorIdentity,
                    },
                  )
                  .toList(),
          'near_misses':
              nearMissCombos
                  .map(
                    (m) => {
                      'id': m.combo.id,
                      'cards': m.combo.cardNames,
                      'missing': m.missingCardNames,
                      'produces': m.combo.produces,
                      'color_identity': m.combo.colorIdentity,
                    },
                  )
                  .toList(),
        },
        'hate_cards_for_archetype': hateCards,
        'colors': recommendationColors.toList()..sort(),
        'color_identity_source': colorIdentitySource,
        'advanced': {
          'wincon_diversity': winconDiversity.data,
          'removal_to_threat': removalToThreat.data,
          'draw_completeness': drawCompleteness.data,
          'post_resolution_viability': postResolution.data,
        },
        'history': weaknessHistory,
      },
    );
  } catch (e, stack) {
    print('Erro em weakness-analysis: $e\n$stack');
    return internalServerError('Failed to analyze deck weaknesses');
  }
}

Future<Map<String, dynamic>> _loadWeaknessHistory(
  Pool pool,
  String deckId,
) async {
  try {
    final summaryRows = await pool.execute(
      Sql.named('''
        SELECT severity, COUNT(*)::int AS count
        FROM deck_weakness_reports
        WHERE deck_id = CAST(@deck_id AS uuid)
        GROUP BY severity
      '''),
      parameters: {'deck_id': deckId},
    );
    final bySeverity = <String, int>{};
    for (final row in summaryRows) {
      final m = row.toColumnMap();
      bySeverity[(m['severity'] as String?) ?? 'unknown'] =
          (m['count'] as int?) ?? 0;
    }

    final recentRows = await pool.execute(
      Sql.named('''
        SELECT weakness_type, severity, description, addressed, created_at
        FROM deck_weakness_reports
        WHERE deck_id = CAST(@deck_id AS uuid)
        ORDER BY created_at DESC
        LIMIT 10
      '''),
      parameters: {'deck_id': deckId},
    );

    return {
      'stored_reports': bySeverity.values.fold<int>(0, (a, b) => a + b),
      'by_severity': bySeverity,
      'recent':
          recentRows.map((row) {
            final m = row.toColumnMap();
            return {
              'type': m['weakness_type'],
              'severity': m['severity'],
              'description': m['description'],
              'addressed': m['addressed'],
              'created_at': m['created_at']?.toString(),
            };
          }).toList(),
    };
  } catch (e) {
    print('[weakness-analysis] weakness history unavailable: $e');
    return const {'stored_reports': 0, 'by_severity': {}, 'recent': []};
  }
}

Future<List<String>> _findWeaknessRecommendations({
  required Pool pool,
  required List<String> roles,
  required Set<String> deckColors,
  required Set<String> excludeNames,
  required String format,
  required int limit,
  List<String> oraclePatterns = const [],
  List<String> fallback = const [],
  bool instantSpeedOnly = false,
}) async {
  final normalizedRoles = roles
      .map((role) => role.trim().toLowerCase())
      .where((role) => role.isNotEmpty)
      .toList(growable: false);
  final predicates = <String>[];

  try {
    if (normalizedRoles.isNotEmpty &&
        await _hasTable(pool, 'card_function_tags')) {
      predicates.add('''
        EXISTS (
          SELECT 1
          FROM card_function_tags cft
          WHERE cft.card_id = c.id
            AND LOWER(cft.tag) = ANY(@role_tags)
        )
      ''');
    }

    if (normalizedRoles.isNotEmpty &&
        await _hasTable(pool, 'card_semantic_tags_v2')) {
      predicates.add('''
        EXISTS (
          SELECT 1
          FROM card_semantic_tags_v2 cstv2
          WHERE cstv2.card_id = c.id
            AND cstv2.role_confidence >= 0.65
            AND cstv2.tags ?| @role_tags
        )
      ''');
    }

    for (final pattern in oraclePatterns) {
      final normalized = pattern.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      predicates.add(
        "LOWER(COALESCE(c.oracle_text, '')) LIKE ${_sqlStringLiteral(normalized)}",
      );
    }

    if (predicates.isEmpty) return fallback.take(limit).toList();

    final instantFilter =
        instantSpeedOnly
            ? '''
          AND (
            c.type_line ILIKE '%instant%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE '%flash%'
            OR LOWER(COALESCE(c.oracle_text, '')) LIKE '%as though it had flash%'
          )
        '''
            : '';

    final result = await pool.execute(
      Sql.named('''
        SELECT c.name, MIN(COALESCE(c.cmc, 99)) AS cmc_sort
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id
         AND cl.format = @format
        WHERE (${predicates.join(' OR ')})
          AND (
            @deck_colors IS NULL
            OR COALESCE(c.color_identity, ARRAY[]::text[]) = ARRAY[]::text[]
            OR COALESCE(c.color_identity, ARRAY[]::text[]) <@ @deck_colors
          )
          AND (cl.id IS NULL OR cl.status = 'legal')
          AND c.type_line NOT ILIKE '%basic%land%'
          $instantFilter
        GROUP BY c.name
        ORDER BY cmc_sort ASC, c.name ASC
        LIMIT @limit_plus
      '''),
      parameters: {
        'format': format.toLowerCase(),
        'deck_colors':
            deckColors.isEmpty
                ? null
                : TypedValue(Type.textArray, deckColors.toList()..sort()),
        'role_tags': TypedValue(Type.textArray, normalizedRoles),
        'limit_plus': limit + 20,
      },
    );

    final recommendations = <String>[];
    for (final row in result) {
      final name = row[0] as String;
      if (excludeNames.contains(name.toLowerCase())) continue;
      recommendations.add(name);
      if (recommendations.length >= limit) break;
    }

    if (recommendations.isNotEmpty) return recommendations;
  } catch (e) {
    print('[weakness-analysis] recommendation lookup unavailable: $e');
  }

  return fallback.take(limit).toList();
}

String _sqlStringLiteral(String value) {
  return "'${value.replaceAll("'", "''")}'";
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = @tableName
      )
    '''),
    parameters: {'tableName': tableName},
  );
  return result.isNotEmpty && result.first[0] == true;
}

Future<String> _functionalTagsSelectSql(Pool pool) async {
  final exists = await _hasTable(pool, 'card_function_tags');
  if (!exists) return "'[]'::jsonb AS functional_tags";
  return '''
               COALESCE(
                 (
                   SELECT jsonb_agg(
                     jsonb_build_object(
                       'tag', cft.tag,
                       'confidence', cft.confidence,
                       'evidence', cft.evidence,
                       'source', cft.source
                     )
                     ORDER BY cft.confidence DESC, cft.tag
                   )
                   FROM card_function_tags cft
                   WHERE cft.card_id = c.id
                 ),
                 '[]'::jsonb
               ) AS functional_tags''';
}

Future<String> _semanticV2SelectSql(Pool pool) async {
  final exists = await _hasTable(pool, 'card_semantic_tags_v2');
  if (!exists) return "'[]'::jsonb AS semantic_tags_v2";
  return '''
               COALESCE(
                 (
                   SELECT jsonb_agg(
                     jsonb_build_object(
                       'tags', cstv2.tags,
                       'role_confidence', cstv2.role_confidence,
                       'engine', cstv2.engine,
                       'payoff', cstv2.payoff,
                       'enabler', cstv2.enabler,
                       'wincon', cstv2.wincon,
                       'combo_piece', cstv2.combo_piece
                     )
                     ORDER BY cstv2.role_confidence DESC, cstv2.source
                   )
                   FROM card_semantic_tags_v2 cstv2
                   WHERE cstv2.card_id = c.id
                 ),
                 '[]'::jsonb
               ) AS semantic_tags_v2''';
}
