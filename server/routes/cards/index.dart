import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/card_identity_support.dart';
import '../../lib/card_query_contract.dart';
import '../../lib/commander_eligibility.dart';
import '../../lib/endpoint_cache.dart';
import '../../lib/scryfall_image_url.dart';

Future<Response> onRequest(RequestContext context) async {
  // Apenas método GET é permitido
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method Not Allowed');
  }

  // Acessa a conexão do banco de dados fornecida pelo middleware
  final conn = context.read<Pool>();
  final hasSets = await _hasTable(conn, 'sets');
  final hasIdentityColumns = await hasCardIdentityColumns(conn);

  final params = context.request.uri.queryParameters;
  final idFilter = params['id']?.trim();
  final nameFilter = params['name'];
  final setFilter = normalizeCardSetFilter(params['set']);
  final includeTokens = params['include_tokens']?.toLowerCase() == 'true';
  final dedupeMode = parseCardDedupeMode(params['dedupe']);
  if (dedupeMode == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'dedupe deve ser true, false ou identity'},
    );
  }
  final rawCommanderFormat = params['commander_format'];
  final commanderFormat = normalizeCommanderCandidateFormat(rawCommanderFormat);
  if (rawCommanderFormat != null &&
      rawCommanderFormat.trim().isNotEmpty &&
      commanderFormat == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'commander_format deve ser commander ou brawl'},
    );
  }

  // Paginação
  final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final safeLimit = limit.clamp(1, 200);
  final safePage = page < 1 ? 1 : page;
  final offset = (safePage - 1) * safeLimit;
  final cacheKey = 'cards:${context.request.uri.query}';

  final cached = EndpointCache.instance.get(cacheKey);
  if (cached != null) {
    return Response.json(body: cached);
  }

  try {
    final query = _buildQuery(
      idFilter,
      nameFilter,
      setFilter,
      safeLimit,
      offset,
      includeSetInfo: hasSets,
      includeIdentityColumns: hasIdentityColumns,
      dedupeMode: dedupeMode,
      includeTokens: includeTokens,
      commanderFormat: commanderFormat,
    );

    final queryResult = await conn.execute(
      Sql.named(query.sql),
      parameters: query.parameters,
    );

    // Mapeamento do resultado para JSON
    final cards =
        queryResult.map((row) {
          final map = row.toColumnMap();
          final imageUrl = normalizeScryfallImageUrl(
            map['image_url']?.toString(),
            printingId: map['scryfall_id']?.toString(),
            oracleId: map['oracle_id']?.toString(),
          );
          return {
            'id': map['id'],
            'scryfall_id': map['scryfall_id'],
            if (map.containsKey('oracle_id')) 'oracle_id': map['oracle_id'],
            if (map.containsKey('layout')) 'layout': map['layout'],
            if (map.containsKey('card_faces_json'))
              'card_faces': map['card_faces_json'],
            'name': map['name'],
            'mana_cost': map['mana_cost'],
            'type_line': map['type_line'],
            'oracle_text': map['oracle_text'],
            'power': map['power'],
            'toughness': map['toughness'],
            'colors': map['colors'],
            'color_identity': map['color_identity'],
            'image_url': imageUrl,
            'set_code': map['set_code'],
            if (hasSets) 'set_name': map['set_name'],
            if (hasSets)
              'set_release_date':
                  (map['set_release_date'] as DateTime?)
                      ?.toIso8601String()
                      .split('T')
                      .first,
            'rarity': map['rarity'],
            'is_reserved': map['is_reserved'] == true,
            'collector_number': map['collector_number'],
            'foil': map['foil'],
            if (map.containsKey('printing_count'))
              'printing_count': map['printing_count'],
          };
        }).toList();

    final payload = {
      'data': cards,
      'page': safePage,
      'limit': safeLimit,
      'total_returned': cards.length,
    };

    EndpointCache.instance.set(
      cacheKey,
      payload,
      ttl: const Duration(seconds: 45),
    );
    return Response.json(body: payload);
  } catch (e) {
    print('[ERROR] Erro interno ao buscar cartas: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro interno ao buscar cartas'},
    );
  }
}

class _QueryBuilder {
  final String sql;
  final Map<String, dynamic> parameters;
  _QueryBuilder(this.sql, this.parameters);
}

_QueryBuilder _buildQuery(
  String? idFilter,
  String? nameFilter,
  String? setFilter,
  int limit,
  int offset, {
  required bool includeSetInfo,
  required bool includeIdentityColumns,
  CardDedupeMode dedupeMode = CardDedupeMode.set,
  bool includeTokens = false,
  String? commanderFormat,
}) {
  final params = <String, dynamic>{};
  final conditions = <String>[];
  final hasNameFilter = nameFilter != null && nameFilter.isNotEmpty;

  // Para ordenação: prioriza match exato, depois basic lands, depois alfabético
  String orderExpression = 'c.name ASC';

  if (idFilter != null && idFilter.isNotEmpty) {
    conditions.add('c.id::text = @id');
    params['id'] = idFilter;
  }

  if (hasNameFilter) {
    conditions.add('c.name ILIKE @name');
    params['name'] = '%$nameFilter%';
    params['exact_name'] = nameFilter;
    // Ordem: 1) match exato (case insensitive), 2) basic lands, 3) startsWith, 4) resto
    final tokenPriority =
        includeTokens ? "WHEN c.type_line ILIKE '%Token%' THEN -1" : '';
    orderExpression = '''
      CASE 
        $tokenPriority
        WHEN LOWER(c.name) = LOWER(@exact_name) THEN 0
        WHEN COALESCE(c.type_line, '') ~* '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)'
             AND LOWER(c.name) = LOWER(@exact_name) THEN 1
        WHEN COALESCE(c.type_line, '') ~* '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)' THEN 2
        WHEN LOWER(c.name) LIKE LOWER(@exact_name) || '%' THEN 3
        ELSE 4
      END, c.name ASC
    ''';
  }

  if (setFilter != null && setFilter.isNotEmpty) {
    // Usar LOWER para comparação case-insensitive
    conditions.add('LOWER(c.set_code) = LOWER(@set)');
    params['set'] = setFilter;
  }

  if (!includeTokens) {
    conditions.add("COALESCE(c.type_line, '') NOT ILIKE '%Token%'");
  }

  if (commanderFormat != null) {
    conditions.add(
      commanderEligibilitySql(format: commanderFormat, tableAlias: 'c'),
    );
  }

  final whereClause =
      conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

  final identityColumns = cardIdentitySelectSql('c', includeIdentityColumns);
  final identityExpression =
      includeIdentityColumns
          ? "COALESCE(NULLIF(BTRIM(c.oracle_id::text), ''), "
              "'name:' || LOWER(BTRIM(c.name)))"
          : "'name:' || LOWER(BTRIM(c.name))";
  final canonicalSetsCte =
      includeSetInfo
          ? '''
        WITH ranked_sets AS (
          SELECT
            code,
            name,
            release_date,
            ROW_NUMBER() OVER (
              PARTITION BY LOWER(code)
              ORDER BY
                release_date DESC NULLS LAST,
                CASE WHEN code = UPPER(code) THEN 0 ELSE 1 END,
                name ASC
            ) AS rn
          FROM sets
        ),
        canonical_sets AS (
          SELECT code, name, release_date
          FROM ranked_sets
          WHERE rn = 1
        )
      '''
          : '';
  final setJoin =
      includeSetInfo
          ? 'LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)'
          : '';
  final setSelect =
      includeSetInfo
          ? ''',
              s.name AS set_name,
              s.release_date AS set_release_date'''
          : '';
  final representativeOrder = '''
          CASE
            WHEN LOWER(COALESCE(c.set_code, '')) LIKE 'p%' THEN 1
            ELSE 0
          END,
          CASE
            WHEN NULLIF(BTRIM(c.image_url), '') IS NULL THEN 1
            ELSE 0
          END,
          ${includeSetInfo ? 's.release_date DESC NULLS LAST,' : ''}
          LOWER(COALESCE(c.set_code, '')) ASC,
          COALESCE(c.collector_number, '') ASC,
          c.id ASC
        ''';
  final resultOrderExpression =
      hasNameFilter
          ? '''
          CASE
            ${includeTokens ? "WHEN type_line ILIKE '%Token%' THEN -1" : ''}
            WHEN LOWER(name) = LOWER(@exact_name) THEN 0
            WHEN COALESCE(type_line, '') ~* '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)'
                 AND LOWER(name) = LOWER(@exact_name) THEN 1
            WHEN COALESCE(type_line, '') ~* '(^|[^[:alpha:]])basic[[:space:]]+(snow[[:space:]]+)?land([^[:alpha:]]|\$)' THEN 2
            WHEN LOWER(name) LIKE LOWER(@exact_name) || '%' THEN 3
            ELSE 4
          END,
          name ASC
        '''
          : 'name ASC, set_code ASC';

  final String sql;
  switch (dedupeMode) {
    case CardDedupeMode.identity:
      sql = '''
        $canonicalSetsCte
        SELECT *
        FROM (
          SELECT
            c.id,
            c.scryfall_id,
            c.name,
            c.mana_cost,
            c.type_line,
            $identityColumns
            c.oracle_text,
            c.power,
            c.toughness,
            c.colors,
            c.color_identity,
            c.image_url,
            LOWER(c.set_code) AS set_code,
            c.rarity,
            c.cmc,
            c.is_reserved,
            c.collector_number,
            c.foil
            $setSelect,
            COUNT(*) OVER (
              PARTITION BY $identityExpression
            )::int AS printing_count,
            ROW_NUMBER() OVER (
              PARTITION BY $identityExpression
              ORDER BY $representativeOrder
            ) AS identity_rank
          FROM cards c
          $setJoin
          $whereClause
        ) AS identity_deduped
        WHERE identity_rank = 1
        ORDER BY $resultOrderExpression
        LIMIT @limit OFFSET @offset
      ''';
      break;
    case CardDedupeMode.set:
      sql = '''
        $canonicalSetsCte
        SELECT *
        FROM (
          SELECT DISTINCT ON (c.name, LOWER(c.set_code))
            c.id,
            c.scryfall_id,
            c.name,
            c.mana_cost,
            c.type_line,
            $identityColumns
            c.oracle_text,
            c.power,
            c.toughness,
            c.colors,
            c.color_identity,
            c.image_url,
            LOWER(c.set_code) AS set_code,
            c.rarity,
            c.cmc,
            c.is_reserved,
            c.collector_number,
            c.foil
            $setSelect,
            1::int AS printing_count
          FROM cards c
          $setJoin
          $whereClause
          ORDER BY
            c.name,
            LOWER(c.set_code),
            ${includeSetInfo ? 's.release_date DESC NULLS LAST,' : ''}
            c.id ASC
        ) AS set_deduped
        ORDER BY $resultOrderExpression
        LIMIT @limit OFFSET @offset
      ''';
      break;
    case CardDedupeMode.none:
      sql = '''
        $canonicalSetsCte
        SELECT
          c.*,
          1::int AS printing_count
          $setSelect
        FROM cards c
        $setJoin
        $whereClause
        ORDER BY $orderExpression
        LIMIT @limit OFFSET @offset
      ''';
      break;
  }

  params['limit'] = limit;
  params['offset'] = offset;

  return _QueryBuilder(sql, params);
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  try {
    final result = await pool.execute(
      Sql.named('SELECT to_regclass(@name)::text'),
      parameters: {'name': 'public.$tableName'},
    );
    final value = result.isNotEmpty ? result.first[0] : null;
    return value != null;
  } catch (_) {
    return false;
  }
}
