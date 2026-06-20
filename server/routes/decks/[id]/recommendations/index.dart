import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import '../../../../lib/deck_recommendations_route_support.dart';
import '../../../../lib/openai_runtime_config.dart';
import '../../../../lib/ai/edhrec_trend_service.dart';

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
  final env = _recommendationsEnv(context);
  final aiConfig = OpenAiRuntimeConfig(env);
  final apiKey = env['OPENAI_API_KEY'];

  try {
    final result = await buildDeckRecommendationsRouteResult(
      deckId: deckId,
      userId: userId,
      apiKey: apiKey,
      aiConfig: aiConfig,
      deckLoader: ({
        required deckId,
        required userId,
      }) async {
        final deckResult = await pool.execute(
          Sql.named('''
            SELECT name, format, description
            FROM decks
            WHERE id = CAST(@deckId AS uuid)
              AND user_id = CAST(@userId AS uuid)
          '''),
          parameters: {'deckId': deckId, 'userId': userId},
        );

        if (deckResult.isEmpty) return null;

        final deck = deckResult.first.toColumnMap();
        return DeckRecommendationRecord(
          name: deck['name'] as String? ?? '',
          format: deck['format'] as String? ?? 'commander',
          description: deck['description'] as String? ?? '',
        );
      },
      deckCardLoader: ({required deckId}) async {
        final hasCardIntelligenceSnapshot =
            await _hasTable(pool, 'card_intelligence_snapshot');
        final cardSourceJoin = hasCardIntelligenceSnapshot
            ? 'JOIN card_intelligence_snapshot c ON c.id = dc.card_id'
            : 'JOIN cards c ON dc.card_id = c.id';
        final functionalTagsSelect = hasCardIntelligenceSnapshot
            ? 'c.function_tag_details AS functional_tags'
            : await _functionalTagsSelectSql(pool);
        final semanticV2Select = hasCardIntelligenceSnapshot
            ? 'c.semantic_tags_v2 AS semantic_tags_v2'
            : await _semanticV2SelectSql(pool);

        final cardsResult = await pool.execute(
          Sql.named('''
            SELECT c.name, c.type_line, c.oracle_text, c.mana_cost, c.colors,
                   c.color_identity,
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
            $cardSourceJoin
            WHERE dc.deck_id = @deckId
          '''),
          parameters: {'deckId': deckId},
        );

        final deckCards = <Map<String, dynamic>>[];
        for (final row in cardsResult) {
          final name = row[0] as String;
          final typeLine = (row[1] as String?) ?? '';
          final oracleText = ((row[2] as String?) ?? '').toLowerCase();
          final manaCost = (row[3] as String?) ?? '';
          final colors = (row[4] as List?)?.cast<String>() ?? [];
          final colorIdentity = (row[5] as List?)?.cast<String>() ?? [];
          final quantity = row[6] as int;
          final isCommander = row[7] as bool? ?? false;
          final cmc = (row[8] as num?)?.toDouble() ?? 0;
          final functionalTags = row[9];
          final semanticTagsV2 = row[10];

          deckCards.add({
            'name': name,
            'type_line': typeLine,
            'oracle_text': oracleText,
            'mana_cost': manaCost,
            'colors': colors,
            'color_identity': colorIdentity,
            'quantity': quantity,
            'is_commander': isCommander,
            'cmc': cmc,
            'functional_tags': functionalTags,
            'semantic_tags_v2': semanticTagsV2,
          });
        }
        return deckCards;
      },
      candidateFinder: ({
        required roles,
        required oraclePatterns,
        required deckColors,
        required excludeNames,
        required limit,
        required format,
        landOnly = false,
      }) {
        return _findCardsForCategory(
          pool: pool,
          roles: roles,
          oraclePatterns: oraclePatterns,
          deckColors: deckColors,
          excludeNames: excludeNames,
          limit: limit,
          format: format,
          landOnly: landOnly,
        );
      },
      trendFinder: (commander) {
        return EdhrecTrendService(pool).getCardTrends(commander);
      },
    );
    return Response.json(statusCode: result.statusCode, body: result.body);
  } catch (e) {
    print('[ERROR] Failed to generate recommendations: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to generate recommendations: $e'},
    );
  }
}

DotEnv _recommendationsEnv(RequestContext context) {
  try {
    return context.read<DotEnv>();
  } on StateError {
    return DotEnv(includePlatformEnvironment: true, quiet: true)..load();
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
  required List<String> roles,
  required List<String> oraclePatterns,
  required Set<String> deckColors,
  required Set<String> excludeNames,
  required int limit,
  required String format,
  bool landOnly = false,
}) async {
  try {
    final normalizedRoles = roles
        .map((role) => role.trim().toLowerCase())
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final predicates = <String>[];

    if (normalizedRoles.isNotEmpty &&
        await _hasTable(pool, 'card_function_tags')) {
      predicates.add('''
        EXISTS (
          SELECT 1
          FROM card_function_tags cft
          WHERE cft.card_id = c.id
            AND LOWER(cft.tag) = ANY(@role_tags)
            AND COALESCE(cft.confidence, 0) >= 0.55
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

    if (predicates.isEmpty) return [];

    final landFilter = landOnly
        ? '''
          AND c.type_line ILIKE '%land%'
          AND c.type_line NOT ILIKE '%basic%land%'
        '''
        : '''
          AND c.type_line NOT ILIKE '%land%'
        ''';

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
          $landFilter
        GROUP BY c.name
        ORDER BY cmc_sort ASC, c.name ASC
        LIMIT @limit_plus
      '''),
      parameters: {
        'format': format.toLowerCase(),
        'deck_colors': deckColors.isEmpty
            ? null
            : TypedValue(Type.textArray, deckColors.toList()..sort()),
        'role_tags': TypedValue(Type.textArray, normalizedRoles),
        'limit_plus': limit + 20,
      },
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

String _sqlStringLiteral(String value) {
  return "'${value.replaceAll("'", "''")}'";
}
