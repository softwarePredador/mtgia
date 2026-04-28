import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/endpoint_cache.dart';
import '../../lib/sets_catalog_contract.dart';

Future<Response> onRequest(RequestContext context) async {
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
    return Response.json(body: cached);
  }

  final where = <String>[];
  final sqlParams = <String, dynamic>{
    'limit': safeLimit,
    'offset': offset,
  };

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
        )
        SELECT
          cs.code,
          cs.name,
          cs.release_date,
          cs.type,
          cs.block,
          cs.is_online_only,
          cs.is_foreign_only,
          COUNT(c.id)::int AS card_count
        FROM canonical_sets cs
        LEFT JOIN cards c ON LOWER(c.set_code) = LOWER(cs.code)
        WHERE cs.rn = 1
        GROUP BY
          cs.code,
          cs.name,
          cs.release_date,
          cs.type,
          cs.block,
          cs.is_online_only,
          cs.is_foreign_only
        ORDER BY cs.release_date DESC NULLS LAST, cs.name ASC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: sqlParams,
    );

    final sets = result.map((row) {
      final map = row.toColumnMap();
      return mapSetCatalogRow(map);
    }).toList();

    final payload = {
      'data': sets,
      'page': safePage,
      'limit': safeLimit,
      'total_returned': sets.length,
    };

    EndpointCache.instance
        .set(cacheKey, payload, ttl: const Duration(seconds: 60));
    return Response.json(body: payload);
  } catch (e) {
    print('[ERROR] Erro interno ao buscar sets: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao buscar sets'},
    );
  }
}
