import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// GET /community/binders/:userId → Cartas disponíveis para troca/venda de um usuário
Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
    final offset = (page - 1) * limit;

    // Filtros
    final forTrade = params['for_trade'];
    final forSale = params['for_sale'];

    final whereClauses = <String>[
      'bi.user_id = @userId',
      '(bi.for_trade = TRUE OR bi.for_sale = TRUE)', // Só itens disponíveis
    ];
    final sqlParams = <String, dynamic>{'userId': userId};

    if (forTrade == 'true') {
      whereClauses.add('bi.for_trade = TRUE');
    }
    if (forSale == 'true') {
      whereClauses.add('bi.for_sale = TRUE');
    }

    final where = whereClauses.join(' AND ');

    // Dados do dono
    final userResult = await pool.execute(Sql.named('''
      SELECT id, username, display_name, avatar_url FROM users WHERE id = @userId
    '''), parameters: {'userId': userId});

    if (userResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Usuário não encontrado'},
      );
    }

    final userRow = userResult.first.toColumnMap();

    // Count
    final countResult = await pool.execute(Sql.named('''
      SELECT COUNT(*) as cnt FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      WHERE $where
    '''), parameters: sqlParams);
    final total = countResult.first[0] as int? ?? 0;

    // Items
    final result = await pool.execute(Sql.named('''
      SELECT bi.id, bi.card_id, bi.quantity, bi.condition, bi.is_foil,
             bi.for_trade, bi.for_sale, bi.price, bi.currency, bi.notes,
             c.name AS card_name, c.image_url AS card_image_url,
             c.set_code AS card_set_code, c.mana_cost AS card_mana_cost,
             c.rarity AS card_rarity
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      WHERE $where
      ORDER BY c.name ASC
      LIMIT @limit OFFSET @offset
    '''), parameters: {...sqlParams, 'limit': limit, 'offset': offset});

    final items = result.map((row) {
      final cols = row.toColumnMap();
      return {
        'id': cols['id'],
        'card': {
          'id': cols['card_id'],
          'name': cols['card_name'],
          'image_url': cols['card_image_url'],
          'set_code': cols['card_set_code'],
          'mana_cost': cols['card_mana_cost'],
          'rarity': cols['card_rarity'],
        },
        'quantity': cols['quantity'],
        'condition': cols['condition'],
        'is_foil': cols['is_foil'],
        'for_trade': cols['for_trade'],
        'for_sale': cols['for_sale'],
        'price': cols['price'] != null
            ? double.tryParse(cols['price'].toString())
            : null,
        'currency': cols['currency'],
        'notes': cols['notes'],
      };
    }).toList();

    return Response.json(body: {
      'owner': {
        'id': userRow['id'],
        'username': userRow['username'],
        'display_name': userRow['display_name'],
        'avatar_url': userRow['avatar_url'],
      },
      'data': items,
      'page': page,
      'limit': limit,
      'total': total,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar binder público: $e'},
    );
  }
}
