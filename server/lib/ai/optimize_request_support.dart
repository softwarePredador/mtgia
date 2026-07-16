import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../logger.dart';
import 'optimize_runtime_support.dart';
import 'optimize_stage_telemetry.dart';
import 'optimize_state_support.dart';

class OptimizeDeckContextData {
  final String deckFormat;
  final List<ResultRow> cardsResult;
  final int currentTotalBeforeMode;
  final int? maxTotalForFormat;
  final bool shouldAutoComplete;
  final String effectiveMode;
  final String deckSignature;
  final String cacheKey;
  final List<String> commanders;
  final List<String> otherCards;
  final List<Map<String, dynamic>> allCardData;
  final Set<String> deckColors;
  final Set<String> commanderColorIdentity;
  final int currentTotalCards;
  final Map<String, int> originalCountsById;
  final Map<String, dynamic> deckAnalysis;
  final DeckThemeProfileResult themeProfile;
  final DeckOptimizationStateResult deckState;
  final String effectiveOptimizeArchetype;

  const OptimizeDeckContextData({
    required this.deckFormat,
    required this.cardsResult,
    required this.currentTotalBeforeMode,
    required this.maxTotalForFormat,
    required this.shouldAutoComplete,
    required this.effectiveMode,
    required this.deckSignature,
    required this.cacheKey,
    required this.commanders,
    required this.otherCards,
    required this.allCardData,
    required this.deckColors,
    required this.commanderColorIdentity,
    required this.currentTotalCards,
    required this.originalCountsById,
    required this.deckAnalysis,
    required this.themeProfile,
    required this.deckState,
    required this.effectiveOptimizeArchetype,
  });
}

Future<OptimizeDeckContextData> loadOptimizeDeckContext({
  required Pool pool,
  required String deckId,
  required String userId,
  required String targetArchetype,
  required String requestMode,
  required String intensity,
  required int? bracket,
  required bool keepTheme,
  String recommendationContextSignature = '',
  OptimizeStageTelemetry? telemetry,
}) async {
  final deckResult =
      await (telemetry?.trackAsync(
            'deck_context.deck_query',
            () => pool.execute(
              Sql.named('''
            SELECT name, format
            FROM decks
            WHERE id = CAST(@id AS uuid)
              AND user_id = CAST(@user_id AS uuid)
          '''),
              parameters: {'id': deckId, 'user_id': userId},
            ),
          ) ??
          pool.execute(
            Sql.named('''
          SELECT name, format
          FROM decks
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
        '''),
            parameters: {'id': deckId, 'user_id': userId},
          ));

  if (deckResult.isEmpty) {
    throw const OptimizeDeckContextException('DECK_NOT_FOUND');
  }

  final deckRow = deckResult[0];
  final deckFormatRaw = deckRow[1] as String?;
  final deckFormat = (deckFormatRaw ?? '').toLowerCase().trim();
  if (deckFormat.isEmpty) {
    throw const OptimizeDeckContextException('DECK_FORMAT_MISSING');
  }

  final hasCardIntelligenceSnapshot = await _hasTable(
    pool,
    'card_intelligence_snapshot',
  );
  final cardSourceJoin =
      hasCardIntelligenceSnapshot
          ? 'JOIN card_intelligence_snapshot c ON c.card_id = dc.card_id'
          : 'JOIN cards c ON c.id = dc.card_id';
  final semanticV2Select =
      hasCardIntelligenceSnapshot
          ? 'c.semantic_tags_v2 AS semantic_tags_v2'
          : await _semanticV2SelectSql(pool);
  final functionalTagsSelect =
      hasCardIntelligenceSnapshot
          ? 'c.function_tag_details AS functional_tags'
          : await _functionalTagsSelectSql(pool);
  final cardsResult =
      await (telemetry?.trackAsync(
            'deck_context.cards_query',
            () => pool.execute(
              Sql.named('''
      SELECT c.name, dc.is_commander, dc.quantity, c.type_line, c.mana_cost, c.colors,
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
             c.oracle_text,
             c.color_identity,
             c.id::text,
             $semanticV2Select,
             $functionalTagsSelect,
             dc.condition
      FROM deck_cards dc
      $cardSourceJoin
      WHERE dc.deck_id = @id
    '''),
              parameters: {'id': deckId},
            ),
          ) ??
          pool.execute(
            Sql.named('''
      SELECT c.name, dc.is_commander, dc.quantity, c.type_line, c.mana_cost, c.colors,
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
             c.oracle_text,
             c.color_identity,
             c.id::text,
             $semanticV2Select,
             $functionalTagsSelect,
             dc.condition
      FROM deck_cards dc
      $cardSourceJoin
      WHERE dc.deck_id = @id
    '''),
            parameters: {'id': deckId},
          ));

  final currentTotalBeforeMode = cardsResult.fold<int>(
    0,
    (sum, row) => sum + ((row[2] as int?) ?? 1),
  );
  final maxTotalForFormat =
      deckFormat == 'commander' ? 100 : (deckFormat == 'brawl' ? 60 : null);
  final shouldAutoComplete =
      maxTotalForFormat != null && currentTotalBeforeMode < maxTotalForFormat;
  final effectiveMode =
      requestMode == 'complete' || shouldAutoComplete ? 'complete' : 'optimize';

  final deckSignature = buildOptimizeDeckSignature(cardsResult);
  final cacheKey = buildOptimizeCacheKey(
    deckId: deckId,
    archetype: targetArchetype,
    mode: effectiveMode,
    bracket: bracket,
    keepTheme: keepTheme,
    deckSignature: deckSignature,
    intensity: intensity,
    recommendationContextSignature: recommendationContextSignature,
  );

  final commanders = <String>[];
  final otherCards = <String>[];
  final allCardData = <Map<String, dynamic>>[];
  final deckColors = <String>{};
  final commanderColorIdentity = <String>{};
  var commanderCanonicalIdentityPresent = false;
  var currentTotalCards = 0;
  final originalCountsById = <String, int>{};

  for (final row in cardsResult) {
    final name = row[0] as String;
    final isCmdr = row[1] as bool;
    final quantity = (row[2] as int?) ?? 1;
    final typeLine = (row[3] as String?) ?? '';
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? [];
    final cmc = (row[6] as num?)?.toDouble() ?? 0.0;
    final oracleText = (row[7] as String?) ?? '';
    final colorIdentity = (row[8] as List?)?.cast<String>();
    final cardId = row[9] as String;
    final semanticTagsV2 = row.length > 10 ? row[10] : null;
    final functionalTags = row.length > 11 ? row[11] : null;
    final condition = row.length > 12 ? row[12] : null;

    currentTotalCards += quantity;
    originalCountsById[cardId] = (originalCountsById[cardId] ?? 0) + quantity;
    deckColors.addAll(colors);

    final cardData = {
      'name': name,
      'type_line': typeLine,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': colorIdentity,
      'cmc': cmc,
      'is_commander': isCmdr,
      'oracle_text': oracleText,
      'quantity': quantity,
      'card_id': cardId,
      'semantic_tags_v2': semanticTagsV2,
      'functional_tags': functionalTags,
      'condition': condition,
    };
    allCardData.add(cardData);

    if (isCmdr) {
      commanders.add(name);
      commanderCanonicalIdentityPresent |= colorIdentity != null;
      commanderColorIdentity.addAll(
        resolveCardColorIdentity(
          colorIdentity: colorIdentity,
          colors: colors,
          manaCost: manaCost,
          oracleText: oracleText,
        ),
      );
    } else {
      final cleanText = oracleText.replaceAll('\n', ' ').trim();
      final truncatedText =
          cleanText.length > 150
              ? '${cleanText.substring(0, 147)}...'
              : cleanText;

      if (truncatedText.isNotEmpty) {
        otherCards.add('$name (Type: $typeLine, Text: $truncatedText)');
      } else {
        otherCards.add('$name (Type: $typeLine)');
      }
    }
  }

  if (commanderColorIdentity.isEmpty) {
    final inferredFromDeck = normalizeColorIdentity(deckColors.toList());
    if (!commanderCanonicalIdentityPresent && inferredFromDeck.isNotEmpty) {
      commanderColorIdentity.addAll(inferredFromDeck);
    } else if (commanders.isEmpty) {
      commanderColorIdentity.addAll(const {'W', 'U', 'B', 'R', 'G'});
    } else {
      Log.i(
        'Commander color identity preservada como colorless. '
        'commanders=${commanders.join(' | ')}',
      );
    }

    final reason =
        commanders.isNotEmpty
            ? 'commander sem color_identity detectável'
            : 'deck sem is_commander marcado';
    if (commanders.isEmpty) {
      Log.w(
        'Color identity fallback aplicado ($reason) para evitar complete degradado. '
        'commanders=${commanders.join(' | ')} '
        'identity=${commanderColorIdentity.join(',')}',
      );
    }
  }

  final themeProfileFuture =
      telemetry?.trackAsync(
        'deck_context.theme_profile',
        () =>
            detectThemeProfile(allCardData, commanders: commanders, pool: pool),
      ) ??
      detectThemeProfile(allCardData, commanders: commanders, pool: pool);

  final analyzer = DeckArchetypeAnalyzerCore(allCardData, deckColors.toList());
  final deckAnalysis =
      telemetry?.trackSync(
        'deck_context.analysis',
        analyzer.generateAnalysis,
      ) ??
      analyzer.generateAnalysis();
  final deckState =
      telemetry?.trackSync(
        'deck_context.state_assessment',
        () => assessDeckOptimizationStateCore(
          cards: allCardData,
          deckAnalysis: deckAnalysis,
          deckFormat: deckFormat,
          currentTotalCards: currentTotalCards,
          commanderColorIdentity: commanderColorIdentity,
        ),
      ) ??
      assessDeckOptimizationStateCore(
        cards: allCardData,
        deckAnalysis: deckAnalysis,
        deckFormat: deckFormat,
        currentTotalCards: currentTotalCards,
        commanderColorIdentity: commanderColorIdentity,
      );
  final effectiveOptimizeArchetype =
      telemetry?.trackSync(
        'deck_context.resolve_archetype',
        () => resolveOptimizeArchetype(
          requestedArchetype: targetArchetype,
          detectedArchetype: deckAnalysis['detected_archetype']?.toString(),
        ),
      ) ??
      resolveOptimizeArchetype(
        requestedArchetype: targetArchetype,
        detectedArchetype: deckAnalysis['detected_archetype']?.toString(),
      );
  final themeProfile = await themeProfileFuture;

  return OptimizeDeckContextData(
    deckFormat: deckFormat,
    cardsResult: cardsResult,
    currentTotalBeforeMode: currentTotalBeforeMode,
    maxTotalForFormat: maxTotalForFormat,
    shouldAutoComplete: shouldAutoComplete,
    effectiveMode: effectiveMode,
    deckSignature: deckSignature,
    cacheKey: cacheKey,
    commanders: commanders,
    otherCards: otherCards,
    allCardData: allCardData,
    deckColors: deckColors,
    commanderColorIdentity: commanderColorIdentity,
    currentTotalCards: currentTotalCards,
    originalCountsById: originalCountsById,
    deckAnalysis: deckAnalysis,
    themeProfile: themeProfile,
    deckState: deckState,
    effectiveOptimizeArchetype: effectiveOptimizeArchetype,
  );
}

Future<void> verifyOptimizeDeckAccess({
  required Pool pool,
  required String deckId,
  required String userId,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT 1
      FROM decks
      WHERE id = CAST(@id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
      LIMIT 1
    '''),
    parameters: {'id': deckId, 'user_id': userId},
  );
  if (result.isEmpty) {
    throw const OptimizeDeckContextException('DECK_NOT_FOUND');
  }
}

Future<String> _semanticV2SelectSql(Pool pool) async {
  final exists = await _hasTable(pool, 'card_semantic_tags_v2');
  if (!exists) return 'NULL::jsonb AS semantic_tags_v2';
  return '''
             (
               SELECT jsonb_agg(jsonb_build_object(
                 'tags', cstv2.tags,
                 'role_confidence', cstv2.role_confidence,
                 'engine', cstv2.engine,
                 'payoff', cstv2.payoff,
                 'enabler', cstv2.enabler,
                 'wincon', cstv2.wincon,
                 'combo_piece', cstv2.combo_piece
               ))
               FROM card_semantic_tags_v2 cstv2
               WHERE cstv2.card_id = c.id
             ) AS semantic_tags_v2''';
}

Future<String> _functionalTagsSelectSql(Pool pool) async {
  final exists = await _hasTable(pool, 'card_function_tags');
  if (!exists) return "'[]'::jsonb AS functional_tags";
  return '''
             COALESCE(
               (SELECT jsonb_agg(jsonb_build_object(
                 'tag', cft.tag,
                 'confidence', cft.confidence,
                 'evidence', cft.evidence,
                 'source', cft.source
               ) ORDER BY cft.confidence DESC, cft.tag)
               FROM card_function_tags cft
               WHERE cft.card_id = c.id
               ),
               '[]'::jsonb
             ) AS functional_tags''';
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  try {
    final result = await pool.execute(
      Sql.named("SELECT to_regclass(@name) IS NOT NULL"),
      parameters: {'name': tableName},
    );
    return result.isNotEmpty && result.first[0] == true;
  } catch (_) {
    return false;
  }
}

class OptimizeDeckContextException implements Exception {
  final String code;

  const OptimizeDeckContextException(this.code);
}
