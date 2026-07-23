import 'package:postgres/postgres.dart';

import 'social_safety_service.dart';

class CommunityEngagementService {
  const CommunityEngagementService(this.pool);

  final Pool pool;

  Future<bool> publicDeckExists(String deckId, {String? viewerUserId}) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT 1
        FROM decks d
        JOIN users u ON u.id = d.user_id
        WHERE d.id = CAST(@deckId AS uuid)
          AND d.is_public = TRUE
          AND d.deleted_at IS NULL
          AND u.deleted_at IS NULL
          AND u.profile_visibility = 'public'
          AND (
            CAST(@viewerUserId AS uuid) IS NULL
            OR NOT EXISTS (
              SELECT 1
              FROM user_blocks b
              WHERE (
                b.blocker_id = CAST(@viewerUserId AS uuid)
                AND b.blocked_id = d.user_id
              ) OR (
                b.blocked_id = CAST(@viewerUserId AS uuid)
                AND b.blocker_id = d.user_id
              )
            )
          )
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'viewerUserId': viewerUserId},
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> listDeckComments({
    required String deckId,
    String? viewerUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          dc.id,
          dc.deck_id,
          dc.user_id,
          dc.body,
          dc.created_at,
          dc.updated_at,
          u.username,
          u.display_name,
          u.avatar_url
        FROM deck_comments dc
        JOIN users u ON u.id = dc.user_id
        WHERE dc.deck_id = CAST(@deckId AS uuid)
          AND dc.status = 'visible'
          AND (
            CAST(@viewerUserId AS uuid) IS NULL
            OR NOT EXISTS (
              SELECT 1
              FROM user_blocks b
              WHERE (
                b.blocker_id = CAST(@viewerUserId AS uuid)
                AND b.blocked_id = dc.user_id
              ) OR (
                b.blocked_id = CAST(@viewerUserId AS uuid)
                AND b.blocker_id = dc.user_id
              )
            )
          )
        ORDER BY dc.created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        'deckId': deckId,
        'viewerUserId': viewerUserId,
        'limit': limit.clamp(1, 100),
        'offset': offset < 0 ? 0 : offset,
      },
    );
    return result.map(_commentRowToJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> createDeckComment({
    required String deckId,
    required String userId,
    required String body,
  }) async {
    final cleanBody = body.trim();
    if (cleanBody.length < 3) {
      throw const FormatException('Comentario muito curto.');
    }
    if (cleanBody.length > 1200) {
      throw const FormatException('Comentario muito longo.');
    }

    final result = await pool.execute(
      Sql.named('''
        INSERT INTO deck_comments (deck_id, user_id, body)
        SELECT d.id, CAST(@userId AS uuid), @body
        FROM decks d
        JOIN users owner ON owner.id = d.user_id
        WHERE d.id = CAST(@deckId AS uuid)
          AND d.is_public = TRUE
          AND d.deleted_at IS NULL
          AND owner.deleted_at IS NULL
          AND owner.profile_visibility = 'public'
          AND NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (
              b.blocker_id = CAST(@userId AS uuid)
              AND b.blocked_id = d.user_id
            ) OR (
              b.blocked_id = CAST(@userId AS uuid)
              AND b.blocker_id = d.user_id
            )
          )
        RETURNING id, deck_id, user_id, body, created_at, updated_at
      '''),
      parameters: {'deckId': deckId, 'userId': userId, 'body': cleanBody},
    );
    if (result.isEmpty) {
      throw const SocialSafetyException(
        'interaction_blocked',
        'Este deck nao aceita novas interacoes.',
      );
    }
    return _commentRowToJson(result.first);
  }

  Future<bool> deleteDeckComment({
    required String deckId,
    required String commentId,
    required String userId,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        UPDATE deck_comments
        SET status = 'deleted', updated_at = CURRENT_TIMESTAMP
        WHERE id = CAST(@commentId AS uuid)
          AND deck_id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
          AND status <> 'deleted'
        RETURNING id
      '''),
      parameters: {'deckId': deckId, 'commentId': commentId, 'userId': userId},
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>> reportContent({
    required String reporterUserId,
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
  }) async {
    return SocialSafetyService(pool).reportContent(
      reporterUserId: reporterUserId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      details: details,
    );
  }

  Future<Map<String, dynamic>> findTradeMatches({
    required String userId,
    String? deckId,
    int limit = 40,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final includeDeckMissing = deckId != null && deckId.trim().isNotEmpty;
    if (includeDeckMissing &&
        !await _ownsDeck(userId: userId, deckId: deckId)) {
      return {
        'source': 'deck_missing_and_wishlist',
        'matches': <Map<String, dynamic>>[],
        'unmatched': <Map<String, dynamic>>[],
        'message': 'Deck nao encontrado.',
      };
    }

    final wantedSql =
        includeDeckMissing
            ? '''
          WITH owned AS (
            SELECT card_id, COALESCE(SUM(quantity), 0)::int AS owned_quantity
            FROM user_binder_items
            WHERE user_id = CAST(@userId AS uuid)
              AND list_type = 'have'
            GROUP BY card_id
          ),
          wanted AS (
            SELECT
              dc.card_id,
              c.name AS card_name,
              GREATEST(dc.quantity - COALESCE(owned.owned_quantity, 0), 1)::int
                AS wanted_quantity,
              'deck_missing'::text AS source
            FROM deck_cards dc
            JOIN cards c ON c.id = dc.card_id
            LEFT JOIN owned ON owned.card_id = dc.card_id
            WHERE dc.deck_id = CAST(@deckId AS uuid)
              AND COALESCE(owned.owned_quantity, 0) < dc.quantity
            UNION ALL
            SELECT
              bi.card_id,
              c.name AS card_name,
              bi.quantity AS wanted_quantity,
              'wishlist'::text AS source
            FROM user_binder_items bi
            JOIN cards c ON c.id = bi.card_id
            WHERE bi.user_id = CAST(@userId AS uuid)
              AND bi.list_type = 'want'
          )
        '''
            : '''
          WITH wanted AS (
            SELECT
              bi.card_id,
              c.name AS card_name,
              bi.quantity AS wanted_quantity,
              'wishlist'::text AS source
            FROM user_binder_items bi
            JOIN cards c ON c.id = bi.card_id
            WHERE bi.user_id = CAST(@userId AS uuid)
              AND bi.list_type = 'want'
          )
        ''';

    final result = await pool.execute(
      Sql.named('''
        $wantedSql,
        dedup_wanted AS (
          SELECT
            card_id,
            card_name,
            SUM(wanted_quantity)::int AS wanted_quantity,
            ARRAY_AGG(DISTINCT source ORDER BY source) AS sources
          FROM wanted
          GROUP BY card_id, card_name
        )
        SELECT
          w.card_id,
          w.card_name,
          w.wanted_quantity,
          w.sources,
          bi.id AS binder_item_id,
          bi.quantity AS available_quantity,
          bi.condition,
          bi.is_foil,
          bi.for_trade,
          bi.for_sale,
          bi.price,
          bi.currency,
          bi.notes,
          u.id AS owner_id,
          u.username AS owner_username,
          u.display_name AS owner_display_name,
          u.avatar_url AS owner_avatar_url,
          CASE
            WHEN u.location_visibility = 'public' THEN u.location_city
            ELSE NULL
          END AS owner_location_city,
          CASE
            WHEN u.location_visibility = 'public' THEN u.location_state
            ELSE NULL
          END AS owner_location_state
        FROM dedup_wanted w
        JOIN user_binder_items bi ON bi.card_id = w.card_id
        JOIN users u ON u.id = bi.user_id
        WHERE bi.user_id <> CAST(@userId AS uuid)
          AND u.deleted_at IS NULL
          AND u.profile_visibility = 'public'
          AND u.binder_visibility = 'public'
          AND (
            u.trade_visibility = 'everyone'
            OR (
              u.trade_visibility = 'followers'
              AND EXISTS (
                SELECT 1
                FROM user_follows f
                WHERE f.follower_id = CAST(@userId AS uuid)
                  AND f.following_id = u.id
              )
            )
          )
          AND NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (
              b.blocker_id = CAST(@userId AS uuid)
              AND b.blocked_id = u.id
            ) OR (
              b.blocked_id = CAST(@userId AS uuid)
              AND b.blocker_id = u.id
            )
          )
          AND bi.list_type = 'have'
          AND (bi.for_trade = TRUE OR bi.for_sale = TRUE)
        ORDER BY w.card_name ASC, bi.for_trade DESC, bi.price ASC NULLS LAST
        LIMIT @limit
      '''),
      parameters: {
        'userId': userId,
        if (includeDeckMissing) 'deckId': deckId.trim(),
        'limit': safeLimit,
      },
    );

    final matches = result
        .map((row) {
          final m = row.toColumnMap();
          return {
            'card': {'id': m['card_id']?.toString(), 'name': m['card_name']},
            'wanted_quantity': m['wanted_quantity'],
            'sources': _stringList(m['sources']),
            'offer': {
              'binder_item_id': m['binder_item_id']?.toString(),
              'quantity': m['available_quantity'],
              'condition': m['condition'],
              'is_foil': m['is_foil'],
              'for_trade': m['for_trade'],
              'for_sale': m['for_sale'],
              'price': _toDouble(m['price']),
              'currency': m['currency'],
              'notes': m['notes'],
            },
            'owner': {
              'id': m['owner_id']?.toString(),
              'username': m['owner_username'],
              'display_name': m['owner_display_name'],
              'avatar_url': m['owner_avatar_url'],
              'location_city': m['owner_location_city'],
              'location_state': m['owner_location_state'],
            },
          };
        })
        .toList(growable: false);

    return {
      'source': includeDeckMissing ? 'deck_missing_and_wishlist' : 'wishlist',
      'deck_id': includeDeckMissing ? deckId.trim() : null,
      'matches': matches,
      'match_count': matches.length,
    };
  }

  Future<bool> _ownsDeck({
    required String userId,
    required String? deckId,
  }) async {
    if (deckId == null || deckId.trim().isEmpty) return false;
    final result = await pool.execute(
      Sql.named('''
        SELECT 1
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        LIMIT 1
      '''),
      parameters: {'deckId': deckId.trim(), 'userId': userId},
    );
    return result.isNotEmpty;
  }

  Map<String, dynamic> _commentRowToJson(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id': m['id']?.toString(),
      'deck_id': m['deck_id']?.toString(),
      'user_id': m['user_id']?.toString(),
      'body': m['body']?.toString() ?? '',
      'created_at': _dateString(m['created_at']),
      'updated_at': _dateString(m['updated_at']),
      if (m.containsKey('username'))
        'author': {
          'id': m['user_id']?.toString(),
          'username': m['username'],
          'display_name': m['display_name'],
          'avatar_url': m['avatar_url'],
        },
    };
  }

  static String? _dateString(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
