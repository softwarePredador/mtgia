import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/binder_item_contract.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';

/// GET /binder  → Lista itens do binder do usuário autenticado
/// POST /binder → Adiciona carta ao binder
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _listBinder(context);
  if (method == HttpMethod.post) return _addToBinder(context);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// GET /binder?page=1&limit=20&condition=NM&for_trade=true&for_sale=true&search=...
Future<Response> _listBinder(RequestContext context) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
    final offset = (page - 1) * limit;
    final condition = params['condition'];
    final forTrade = params['for_trade'];
    final forSale = params['for_sale'];
    final search = params['search'];
    final listType = params['list_type']; // 'have' or 'want'
    final setCode = params['set'];
    final rarity = params['rarity'];
    final language = params['language'];
    final foil = params['foil'] ?? params['is_foil'];
    final minPrice = double.tryParse(params['min_price'] ?? '');
    final maxPrice = double.tryParse(params['max_price'] ?? '');
    final sort = _normalizeSort(params['sort']);
    final direction = _normalizeDirection(params['order']);

    // Build dynamic WHERE
    final whereClauses = <String>['bi.user_id = @userId'];
    final sqlParams = <String, dynamic>{'userId': userId};

    if (listType != null && (listType == 'have' || listType == 'want')) {
      whereClauses.add('bi.list_type = @listType');
      sqlParams['listType'] = listType;
    }

    if (condition != null && condition.isNotEmpty) {
      whereClauses.add('bi.condition = @condition');
      sqlParams['condition'] = condition;
    }
    if (forTrade == 'true') {
      whereClauses.add('bi.for_trade = TRUE');
    }
    if (forSale == 'true') {
      whereClauses.add('bi.for_sale = TRUE');
    }
    if (search != null && search.isNotEmpty) {
      whereClauses.add('LOWER(c.name) LIKE LOWER(@search)');
      sqlParams['search'] = '%$search%';
    }
    if (setCode != null && setCode.isNotEmpty) {
      whereClauses.add('LOWER(c.set_code) = LOWER(@setCode)');
      sqlParams['setCode'] = setCode;
    }
    if (rarity != null && rarity.isNotEmpty) {
      whereClauses.add('LOWER(c.rarity) = LOWER(@rarity)');
      sqlParams['rarity'] = rarity;
    }
    if (language != null && language.isNotEmpty) {
      whereClauses.add('LOWER(bi.language) = LOWER(@language)');
      sqlParams['language'] = language;
    }
    if (foil == 'true' || foil == 'false') {
      whereClauses.add('bi.is_foil = @isFoil');
      sqlParams['isFoil'] = foil == 'true';
    }
    if (minPrice != null) {
      whereClauses.add('COALESCE(bi.price, c.price_usd, c.price) >= @minPrice');
      sqlParams['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      whereClauses.add('COALESCE(bi.price, c.price_usd, c.price) <= @maxPrice');
      sqlParams['maxPrice'] = maxPrice;
    }

    final where = whereClauses.join(' AND ');
    final orderBy = _orderBySql(sort, direction);

    // Count total
    final countFuture = pool.execute(
      Sql.named('''
      SELECT COUNT(*) as cnt
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      WHERE $where
    '''),
      parameters: sqlParams,
    );

    // Fetch items
    final itemsFuture = pool.execute(
      Sql.named('''
      WITH deck_usage AS (
        SELECT
          COALESCE(deck_card.oracle_id, deck_card.id) AS playable_card_id,
          COUNT(DISTINCT d.id)::int AS deck_count,
          COALESCE(SUM(dc.quantity), 0)::int AS deck_quantity
        FROM deck_cards dc
        JOIN decks d ON d.id = dc.deck_id
        JOIN cards deck_card ON deck_card.id = dc.card_id
        WHERE d.user_id = @userId
          AND d.deleted_at IS NULL
        GROUP BY COALESCE(deck_card.oracle_id, deck_card.id)
      )
      SELECT bi.id, bi.card_id, bi.quantity, bi.condition, bi.is_foil,
              bi.for_trade, bi.for_sale, bi.price, bi.currency,
              bi.notes, bi.language, bi.list_type, bi.created_at, bi.updated_at,
              c.name AS card_name, c.image_url AS card_image_url,
              c.set_code AS card_set_code, c.mana_cost AS card_mana_cost,
              c.type_line AS card_type_line, c.rarity AS card_rarity,
              c.is_reserved AS card_is_reserved,
              COALESCE(c.price_usd, c.price) AS card_market_price,
              c.price_source AS card_market_price_source,
              c.price_updated_at AS card_market_price_updated_at,
              COALESCE(du.deck_count, 0)::int AS deck_count,
              COALESCE(du.deck_quantity, 0)::int AS deck_quantity,
              availability.playable_card_id,
              COALESCE(availability.owned_quantity, 0)::int AS owned_quantity,
              COALESCE(availability.allocated_quantity, 0)::int AS allocated_quantity,
              COALESCE(availability.committed_trade_quantity, 0)::int AS committed_trade_quantity,
              COALESCE(availability.free_quantity, 0)::int AS free_quantity,
              COALESCE(availability.missing_quantity, 0)::int AS missing_quantity,
              COALESCE(item_availability.available_quantity, 0)::int AS available_quantity
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      LEFT JOIN deck_usage du
        ON du.playable_card_id = COALESCE(c.oracle_id, c.id)
      LEFT JOIN collection_availability_snapshot availability
        ON availability.user_id = bi.user_id
       AND availability.playable_card_id = COALESCE(c.oracle_id, c.id)
      LEFT JOIN binder_item_availability item_availability
        ON item_availability.binder_item_id = bi.id
      WHERE $where
      ORDER BY $orderBy
      LIMIT @limit OFFSET @offset
    '''),
      parameters: {...sqlParams, 'limit': limit, 'offset': offset},
    );

    final queryResults = await Future.wait([countFuture, itemsFuture]);
    final countResult = queryResults[0];
    final result = queryResults[1];
    final total = countResult.first[0] as int? ?? 0;

    final items =
        result.map((row) {
          final cols = row.toColumnMap();
          return {
            'id': cols['id'],
            'card': {
              'id': cols['card_id'],
              'name': cols['card_name'],
              'image_url': cols['card_image_url'],
              'set_code': cols['card_set_code'],
              'mana_cost': cols['card_mana_cost'],
              'type_line': cols['card_type_line'],
              'rarity': cols['card_rarity'],
              'is_reserved': cols['card_is_reserved'] == true,
              'market_price':
                  cols['card_market_price'] != null
                      ? double.tryParse(cols['card_market_price'].toString())
                      : null,
              'market_price_currency': 'USD',
              'market_price_source':
                  cols['card_market_price_source'] ??
                  (cols['card_market_price'] == null ? null : 'legacy'),
              'market_price_updated_at':
                  cols['card_market_price_updated_at'] is DateTime
                      ? (cols['card_market_price_updated_at'] as DateTime)
                          .toUtc()
                          .toIso8601String()
                      : cols['card_market_price_updated_at']?.toString(),
            },
            'quantity': cols['quantity'],
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
            'created_at': cols['created_at']?.toString(),
            'updated_at': cols['updated_at']?.toString(),
            'deck_count': cols['deck_count'] ?? 0,
            'deck_quantity': cols['deck_quantity'] ?? 0,
            'used_in_decks': (cols['deck_count'] as int? ?? 0) > 0,
            'playable_card_id': cols['playable_card_id'],
            'owned_quantity': cols['owned_quantity'] ?? 0,
            'allocated_quantity': cols['allocated_quantity'] ?? 0,
            'committed_trade_quantity': cols['committed_trade_quantity'] ?? 0,
            'free_quantity': cols['free_quantity'] ?? 0,
            'missing_quantity': cols['missing_quantity'] ?? 0,
            'available_quantity': cols['available_quantity'] ?? 0,
          };
        }).toList();

    return Response.json(
      body: {'data': items, 'page': page, 'limit': limit, 'total': total},
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'binder_route',
      extras: {'operation': 'list_binder'},
    );
    Log.e('[ERROR] list binder failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao listar binder'},
    );
  }
}

String _normalizeSort(String? value) {
  const supported = {
    'name',
    'set',
    'rarity',
    'condition',
    'language',
    'foil',
    'quantity',
    'price',
    'updated_at',
  };
  final normalized = value?.trim().toLowerCase();
  return supported.contains(normalized) ? normalized! : 'name';
}

String _normalizeDirection(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == 'desc' ? 'DESC' : 'ASC';
}

String _orderBySql(String sort, String direction) {
  final expression = switch (sort) {
    'set' => 'LOWER(c.set_code)',
    'rarity' => 'LOWER(c.rarity)',
    'condition' => 'bi.condition',
    'language' => 'LOWER(bi.language)',
    'foil' => 'bi.is_foil',
    'quantity' => 'bi.quantity',
    'price' => 'COALESCE(bi.price, c.price_usd, c.price)',
    'updated_at' => 'bi.updated_at',
    _ => 'LOWER(c.name)',
  };
  return '$expression $direction NULLS LAST, LOWER(c.name) ASC, bi.condition ASC';
}

/// POST /binder
/// Body: { card_id, quantity?, condition?, is_foil?, for_trade?, for_sale?, price?, notes?, language? }
Future<Response> _addToBinder(RequestContext context) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final decoded = await context.request.json();
    if (decoded is! Map<String, dynamic>) {
      throw const BinderItemInputException(
        'binder_body_invalid',
        'Corpo da requisição inválido.',
      );
    }
    final body = decoded;
    final cardId = readBinderCardId(body['card_id']);

    // Verifica que a carta existe
    final cardCheck = await pool.execute(
      Sql.named('SELECT id FROM cards WHERE id = @cardId'),
      parameters: {'cardId': cardId},
    );
    if (cardCheck.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Carta não encontrada'},
      );
    }

    final quantity = readBinderQuantity(body['quantity']);
    final condition = readBinderCondition(body['condition']);
    final isFoil = readBinderBoolean(body['is_foil']);
    final forTrade = readBinderBoolean(body['for_trade']);
    final forSale = readBinderBoolean(body['for_sale']);
    final price = readBinderPrice(body['price']);
    final notes = readBinderNotes(body['notes']);
    final language = readBinderLanguage(body['language']);
    final listType = readBinderListType(body['list_type']);

    // Insere
    final insertResult = await pool.execute(
      Sql.named('''
      INSERT INTO user_binder_items
        (user_id, card_id, quantity, condition, is_foil, for_trade, for_sale, price, notes, language, list_type)
      VALUES
        (@userId, @cardId, @quantity, @condition, @isFoil, @forTrade, @forSale, @price, @notes, @language, @listType)
      ON CONFLICT (
        user_id, card_id, condition, is_foil, language, list_type
      ) DO NOTHING
      RETURNING id
    '''),
      parameters: {
        'userId': userId,
        'cardId': cardId,
        'quantity': quantity,
        'condition': condition,
        'isFoil': isFoil,
        'forTrade': forTrade,
        'forSale': forSale,
        'price': price,
        'notes': notes,
        'language': language,
        'listType': listType,
      },
    );

    if (insertResult.isEmpty) {
      final existing = await pool.execute(
        Sql.named('''
          SELECT id
          FROM user_binder_items
          WHERE user_id = @userId
            AND card_id = @cardId
            AND condition = @condition
            AND is_foil = @isFoil
            AND language = @language
            AND list_type = @listType
          LIMIT 1
        '''),
        parameters: {
          'userId': userId,
          'cardId': cardId,
          'condition': condition,
          'isFoil': isFoil,
          'language': language,
          'listType': listType,
        },
      );
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'Esta cópia física já existe no fichário.',
          'code': 'binder_item_identity_conflict',
          if (existing.isNotEmpty) 'existing_id': existing.first[0],
        },
      );
    }

    final newId = insertResult.first[0];

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'id': newId,
        'card_id': cardId,
        'quantity': quantity,
        'condition': condition,
        'is_foil': isFoil,
        'for_trade': forTrade,
        'for_sale': forSale,
        'language': language,
        'list_type': listType,
        'message': 'Carta adicionada ao fichário',
      },
    );
  } on BinderItemInputException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.message, 'code': error.code},
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'binder_route',
      extras: {'operation': 'add_binder_item'},
    );
    Log.e('[ERROR] add binder item failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao adicionar ao binder'},
    );
  }
}
