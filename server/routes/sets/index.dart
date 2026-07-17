import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/endpoint_cache.dart';
import '../../lib/sets_catalog_contract.dart';

Future<Response> onRequest(RequestContext context) async {
  final totalStopwatch = Stopwatch()..start();
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final pool = context.read<Pool>();
  final params = context.request.uri.queryParameters;

  final query = normalizeSetSearchQuery(params['q']);
  final code = normalizeSetCodeFilter(params['code']);

  final safeLimit = safeSetCatalogLimit(params['limit']);
  final safePage = safeSetCatalogPage(params['page']);
  final offset = (safePage - 1) * safeLimit;
  final cacheKey = 'sets:${context.request.uri.query}';

  final cached = EndpointCache.instance.get(cacheKey);
  if (cached != null) {
    return Response.json(
      body: cached,
      headers: buildSetCatalogTimingHeaders(
        cacheHit: true,
        totalElapsedMs: totalStopwatch.elapsedMilliseconds,
      ),
    );
  }

  final where = <String>[];
  final sqlParams = <String, dynamic>{'limit': safeLimit, 'offset': offset};

  if (code != null && code.isNotEmpty) {
    where.add('LOWER(code) = LOWER(@code)');
    sqlParams['code'] = code;
  }

  if (query != null && query.isNotEmpty) {
    where.add('(name ILIKE @q OR code ILIKE @q)');
    sqlParams['q'] = '%$query%';
  }

  final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

  try {
    final queryStopwatch = Stopwatch()..start();
    final result = await pool.execute(
      Sql.named('''
        WITH filtered_sets AS (
          SELECT code, name, release_date, type, block, is_online_only, is_foreign_only
          FROM sets
          $whereSql
        ),
        canonical_sets AS (
          SELECT
            *,
            ROW_NUMBER() OVER (
              PARTITION BY LOWER(code)
              ORDER BY
                release_date DESC NULLS LAST,
                CASE WHEN code = UPPER(code) THEN 0 ELSE 1 END,
                name ASC
            ) AS rn
          FROM filtered_sets
        ),
        paged_sets AS (
          SELECT
            code,
            name,
            release_date,
            type,
            block,
            is_online_only,
            is_foreign_only
          FROM canonical_sets
          WHERE rn = 1
          ORDER BY release_date DESC NULLS LAST, name ASC
          LIMIT @limit OFFSET @offset
        ),
        card_stats AS (
          SELECT
            LOWER(c.set_code) AS set_key,
            COUNT(c.id)::int AS card_count
          FROM cards c
          INNER JOIN paged_sets ps
            ON LOWER(ps.code) = LOWER(c.set_code)
          GROUP BY LOWER(c.set_code)
        ),
        representative_cards AS (
          SELECT DISTINCT ON (LOWER(c.set_code))
            LOWER(c.set_code) AS set_key,
            c.image_url AS representative_image_url
          FROM cards c
          INNER JOIN paged_sets ps
            ON LOWER(ps.code) = LOWER(c.set_code)
          WHERE NULLIF(BTRIM(c.image_url), '') IS NOT NULL
          ORDER BY
            LOWER(c.set_code),
            CASE
              WHEN COALESCE(c.type_line, '') ILIKE '%Token%'
                OR COALESCE(c.type_line, '') ILIKE '%Emblem%'
                OR COALESCE(c.type_line, '')
                  ~* '(^|[^[:alpha:]])basic[[:space:]]+land([^[:alpha:]]|\$)'
              THEN 1
              ELSE 0
            END,
            CASE
              WHEN COALESCE(c.type_line, '') ILIKE 'Legendary%' THEN 0
              ELSE 1
            END,
            CASE LOWER(COALESCE(c.rarity, ''))
              WHEN 'mythic' THEN 0
              WHEN 'rare' THEN 1
              WHEN 'uncommon' THEN 2
              ELSE 3
            END,
            LOWER(c.name),
            c.id
        )
        SELECT
          ps.code,
          ps.name,
          ps.release_date,
          ps.type,
          ps.block,
          ps.is_online_only,
          ps.is_foreign_only,
          COALESCE(stats.card_count, 0)::int AS card_count,
          representative.representative_image_url
        FROM paged_sets ps
        LEFT JOIN card_stats stats ON stats.set_key = LOWER(ps.code)
        LEFT JOIN representative_cards representative
          ON representative.set_key = LOWER(ps.code)
        ORDER BY ps.release_date DESC NULLS LAST, ps.name ASC
      '''),
      parameters: sqlParams,
    );
    queryStopwatch.stop();

    final sets =
        result.map((row) {
          final map = row.toColumnMap();
          return mapSetCatalogRow(map);
        }).toList();

    final payload = {
      'data': sets,
      'page': safePage,
      'limit': safeLimit,
      'total_returned': sets.length,
    };

    EndpointCache.instance.set(
      cacheKey,
      payload,
      ttl: const Duration(seconds: 60),
    );
    return Response.json(
      body: payload,
      headers: buildSetCatalogTimingHeaders(
        cacheHit: false,
        totalElapsedMs: totalStopwatch.elapsedMilliseconds,
        queryElapsedMs: queryStopwatch.elapsedMilliseconds,
      ),
    );
  } catch (e) {
    print('[ERROR] Erro interno ao buscar sets: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao buscar sets'},
    );
  }
}
