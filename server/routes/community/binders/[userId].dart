import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/community_request_auth.dart';
import '../../../lib/scryfall_image_url.dart';

/// GET /community/binders/:userId → Cartas disponíveis para troca/venda de um usuário
Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final pool = context.read<Pool>();
    final viewerUserId = await readAuthenticatedUserId(context);
    final params = context.request.uri.queryParameters;

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
    final offset = (page - 1) * limit;

    // Filtros
    final forTrade = params['for_trade'];
    final forSale = params['for_sale'];
    final listType = params['list_type']; // 'have', 'want', or null (all)
    final itemId = params['item_id']?.trim();

    if (itemId != null && itemId.isNotEmpty && !_uuidPattern.hasMatch(itemId)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'item_id inválido'},
      );
    }

    final whereClauses = <String>['bi.user_id = @userId'];
    final sqlParams = <String, dynamic>{'userId': userId};

    // Se list_type == 'want', não precisa exigir for_trade/for_sale
    // Se list_type == 'have' (ou null), mostrar só quem marcou disponível
    if (listType == 'want') {
      whereClauses.add("bi.list_type = 'want'");
    } else if (listType == 'have') {
      whereClauses.add("bi.list_type = 'have'");
      whereClauses.add('(bi.for_trade = TRUE OR bi.for_sale = TRUE)');
      whereClauses.add('item_availability.available_quantity > 0');
    } else {
      // Sem filtro de list_type: mostrar disponíveis (have com flag) ou wants
      whereClauses.add(
        "(bi.list_type = 'want' OR ((bi.for_trade = TRUE OR bi.for_sale = TRUE) AND item_availability.available_quantity > 0))",
      );
    }

    if (forTrade == 'true') {
      whereClauses.add('bi.for_trade = TRUE');
    }
    if (forSale == 'true') {
      whereClauses.add('bi.for_sale = TRUE');
    }
    if (itemId != null && itemId.isNotEmpty) {
      whereClauses.add('bi.id = CAST(@itemId AS uuid)');
      sqlParams['itemId'] = itemId;
    }

    final where = whereClauses.join(' AND ');

    // Dados do dono
    final userResult = await pool.execute(
      Sql.named('''
      SELECT
        u.id,
        u.username,
        u.display_name,
        u.avatar_url,
        CASE
          WHEN u.id = CAST(@viewerUserId AS uuid)
            OR u.location_visibility = 'public'
            OR (
              u.location_visibility = 'trade_only'
              AND EXISTS (
                SELECT 1
                FROM trade_offers t
                WHERE (
                  t.sender_id = u.id
                  AND t.receiver_id = CAST(@viewerUserId AS uuid)
                ) OR (
                  t.receiver_id = u.id
                  AND t.sender_id = CAST(@viewerUserId AS uuid)
                )
              )
            )
          THEN u.location_state
          ELSE NULL
        END AS location_state,
        CASE
          WHEN u.id = CAST(@viewerUserId AS uuid)
            OR u.location_visibility = 'public'
            OR (
              u.location_visibility = 'trade_only'
              AND EXISTS (
                SELECT 1
                FROM trade_offers t
                WHERE (
                  t.sender_id = u.id
                  AND t.receiver_id = CAST(@viewerUserId AS uuid)
                ) OR (
                  t.receiver_id = u.id
                  AND t.sender_id = CAST(@viewerUserId AS uuid)
                )
              )
            )
          THEN u.location_city
          ELSE NULL
        END AS location_city,
        CASE
          WHEN u.id = CAST(@viewerUserId AS uuid)
            OR (
              u.trade_notes_visibility = 'trade_only'
              AND EXISTS (
                SELECT 1
                FROM trade_offers t
                WHERE (
                  t.sender_id = u.id
                  AND t.receiver_id = CAST(@viewerUserId AS uuid)
                ) OR (
                  t.receiver_id = u.id
                  AND t.sender_id = CAST(@viewerUserId AS uuid)
                )
              )
            )
          THEN u.trade_notes
          ELSE NULL
        END AS trade_notes
      FROM users u
      WHERE u.id = @userId
        AND u.deleted_at IS NULL
        AND (
          u.binder_visibility = 'public'
          OR u.id = CAST(@viewerUserId AS uuid)
        )
        AND (
          u.profile_visibility = 'public'
          OR u.id = CAST(@viewerUserId AS uuid)
        )
        AND (
          u.id = CAST(@viewerUserId AS uuid)
          OR CAST(@viewerUserId AS uuid) IS NULL
          OR NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (
              b.blocker_id = CAST(@viewerUserId AS uuid)
              AND b.blocked_id = u.id
            ) OR (
              b.blocked_id = CAST(@viewerUserId AS uuid)
              AND b.blocker_id = u.id
            )
          )
        )
    '''),
      parameters: {'userId': userId, 'viewerUserId': viewerUserId},
    );

    if (userResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Usuário não encontrado'},
      );
    }

    final userRow = userResult.first.toColumnMap();

    // Count
    final countResult = await pool.execute(
      Sql.named('''
      SELECT COUNT(*) as cnt FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      LEFT JOIN binder_item_availability item_availability
        ON item_availability.binder_item_id = bi.id
      WHERE $where
    '''),
      parameters: sqlParams,
    );
    final total = countResult.first[0] as int? ?? 0;

    // Items
    final result = await pool.execute(
      Sql.named('''
      WITH canonical_sets AS (
        SELECT DISTINCT ON (LOWER(code))
          code,
          name,
          release_date
        FROM sets
        ORDER BY LOWER(code), release_date DESC NULLS LAST, code
      )
      SELECT bi.id, bi.card_id, bi.created_at, bi.updated_at,
             CASE WHEN bi.list_type = 'have'
               THEN COALESCE(item_availability.available_quantity, 0)
               ELSE bi.quantity
             END::int AS public_quantity,
             bi.condition, bi.is_foil,
             bi.for_trade, bi.for_sale, bi.price, bi.currency, bi.notes,
             bi.language, bi.list_type,
             c.name AS card_name, c.image_url AS card_image_url,
             c.scryfall_id::text AS card_scryfall_id,
             c.oracle_id::text AS card_oracle_id,
             c.layout AS card_layout,
             c.card_faces_json AS card_faces,
             c.set_code AS card_set_code, c.mana_cost AS card_mana_cost,
             c.collector_number AS card_collector_number,
             c.rarity AS card_rarity,
             c.is_reserved AS card_is_reserved,
             s.name AS card_set_name,
             s.release_date AS card_set_release_date
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
      LEFT JOIN binder_item_availability item_availability
        ON item_availability.binder_item_id = bi.id
      WHERE $where
      ORDER BY c.name ASC
      LIMIT @limit OFFSET @offset
    '''),
      parameters: {...sqlParams, 'limit': limit, 'offset': offset},
    );

    final items =
        result.map((row) {
          final cols = row.toColumnMap();
          return {
            'id': cols['id'],
            'card': {
              'id': cols['card_id'],
              'name': cols['card_name'],
              'image_url': normalizeScryfallImageUrl(
                cols['card_image_url']?.toString(),
                printingId: cols['card_scryfall_id']?.toString(),
                oracleId: cols['card_oracle_id']?.toString(),
              ),
              'scryfall_id': cols['card_scryfall_id'],
              'oracle_id': cols['card_oracle_id'],
              'layout': cols['card_layout'],
              'card_faces': cols['card_faces'],
              'set_code': cols['card_set_code'],
              'collector_number': cols['card_collector_number'],
              'set_name': cols['card_set_name'],
              'set_release_date':
                  cols['card_set_release_date'] is DateTime
                      ? (cols['card_set_release_date'] as DateTime)
                          .toIso8601String()
                          .split('T')
                          .first
                      : cols['card_set_release_date']?.toString(),
              'mana_cost': cols['card_mana_cost'],
              'rarity': cols['card_rarity'],
              'is_reserved': cols['card_is_reserved'] == true,
            },
            'quantity': cols['public_quantity'],
            'available_quantity': cols['public_quantity'],
            'condition': cols['condition'],
            'is_foil': cols['is_foil'],
            'for_trade': cols['for_trade'],
            'for_sale': cols['for_sale'],
            'price':
                cols['price'] != null
                    ? double.tryParse(cols['price'].toString())
                    : null,
            'currency': cols['currency'],
            'notes': cols['notes'],
            'language': cols['language'],
            'list_type': cols['list_type'] ?? 'have',
            'created_at': _dateTimeString(cols['created_at']),
            'updated_at': _dateTimeString(cols['updated_at']),
          };
        }).toList();

    return Response.json(
      body: {
        'owner': {
          'id': userRow['id'],
          'username': userRow['username'],
          'display_name': userRow['display_name'],
          'avatar_url': userRow['avatar_url'],
          'location_state': userRow['location_state'],
          'location_city': userRow['location_city'],
          'trade_notes': userRow['trade_notes'],
        },
        'data': items,
        'page': page,
        'limit': limit,
        'total': total,
      },
    );
  } catch (e) {
    print('[ERROR] Erro ao buscar binder público: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar binder público'},
    );
  }
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

String? _dateTimeString(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
