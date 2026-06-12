import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';
import '../../../../lib/basic_land_utils.dart' as basic_lands;
import '../../../../lib/openai_runtime_config.dart';
import '../../../../lib/ai/edhrec_trend_service.dart';
import '../../../../lib/ai/optimization_functional_roles.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method == HttpMethod.post) {
    return _generateRecommendations(context, deckId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _generateRecommendations(
    RequestContext context, String deckId) async {
  final pool = context.read<Pool>();
  final userId = context.read<String>();
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final aiConfig = OpenAiRuntimeConfig(env);
  final apiKey = env['OPENAI_API_KEY'];

  try {
    // ─── 1. Buscar dados do deck ──────────────────────────────
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT name, format, description
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );

    if (deckResult.isEmpty) {
      return Response.json(
          statusCode: HttpStatus.notFound, body: {'error': 'Deck not found'});
    }

    final deck = deckResult.first.toColumnMap();
    final deckName = deck['name'] as String? ?? '';
    final format = deck['format'] as String? ?? 'commander';
    final description = deck['description'] as String? ?? '';
    final functionalTagsSelect = await _functionalTagsSelectSql(pool);
    final semanticV2Select = await _semanticV2SelectSql(pool);

    // ─── 2. Buscar cartas do deck com detalhes ────────────────
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, 
               dc.quantity, dc.is_commander,
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
               $functionalTagsSelect,
               $semanticV2Select
        FROM deck_cards dc
        JOIN cards c ON dc.card_id = c.id
        WHERE dc.deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );

    // ─── 3. Analisar o deck ───────────────────────────────────
    final deckCards = <Map<String, dynamic>>[];
    final deckCardNames = <String>{};
    final deckColors = <String>{};
    final commanderNames = <String>[];
    int totalCards = 0;
    int landCount = 0;
    int creatureCount = 0;
    int nonLandCards = 0;
    double totalCMC = 0;
    int rampCount = 0;
    int drawCount = 0;
    int removalCount = 0;
    int boardWipeCount = 0;
    int protectionCount = 0;

    for (final row in cardsResult) {
      final name = row[0] as String;
      final typeLine = (row[1] as String?) ?? '';
      final oracleText = ((row[2] as String?) ?? '').toLowerCase();
      final manaCost = (row[3] as String?) ?? '';
      final colors = (row[4] as List?)?.cast<String>() ?? [];
      final quantity = row[5] as int;
      final isCommander = row[6] as bool? ?? false;
      final cmc = (row[7] as num?)?.toDouble() ?? 0;
      final functionalTags = row[8];
      final semanticTagsV2 = row[9];
      final resolvedRoles = resolveCardFunctionalRoles(
        functionalTags: functionalTags,
        semanticTagsV2: semanticTagsV2,
        oracleText: oracleText,
        typeLine: typeLine,
        name: name,
        manaCost: manaCost,
        cmc: cmc,
      ).roles;

      deckColors.addAll(colors);
      deckCardNames.add(name.toLowerCase());
      totalCards += quantity;
      if (isCommander) commanderNames.add(name);

      deckCards.add({
        'name': name,
        'type_line': typeLine,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
        'colors': colors,
        'quantity': quantity,
        'is_commander': isCommander,
        'cmc': cmc,
        'functional_tags': functionalTags,
        'semantic_tags_v2': semanticTagsV2,
      });

      final tl = typeLine.toLowerCase();
      if (tl.contains('land')) {
        landCount += quantity;
      } else {
        nonLandCards += quantity;
        totalCMC += cmc * quantity;
      }
      if (tl.contains('creature')) creatureCount += quantity;

      final heuristicRamp = oracleText.contains('add {') ||
          (oracleText.contains('search your library for a') &&
              oracleText.contains('land')) ||
          oracleText.contains('put a land card');
      final heuristicDraw =
          oracleText.contains('draw') && oracleText.contains('card');
      final heuristicRemoval = oracleText.contains('destroy target') ||
          oracleText.contains('exile target') ||
          (oracleText.contains('deal') &&
              oracleText.contains('damage to target'));
      final heuristicBoardWipe = oracleText.contains('destroy all') ||
          oracleText.contains('exile all');
      final heuristicProtection = oracleText.contains('hexproof') ||
          oracleText.contains('indestructible') ||
          oracleText.contains('protection from');

      // Categorias funcionais: tags persistidas/semantic v2 primeiro,
      // heurística textual apenas como fallback.
      if (resolvedRoles.contains('ramp') || heuristicRamp) {
        rampCount += quantity;
      }
      if (resolvedRoles.contains('draw') || heuristicDraw) {
        drawCount += quantity;
      }
      if (resolvedRoles.contains('removal') || heuristicRemoval) {
        removalCount += quantity;
      }
      if (resolvedRoles.contains('board_wipe') || heuristicBoardWipe) {
        boardWipeCount += quantity;
      }
      if (resolvedRoles.contains('protection') || heuristicProtection) {
        protectionCount += quantity;
      }
    }

    final avgCMC = nonLandCards > 0 ? totalCMC / nonLandCards : 0.0;
    final creatureRatio = nonLandCards > 0 ? creatureCount / nonLandCards : 0.0;
    final isCommanderFmt = format.toLowerCase() == 'commander';

    // Detectar arquétipo
    String archetype = 'midrange';
    if (avgCMC < 2.5 && creatureRatio > 0.4)
      archetype = 'aggro';
    else if (avgCMC > 3.0 && creatureRatio < 0.25)
      archetype = 'control';
    else if (creatureRatio < 0.3) archetype = 'combo';

    // Calcular power level
    int powerLevel = 5;
    if (rampCount >= 10 && drawCount >= 8 && removalCount >= 6) powerLevel = 7;
    if (rampCount >= 12 && drawCount >= 10 && avgCMC < 2.8) powerLevel = 8;
    if (totalCards < 40) powerLevel = 3;

    // ─── 4. Se tem OpenAI, usar IA ───────────────────────────
    if (apiKey != null && apiKey.isNotEmpty) {
      return _callOpenAI(
        apiKey: apiKey,
        aiConfig: aiConfig,
        deckName: deckName,
        format: format,
        description: description,
        deckCards: deckCards,
      );
    }

    // ─── 5. FALLBACK INTELIGENTE (sem OpenAI) ────────────────
    //    Analisa lacunas reais e busca cartas do banco nas cores do deck
    final addRecommendations = <Map<String, String>>[];
    final removeRecommendations = <Map<String, String>>[];

    // Filtro de cores: aceita incolores + cores do deck
    final colorFilter = deckColors.isNotEmpty
        ? deckColors.map((c) => "'$c'").join(', ')
        : "'W','U','B','R','G'";

    // Falta de Ramp
    if (rampCount < 10) {
      final cards = await _findCardsForCategory(
        pool: pool,
        oraclePatterns: ["add {%", "search your library for a%land%"],
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        limit: (10 - rampCount).clamp(1, 5),
        format: format,
      );
      for (final c in cards) {
        addRecommendations.add({
          'card_name': c,
          'reason':
              'Ramp — deck tem apenas $rampCount fontes (recomendado: 10+)',
        });
      }
    }

    // Falta de Card Draw
    if (drawCount < 8) {
      final cards = await _findCardsForCategory(
        pool: pool,
        oraclePatterns: ["%draw%card%"],
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        limit: (8 - drawCount).clamp(1, 4),
        format: format,
      );
      for (final c in cards) {
        addRecommendations.add({
          'card_name': c,
          'reason':
              'Card draw — deck tem apenas $drawCount fontes (recomendado: 8+)',
        });
      }
    }

    // Falta de Removal
    if (removalCount < 6) {
      final cards = await _findCardsForCategory(
        pool: pool,
        oraclePatterns: ["destroy target%", "exile target%"],
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        limit: (6 - removalCount).clamp(1, 4),
        format: format,
      );
      for (final c in cards) {
        addRecommendations.add({
          'card_name': c,
          'reason': 'Remoção — deck tem apenas $removalCount (recomendado: 6+)',
        });
      }
    }

    // Falta de Board Wipes
    if (boardWipeCount < 2) {
      final cards = await _findCardsForCategory(
        pool: pool,
        oraclePatterns: ["destroy all%creature%", "exile all%"],
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        limit: (3 - boardWipeCount).clamp(1, 2),
        format: format,
      );
      for (final c in cards) {
        addRecommendations.add({
          'card_name': c,
          'reason':
              'Board wipe — deck tem apenas $boardWipeCount (recomendado: 2-3)',
        });
      }
    }

    // Falta de Proteção
    if (protectionCount < 3) {
      final cards = await _findCardsForCategory(
        pool: pool,
        oraclePatterns: ["%hexproof%", "%indestructible%"],
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        limit: (3 - protectionCount).clamp(1, 2),
        format: format,
      );
      for (final c in cards) {
        addRecommendations.add({
          'card_name': c,
          'reason': 'Proteção — deck tem apenas $protectionCount fontes',
        });
      }
    }

    // Falta de terrenos (Commander)
    if (isCommanderFmt && landCount < 34) {
      addRecommendations.add({
        'card_name': 'Command Tower',
        'reason':
            'Terreno essencial — deck tem apenas $landCount terrenos (recomendado: 35-38)',
      });
    }

    // Se o deck está bem, sugerir staples de alto impacto
    if (addRecommendations.isEmpty) {
      final staples = await _findStaples(
        pool: pool,
        colorFilter: colorFilter,
        excludeNames: deckCardNames,
        format: format,
        limit: 3,
      );
      for (final c in staples) {
        addRecommendations.add({
          'card_name': c,
          'reason': 'Staple de alto impacto para $format',
        });
      }
    }

    // ─── Identificar cartas fracas para remover ───────────────
    for (final card in deckCards) {
      if (removeRecommendations.length >= 3) break;
      final tl = (card['type_line'] as String).toLowerCase();
      if (tl.contains('land') || card['is_commander'] == true) continue;
      final cmc = (card['cmc'] as num).toDouble();

      if (archetype == 'aggro' && cmc > 5) {
        removeRecommendations.add({
          'card_name': card['name'] as String,
          'reason':
              'CMC ${cmc.toInt()} é alto para aggro — considere alternativas mais baratas',
        });
      } else if (archetype == 'control' && cmc <= 1 && creatureRatio > 0.3) {
        final oracle = card['oracle_text'] as String;
        if (!oracle.contains('draw') &&
            !oracle.contains('counter') &&
            !oracle.contains('destroy')) {
          removeRecommendations.add({
            'card_name': card['name'] as String,
            'reason':
                'Criatura fraca para control — slot melhor usado com remoção/draw',
          });
        }
      }
    }

    // Terrenos básicos em excesso em deck multicolor
    if (deckColors.length >= 3 && landCount > 38) {
      final basicLands = deckCards.where((c) {
        return basic_lands.isBasicLandCard(
          name: c['name'] as String? ?? '',
          typeLine: c['type_line'] as String? ?? '',
        );
      }).toList();
      if (basicLands.isNotEmpty && removeRecommendations.length < 5) {
        removeRecommendations.add({
          'card_name': basicLands.last['name'] as String,
          'reason':
              'Terreno básico em excesso — trocar por terreno utilitário ou dual',
        });
      }
    }

    // ─── Tendências EDHREC (snapshots) ────────────────────────
    //    Cartas em ALTA (rising) para o(s) commander(s) que ainda não estão
    //    no deck viram recomendações com contexto de tendência.
    final trendingCards = <Map<String, dynamic>>[];
    if (commanderNames.isNotEmpty) {
      final trendService = EdhrecTrendService(pool);
      final seen = <String>{};
      for (final commander in commanderNames) {
        try {
          final trends = await trendService.getCardTrends(commander);
          for (final t in trends) {
            if (t.direction != TrendDirection.rising) continue;
            final lower = t.cardName.toLowerCase();
            if (deckCardNames.contains(lower)) continue;
            if (!seen.add(lower)) continue;
            trendingCards.add({
              ...t.toJson(),
              'commander': commander,
            });
            if (trendingCards.length >= 8) break;
          }
        } catch (e) {
          print('[WARN] EDHREC trends error for "$commander": $e');
        }
        if (trendingCards.length >= 8) break;
      }

      // Promove as 2 maiores altas a recomendações de adição.
      for (final t in trendingCards.take(2)) {
        final name = t['card_name'] as String;
        if (addRecommendations.any((r) => r['card_name'] == name)) continue;
        final pct = ((t['delta_inclusion'] as num) * 100).toStringAsFixed(1);
        addRecommendations.add({
          'card_name': name,
          'reason':
              'Em alta no EDHREC para ${t['commander']} (+$pct% de inclusão recente)',
        });
      }
    }

    // ─── Montar resposta ──────────────────────────────────────
    final analysis = StringBuffer();
    analysis.write('Deck "$deckName" ($format) — Arquétipo: $archetype. ');
    analysis.write('CMC médio: ${avgCMC.toStringAsFixed(1)}. ');
    analysis.write(
        '$totalCards cartas ($landCount terrenos, $creatureCount criaturas). ');
    if (rampCount < 8) analysis.write('⚠️ Ramp insuficiente. ');
    if (drawCount < 8) analysis.write('⚠️ Card draw baixo. ');
    if (removalCount < 5) analysis.write('⚠️ Pouca remoção. ');

    return Response.json(body: {
      'archetype': archetype,
      'power_level': powerLevel,
      'analysis': analysis.toString(),
      'recommendations': {
        'add': addRecommendations.take(5).toList(),
        'remove': removeRecommendations.take(5).toList(),
      },
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
      'colors': deckColors.toList(),
      'trending': trendingCards,
      'source': 'heuristic',
      'message':
          'Análise baseada em heurísticas — configure OPENAI_API_KEY para IA generativa.',
    });
  } catch (e) {
    print('[ERROR] Failed to generate recommendations: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to generate recommendations: $e'},
    );
  }
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

/// Busca cartas reais do banco que preenchem uma categoria funcional
Future<List<String>> _findCardsForCategory({
  required Pool pool,
  required List<String> oraclePatterns,
  required String colorFilter,
  required Set<String> excludeNames,
  required int limit,
  required String format,
}) async {
  try {
    final orClauses = oraclePatterns
        .map((p) => "LOWER(c.oracle_text) LIKE '${p.toLowerCase()}'")
        .join(' OR ');

    final result = await pool.execute(
      Sql('''
        SELECT DISTINCT c.name FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = '${format.toLowerCase()}'
        WHERE ($orClauses)
          AND (c.colors = '{}' OR c.colors && ARRAY[$colorFilter])
          AND (cl.id IS NULL OR cl.status = 'legal')
          AND c.type_line NOT ILIKE '%land%'
        ORDER BY c.name
        LIMIT ${limit + 10}
      '''),
    );

    final candidates = <String>[];
    for (final row in result) {
      final name = row[0] as String;
      if (!excludeNames.contains(name.toLowerCase())) {
        candidates.add(name);
        if (candidates.length >= limit) break;
      }
    }
    return candidates;
  } catch (e) {
    print('[WARN] _findCardsForCategory error: $e');
    return [];
  }
}

/// Busca staples genéricos de alto impacto
Future<List<String>> _findStaples({
  required Pool pool,
  required String colorFilter,
  required Set<String> excludeNames,
  required String format,
  required int limit,
}) async {
  try {
    final result = await pool.execute(
      Sql('''
        SELECT DISTINCT c.name FROM cards c
        LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = '${format.toLowerCase()}'
        WHERE (c.colors = '{}' OR c.colors && ARRAY[$colorFilter])
          AND (cl.id IS NULL OR cl.status = 'legal')
          AND c.rarity IN ('rare', 'mythic')
          AND c.type_line NOT ILIKE '%basic%land%'
        ORDER BY c.name
        LIMIT ${limit + 20}
      '''),
    );

    final candidates = <String>[];
    for (final row in result) {
      final name = row[0] as String;
      if (!excludeNames.contains(name.toLowerCase())) {
        candidates.add(name);
        if (candidates.length >= limit) break;
      }
    }
    return candidates;
  } catch (e) {
    print('[WARN] _findStaples error: $e');
    return [];
  }
}

/// Caminho com OpenAI (quando apiKey está configurada)
Future<Response> _callOpenAI({
  required String apiKey,
  required OpenAiRuntimeConfig aiConfig,
  required String deckName,
  required String format,
  required String description,
  required List<Map<String, dynamic>> deckCards,
}) async {
  final cardList =
      deckCards.map((c) => "${c['quantity']}x ${c['name']}").join(', ');
  final commanders = deckCards
      .where((c) => c['is_commander'] == true)
      .map((c) => (c['name'] as String?) ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
  final colors = <String>{};
  for (final card in deckCards) {
    final cardColors =
        (card['colors'] as List?)?.cast<String>() ?? const <String>[];
    colors.addAll(cardColors);
  }

  final prompt = '''
Você é um juiz nível 3 e deck builder competitivo de Magic: The Gathering.

Contexto do deck:
- Nome: $deckName
- Formato: $format
- Descrição: $description
- Comandante(s): ${commanders.join(', ')}
- Cores detectadas: ${colors.join(', ')}
- Lista atual: $cardList

Objetivo:
Gerar recomendações práticas para melhorar consistência, plano de vitória e interação.

Regras obrigatórias:
1) Identifique o arquétipo predominante do deck.
2) Sugira EXATAMENTE 5 cartas para adicionar e EXATAMENTE 5 para remover.
3) Cada recomendação deve ter motivo curto e acionável (1 frase).
4) Priorize melhorar as categorias mais fracas do deck, seguindo a Regra dos 8s:
   - 10-12 ramp, 10+ draw, 8-10 removal, 3-4 board wipes, 35-38 lands, 2-3 win conditions.
5) Em Commander, respeite ESTRITAMENTE a identidade de cor do(s) comandante(s) (CR 903.4): mana no custo + texto de regras + indicador de cor + MDFC. Mana híbrido = ambas as cores.
6) Não recomende cartas banidas no formato.
7) Não sugira cartas que JÁ ESTÃO no deck (singleton rule em Commander).
8) Priorize instant-speed sobre sorcery-speed para interação.
9) Em Commander multiplayer (40 vida, 3-4 jogadores): "cada oponente" > "jogador alvo"; board wipes são valiosos.
10) power_level deve usar bracket 1-4 (1=casual, 2=mid, 3=high, 4=cEDH).
11) Responda SOMENTE JSON válido, sem markdown.

Formato obrigatório:
{
  "archetype": "string",
  "power_level": 1-4,
  "analysis": "resumo curto e objetivo incluindo pontos fortes, fracos e categoria mais deficiente",
  "recommendations": {
    "add": [
      {"card_name": "string", "reason": "string (inclua a categoria: ramp/draw/removal/synergy/win-con)"}
    ],
    "remove": [
      {"card_name": "string", "reason": "string (explique por que é fraca ou ineficiente)"}
    ]
  }
}
''';

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': aiConfig.modelFor(
        key: 'OPENAI_MODEL_RECOMMENDATIONS',
        fallback: 'gpt-4o-mini',
        devFallback: 'gpt-4o-mini',
        stagingFallback: 'gpt-4o-mini',
        prodFallback: 'gpt-4o-mini',
      ),
      'messages': [
        {
          'role': 'system',
          'content':
              'Você é um juiz nível 3 e especialista em otimização de decks MTG orientado a decisão do jogador. Avalie cada recomendação considerando: legalidade (identidade de cor, ban list, singleton rule), eficiência (mana value, instant vs sorcery), sinergia com comandante, e impacto em multiplayer (40 vida, 3-4 jogadores). Seja técnico, direto e sempre retorne JSON válido.'
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': aiConfig.temperatureFor(
        key: 'OPENAI_TEMP_RECOMMENDATIONS',
        fallback: 0.3,
        devFallback: 0.35,
        stagingFallback: 0.3,
        prodFallback: 0.25,
      ),
      'response_format': {'type': 'json_object'},
    }),
  );

  if (response.statusCode != 200) {
    return Response.json(
      statusCode: response.statusCode,
      body: {'error': 'OpenAI API Error: ${response.body}'},
    );
  }

  final aiData = jsonDecode(utf8.decode(response.bodyBytes));
  final content = aiData['choices'][0]['message']['content'];

  try {
    final recommendations = jsonDecode(content);
    return Response.json(body: recommendations);
  } catch (e) {
    print('[ERROR] Failed to parse OpenAI recommendations: $e');
    return Response.json(body: {'raw_response': content});
  }
}
