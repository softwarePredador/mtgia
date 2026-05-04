import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// PUT /binder/:id  → Atualiza item do binder
/// DELETE /binder/:id → Remove item do binder
/// GET /binder/stats → Estatísticas (caso especial, id == "stats")
Future<Response> onRequest(RequestContext context, String id) async {
  // Caso especial: /binder/stats é capturado aqui como id="stats"
  if (id == 'stats') return _getStats(context);

  final method = context.request.method;
  if (method == HttpMethod.put) return _updateBinderItem(context, id);
  if (method == HttpMethod.delete) return _deleteBinderItem(context, id);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// GET /binder/stats → Estatísticas do fichário do usuário autenticado
Future<Response> _getStats(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final summaryFuture = pool.execute(Sql.named('''
      SELECT
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'have'), 0)::int AS total_items,
        COUNT(DISTINCT bi.card_id) FILTER (WHERE bi.list_type = 'have')::int AS unique_cards,
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'have' AND bi.for_trade = TRUE), 0)::int AS for_trade_count,
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'have' AND bi.for_sale = TRUE), 0)::int AS for_sale_count,
        COALESCE(
          SUM(
            CASE
              WHEN bi.list_type = 'have'
              THEN COALESCE(bi.price, c.price_usd, c.price, 0) * bi.quantity
              ELSE 0
            END
          ),
          0
        ) AS estimated_value,
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'want'), 0)::int AS wishlist_count,
        COUNT(DISTINCT bi.card_id) FILTER (WHERE bi.list_type = 'want')::int AS wishlist_unique_cards,
        COUNT(*) FILTER (
          WHERE bi.list_type = 'have'
            AND bi.price IS NULL
            AND c.price_usd IS NULL
            AND c.price IS NULL
        )::int AS price_missing_count
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      WHERE bi.user_id = @userId
    '''), parameters: {'userId': userId});

    final distributionsFuture = pool.execute(Sql.named('''
      SELECT
        'rarity' AS type,
        COALESCE(NULLIF(c.rarity, ''), 'unknown') AS label,
        COALESCE(SUM(bi.quantity), 0)::int AS quantity
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      WHERE bi.user_id = @userId AND bi.list_type = 'have'
      GROUP BY COALESCE(NULLIF(c.rarity, ''), 'unknown')
      UNION ALL
      SELECT
        'condition' AS type,
        COALESCE(NULLIF(bi.condition, ''), 'unknown') AS label,
        COALESCE(SUM(bi.quantity), 0)::int AS quantity
      FROM user_binder_items bi
      WHERE bi.user_id = @userId AND bi.list_type = 'have'
      GROUP BY COALESCE(NULLIF(bi.condition, ''), 'unknown')
      UNION ALL
      SELECT
        'language' AS type,
        COALESCE(NULLIF(bi.language, ''), 'unknown') AS label,
        COALESCE(SUM(bi.quantity), 0)::int AS quantity
      FROM user_binder_items bi
      WHERE bi.user_id = @userId AND bi.list_type = 'have'
      GROUP BY COALESCE(NULLIF(bi.language, ''), 'unknown')
      UNION ALL
      SELECT
        'foil' AS type,
        CASE WHEN bi.is_foil THEN 'foil' ELSE 'non_foil' END AS label,
        COALESCE(SUM(bi.quantity), 0)::int AS quantity
      FROM user_binder_items bi
      WHERE bi.user_id = @userId AND bi.list_type = 'have'
      GROUP BY bi.is_foil
      ORDER BY type ASC, quantity DESC, label ASC
    '''), parameters: {'userId': userId});

    final setProgressFuture = pool.execute(Sql.named('''
      WITH owned AS (
        SELECT
          LOWER(c.set_code) AS set_code,
          COUNT(DISTINCT bi.card_id)::int AS unique_owned,
          COALESCE(SUM(bi.quantity), 0)::int AS quantity_owned,
          COALESCE(SUM(COALESCE(bi.price, c.price_usd, c.price, 0) * bi.quantity), 0) AS estimated_value
        FROM user_binder_items bi
        JOIN cards c ON c.id = bi.card_id
        WHERE bi.user_id = @userId
          AND bi.list_type = 'have'
          AND c.set_code IS NOT NULL
          AND c.set_code <> ''
        GROUP BY LOWER(c.set_code)
      ),
      totals AS (
        SELECT
          LOWER(set_code) AS set_code,
          COUNT(DISTINCT LOWER(name))::int AS total_cards
        FROM cards
        WHERE set_code IS NOT NULL AND set_code <> ''
        GROUP BY LOWER(set_code)
      ),
      canonical_sets AS (
        SELECT DISTINCT ON (LOWER(code))
          LOWER(code) AS set_code,
          code,
          name
        FROM sets
        ORDER BY LOWER(code), release_date DESC NULLS LAST, name ASC
      )
      SELECT
        UPPER(o.set_code) AS set_code,
        cs.name AS set_name,
        o.unique_owned,
        o.quantity_owned,
        o.estimated_value,
        COALESCE(t.total_cards, o.unique_owned)::int AS total_cards
      FROM owned o
      LEFT JOIN totals t ON t.set_code = o.set_code
      LEFT JOIN canonical_sets cs ON cs.set_code = o.set_code
      ORDER BY
        CASE WHEN COALESCE(t.total_cards, 0) > 0
          THEN o.unique_owned::numeric / t.total_cards
          ELSE 0
        END DESC,
        o.unique_owned DESC,
        o.quantity_owned DESC
      LIMIT 10
    '''), parameters: {'userId': userId});

    final wishlistFuture = pool.execute(Sql.named('''
      WITH want AS (
        SELECT
          bi.card_id,
          COALESCE(SUM(bi.quantity), 0)::int AS want_quantity
        FROM user_binder_items bi
        WHERE bi.user_id = @userId AND bi.list_type = 'want'
        GROUP BY bi.card_id
      ),
      have AS (
        SELECT
          bi.card_id,
          COALESCE(SUM(bi.quantity), 0)::int AS have_quantity
        FROM user_binder_items bi
        WHERE bi.user_id = @userId AND bi.list_type = 'have'
        GROUP BY bi.card_id
      )
      SELECT
        c.id AS card_id,
        c.name AS card_name,
        c.set_code,
        c.rarity,
        w.want_quantity,
        COALESCE(h.have_quantity, 0)::int AS have_quantity,
        GREATEST(w.want_quantity - COALESCE(h.have_quantity, 0), 0)::int AS missing_quantity
      FROM want w
      JOIN cards c ON c.id = w.card_id
      LEFT JOIN have h ON h.card_id = w.card_id
      ORDER BY missing_quantity DESC, c.name ASC
      LIMIT 10
    '''), parameters: {'userId': userId});

    final deckUsageFuture = pool.execute(Sql.named('''
      SELECT
        COUNT(DISTINCT bi.card_id)::int AS cards_used_in_decks,
        COUNT(DISTINCT d.id)::int AS decks_using_binder_cards
      FROM user_binder_items bi
      JOIN deck_cards dc ON dc.card_id = bi.card_id
      JOIN decks d ON d.id = dc.deck_id
      WHERE bi.user_id = @userId
        AND bi.list_type = 'have'
        AND d.user_id = @userId
        AND d.deleted_at IS NULL
    '''), parameters: {'userId': userId});

    final results = await Future.wait([
      summaryFuture,
      distributionsFuture,
      setProgressFuture,
      wishlistFuture,
      deckUsageFuture,
    ]);

    final row = results[0].first.toColumnMap();
    final totalItems = _toInt(row['total_items']);
    final uniqueCards = _toInt(row['unique_cards']);
    final duplicates = totalItems > uniqueCards ? totalItems - uniqueCards : 0;
    final distributions = _mapDistributions(results[1]);
    final setProgress = results[2].map((setRow) {
      final cols = setRow.toColumnMap();
      final totalCards = _toInt(cols['total_cards']);
      final uniqueOwned = _toInt(cols['unique_owned']);
      return {
        'set_code': cols['set_code'],
        'set_name': cols['set_name'],
        'unique_owned': uniqueOwned,
        'quantity_owned': _toInt(cols['quantity_owned']),
        'total_cards': totalCards,
        'completion_ratio': totalCards > 0 ? uniqueOwned / totalCards : 0.0,
        'estimated_value': _toDouble(cols['estimated_value']),
      };
    }).toList();
    final wishlist = results[3].map((wishRow) {
      final cols = wishRow.toColumnMap();
      return {
        'card_id': cols['card_id'],
        'card_name': cols['card_name'],
        'set_code': cols['set_code'],
        'rarity': cols['rarity'],
        'want_quantity': _toInt(cols['want_quantity']),
        'have_quantity': _toInt(cols['have_quantity']),
        'missing_quantity': _toInt(cols['missing_quantity']),
      };
    }).toList();
    final deckUsage = results[4].isEmpty
        ? <String, dynamic>{}
        : results[4].first.toColumnMap();

    return Response.json(body: {
      'total_items': totalItems,
      'unique_cards': uniqueCards,
      'duplicate_copies': duplicates,
      'for_trade_count': _toInt(row['for_trade_count']),
      'for_sale_count': _toInt(row['for_sale_count']),
      'estimated_value': _toDouble(row['estimated_value']),
      'wishlist_count': _toInt(row['wishlist_count']),
      'wishlist_unique_cards': _toInt(row['wishlist_unique_cards']),
      'missing_cards_count': wishlist.fold<int>(
        0,
        (sum, item) => sum + (item['missing_quantity'] as int? ?? 0),
      ),
      'price_missing_count': _toInt(row['price_missing_count']),
      'cards_used_in_decks': _toInt(deckUsage['cards_used_in_decks']),
      'decks_using_binder_cards': _toInt(deckUsage['decks_using_binder_cards']),
      'set_progress': setProgress,
      'wishlist': wishlist,
      'distributions': distributions,
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'binder_item_route',
      extras: {'operation': 'get_binder_stats'},
    );
    Log.e('[ERROR] get binder stats failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao calcular estatísticas'},
    );
  }
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

Map<String, List<Map<String, dynamic>>> _mapDistributions(Result rows) {
  final output = <String, List<Map<String, dynamic>>>{
    'rarity': [],
    'condition': [],
    'language': [],
    'foil': [],
  };

  for (final row in rows) {
    final cols = row.toColumnMap();
    final type = cols['type']?.toString();
    if (type == null || !output.containsKey(type)) continue;
    output[type]!.add({
      'label': cols['label']?.toString() ?? 'unknown',
      'quantity': _toInt(cols['quantity']),
    });
  }

  return output;
}

/// PUT /binder/:id
/// Body: { quantity?, condition?, is_foil?, for_trade?, for_sale?, price?, notes?, language? }
Future<Response> _updateBinderItem(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    // Verifica ownership
    final check = await pool.execute(Sql.named('''
      SELECT id FROM user_binder_items WHERE id = @id AND user_id = @userId
    '''), parameters: {'id': id, 'userId': userId});

    if (check.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Item não encontrado ou não pertence a você'},
      );
    }

    // Build dynamic SET
    final setClauses = <String>['updated_at = CURRENT_TIMESTAMP'];
    final params = <String, dynamic>{'id': id, 'userId': userId};

    if (body.containsKey('quantity')) {
      final qty = body['quantity'] as int? ?? 1;
      if (qty < 1) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Quantidade deve ser >= 1'},
        );
      }
      setClauses.add('quantity = @quantity');
      params['quantity'] = qty;
    }

    if (body.containsKey('condition')) {
      final cond = body['condition'] as String;
      if (!['NM', 'LP', 'MP', 'HP', 'DMG'].contains(cond)) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Condição inválida. Use: NM, LP, MP, HP, DMG'},
        );
      }
      setClauses.add('condition = @condition');
      params['condition'] = cond;
    }

    if (body.containsKey('is_foil')) {
      setClauses.add('is_foil = @isFoil');
      params['isFoil'] = body['is_foil'] as bool? ?? false;
    }

    if (body.containsKey('for_trade')) {
      setClauses.add('for_trade = @forTrade');
      params['forTrade'] = body['for_trade'] as bool? ?? false;
    }

    if (body.containsKey('for_sale')) {
      setClauses.add('for_sale = @forSale');
      params['forSale'] = body['for_sale'] as bool? ?? false;
    }

    if (body.containsKey('price')) {
      setClauses.add('price = @price');
      params['price'] = body['price'] != null
          ? double.tryParse(body['price'].toString())
          : null;
    }

    if (body.containsKey('notes')) {
      setClauses.add('notes = @notes');
      params['notes'] = body['notes'] as String?;
    }

    if (body.containsKey('language')) {
      setClauses.add('language = @language');
      params['language'] = body['language'] as String? ?? 'en';
    }

    if (body.containsKey('list_type')) {
      final lt = body['list_type'] as String? ?? 'have';
      if (lt != 'have' && lt != 'want') {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'list_type inválido. Use: have, want'},
        );
      }
      setClauses.add('list_type = @listType');
      params['listType'] = lt;
    }

    await pool.execute(Sql.named('''
      UPDATE user_binder_items
      SET ${setClauses.join(', ')}
      WHERE id = @id AND user_id = @userId
    '''), parameters: params);

    return Response.json(body: {'message': 'Item atualizado', 'id': id});
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'binder_item_route',
      extras: {'operation': 'update_binder_item', 'binder_item_id': id},
    );
    Log.e('[ERROR] update binder item failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao atualizar item'},
    );
  }
}

/// DELETE /binder/:id
Future<Response> _deleteBinderItem(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(Sql.named('''
      DELETE FROM user_binder_items
      WHERE id = @id AND user_id = @userId
      RETURNING id
    '''), parameters: {'id': id, 'userId': userId});

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Item não encontrado ou não pertence a você'},
      );
    }

    return Response(statusCode: HttpStatus.noContent);
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'binder_item_route',
      extras: {'operation': 'delete_binder_item', 'binder_item_id': id},
    );
    Log.e('[ERROR] delete binder item failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao remover item'},
    );
  }
}
