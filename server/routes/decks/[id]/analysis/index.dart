import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

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
    final hasSemanticV2 = await _hasTable(pool, 'card_semantic_tags_v2');
    final semanticV2Select = hasSemanticV2
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
          )
        '''
        : ''''[]'::jsonb''';

    // 2. Buscar cartas do deck
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT
          c.id,
          c.name,
          c.mana_cost,
          c.type_line,
          c.oracle_text,
          c.price,
          dc.quantity,
          c.cmc,
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
          ) AS functional_tags,
          $semanticV2Select AS semantic_tags_v2
        FROM deck_cards dc
        JOIN cards c ON dc.card_id = c.id
        WHERE dc.deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );

    final cards = cardsResult.map((row) => row.toColumnMap()).toList();

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
