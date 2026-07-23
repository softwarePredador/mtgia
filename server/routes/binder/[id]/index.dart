import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/binder_item_contract.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// PUT /binder/:id  → Atualiza item do binder
/// DELETE /binder/:id → Remove item do binder
/// GET /binder/stats → Estatísticas (caso especial, id == "stats")
Future<Response> onRequest(RequestContext context, String id) async {
  // Caso especial: /binder/stats é capturado aqui como id="stats"
  if (id == 'stats') return _getStats(context);
  if (id == 'availability') return _getAvailability(context);

  final method = context.request.method;
  if (method == HttpMethod.put) return _updateBinderItem(context, id);
  if (method == HttpMethod.delete) return _deleteBinderItem(context, id);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// GET /binder/availability?card_ids=<uuid,uuid>
///
/// Returns the authenticated user's playable-identity quantities for every
/// requested printing. Physical printing, language, foil and condition remain
/// binder metadata and never split the playable availability calculation.
Future<Response> _getAvailability(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final rawIds = context.request.uri.queryParameters['card_ids'];
    if (rawIds == null || rawIds.trim().isEmpty) {
      throw const BinderItemInputException(
        'binder_card_ids_required',
        'card_ids é obrigatório.',
      );
    }
    final cardIds = rawIds
        .split(',')
        .map((value) => readBinderCardId(value))
        .toSet()
        .toList(growable: false);
    if (cardIds.length > 100) {
      throw const BinderItemInputException(
        'binder_card_ids_limit_exceeded',
        'Consulte no máximo 100 cartas por vez.',
      );
    }

    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final result = await pool.execute(
      Sql.named('''
        WITH requested AS (
          SELECT
            c.id AS card_id,
            COALESCE(c.oracle_id, c.id) AS playable_card_id
          FROM cards c
          WHERE c.id::text = ANY(@cardIds)
        )
        SELECT
          requested.card_id::text AS card_id,
          requested.playable_card_id::text AS playable_card_id,
          COALESCE(availability.owned_quantity, 0)::int AS owned_quantity,
          COALESCE(availability.allocated_quantity, 0)::int
            AS allocated_quantity,
          COALESCE(availability.committed_trade_quantity, 0)::int
            AS committed_trade_quantity,
          COALESCE(availability.free_quantity, 0)::int AS free_quantity,
          COALESCE(availability.missing_quantity, 0)::int AS missing_quantity
        FROM requested
        LEFT JOIN collection_availability_snapshot availability
          ON availability.user_id = @userId
         AND availability.playable_card_id = requested.playable_card_id
        ORDER BY requested.card_id
      '''),
      parameters: {'cardIds': cardIds, 'userId': userId},
    );

    return Response.json(
      body: {
        'data': result
            .map((row) {
              final values = row.toColumnMap();
              return {
                'card_id': values['card_id'],
                'playable_card_id': values['playable_card_id'],
                'owned_quantity': _toInt(values['owned_quantity']),
                'allocated_quantity': _toInt(values['allocated_quantity']),
                'committed_trade_quantity': _toInt(
                  values['committed_trade_quantity'],
                ),
                'free_quantity': _toInt(values['free_quantity']),
                'missing_quantity': _toInt(values['missing_quantity']),
              };
            })
            .toList(growable: false),
      },
    );
  } on BinderItemInputException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.message, 'code': error.code},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      source: 'binder_item_route',
      extras: {'operation': 'get_binder_availability'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao consultar disponibilidade'},
    );
  }
}

/// GET /binder/stats → Estatísticas do fichário do usuário autenticado
Future<Response> _getStats(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final summaryFuture = pool.execute(
      Sql.named('''
      SELECT
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'have'), 0)::int AS total_items,
        COUNT(DISTINCT bi.card_id) FILTER (WHERE bi.list_type = 'have')::int AS unique_cards,
        COALESCE(SUM(item_availability.available_quantity) FILTER (WHERE bi.list_type = 'have' AND bi.for_trade = TRUE), 0)::int AS for_trade_count,
        COALESCE(SUM(item_availability.available_quantity) FILTER (WHERE bi.list_type = 'have' AND bi.for_sale = TRUE), 0)::int AS for_sale_count,
        SUM(bi.price * bi.quantity) FILTER (
          WHERE bi.list_type = 'have'
            AND bi.price IS NOT NULL
            AND bi.currency = 'BRL'
        ) AS estimated_value_brl,
        SUM(
          CASE
            WHEN bi.price IS NOT NULL AND bi.currency = 'USD'
              THEN bi.price * bi.quantity
            WHEN bi.price IS NULL
              THEN COALESCE(c.price_usd, c.price) * bi.quantity
            ELSE NULL
          END
        ) FILTER (WHERE bi.list_type = 'have') AS estimated_value_usd,
        COALESCE(SUM(bi.quantity) FILTER (
          WHERE bi.list_type = 'have'
            AND (
              (bi.price IS NOT NULL AND bi.currency IN ('BRL', 'USD'))
              OR (bi.price IS NULL AND COALESCE(c.price_usd, c.price) IS NOT NULL)
            )
        ), 0)::int AS priced_copies_count,
        COALESCE(SUM(bi.quantity) FILTER (WHERE bi.list_type = 'want'), 0)::int AS wishlist_count,
        COUNT(DISTINCT bi.card_id) FILTER (WHERE bi.list_type = 'want')::int AS wishlist_unique_cards,
        COALESCE(SUM(bi.quantity) FILTER (
          WHERE bi.list_type = 'have'
            AND bi.price IS NULL
            AND c.price_usd IS NULL
            AND c.price IS NULL
        ), 0)::int AS price_missing_count
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      LEFT JOIN binder_item_availability item_availability
        ON item_availability.binder_item_id = bi.id
      WHERE bi.user_id = @userId
    '''),
      parameters: {'userId': userId},
    );

    final distributionsFuture = pool.execute(
      Sql.named('''
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
    '''),
      parameters: {'userId': userId},
    );

    final setProgressFuture = pool.execute(
      Sql.named('''
      WITH owned AS (
        SELECT
          LOWER(c.set_code) AS set_code,
          COUNT(DISTINCT bi.card_id)::int AS unique_owned,
          COALESCE(SUM(bi.quantity), 0)::int AS quantity_owned,
          SUM(bi.price * bi.quantity) FILTER (
            WHERE bi.price IS NOT NULL AND bi.currency = 'BRL'
          ) AS estimated_value_brl,
          SUM(
            CASE
              WHEN bi.price IS NOT NULL AND bi.currency = 'USD'
                THEN bi.price * bi.quantity
              WHEN bi.price IS NULL
                THEN COALESCE(c.price_usd, c.price) * bi.quantity
              ELSE NULL
            END
          ) AS estimated_value_usd,
          COALESCE(SUM(bi.quantity) FILTER (
            WHERE bi.price IS NOT NULL
               OR COALESCE(c.price_usd, c.price) IS NOT NULL
          ), 0)::int AS priced_copies_count
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
        o.estimated_value_brl,
        o.estimated_value_usd,
        o.priced_copies_count,
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
    '''),
      parameters: {'userId': userId},
    );

    final wishlistFuture = pool.execute(
      Sql.named('''
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
    '''),
      parameters: {'userId': userId},
    );

    final deckUsageFuture = pool.execute(
      Sql.named('''
      WITH binder_identities AS (
        SELECT DISTINCT COALESCE(card.oracle_id, card.id) AS playable_card_id
        FROM user_binder_items binder_item
        JOIN cards card ON card.id = binder_item.card_id
        WHERE binder_item.user_id = @userId
          AND binder_item.list_type = 'have'
      ),
      deck_usage AS (
        SELECT DISTINCT
          deck.id AS deck_id,
          COALESCE(card.oracle_id, card.id) AS playable_card_id
        FROM decks deck
        JOIN deck_cards deck_card ON deck_card.deck_id = deck.id
        JOIN cards card ON card.id = deck_card.card_id
        WHERE deck.user_id = @userId
          AND deck.deleted_at IS NULL
      )
      SELECT
        COUNT(DISTINCT binder.playable_card_id)::int AS cards_used_in_decks,
        COUNT(DISTINCT deck.deck_id)::int AS decks_using_binder_cards
      FROM binder_identities binder
      JOIN deck_usage deck USING (playable_card_id)
    '''),
      parameters: {'userId': userId},
    );

    final availabilityFuture = pool.execute(
      Sql.named('''
      SELECT
        COALESCE(SUM(owned_quantity), 0)::int AS owned_quantity,
        COALESCE(SUM(allocated_quantity), 0)::int AS allocated_quantity,
        COALESCE(SUM(committed_trade_quantity), 0)::int AS committed_trade_quantity,
        COALESCE(SUM(free_quantity), 0)::int AS free_quantity,
        COALESCE(SUM(missing_quantity), 0)::int AS missing_quantity
      FROM collection_availability_snapshot
      WHERE user_id = @userId
    '''),
      parameters: {'userId': userId},
    );

    final results = await Future.wait([
      summaryFuture,
      distributionsFuture,
      setProgressFuture,
      wishlistFuture,
      deckUsageFuture,
      availabilityFuture,
    ]);

    final row = results[0].first.toColumnMap();
    final totalItems = _toInt(row['total_items']);
    final uniqueCards = _toInt(row['unique_cards']);
    final duplicates = totalItems > uniqueCards ? totalItems - uniqueCards : 0;
    final distributions = _mapDistributions(results[1]);
    final setProgress =
        results[2].map((setRow) {
          final cols = setRow.toColumnMap();
          final totalCards = _toInt(cols['total_cards']);
          final uniqueOwned = _toInt(cols['unique_owned']);
          final valueBrl = _toNullableDouble(cols['estimated_value_brl']);
          final valueUsd = _toNullableDouble(cols['estimated_value_usd']);
          final mixedCurrency = valueBrl != null && valueUsd != null;
          return {
            'set_code': cols['set_code'],
            'set_name': cols['set_name'],
            'unique_owned': uniqueOwned,
            'quantity_owned': _toInt(cols['quantity_owned']),
            'total_cards': totalCards,
            'completion_ratio': totalCards > 0 ? uniqueOwned / totalCards : 0.0,
            'estimated_value': mixedCurrency ? null : valueBrl ?? valueUsd,
            'estimated_value_currency':
                mixedCurrency
                    ? null
                    : valueBrl != null
                    ? 'BRL'
                    : valueUsd != null
                    ? 'USD'
                    : null,
            'estimated_value_brl': valueBrl,
            'estimated_value_usd': valueUsd,
            'estimated_value_mixed_currency': mixedCurrency,
            'priced_copies_count': _toInt(cols['priced_copies_count']),
          };
        }).toList();
    final wishlist =
        results[3].map((wishRow) {
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
    final deckUsage =
        results[4].isEmpty
            ? <String, dynamic>{}
            : results[4].first.toColumnMap();
    final availability =
        results[5].isEmpty
            ? <String, dynamic>{}
            : results[5].first.toColumnMap();
    final estimatedValueBrl = _toNullableDouble(row['estimated_value_brl']);
    final estimatedValueUsd = _toNullableDouble(row['estimated_value_usd']);
    final hasMixedCurrencies =
        estimatedValueBrl != null && estimatedValueUsd != null;
    final legacyEstimatedValue =
        hasMixedCurrencies ? null : estimatedValueBrl ?? estimatedValueUsd;
    final legacyEstimatedCurrency =
        hasMixedCurrencies
            ? null
            : estimatedValueBrl != null
            ? 'BRL'
            : estimatedValueUsd != null
            ? 'USD'
            : null;

    return Response.json(
      body: {
        'total_items': totalItems,
        'unique_cards': uniqueCards,
        'duplicate_copies': duplicates,
        'for_trade_count': _toInt(row['for_trade_count']),
        'for_sale_count': _toInt(row['for_sale_count']),
        'estimated_value': legacyEstimatedValue,
        'estimated_value_currency': legacyEstimatedCurrency,
        'estimated_value_brl': estimatedValueBrl,
        'estimated_value_usd': estimatedValueUsd,
        'estimated_value_mixed_currency': hasMixedCurrencies,
        'priced_copies_count': _toInt(row['priced_copies_count']),
        'wishlist_count': _toInt(row['wishlist_count']),
        'wishlist_unique_cards': _toInt(row['wishlist_unique_cards']),
        'missing_cards_count': wishlist.fold<int>(
          0,
          (sum, item) => sum + (item['missing_quantity'] as int? ?? 0),
        ),
        'price_missing_count': _toInt(row['price_missing_count']),
        'cards_used_in_decks': _toInt(deckUsage['cards_used_in_decks']),
        'decks_using_binder_cards': _toInt(
          deckUsage['decks_using_binder_cards'],
        ),
        'owned_quantity': _toInt(availability['owned_quantity']),
        'allocated_quantity': _toInt(availability['allocated_quantity']),
        'committed_trade_quantity': _toInt(
          availability['committed_trade_quantity'],
        ),
        'free_quantity': _toInt(availability['free_quantity']),
        'deck_missing_quantity': _toInt(availability['missing_quantity']),
        'set_progress': setProgress,
        'wishlist': wishlist,
        'distributions': distributions,
      },
    );
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

double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
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
    final decoded = await context.request.json();
    if (decoded is! Map<String, dynamic>) {
      throw const BinderItemInputException(
        'binder_body_invalid',
        'Corpo da requisição inválido.',
      );
    }
    final body = decoded;

    // Build dynamic SET
    final setClauses = <String>['updated_at = CURRENT_TIMESTAMP'];
    final params = <String, dynamic>{'id': id, 'userId': userId};

    if (body.containsKey('quantity')) {
      final qty = readBinderQuantity(body['quantity']);
      setClauses.add('quantity = @quantity');
      params['quantity'] = qty;
    }

    if (body.containsKey('condition')) {
      final cond = readBinderCondition(body['condition']);
      setClauses.add('condition = @condition');
      params['condition'] = cond;
    }

    if (body.containsKey('is_foil')) {
      setClauses.add('is_foil = @isFoil');
      params['isFoil'] = readBinderBoolean(body['is_foil']);
    }

    if (body.containsKey('for_trade')) {
      setClauses.add('for_trade = @forTrade');
      params['forTrade'] = readBinderBoolean(body['for_trade']);
    }

    if (body.containsKey('for_sale')) {
      setClauses.add('for_sale = @forSale');
      params['forSale'] = readBinderBoolean(body['for_sale']);
    }

    if (body.containsKey('price')) {
      setClauses.add('price = @price');
      params['price'] = readBinderPrice(body['price']);
    }

    if (body.containsKey('notes')) {
      setClauses.add('notes = @notes');
      params['notes'] = readBinderNotes(body['notes']);
    }

    if (body.containsKey('language')) {
      setClauses.add('language = @language');
      params['language'] = readBinderLanguage(body['language']);
    }

    if (body.containsKey('list_type')) {
      final lt = readBinderListType(body['list_type']);
      setClauses.add('list_type = @listType');
      params['listType'] = lt;
    }

    return pool.runTx((transaction) async {
      final locked = await transaction.execute(
        Sql.named('''
          SELECT id, quantity, condition, is_foil, language, list_type
          FROM user_binder_items
          WHERE id = @id AND user_id = @userId
          FOR UPDATE
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      if (locked.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Item não encontrado ou não pertence a você'},
        );
      }

      final committedResult = await transaction.execute(
        Sql.named('''
          SELECT COALESCE(SUM(trade_item.quantity), 0)::int
          FROM trade_items trade_item
          JOIN trade_offers trade
            ON trade.id = trade_item.trade_offer_id
          WHERE trade_item.binder_item_id = @id
            AND trade_item.owner_id = @userId
            AND trade.status IN (
              'pending', 'accepted', 'shipped', 'delivered', 'disputed'
            )
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      final committedQuantity = _toInt(committedResult.first[0]);
      final current = locked.first.toColumnMap();
      final physicalIdentityChanged =
          (body.containsKey('condition') &&
              params['condition'] != current['condition']) ||
          (body.containsKey('is_foil') &&
              params['isFoil'] != current['is_foil']) ||
          (body.containsKey('language') &&
              params['language'] != current['language']) ||
          (body.containsKey('list_type') &&
              params['listType'] != current['list_type']);
      if (committedQuantity > 0 && physicalIdentityChanged) {
        return _binderCommitmentConflict(committedQuantity);
      }
      if (params['quantity'] case final int quantity
          when quantity < committedQuantity) {
        return _binderCommitmentConflict(committedQuantity);
      }

      await transaction.execute(
        Sql.named('''
          UPDATE user_binder_items
          SET ${setClauses.join(', ')}
          WHERE id = @id AND user_id = @userId
        '''),
        parameters: params,
      );
      return Response.json(body: {'message': 'Item atualizado', 'id': id});
    });
  } on BinderItemInputException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.message, 'code': error.code},
    );
  } on ServerException catch (error, stackTrace) {
    if (error.code == '23505') {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'Esta cópia física já existe no fichário.',
          'code': 'binder_item_identity_conflict',
        },
      );
    }
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      source: 'binder_item_route',
      extras: {'operation': 'update_binder_item', 'binder_item_id': id},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao atualizar item'},
    );
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

    return pool.runTx((transaction) async {
      final locked = await transaction.execute(
        Sql.named('''
          SELECT id
          FROM user_binder_items
          WHERE id = @id AND user_id = @userId
          FOR UPDATE
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      if (locked.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Item não encontrado ou não pertence a você'},
        );
      }

      final committedResult = await transaction.execute(
        Sql.named('''
          SELECT COALESCE(SUM(trade_item.quantity), 0)::int
          FROM trade_items trade_item
          JOIN trade_offers trade
            ON trade.id = trade_item.trade_offer_id
          WHERE trade_item.binder_item_id = @id
            AND trade_item.owner_id = @userId
            AND trade.status IN (
              'pending', 'accepted', 'shipped', 'delivered', 'disputed'
            )
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      final committedQuantity = _toInt(committedResult.first[0]);
      if (committedQuantity > 0) {
        return _binderCommitmentConflict(committedQuantity);
      }

      await transaction.execute(
        Sql.named('''
          DELETE FROM user_binder_items
          WHERE id = @id AND user_id = @userId
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      return Response(statusCode: HttpStatus.noContent);
    });
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

Response _binderCommitmentConflict(int committedQuantity) => Response.json(
  statusCode: HttpStatus.conflict,
  body: {
    'error':
        'A cópia possui quantidade comprometida em uma troca ativa. '
        'Conclua ou cancele a troca antes de alterar a identidade ou remover.',
    'code': 'binder_item_committed',
    'committed_trade_quantity': committedQuantity,
  },
);
