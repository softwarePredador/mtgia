import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/card_identity_support.dart';
import '../../../lib/scryfall_image_url.dart';

/// GET /cards/printings?name=<nome>[&limit=N][&dedupe=false]
///
/// Somente leitura (BT-CAT-04, decisão D-35 do dono): a rota consulta o
/// catálogo local e nunca escreve no banco nem chama a Scryfall. O antigo
/// `sync=true` não dispara mais nada; o parâmetro é ignorado. O catálogo é
/// atualizado só pelo job interno de dado de referência (BT-CAT-01).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final pool = context.read<Pool>();
  final hasSets = await _hasTable(pool, 'sets');
  final hasIdentityColumns = await hasCardIdentityColumns(pool);

  final params = context.request.uri.queryParameters;
  final name = params['name']?.trim();
  final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
  final safeLimit = limit.clamp(1, 200);
  final deduplicate = params['dedupe']?.toLowerCase() != 'false';

  if (name == null || name.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'name é obrigatório'},
    );
  }

  final data = await _queryPrintings(
    pool,
    name,
    safeLimit,
    hasSets,
    hasIdentityColumns,
    deduplicate: deduplicate,
  );

  return Response.json(
    body: {'name': name, 'total_returned': data.length, 'data': data},
  );
}

/// Faz a query de printings no banco local
/// Usa DISTINCT ON para retornar apenas uma carta por set_code (deduplica variantes)
Future<List<Map<String, dynamic>>> _queryPrintings(
  Pool pool,
  String name,
  int limit,
  bool hasSets,
  bool hasIdentityColumns, {
  required bool deduplicate,
}) async {
  // Usamos DISTINCT ON (LOWER(c.set_code)) para deduplicar variantes do mesmo set
  // Isso garante que cada edição apareça apenas uma vez no seletor
  final String sql;
  final identityColumns = cardIdentitySelectSql('c', hasIdentityColumns);

  if (!deduplicate) {
    sql =
        hasSets
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
      SELECT
        c.id::text,
        c.scryfall_id::text,
        $identityColumns
        c.name,
        c.mana_cost,
        c.type_line,
        c.oracle_text,
        c.power,
        c.toughness,
        c.colors,
        c.color_identity,
        c.image_url,
        LOWER(c.set_code) AS set_code,
        s.name AS set_name,
        s.release_date AS set_release_date,
        c.rarity,
        c.is_reserved,
        COALESCE(c.price_usd, c.price) AS price,
        c.price_source,
        c.price_updated_at,
        c.collector_number,
        c.foil
      FROM cards c
      LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
      WHERE LOWER(c.name) = LOWER(@name)
      ORDER BY s.release_date DESC NULLS LAST,
        LOWER(c.set_code) ASC,
        c.collector_number ASC NULLS LAST,
        c.foil DESC NULLS LAST
      LIMIT @limit
    '''
            : '''
      SELECT
        c.id::text,
        c.scryfall_id::text,
        $identityColumns
        c.name,
        c.mana_cost,
        c.type_line,
        c.oracle_text,
        c.power,
        c.toughness,
        c.colors,
        c.color_identity,
        c.image_url,
        LOWER(c.set_code) AS set_code,
        c.rarity,
        c.is_reserved,
        COALESCE(c.price_usd, c.price) AS price,
        c.price_source,
        c.price_updated_at,
        c.collector_number,
        c.foil
      FROM cards c
      WHERE LOWER(c.name) = LOWER(@name)
      ORDER BY LOWER(c.set_code) ASC,
        c.collector_number ASC NULLS LAST,
        c.foil DESC NULLS LAST
      LIMIT @limit
    ''';
  } else if (hasSets) {
    sql = '''
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
      SELECT * FROM (
        SELECT DISTINCT ON (LOWER(c.set_code))
          c.id::text,
          c.scryfall_id::text,
          $identityColumns
          c.name,
          c.mana_cost,
          c.type_line,
          c.oracle_text,
          c.power,
          c.toughness,
          c.colors,
          c.color_identity,
          c.image_url,
          LOWER(c.set_code) AS set_code,
          s.name AS set_name,
          s.release_date AS set_release_date,
          c.rarity,
          c.is_reserved,
          COALESCE(c.price_usd, c.price) AS price,
          c.price_source,
          c.price_updated_at,
          c.collector_number,
          c.foil
        FROM cards c
        LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
        WHERE LOWER(c.name) = LOWER(@name)
        ORDER BY LOWER(c.set_code), s.release_date DESC NULLS LAST
      ) AS deduplicated
      ORDER BY set_release_date DESC NULLS LAST, set_code ASC
      LIMIT @limit
    ''';
  } else {
    sql = '''
      SELECT * FROM (
        SELECT DISTINCT ON (LOWER(c.set_code))
          c.id::text,
          c.scryfall_id::text,
          $identityColumns
          c.name,
          c.mana_cost,
          c.type_line,
          c.oracle_text,
          c.power,
          c.toughness,
          c.colors,
          c.color_identity,
          c.image_url,
          LOWER(c.set_code) AS set_code,
          c.rarity,
          c.is_reserved,
          COALESCE(c.price_usd, c.price) AS price,
          c.price_source,
          c.price_updated_at,
          c.collector_number,
          c.foil
        FROM cards c
        WHERE LOWER(c.name) = LOWER(@name)
        ORDER BY LOWER(c.set_code)
      ) AS deduplicated
      ORDER BY set_code ASC
      LIMIT @limit
    ''';
  }

  final result = await pool.execute(
    Sql.named(sql),
    parameters: {'name': name, 'limit': limit},
  );

  final data =
      result.map((row) {
        final m = row.toColumnMap();
        final imageUrl = normalizeScryfallImageUrl(
          m['image_url']?.toString(),
          printingId: m['scryfall_id']?.toString(),
          oracleId: m['oracle_id']?.toString(),
        );
        return <String, dynamic>{
          'id': m['id'],
          'scryfall_id': m['scryfall_id'],
          'oracle_id': m['oracle_id'],
          'layout': m['layout'],
          'card_faces': m['card_faces_json'],
          'name': m['name'],
          'mana_cost': m['mana_cost'],
          'type_line': m['type_line'],
          'oracle_text': m['oracle_text'],
          'power': m['power'],
          'toughness': m['toughness'],
          'colors': m['colors'],
          'color_identity': m['color_identity'],
          'image_url': imageUrl,
          'set_code': m['set_code'],
          if (hasSets) 'set_name': m['set_name'],
          if (hasSets)
            'set_release_date':
                (m['set_release_date'] as DateTime?)
                    ?.toIso8601String()
                    .split('T')
                    .first,
          'rarity': m['rarity'],
          'is_reserved': m['is_reserved'] == true,
          'price': m['price'],
          'price_currency': 'USD',
          'price_source':
              m['price_source'] ?? (m['price'] == null ? null : 'legacy'),
          'price_updated_at':
              (m['price_updated_at'] as DateTime?)?.toIso8601String(),
          'collector_number': m['collector_number'],
          'foil': m['foil'],
        };
      }).toList();

  return data;
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
