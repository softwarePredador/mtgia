import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/ai/commander_deckbuilding_contract_support.dart';
import '../../../../lib/ai/deck_battle_learning_evidence.dart';
import '../../../../lib/ai/functional_card_tags.dart';
import '../../../../lib/meta/meta_deck_card_list_support.dart';
import '../../../../lib/meta/meta_deck_format_support.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method == HttpMethod.get) {
    return _analyzeDeck(context, deckId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _analyzeDeck(RequestContext context, String deckId) async {
  final pool = context.read<Pool>();
  final userId = context.read<String>();

  try {
    // 1. Buscar informações do deck (formato)
    final deckResult = await pool.execute(
      Sql.named(
          'SELECT format FROM decks WHERE id = @deckId AND user_id = @userId'),
      parameters: {'deckId': deckId, 'userId': userId},
    );

    if (deckResult.isEmpty) {
      return Response.json(
          statusCode: HttpStatus.notFound, body: {'error': 'Deck not found'});
    }

    final format = deckResult.first[0] as String;
    final hasCardIntelligenceSnapshot =
        await _hasTable(pool, 'card_intelligence_snapshot');
    final hasSemanticV2 = await _hasTable(pool, 'card_semantic_tags_v2');
    final cardSourceJoin = hasCardIntelligenceSnapshot
        ? 'JOIN card_intelligence_snapshot c ON dc.card_id = c.card_id'
        : 'JOIN cards c ON dc.card_id = c.id';
    final priceSelect =
        hasCardIntelligenceSnapshot ? 'c.price_usd AS price' : 'c.price';
    final battleRuleCountSelect = hasCardIntelligenceSnapshot
        ? 'c.battle_rule_count AS battle_rule_count'
        : '0::int AS battle_rule_count';
    final verifiedBattleRuleCountSelect = hasCardIntelligenceSnapshot
        ? 'c.verified_battle_rule_count AS verified_battle_rule_count'
        : '0::int AS verified_battle_rule_count';
    final sourceCoverageSelect = hasCardIntelligenceSnapshot
        ? 'c.source_coverage AS source_coverage'
        : '''jsonb_build_object(
            'has_function_tags', false,
            'has_semantic_v2', false,
            'has_verified_battle_rules', false,
            'has_any_battle_rules', false,
            'has_legalities', false
          ) AS source_coverage''';
    final functionalTagsSelect = hasCardIntelligenceSnapshot
        ? 'c.function_tag_details AS functional_tags'
        : '''
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
          ) AS functional_tags
        ''';
    final semanticV2Select = hasCardIntelligenceSnapshot
        ? 'c.semantic_tags_v2 AS semantic_tags_v2'
        : hasSemanticV2
            ? '''
          COALESCE(
            (
              SELECT jsonb_agg(
                jsonb_build_object(
                  'schema_version', cstv2.schema_version,
                  'source', cstv2.source,
                  'speed', cstv2.speed,
                  'mana_efficiency', cstv2.mana_efficiency,
                  'card_advantage_type', cstv2.card_advantage_type,
                  'interaction_scope', cstv2.interaction_scope,
                  'combo_piece', cstv2.combo_piece,
                  'wincon', cstv2.wincon,
                  'engine', cstv2.engine,
                  'payoff', cstv2.payoff,
                  'enabler', cstv2.enabler,
                  'protection_type', cstv2.protection_type,
                  'recursion_type', cstv2.recursion_type,
                  'role_confidence', cstv2.role_confidence,
                  'explanation_reason', cstv2.explanation_reason,
                  'tags', cstv2.tags
                )
                ORDER BY cstv2.role_confidence DESC, cstv2.source
              )
              FROM card_semantic_tags_v2 cstv2
              WHERE cstv2.card_id = c.id
            ),
            '[]'::jsonb
          ) AS semantic_tags_v2
        '''
            : ''''[]'::jsonb AS semantic_tags_v2''';

    // 2. Buscar cartas do deck
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT
          c.id,
          c.name,
          c.mana_cost,
          c.type_line,
          c.oracle_text,
          $priceSelect,
          dc.quantity,
          dc.is_commander,
          c.cmc,
          $functionalTagsSelect,
          $semanticV2Select,
          $battleRuleCountSelect,
          $verifiedBattleRuleCountSelect,
          $sourceCoverageSelect
        FROM deck_cards dc
        $cardSourceJoin
        WHERE dc.deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );

    final cards = cardsResult.map((row) => row.toColumnMap()).toList();
    final battleLearningEvidence = await loadDeckBattleLearningEvidence(
      pool: pool,
      deckId: deckId,
    );

    // 3. Análise: Curva de Mana, Cores e Preço
    final manaCurve = <int, int>{};
    final colorDistribution = <String, int>{
      'W': 0,
      'U': 0,
      'B': 0,
      'R': 0,
      'G': 0,
      'C': 0
    };
    var totalCards = 0;
    var totalLands = 0;
    double totalPrice = 0.0;

    for (final card in cards) {
      final quantity = card['quantity'] as int;
      final typeLine = card['type_line'] as String? ?? '';
      final manaCost = card['mana_cost'] as String? ?? '';
      final price = double.tryParse(card['price']?.toString() ?? '0') ?? 0.0;

      totalPrice += price * quantity;
      totalCards += quantity;

      if (typeLine.toLowerCase().contains('land')) {
        totalLands += quantity;
        continue; // Terrenos geralmente não têm custo de mana (exceto alguns especiais)
      }

      // Calcular CMC e Cores
      final analysis = _parseManaCost(manaCost);

      // Atualiza Curva de Mana
      final cmc = analysis.cmc;
      manaCurve[cmc] = (manaCurve[cmc] ?? 0) + quantity;

      // Atualiza Distribuição de Cores
      analysis.colors.forEach((color, count) {
        if (colorDistribution.containsKey(color)) {
          colorDistribution[color] =
              (colorDistribution[color] ?? 0) + (count * quantity);
        }
      });
    }

    // 4. Análise: Legalidade (Otimizada)
    final issues = <Map<String, dynamic>>[];

    // 4.1. Regras de Construção (Quantidade e Cópias)
    final isCommander = format.toLowerCase() == 'commander';
    final minCards = isCommander ? 100 : 60;
    final maxCopies = isCommander ? 1 : 4;

    if (totalCards < minCards) {
      issues.add({
        'type': 'error',
        'message': 'Deck has $totalCards cards. Minimum required is $minCards.',
      });
    }

    if (isCommander && totalCards > 100) {
      issues.add({
        'type': 'error',
        'message':
            'Commander decks must have exactly 100 cards (currently $totalCards).',
      });
    }

    // Checagem de cópias (exceto terrenos básicos e cartas que permitem múltiplas cópias ex: Relentless Rats)
    // Simplificação: assumimos que apenas terrenos básicos podem ter > maxCopies
    final basicLands = [
      'Plains',
      'Island',
      'Swamp',
      'Mountain',
      'Forest',
      'Wastes',
      'Snow-Covered Plains',
      'Snow-Covered Island',
      'Snow-Covered Swamp',
      'Snow-Covered Mountain',
      'Snow-Covered Forest'
    ];

    for (final card in cards) {
      final name = card['name'] as String;
      final quantity = card['quantity'] as int;

      // Verifica se é terreno básico (pode ter qualquer quantidade)
      // Uma verificação mais robusta seria checar o supertype "Basic" no banco, mas pelo nome resolve 99%
      final isBasic = basicLands.any((b) => name.contains(b));

      if (!isBasic && quantity > maxCopies) {
        issues.add({
          'type': 'error',
          'message': 'Card "$name" has $quantity copies. Limit is $maxCopies.',
        });
      }
    }

    // 4.2. Checagem de Banidas (Batch Query)
    final cardIds = cards.map((c) => c['id'] as String).toList();

    if (cardIds.isNotEmpty) {
      // Busca o status de legalidade de todas as cartas do deck para o formato
      final legalityResult = await pool.execute(
        Sql.named(
          'SELECT card_id, status FROM card_legalities WHERE format = @format AND card_id = ANY(@ids)',
        ),
        parameters: {
          'format': format.toLowerCase(),
          'ids': TypedValue(Type.uuidArray, cardIds),
        },
      );

      final legalityMap = <String, String>{};
      for (final row in legalityResult) {
        legalityMap[row[0] as String] = row[1] as String;
      }

      for (final card in cards) {
        final id = card['id'] as String;
        final name = card['name'] as String;

        // Se não tiver registro na tabela de legalidade, assumimos que é legal (ou que falta dado)
        // Mas se tiver e for 'banned', reportamos.
        if (legalityMap.containsKey(id)) {
          final status = legalityMap[id]!;
          if (status == 'banned') {
            issues.add({
              'type': 'error',
              'message': '"$name" is BANNED in $format.',
            });
          } else if (status == 'restricted' && (card['quantity'] as int) > 1) {
            issues.add({
              'type': 'error',
              'message': '"$name" is RESTRICTED in $format (max 1 copy).',
            });
          }
        }
      }
    }

    // 4.3. Análise de Consistência (Land Count & Colors)
    // Baseado em heurísticas de Frank Karsten

    // Calcular CMC Médio (apenas cartas não-terreno)
    var totalCmc = 0;
    var nonLandCards = totalCards - totalLands;

    manaCurve.forEach((cmc, count) {
      totalCmc += cmc * count;
    });

    final avgCmc = nonLandCards > 0 ? totalCmc / nonLandCards : 0.0;

    // Recomendação de Terrenos
    // Fórmula simplificada: 31 + (AvgCMC * 2.5) para Commander (aprox)
    // Ex: Avg 2.0 -> 36 lands. Avg 3.0 -> 38.5 lands. Avg 4.0 -> 41 lands.
    if (isCommander) {
      final recommendedLands = (31 + (avgCmc * 2.5)).round();
      final diff = totalLands - recommendedLands;

      if (diff.abs() > 3) {
        issues.add({
          'type': 'warning',
          'message': 'Land Count Warning: Your deck has an Average CMC of ${avgCmc.toStringAsFixed(2)}. '
              'We recommend around $recommendedLands lands, but you have $totalLands. '
              '${diff < 0 ? "Consider adding more lands to avoid missing drops." : "Consider removing lands to avoid flooding."}',
        });
      }
    }

    // 4.4. Análise de Composição (Ramp, Draw, Removal, Wipes)
    final functionalSummary = summarizeFunctionalTagsForDeck(cards);
    final rampCount = functionalSummary.count('ramp');
    final drawCount = functionalSummary.count('draw');
    final removalCount = functionalSummary.count('removal');
    final boardWipeCount = functionalSummary.count('board_wipe');
    final protectionCount = functionalSummary.count('protection');

    // Recomendações de Composição (Commander)
    if (isCommander) {
      if (rampCount < 10) {
        issues.add({
          'type': 'warning',
          'message':
              'Ramp Warning: You have $rampCount ramp sources. We recommend at least 10 to ensure you have mana.',
        });
      }
      if (drawCount < 10) {
        issues.add({
          'type': 'warning',
          'message':
              'Card Draw Warning: You have $drawCount card draw sources. We recommend at least 10 to keep your hand full.',
        });
      }
      if (removalCount < 8) {
        // Um pouco menos exigente que 10
        issues.add({
          'type': 'warning',
          'message':
              'Removal Warning: You have $removalCount single target removal spells. We recommend at least 8 to deal with threats.',
        });
      }
      if (boardWipeCount < 2) {
        issues.add({
          'type': 'warning',
          'message':
              'Board Wipe Warning: You have $boardWipeCount board wipes. We recommend at least 2-3 to reset the game when losing.',
        });
      }
    }

    // 4.5. Comparação com o Meta (Meta Insights)
    // Busca decks similares no banco de dados de Meta para sugerir melhorias
    Map<String, dynamic>? metaAnalysis;

    try {
      final metaFormats = metaDeckFormatCodesForDeckFormat(format);
      final metaScope =
          format.toLowerCase() == 'commander' ? 'commander' : null;
      final metaDecksResult = metaFormats.isEmpty
          ? const <dynamic>[]
          : await pool.execute(
              Sql.named('''
                SELECT format, archetype, card_list, source_url
                FROM meta_decks
                WHERE format = ANY(@formats)
                ORDER BY created_at DESC
                LIMIT 50
              '''),
              parameters: {
                'formats': TypedValue(Type.textArray, metaFormats),
              },
            );

      if (metaDecksResult.isNotEmpty) {
        var bestMatchArchetype = '';
        var bestMatchScore = 0.0;
        var bestMatchMissingCards = <String>[];
        String? bestMatchFormatCode;
        String? bestMatchSubformat;
        String? bestMatchFormatLabel;

        // Cria um Set com os nomes das cartas do usuário para comparação rápida
        final userCardNames =
            cards.map((c) => (c['name'] as String).toLowerCase()).toSet();

        for (final row in metaDecksResult) {
          final storedFormat = (row[0] as String?) ?? '';
          final archetype = row[1] as String;
          final cardListRaw = row[2] as String;
          final formatDescriptor = describeMetaDeckFormat(storedFormat);

          final parsedDeck = parseMetaDeckCardList(
            cardList: cardListRaw,
            format: storedFormat,
          );
          final metaCards = parsedDeck.mainboard.keys
              .map((name) => name.toLowerCase())
              .toSet();

          // Calcula similaridade (Jaccard Index simplificado: Interseção / União)
          final intersection = userCardNames.intersection(metaCards).length;
          final union = userCardNames.union(metaCards).length;
          final score = union > 0 ? intersection / union : 0.0;

          if (score > bestMatchScore) {
            bestMatchScore = score;
            bestMatchArchetype = archetype;
            bestMatchFormatCode = formatDescriptor.storedFormatCode;
            bestMatchSubformat = formatDescriptor.commanderSubformat;
            bestMatchFormatLabel = formatDescriptor.label;
            // Identifica cartas que o meta tem e o usuário não (Staples potenciais)
            bestMatchMissingCards = metaCards
                .difference(userCardNames)
                .take(5)
                .toList(); // Sugere top 5
          }
        }

        // Se encontrou alguma similaridade relevante (> 10% para começar)
        if (bestMatchScore > 0.10) {
          metaAnalysis = {
            'archetype': bestMatchArchetype,
            'similarity':
                double.parse((bestMatchScore * 100).toStringAsFixed(1)),
            'format_code': bestMatchFormatCode,
            'format_label': bestMatchFormatLabel,
            'subformat': bestMatchSubformat,
            if (metaScope != null)
              'meta_scope': {
                'requested': metaScope,
                'label': commanderMetaScopeLabel(metaScope),
                'format_codes': metaFormats,
              },
            'suggested_adds': bestMatchMissingCards,
            'message':
                'Your deck is ${(bestMatchScore * 100).toStringAsFixed(0)}% similar to "$bestMatchArchetype". Consider adding these cards used in the meta.',
          };
        }
      }
    } catch (e) {
      print('[ERROR] handler: $e');
      print('Erro na análise de meta: $e');
      // Não falha a requisição inteira se o meta falhar
    }

    return Response.json(body: {
      'deck_id': deckId,
      'format': format,
      'stats': {
        'total_cards': totalCards,
        'total_lands': totalLands,
        'total_price': double.parse(totalPrice.toStringAsFixed(2)),
        'avg_cmc': double.parse(avgCmc.toStringAsFixed(2)),
        'composition': {
          'ramp': rampCount,
          'draw': drawCount,
          'removal': removalCount,
          'board_wipes': boardWipeCount,
          'protection': protectionCount,
        }
      },
      'functional_tags': functionalSummary.toJson(),
      'readiness': _buildDeckReadinessSummary(
        format: format,
        totalCards: totalCards,
        cards: cards,
        issues: issues,
      ),
      'battle_readiness': _buildBattleReadinessSummary(cards),
      'battle_learning_evidence': battleLearningEvidence,
      'card_battle_readiness': _buildCardBattleReadiness(cards),
      'understanding_summary': _buildUnderstandingSummary(
        cards: cards,
        functionalSummary: functionalSummary,
        hasCardIntelligenceSnapshot: hasCardIntelligenceSnapshot,
      ),
      'commander_contract': _buildCommanderContractSummary(
        format: format,
        totalCards: totalCards,
        cards: cards,
        issues: issues,
        battleLearningEvidence: battleLearningEvidence,
      ),
      'launch_capabilities': _buildLaunchCapabilities(
        format: format,
        hasCardIntelligenceSnapshot: hasCardIntelligenceSnapshot,
        hasSemanticV2: hasSemanticV2,
      ),
      'meta_analysis': metaAnalysis,
      'mana_curve':
          manaCurve.map((key, value) => MapEntry(key.toString(), value)),
      'color_distribution': colorDistribution,
      'legality': {
        'is_valid': issues.where((i) => i['type'] == 'error').isEmpty,
        'issues': issues,
      }
    });
  } catch (e) {
    print('[ERROR] Failed to analyze deck: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to analyze deck'},
    );
  }
}

Map<String, dynamic> _buildLaunchCapabilities({
  required String format,
  required bool hasCardIntelligenceSnapshot,
  required bool hasSemanticV2,
}) {
  final normalizedFormat = format.toLowerCase().trim();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';
  final betaSurfacesEnabled = _envFlag('MANALOOM_BETA_SURFACES', true);

  return {
    'schema_version': 'launch_capabilities_v1_2026-07-01',
    'release_channel': betaSurfacesEnabled ? 'beta' : 'stable_only',
    'flags': {
      'beta_surfaces_enabled': betaSurfacesEnabled,
      'card_intelligence_snapshot': hasCardIntelligenceSnapshot,
      'semantic_v2_available': hasSemanticV2 || hasCardIntelligenceSnapshot,
    },
    'surfaces': [
      {
        'key': 'deck_analysis',
        'label': 'Análise de deck',
        'enabled': true,
        'stage': 'stable',
        'requires_review': false,
      },
      {
        'key': 'commander_contract',
        'label': 'Plano Commander',
        'enabled': betaSurfacesEnabled && isCommander,
        'stage': 'beta',
        'requires_review': true,
      },
      {
        'key': 'battle_readiness',
        'label': 'Battle readiness',
        'enabled': betaSurfacesEnabled && hasCardIntelligenceSnapshot,
        'stage': 'beta',
        'requires_review': true,
      },
      {
        'key': 'optimize_explanations',
        'label': 'Explicações de optimize',
        'enabled': betaSurfacesEnabled,
        'stage': 'beta',
        'requires_review': true,
      },
      {
        'key': 'recommendations',
        'label': 'Recomendações',
        'enabled': true,
        'stage': 'advisory',
        'requires_review': true,
      },
    ],
    'disclaimer':
        'Superficies beta e advisory exigem preview/review; nao sao verdade final do deck.',
  };
}

Map<String, dynamic> _buildCommanderContractSummary({
  required String format,
  required int totalCards,
  required List<Map<String, dynamic>> cards,
  required List<Map<String, dynamic>> issues,
  required Map<String, dynamic> battleLearningEvidence,
}) {
  final normalizedFormat = format.toLowerCase().trim();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';

  if (!isCommander) {
    final diagnostics = buildCommanderDeckbuildingContractDiagnostics(
      format: format,
      generatedDeck: const {
        'commander': '',
        'cards': <Map<String, dynamic>>[],
      },
      validationSummary: const {
        'is_valid': true,
        'invalid_cards': <String>[],
        'errors': <String>[],
        'warnings': <String>[],
      },
      battleGateRequired: false,
    );
    return buildCommanderDeckbuildingAppSummary(
      diagnostics,
      totalCards: totalCards,
      commanderCount: 0,
    );
  }

  final commanderCards =
      cards.where((card) => card['is_commander'] == true).toList();
  final commanderCount = commanderCards.fold<int>(
    0,
    (sum, card) => sum + _quantity(card),
  );
  final commanderName = commanderCards.isEmpty
      ? ''
      : commanderCards.first['name']?.toString().trim() ?? '';
  final errors = issues
      .where((issue) => issue['type']?.toString() == 'error')
      .map((issue) => issue['message']?.toString().trim() ?? '')
      .where((message) => message.isNotEmpty)
      .toList();
  final warnings = issues
      .where((issue) => issue['type']?.toString() == 'warning')
      .map((issue) => issue['message']?.toString().trim() ?? '')
      .where((message) => message.isNotEmpty)
      .toList();

  if (commanderCount <= 0) errors.add('Commander missing.');
  if (totalCards != 100) {
    errors.add('Commander decks must have exactly 100 cards.');
  }

  final generatedCards = cards
      .where((card) => card['is_commander'] != true)
      .map(
        (card) => {
          'name': card['name']?.toString() ?? '',
          'quantity': _quantity(card),
        },
      )
      .where((card) => card['name']?.toString().trim().isNotEmpty == true)
      .toList(growable: false);

  final diagnostics = buildCommanderDeckbuildingContractDiagnostics(
    format: format,
    generatedDeck: {
      'commander': {'name': commanderName},
      'cards': generatedCards,
    },
    validationSummary: {
      'is_valid': errors.isEmpty,
      'invalid_cards': const <String>[],
      'errors': errors,
      'warnings': warnings,
    },
    battleGateRequired: true,
    battleLearningEvidence: battleLearningEvidence,
  );

  return buildCommanderDeckbuildingAppSummary(
    diagnostics,
    totalCards: totalCards,
    commanderCount: commanderCount,
  );
}

Map<String, dynamic> _buildDeckReadinessSummary({
  required String format,
  required int totalCards,
  required List<Map<String, dynamic>> cards,
  required List<Map<String, dynamic>> issues,
}) {
  final normalizedFormat = format.toLowerCase().trim();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';
  final commanderCount = cards.fold<int>(
    0,
    (sum, card) => sum + (card['is_commander'] == true ? _quantity(card) : 0),
  );
  final errorCount =
      issues.where((issue) => issue['type']?.toString() == 'error').length;
  final warningCount =
      issues.where((issue) => issue['type']?.toString() == 'warning').length;
  final blockers = <String>[];
  final nextActions = <String>[];

  if (isCommander) {
    if (commanderCount <= 0) {
      blockers.add('needs_commander');
      nextActions.add('Definir o comandante antes de avaliar o plano.');
    }
    if (totalCards < 100) {
      blockers.add('incomplete_deck');
      nextActions.add('Completar a lista ate 100 cartas.');
    } else if (totalCards > 100) {
      blockers.add('too_many_cards');
      nextActions.add('Reduzir a lista para exatamente 100 cartas.');
    }
  } else if (totalCards < 60) {
    blockers.add('incomplete_deck');
    nextActions
        .add('Completar a lista antes de aplicar diagnosticos avancados.');
  }

  if (errorCount > 0) {
    blockers.add('legality_or_structure_errors');
    nextActions.add('Corrigir erros de legalidade e estrutura.');
  }

  final status = blockers.isNotEmpty
      ? blockers.first
      : warningCount > 0
          ? 'ready_with_warnings'
          : isCommander
              ? 'valid_commander_deck'
              : 'valid_deck';

  return {
    'schema_version': 'deck_readiness_v1_2026-07-01',
    'status': status,
    'is_commander': isCommander,
    'commander_count': commanderCount,
    'total_cards': totalCards,
    'error_count': errorCount,
    'warning_count': warningCount,
    'blockers': blockers.toSet().toList(growable: false),
    'next_actions': nextActions.toSet().toList(growable: false),
    'advanced_intelligence_enabled': blockers.isEmpty,
  };
}

List<Map<String, dynamic>> _buildCardBattleReadiness(
  List<Map<String, dynamic>> cards,
) {
  final readiness = cards.map((card) {
    final name = card['name']?.toString() ?? '';
    final quantity = _quantity(card);
    final battleRuleCount = _intValue(card['battle_rule_count']);
    final verifiedBattleRuleCount =
        _intValue(card['verified_battle_rule_count']);
    final status = _cardBattleReadinessStatus(card);
    final sourceCoverage = card['source_coverage'] is Map
        ? (card['source_coverage'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return {
      'schema_version': 'card_battle_readiness_v1_2026-07-01',
      'card_id': card['id']?.toString() ?? '',
      'name': name,
      'quantity': quantity,
      'is_commander': card['is_commander'] == true,
      'status': status,
      'status_label': _cardBattleReadinessLabel(status),
      'battle_rule_count': battleRuleCount,
      'verified_battle_rule_count': verifiedBattleRuleCount,
      'source_coverage': sourceCoverage,
      'detail': _cardBattleReadinessDetail(
        status: status,
        verifiedBattleRuleCount: verifiedBattleRuleCount,
        battleRuleCount: battleRuleCount,
      ),
      'disclaimer':
          'Badge conservador: indica cobertura de regra/battle no backend, nao garantia de simulacao perfeita.',
    };
  }).toList(growable: false);

  final sorted = [...readiness];
  sorted.sort((a, b) {
    final commanderCompare = (b['is_commander'] == true ? 1 : 0) -
        (a['is_commander'] == true ? 1 : 0);
    if (commanderCompare != 0) return commanderCompare;
    return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
  });
  return sorted;
}

Map<String, dynamic> _buildBattleReadinessSummary(
  List<Map<String, dynamic>> cards,
) {
  var totalCopies = 0;
  var verifiedCopies = 0;
  var partialCopies = 0;
  var pendingAdapterCopies = 0;
  var rulesTextOnlyCopies = 0;
  final samples = <String, List<String>>{
    'verified_simulation': <String>[],
    'partial_simulation': <String>[],
    'pending_adapter': <String>[],
    'rules_text_only': <String>[],
  };

  void addSample(String key, String name) {
    final bucket = samples[key];
    if (bucket == null || bucket.length >= 5 || name.trim().isEmpty) return;
    if (!bucket.contains(name)) bucket.add(name);
  }

  for (final card in cards) {
    final quantity = _quantity(card);
    final name = card['name']?.toString() ?? '';
    final oracleText = card['oracle_text']?.toString().trim() ?? '';
    final battleRuleCount = _intValue(card['battle_rule_count']);
    final verifiedBattleRuleCount =
        _intValue(card['verified_battle_rule_count']);
    totalCopies += quantity;

    if (verifiedBattleRuleCount > 0) {
      verifiedCopies += quantity;
      addSample('verified_simulation', name);
    } else if (battleRuleCount > 0) {
      partialCopies += quantity;
      addSample('partial_simulation', name);
    } else if (oracleText.isNotEmpty) {
      pendingAdapterCopies += quantity;
      addSample('pending_adapter', name);
    } else {
      rulesTextOnlyCopies += quantity;
      addSample('rules_text_only', name);
    }
  }

  final verifiedRatio = totalCopies == 0 ? 0.0 : verifiedCopies / totalCopies;
  final status = totalCopies == 0
      ? 'not_available'
      : verifiedCopies == totalCopies
          ? 'verified_simulation'
          : verifiedCopies > 0 || partialCopies > 0
              ? 'partial_simulation'
              : pendingAdapterCopies > 0
                  ? 'pending_adapter'
                  : 'rules_text_only';

  return {
    'schema_version': 'deck_battle_readiness_v1_2026-07-01',
    'status': status,
    'total_copies': totalCopies,
    'verified_simulation_copies': verifiedCopies,
    'partial_simulation_copies': partialCopies,
    'pending_adapter_copies': pendingAdapterCopies,
    'rules_text_only_copies': rulesTextOnlyCopies,
    'verified_ratio': double.parse(verifiedRatio.toStringAsFixed(4)),
    'samples': samples,
    'disclaimer':
        'Battle readiness indica suporte verificado do runtime quando existe; nao significa simulacao perfeita de todas as cartas.',
  };
}

String _cardBattleReadinessStatus(Map<String, dynamic> card) {
  final oracleText = card['oracle_text']?.toString().trim() ?? '';
  final battleRuleCount = _intValue(card['battle_rule_count']);
  final verifiedBattleRuleCount = _intValue(card['verified_battle_rule_count']);

  if (verifiedBattleRuleCount > 0) return 'verified_simulation';
  if (battleRuleCount > 0) return 'partial_simulation';
  if (oracleText.isNotEmpty) return 'pending_adapter';
  return 'rules_text_only';
}

String _cardBattleReadinessLabel(String status) {
  switch (status) {
    case 'verified_simulation':
      return 'Simulação verificada';
    case 'partial_simulation':
      return 'Simulação parcial';
    case 'pending_adapter':
      return 'Adaptador pendente';
    case 'rules_text_only':
      return 'Texto de regra';
    default:
      return 'Sem leitura';
  }
}

String _cardBattleReadinessDetail({
  required String status,
  required int verifiedBattleRuleCount,
  required int battleRuleCount,
}) {
  switch (status) {
    case 'verified_simulation':
      return '$verifiedBattleRuleCount regra(s) verificadas para battle.';
    case 'partial_simulation':
      return '$battleRuleCount regra(s) mapeadas, ainda sem verificação completa.';
    case 'pending_adapter':
      return 'Texto Oracle presente, mas sem adaptador battle verificado.';
    case 'rules_text_only':
      return 'Sem texto Oracle ou regra battle suficiente para simulação.';
    default:
      return 'Sem leitura de battle para esta carta.';
  }
}

Map<String, dynamic> _buildUnderstandingSummary({
  required List<Map<String, dynamic>> cards,
  required FunctionalDeckSummary functionalSummary,
  required bool hasCardIntelligenceSnapshot,
}) {
  final totalCopies = cards.fold<int>(
    0,
    (sum, card) => sum + _quantity(card),
  );
  final taggedCopies = functionalSummary.taggedCopies;
  var semanticCopies = 0;
  var verifiedRuleCopies = 0;

  for (final card in cards) {
    final quantity = _quantity(card);
    final semanticTags = card['semantic_tags_v2'];
    final hasSemantic = semanticTags is Iterable
        ? semanticTags.isNotEmpty
        : semanticTags?.toString().trim().isNotEmpty == true &&
            semanticTags.toString() != '[]';
    if (hasSemantic) semanticCopies += quantity;
    if (_intValue(card['verified_battle_rule_count']) > 0) {
      verifiedRuleCopies += quantity;
    }
  }

  return {
    'schema_version': 'deck_understanding_summary_v1_2026-07-01',
    'source': hasCardIntelligenceSnapshot
        ? 'card_intelligence_snapshot'
        : 'legacy_aggregated_queries',
    'total_copies': totalCopies,
    'functional_tagged_copies': taggedCopies,
    'semantic_tagged_copies': semanticCopies,
    'verified_battle_rule_copies': verifiedRuleCopies,
    'functional_coverage_ratio': totalCopies == 0
        ? 0.0
        : double.parse((taggedCopies / totalCopies).toStringAsFixed(4)),
    'verified_battle_ratio': totalCopies == 0
        ? 0.0
        : double.parse((verifiedRuleCopies / totalCopies).toStringAsFixed(4)),
  };
}

int _quantity(Map<String, dynamic> card) {
  final raw = card['quantity'];
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  return int.tryParse(raw?.toString() ?? '') ?? 1;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _envFlag(String key, bool defaultValue) {
  final value = Platform.environment[key]?.trim().toLowerCase();
  if (value == null || value.isEmpty) return defaultValue;
  if (value == '0' || value == 'false' || value == 'no') return false;
  if (value == '1' || value == 'true' || value == 'yes') return true;
  return defaultValue;
}

class ManaAnalysis {
  final int cmc;
  final Map<String, int> colors;
  ManaAnalysis(this.cmc, this.colors);
}

ManaAnalysis _parseManaCost(String manaCost) {
  int cmc = 0;
  final colors = <String, int>{};

  // Regex para capturar símbolos como {2}, {U}, {B/G}, {2/W}, {B/P}, etc.
  final regex = RegExp(r'\{([^}]+)\}');
  final matches = regex.allMatches(manaCost);

  for (final match in matches) {
    final symbol = match.group(1) ?? '';

    // Se for número (ex: {2})
    final number = int.tryParse(symbol);
    if (number != null) {
      cmc += number;
    } else if (symbol == 'X') {
      // X conta como 0 para CMC na pilha/deck
      continue;
    } else if (symbol.contains('/')) {
      // Símbolo híbrido: {2/W}, {B/G}, {W/P}, {B/P}, etc.
      final parts = symbol.split('/');

      // Para híbridos com número (ex: {2/W}), o CMC é o maior valor
      // Para híbridos de cor (ex: {B/G}) ou Phyrexian (ex: {B/P}), o CMC é 1
      // P (Phyrexian) não é número, então não afeta o cálculo
      int hybridCmc = 1;
      for (final part in parts) {
        // Ignora 'P' (Phyrexian) ao calcular CMC numérico
        if (part == 'P') continue;
        final partNumber = int.tryParse(part);
        if (partNumber != null && partNumber > hybridCmc) {
          hybridCmc = partNumber;
        }
      }
      cmc += hybridCmc;

      // Conta as cores (ignorando números e 'P' para Phyrexian)
      if (symbol.contains('W')) colors['W'] = (colors['W'] ?? 0) + 1;
      if (symbol.contains('U')) colors['U'] = (colors['U'] ?? 0) + 1;
      if (symbol.contains('B')) colors['B'] = (colors['B'] ?? 0) + 1;
      if (symbol.contains('R')) colors['R'] = (colors['R'] ?? 0) + 1;
      if (symbol.contains('G')) colors['G'] = (colors['G'] ?? 0) + 1;
      if (symbol.contains('C')) colors['C'] = (colors['C'] ?? 0) + 1;
    } else {
      // Símbolo de cor simples: {U}, {B}, {R}, {G}, {W}, {C}
      cmc += 1;

      if (symbol.contains('W')) colors['W'] = (colors['W'] ?? 0) + 1;
      if (symbol.contains('U')) colors['U'] = (colors['U'] ?? 0) + 1;
      if (symbol.contains('B')) colors['B'] = (colors['B'] ?? 0) + 1;
      if (symbol.contains('R')) colors['R'] = (colors['R'] ?? 0) + 1;
      if (symbol.contains('G')) colors['G'] = (colors['G'] ?? 0) + 1;
      if (symbol.contains('C')) colors['C'] = (colors['C'] ?? 0) + 1;
    }
  }

  return ManaAnalysis(cmc, colors);
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  final result = await pool.execute(
    Sql.named("SELECT to_regclass(@table_name) IS NOT NULL"),
    parameters: {'table_name': tableName},
  );
  return result.isNotEmpty && result.first[0] == true;
}
