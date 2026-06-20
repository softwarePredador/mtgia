import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/archetype_counters_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/ai/optimization_functional_roles.dart';
import '../../../lib/meta/meta_deck_card_list_support.dart';

/// Endpoint para simular matchup entre dois decks
///
/// POST /ai/simulate-matchup
/// Body: {
///   "my_deck_id": "uuid",
///   "opponent_deck_id": "uuid",  // Pode ser de meta_decks ou decks
///   "simulations": 100           // Opcional, default 50
/// }
///
/// Retorna análise de matchup com win rate estimado e recomendações
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final myDeckId = body['my_deck_id'] as String?;
    final opponentDeckId = body['opponent_deck_id'] as String?;
    final simulationCount = _normalizedSimulationCount(body['simulations']);
    final simulationSeed = body['seed'] is int ? body['seed'] as int : null;
    final userId = context.read<String>();

    if (myDeckId == null || opponentDeckId == null) {
      return badRequest('my_deck_id and opponent_deck_id are required');
    }

    final pool = context.read<Pool>();
    final countersService = ArchetypeCountersService(pool);

    // 1. Buscar dados de ambos os decks
    final myDeckData = await _getDeckData(
      pool,
      myDeckId,
      userId: userId,
    );
    final opponentDeckData = await _getDeckData(
      pool,
      opponentDeckId,
      userId: userId,
      allowPublicDeck: true,
    );

    if (myDeckData == null) {
      return notFound('Your deck not found');
    }

    if (opponentDeckData == null) {
      // Tentar buscar de meta_decks
      final metaDeckData = await _getMetaDeckData(pool, opponentDeckId);
      if (metaDeckData == null) {
        return notFound('Opponent deck not found');
      }
      // Usar meta deck
      return _analyzeMatchup(
        pool: pool,
        countersService: countersService,
        myDeck: myDeckData,
        opponentDeck: metaDeckData,
        simulationCount: simulationCount,
        simulationSeed: simulationSeed,
        isMetaDeck: true,
      );
    }

    return _analyzeMatchup(
      pool: pool,
      countersService: countersService,
      myDeck: myDeckData,
      opponentDeck: opponentDeckData,
      simulationCount: simulationCount,
      simulationSeed: simulationSeed,
      isMetaDeck: false,
    );
  } catch (e, stack) {
    print('Erro em simulate-matchup: $e\n$stack');
    return internalServerError('Failed to simulate matchup');
  }
}

/// Busca dados completos de um deck
Future<Map<String, dynamic>?> _getDeckData(
  Pool pool,
  String deckId, {
  required String userId,
  bool allowPublicDeck = false,
}) async {
  try {
    final hasCardIntelligenceSnapshot =
        await _hasTable(pool, 'card_intelligence_snapshot');
    final cardSourceJoin = hasCardIntelligenceSnapshot
        ? 'JOIN card_intelligence_snapshot c ON c.id = dc.card_id'
        : 'JOIN cards c ON c.id = dc.card_id';
    final functionalTagsSelect = hasCardIntelligenceSnapshot
        ? 'c.function_tag_details AS functional_tags'
        : await _functionalTagsSelectSql(pool);
    final semanticV2Select = hasCardIntelligenceSnapshot
        ? 'c.semantic_tags_v2 AS semantic_tags_v2'
        : await _semanticV2SelectSql(pool);

    final deckResult = await pool.execute(
      Sql.named('''
        SELECT id, name, format
        FROM decks
        WHERE id = CAST(@id AS uuid)
          AND (
            user_id = CAST(@user_id AS uuid)
            OR (CAST(@allow_public AS boolean) AND is_public = true)
          )
      '''),
      parameters: {
        'id': deckId,
        'user_id': userId,
        'allow_public': allowPublicDeck,
      },
    );

    if (deckResult.isEmpty) return null;

    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors, dc.quantity, dc.is_commander,
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
               c.color_identity,
               $functionalTagsSelect,
               $semanticV2Select
        FROM deck_cards dc
        $cardSourceJoin
        WHERE dc.deck_id = @id
      '''),
      parameters: {'id': deckId},
    );

    final cards = <Map<String, dynamic>>[];
    String? commander;
    int landCount = 0;
    int creatureCount = 0;
    int rampCount = 0;
    int removalCount = 0;
    int counterspellCount = 0;
    double totalCMC = 0;
    int nonLandCards = 0;
    final observedDeckColors = <String>{};
    final commanderColorIdentity = <String>{};

    for (final row in cardsResult) {
      final name = row[0] as String;
      final typeLine = (row[1] as String?) ?? '';
      final oracleText = ((row[2] as String?) ?? '').toLowerCase();
      final manaCost = (row[3] as String?) ?? '';
      final quantity = row[5] as int;
      final isCommander = row[6] as bool;
      final cmc = (row[7] as num?)?.toDouble() ?? 0;
      final cardColors = (row[4] as List?)?.cast<String>() ?? [];
      final colorIdentity = (row[8] as List?)?.cast<String>() ?? [];
      final functionalTags = row[9];
      final semanticTagsV2 = row[10];

      observedDeckColors.addAll(cardColors);

      if (isCommander) {
        commander = name;
        commanderColorIdentity.addAll(colorIdentity);
      }

      cards.add({
        'name': name,
        'type_line': typeLine,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
        'colors': cardColors,
        'color_identity': colorIdentity,
        'quantity': quantity,
        'cmc': cmc,
        'is_commander': isCommander,
        'functional_tags': functionalTags,
        'semantic_tags_v2': semanticTagsV2,
      });

      final typeLineLower = typeLine.toLowerCase();
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

      if (typeLineLower.contains('creature')) creatureCount += quantity;
      if (cardRoles.contains('ramp') || cardRoles.contains('ritual')) {
        rampCount += quantity;
      }
      if (cardRoles.contains('removal') ||
          cardRoles.contains('wipe') ||
          cardRoles.contains('board_wipe')) {
        removalCount += quantity;
      }
      if (cardRoles.contains('counterspell') ||
          cardRoles.contains('counter_magic') ||
          oracleText.contains('counter target')) {
        counterspellCount += quantity;
      }
    }

    final recommendationColors = commanderColorIdentity.isNotEmpty
        ? commanderColorIdentity
        : observedDeckColors;
    final colorIdentitySource = commanderColorIdentity.isNotEmpty
        ? 'commander_color_identity'
        : 'observed_card_colors';

    return {
      'id': deckResult.first[0] as String,
      'name': deckResult.first[1] as String,
      'format': deckResult.first[2] as String,
      'commander': commander,
      'cards': cards,
      'colors': recommendationColors.toList()..sort(),
      'color_identity_source': colorIdentitySource,
      'stats': {
        'lands': landCount,
        'creatures': creatureCount,
        'ramp': rampCount,
        'removal': removalCount,
        'counterspells': counterspellCount,
        'average_cmc': nonLandCards > 0 ? totalCMC / nonLandCards : 0.0,
      },
    };
  } catch (e) {
    print('[ERROR] handler: $e');
    print('Erro ao buscar deck $deckId: $e');
    return null;
  }
}

/// Busca dados de um meta deck
Future<Map<String, dynamic>?> _getMetaDeckData(
    Pool pool, String metaDeckId) async {
  try {
    final result = await pool.execute(
      Sql.named(
          'SELECT id, format, archetype, card_list, placement FROM meta_decks WHERE id = @id'),
      parameters: {'id': metaDeckId},
    );

    if (result.isEmpty) return null;

    final format = result.first[1] as String;
    final cardList = result.first[3] as String;
    final parsedCardList = parseMetaDeckCardList(
      cardList: cardList,
      format: format,
    );

    return {
      'id': result.first[0] as String,
      'name': '${result.first[2]} (Meta)',
      'format': format,
      'archetype': result.first[2] as String,
      'placement': result.first[4] as String?,
      'card_count': parsedCardList.effectiveTotal,
      'is_meta_deck': true,
    };
  } catch (e) {
    print('[ERROR] handler: $e');
    print('Erro ao buscar meta deck $metaDeckId: $e');
    return null;
  }
}

/// Analisa o matchup e retorna resultado
Future<Response> _analyzeMatchup({
  required Pool pool,
  required ArchetypeCountersService countersService,
  required Map<String, dynamic> myDeck,
  required Map<String, dynamic> opponentDeck,
  required int simulationCount,
  required int? simulationSeed,
  required bool isMetaDeck,
}) async {
  // Detectar arquétipos
  final myCards =
      (myDeck['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  final myArchetypeData =
      await countersService.detectDeckArchetype(cards: myCards);
  final myArchetype = myArchetypeData['archetype'] as String;

  String opponentArchetype;
  if (isMetaDeck) {
    opponentArchetype = opponentDeck['archetype'] as String? ?? 'unknown';
  } else {
    final oppCards =
        (opponentDeck['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final oppArchetypeData =
        await countersService.detectDeckArchetype(cards: oppCards);
    opponentArchetype = oppArchetypeData['archetype'] as String;
  }

  // Buscar hate cards relevantes
  final hateCardsForOpponent = await countersService.getHateCards(
    archetype: opponentArchetype,
    colors: (myDeck['colors'] as List?)?.cast<String>(),
  );

  // Calcular vantagens/desvantagens baseado em estatísticas
  final myStats = myDeck['stats'] as Map<String, dynamic>? ?? {};
  final oppStats = opponentDeck['stats'] as Map<String, dynamic>? ?? {};

  double myScore = 50.0; // Base 50%
  final advantages = <String>[];
  final disadvantages = <String>[];
  final recommendations = <String>[];

  // Comparar ramp
  final myRamp = (myStats['ramp'] as int?) ?? 0;
  final oppRamp = (oppStats['ramp'] as int?) ?? 5;
  if (myRamp > oppRamp + 3) {
    myScore += 5;
    advantages.add('Mais ramp que o oponente (+${myRamp - oppRamp})');
  } else if (oppRamp > myRamp + 3) {
    myScore -= 5;
    disadvantages.add('Menos ramp que o oponente (-${oppRamp - myRamp})');
    recommendations.add('Adicionar mais fontes de ramp');
  }

  // Comparar removal
  final myRemoval = (myStats['removal'] as int?) ?? 0;
  final oppRemoval = (oppStats['removal'] as int?) ?? 5;
  if (myRemoval > oppRemoval + 2) {
    myScore += 5;
    advantages.add('Mais removal que o oponente');
  } else if (myRemoval < 5) {
    myScore -= 5;
    disadvantages.add('Removal insuficiente');
    recommendations.add('Adicionar mais removal pontual');
  }

  // Comparar curva de mana
  final myCMC = (myStats['average_cmc'] as num?)?.toDouble() ?? 3.0;
  final oppCMC = (oppStats['average_cmc'] as num?)?.toDouble() ?? 3.0;
  if (myCMC < oppCMC - 0.5) {
    myScore += 7;
    advantages.add(
        'Curva de mana mais baixa (${myCMC.toStringAsFixed(1)} vs ${oppCMC.toStringAsFixed(1)})');
  } else if (myCMC > oppCMC + 0.5) {
    myScore -= 5;
    disadvantages.add('Curva de mana mais alta');
    recommendations.add('Reduzir CMC médio do deck');
  }

  // Counterspells (vantagem em matchups)
  final myCounters = (myStats['counterspells'] as int?) ?? 0;
  if (myCounters >= 5) {
    myScore += 5;
    advantages.add('Boa quantidade de counters ($myCounters)');
  }

  // Verificar se tem hate cards
  int hateCardCount = 0;
  for (final card in myCards) {
    if (hateCardsForOpponent.contains(card['name'])) {
      hateCardCount++;
    }
  }

  if (hateCardCount > 0) {
    myScore += hateCardCount * 3;
    advantages.add('Tem $hateCardCount hate cards contra $opponentArchetype');
  } else if (hateCardsForOpponent.isNotEmpty) {
    myScore -= 5;
    disadvantages.add('Sem hate cards contra $opponentArchetype');
    recommendations.addAll(
        hateCardsForOpponent.take(3).map((c) => 'Considerar adicionar: $c'));
  }

  // Matchup arquétipo vs arquétipo
  final matchupModifier =
      _getArchetypeMatchupModifier(myArchetype, opponentArchetype);
  myScore += matchupModifier;
  if (matchupModifier > 0) {
    advantages
        .add('$myArchetype geralmente tem vantagem contra $opponentArchetype');
  } else if (matchupModifier < 0) {
    disadvantages
        .add('$opponentArchetype geralmente tem vantagem contra $myArchetype');
  }

  // Simular partidas (Monte Carlo simplificado)
  final seed = simulationSeed ??
      _stableMatchupSeed(
        myDeck,
        opponentDeck,
        simulationCount,
      );
  final random = Random(seed);
  int wins = 0;
  int totalTurns = 0;

  for (int i = 0; i < simulationCount; i++) {
    // Simular uma partida baseada nas estatísticas
    final roll = random.nextDouble() * 100;

    // Adicionar variância
    final variance = (random.nextDouble() - 0.5) * 20;
    final effectiveWinChance = myScore + variance;

    if (roll < effectiveWinChance) {
      wins++;
      // Estimar turnos para vitória baseado na curva
      totalTurns += (6 + (myCMC * 1.5) + random.nextInt(4)).round();
    } else {
      totalTurns += (6 + (oppCMC * 1.5) + random.nextInt(4)).round();
    }
  }

  final winRate = wins / simulationCount;
  final avgTurns = totalTurns / simulationCount;
  final previousMatchup = await _loadStoredMatchup(
    pool,
    myDeck['id'] as String,
    opponentDeck['id'] as String,
  );

  // Salvar resultado no banco
  try {
    await pool.execute(
      Sql.named('''
        INSERT INTO deck_matchups (deck_id, opponent_deck_id, win_rate, notes)
        VALUES (@my_deck, @opp_deck, @win_rate, @notes)
        ON CONFLICT (deck_id, opponent_deck_id)
        DO UPDATE SET win_rate = @win_rate, notes = @notes, updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: {
        'my_deck': myDeck['id'],
        'opp_deck': opponentDeck['id'],
        'win_rate': winRate,
        'notes': 'Auto-generated: ${advantages.join(", ")}',
      },
    );
  } catch (e) {
    print('[ERROR] handler: $e');
    print('Aviso: Não foi possível salvar matchup: $e');
  }

  return Response.json(body: {
    'my_deck': {
      'id': myDeck['id'],
      'name': myDeck['name'],
      'archetype': myArchetype,
      'commander': myDeck['commander'],
      'colors': myDeck['colors'],
      'color_identity_source': myDeck['color_identity_source'],
    },
    'opponent_deck': {
      'id': opponentDeck['id'],
      'name': opponentDeck['name'],
      'archetype': opponentArchetype,
      'is_meta_deck': isMetaDeck,
      if (!isMetaDeck)
        'color_identity_source': opponentDeck['color_identity_source'],
    },
    'simulation': {
      'runs': simulationCount,
      'seed': seed,
      'wins': wins,
      'losses': simulationCount - wins,
      'win_rate': (winRate * 100).toStringAsFixed(1) + '%',
      'win_rate_numeric': winRate,
      'average_game_length': avgTurns.toStringAsFixed(1),
    },
    'stored_matchup': {
      'previous': previousMatchup,
      'current': {
        'win_rate_numeric': winRate,
        'notes': 'Auto-generated: ${advantages.join(", ")}',
      },
    },
    'analysis': {
      'base_win_chance': myScore,
      'advantages': advantages,
      'disadvantages': disadvantages,
    },
    'recommendations': {
      'cards_to_add': recommendations,
      'hate_cards_for_opponent': hateCardsForOpponent.take(5).toList(),
    },
    'matchup_verdict': _getMatchupVerdict(winRate),
  });
}

Future<Map<String, dynamic>?> _loadStoredMatchup(
  Pool pool,
  String deckId,
  String opponentDeckId,
) async {
  try {
    final rows = await pool.execute(
      Sql.named('''
        SELECT win_rate, notes, updated_at
        FROM deck_matchups
        WHERE deck_id = CAST(@deck_id AS uuid)
          AND opponent_deck_id = CAST(@opponent_deck_id AS uuid)
        LIMIT 1
      '''),
      parameters: {
        'deck_id': deckId,
        'opponent_deck_id': opponentDeckId,
      },
    );
    if (rows.isEmpty) return null;
    final m = rows.first.toColumnMap();
    return {
      'win_rate_numeric': (m['win_rate'] as num?)?.toDouble(),
      'notes': m['notes'],
      'updated_at': m['updated_at']?.toString(),
    };
  } catch (e) {
    print('[simulate-matchup] stored matchup unavailable: $e');
    return null;
  }
}

/// Retorna modificador de win rate baseado em matchup de arquétipos
double _getArchetypeMatchupModifier(String myArchetype, String oppArchetype) {
  final matchups = {
    'aggro': {'control': -10, 'combo': 5, 'midrange': 0, 'ramp': 10},
    'control': {'aggro': 10, 'combo': -5, 'midrange': 5, 'ramp': 5},
    'combo': {'aggro': -5, 'control': 5, 'midrange': 0, 'stax': -15},
    'midrange': {'aggro': 0, 'control': -5, 'combo': 0, 'ramp': 0},
    'ramp': {'aggro': -10, 'control': -5, 'combo': 5, 'midrange': 0},
    'graveyard': {'control': -5, 'aggro': 5},
    'tokens': {'control': -10, 'aggro': -5},
    'stax': {'combo': 15, 'control': 5, 'aggro': 0},
  };

  return matchups[myArchetype]?[oppArchetype]?.toDouble() ?? 0.0;
}

/// Retorna veredicto textual do matchup
String _getMatchupVerdict(double winRate) {
  if (winRate >= 0.65) return 'Matchup MUITO favorável ✅';
  if (winRate >= 0.55) return 'Matchup favorável 👍';
  if (winRate >= 0.45) return 'Matchup equilibrado ⚖️';
  if (winRate >= 0.35) return 'Matchup desfavorável 👎';
  return 'Matchup MUITO desfavorável ❌';
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

int _normalizedSimulationCount(Object? value) {
  final parsed = value is int ? value : 50;
  return parsed.clamp(1, 5000);
}

int _stableMatchupSeed(
  Map<String, dynamic> myDeck,
  Map<String, dynamic> opponentDeck,
  int simulationCount,
) {
  final raw = '${myDeck['id']}|${opponentDeck['id']}|$simulationCount';
  var hash = 0x811c9dc5;
  for (final unit in raw.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
