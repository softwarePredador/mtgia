import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/card_identity_support.dart';
import '../../../lib/card_resolution_support.dart';
import '../../../lib/catalog_read_contract.dart';
import '../../../lib/scryfall_image_url.dart';

/// POST /cards/resolve
///
/// Resolve um nome de carta contra o catálogo local, somente leitura
/// (BT-CAT-02, decisão D-35 do dono): nome exato, depois prefixo ou trecho
/// único; nome ambíguo responde 409 com os candidatos. Carta ausente responde
/// 404 `card_not_in_catalog` com frase em português. A rota nunca chama a
/// Scryfall nem grava no banco; carta nova entra pelo job de dado de
/// referência (BT-CAT-01).
///
/// Body: { "name": "Lightning Bolt", "include_tokens": false }
/// Response 200: { "source": "local", "name": ..., "data": [...] }
/// Response 404: { "error": "card_not_in_catalog", "message": ..., "name": ... }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final pool = context.read<Pool>();

  // Parse body
  final bodyStr = await context.request.body();
  if (bodyStr.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Body vazio. Envie {"name": "Card Name"}'},
    );
  }

  Map<String, dynamic> body;
  try {
    body = jsonDecode(bodyStr) as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'JSON inválido'},
    );
  }

  final name = (body['name'] as String?)?.trim();
  if (name == null || name.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Campo "name" é obrigatório'},
    );
  }
  final includeTokens = _parseBool(body['include_tokens']);
  final hasIdentityColumns = await hasCardIdentityColumns(pool);

  try {
    // ─── 1) Busca local (nome exato, case-insensitive) ───
    final localExact = await _searchLocal(
      pool,
      name,
      exact: true,
      includeTokens: includeTokens,
      hasIdentityColumns: hasIdentityColumns,
    );
    if (localExact.isNotEmpty) {
      return Response.json(
        body: {
          'source': 'local',
          'name': localExact.first['name'],
          'total_returned': localExact.length,
          'data': localExact,
        },
      );
    }

    // Token OCR must not resolve to a normal card with a similar name.
    if (includeTokens) {
      return cardNotInCatalogResponse(name);
    }

    // ─── 2) Busca local com resolução controlada (prefix/contains únicos) ───
    final localDecision = await _resolveLocalCandidate(pool, name);
    if (localDecision.isResolved) {
      final localFuzzy = await _searchLocal(
        pool,
        localDecision.matchedName!,
        exact: true,
        hasIdentityColumns: hasIdentityColumns,
      );
      return Response.json(
        body: {
          'source': 'local',
          'name': localFuzzy.first['name'],
          'total_returned': localFuzzy.length,
          'resolution': {
            'input_name': name,
            'matched_name': localDecision.matchedName,
            'strategy': localDecision.strategy,
          },
          'data': localFuzzy,
        },
      );
    }

    if (localDecision.isAmbiguous) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'Nome de carta ambiguo. Refine a busca antes de continuar.',
          'input_name': name,
          'candidates': localDecision.candidateNames,
        },
      );
    }

    // ─── 3) Carta ausente: sem Scryfall e sem escrita (D-35) ───
    return cardNotInCatalogResponse(name);
  } catch (e) {
    print('[ERROR] Erro ao resolver carta: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao resolver carta'},
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// Busca local no PostgreSQL
// ───────────────────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> _searchLocal(
  Pool pool,
  String name, {
  required bool exact,
  bool includeTokens = false,
  required bool hasIdentityColumns,
}) async {
  final hasSets = await _hasTable(pool, 'sets');
  final identityColumns = cardIdentitySelectSql('c', hasIdentityColumns);

  final condition =
      exact ? 'LOWER(c.name) = LOWER(@name)' : 'c.name ILIKE @name';
  final tokenCondition =
      includeTokens ? " AND c.type_line ILIKE '%Token%'" : '';
  final paramValue = exact ? name : '%$name%';

  final sql =
      hasSets
          ? '''
    SELECT
      c.id::text, c.scryfall_id::text, c.name, c.mana_cost, c.type_line,
      $identityColumns
      c.oracle_text, c.power, c.toughness,
      c.colors, c.color_identity, c.image_url, c.set_code,
      s.name AS set_name, s.release_date AS set_release_date,
      c.rarity, c.is_reserved, COALESCE(c.price_usd, c.price) AS price,
      c.price_source, c.price_updated_at,
      c.collector_number, c.foil
    FROM cards c
    LEFT JOIN sets s ON s.code = c.set_code
    WHERE $condition$tokenCondition
    ORDER BY s.release_date DESC NULLS LAST, c.set_code ASC
    LIMIT 50
  '''
          : '''
    SELECT
      c.id::text, c.scryfall_id::text, c.name, c.mana_cost, c.type_line,
      $identityColumns
      c.oracle_text, c.power, c.toughness,
      c.colors, c.color_identity, c.image_url, c.set_code,
      c.rarity, c.is_reserved, COALESCE(c.price_usd, c.price) AS price,
      c.price_source, c.price_updated_at,
      c.collector_number, c.foil
    FROM cards c
    WHERE $condition$tokenCondition
    ORDER BY c.set_code ASC
    LIMIT 50
  ''';

  final result = await pool.execute(
    Sql.named(sql),
    parameters: {'name': paramValue},
  );

  return result.map((row) {
    final m = row.toColumnMap();
    return {
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
      'image_url': normalizeScryfallImageUrl(
        m['image_url']?.toString(),
        printingId: m['scryfall_id']?.toString(),
        oracleId: m['oracle_id']?.toString(),
      ),
      'set_code': m['set_code'],
      if (m.containsKey('set_name')) 'set_name': m['set_name'],
      if (m.containsKey('set_release_date'))
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
}

Future<CardResolutionDecision> _resolveLocalCandidate(
  Pool pool,
  String inputName,
) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT candidate_name
      FROM (
        SELECT DISTINCT ON (c.name)
          c.name AS candidate_name,
          CASE
            WHEN LOWER(c.name) = LOWER(@name) THEN 0
            WHEN LOWER(c.name) LIKE LOWER(@name) || '%' THEN 1
            ELSE 2
          END AS rank
        FROM cards c
        WHERE c.name ILIKE '%' || @name || '%'
        ORDER BY c.name, rank ASC, c.id ASC
      ) ranked
      ORDER BY rank ASC, candidate_name ASC
      LIMIT 5
    '''),
    parameters: {'name': inputName},
  );

  final candidateNames =
      result
          .map((row) => (row[0] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

  return resolveCardCandidateNames(inputName, candidateNames);
}

bool _parseBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

// ───────────────────────────────────────────────────────────────────────────────
// Helpers
// ───────────────────────────────────────────────────────────────────────────────

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
