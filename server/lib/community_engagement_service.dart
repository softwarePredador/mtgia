import 'package:postgres/postgres.dart';

import 'scryfall_image_url.dart';
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
          WITH deck_demand AS (
            SELECT
              COALESCE(c.oracle_id, c.id) AS playable_card_id,
              MIN(c.name) AS card_name,
              COALESCE(SUM(dc.quantity), 0)::int AS required_quantity
            FROM deck_cards dc
            JOIN cards c ON c.id = dc.card_id
            WHERE dc.deck_id = CAST(@deckId AS uuid)
            GROUP BY COALESCE(c.oracle_id, c.id)
          ),
          owned AS (
            SELECT
              COALESCE(c.oracle_id, c.id) AS playable_card_id,
              COALESCE(SUM(bi.quantity), 0)::int AS owned_quantity
            FROM user_binder_items bi
            JOIN cards c ON c.id = bi.card_id
            WHERE bi.user_id = CAST(@userId AS uuid)
              AND bi.list_type = 'have'
            GROUP BY COALESCE(c.oracle_id, c.id)
          ),
          wanted AS (
            SELECT
              demand.playable_card_id,
              demand.card_name,
              GREATEST(
                demand.required_quantity - COALESCE(owned.owned_quantity, 0),
                0
              )::int AS wanted_quantity,
              'deck_missing'::text AS source
            FROM deck_demand demand
            LEFT JOIN owned USING (playable_card_id)
            WHERE demand.required_quantity > COALESCE(owned.owned_quantity, 0)
            UNION ALL
            SELECT
              availability.playable_card_id,
              availability.canonical_name AS card_name,
              availability.wanted_missing_quantity AS wanted_quantity,
              'wishlist'::text AS source
            FROM collection_availability_snapshot availability
            WHERE availability.user_id = CAST(@userId AS uuid)
              AND availability.wanted_missing_quantity > 0
          )
        '''
            : '''
          WITH wanted AS (
            SELECT
              availability.playable_card_id,
              availability.canonical_name AS card_name,
              availability.missing_quantity AS wanted_quantity,
              'deck_missing'::text AS source
            FROM collection_availability_snapshot availability
            WHERE availability.user_id = CAST(@userId AS uuid)
              AND availability.missing_quantity > 0
            UNION ALL
            SELECT
              availability.playable_card_id,
              availability.canonical_name AS card_name,
              availability.wanted_missing_quantity AS wanted_quantity,
              'wishlist'::text AS source
            FROM collection_availability_snapshot availability
            WHERE availability.user_id = CAST(@userId AS uuid)
              AND availability.wanted_missing_quantity > 0
          )
        ''';

    final result = await pool.execute(
      Sql.named('''
        $wantedSql,
        dedup_wanted AS (
          SELECT
            playable_card_id,
            MIN(card_name) AS card_name,
            MAX(wanted_quantity)::int AS wanted_quantity,
            ARRAY_AGG(DISTINCT source ORDER BY source) AS sources
          FROM wanted
          GROUP BY playable_card_id
        )
        SELECT
          c.id AS card_id,
          w.card_name,
          w.wanted_quantity,
          w.sources,
          bi.id AS binder_item_id,
          item_availability.available_quantity,
          bi.condition,
          bi.is_foil,
          bi.language,
          bi.for_trade,
          bi.for_sale,
          bi.price,
          bi.currency,
          bi.notes,
          bi.updated_at AS offer_updated_at,
          c.image_url AS card_image_url,
          c.scryfall_id::text AS card_scryfall_id,
          c.oracle_id::text AS card_oracle_id,
          c.layout AS card_layout,
          c.card_faces_json AS card_faces,
          c.set_code AS card_set_code,
          c.collector_number AS card_collector_number,
          c.mana_cost AS card_mana_cost,
          c.rarity AS card_rarity,
          c.type_line AS card_type_line,
          c.is_reserved AS card_is_reserved,
          card_set.name AS card_set_name,
          card_set.release_date AS card_set_release_date,
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
        JOIN cards c
          ON COALESCE(c.oracle_id, c.id) = w.playable_card_id
        JOIN user_binder_items bi ON bi.card_id = c.id
        JOIN binder_item_availability item_availability
          ON item_availability.binder_item_id = bi.id
        JOIN users u ON u.id = bi.user_id
        LEFT JOIN LATERAL (
          SELECT s.name, s.release_date
          FROM sets s
          WHERE LOWER(s.code) = LOWER(c.set_code)
          ORDER BY s.release_date DESC NULLS LAST, s.code
          LIMIT 1
        ) card_set ON TRUE
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
          AND item_availability.available_quantity > 0
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
            'card': {
              'id': m['card_id']?.toString(),
              'name': m['card_name'],
              'image_url': normalizeScryfallImageUrl(
                m['card_image_url']?.toString(),
                printingId: m['card_scryfall_id']?.toString(),
                oracleId: m['card_oracle_id']?.toString(),
              ),
              'scryfall_id': m['card_scryfall_id'],
              'oracle_id': m['card_oracle_id'],
              'layout': m['card_layout'],
              'card_faces': m['card_faces'],
              'set_code': m['card_set_code'],
              'collector_number': m['card_collector_number'],
              'set_name': m['card_set_name'],
              'set_release_date': _dateString(m['card_set_release_date']),
              'mana_cost': m['card_mana_cost'],
              'rarity': m['card_rarity'],
              'type_line': m['card_type_line'],
              'is_reserved': m['card_is_reserved'] == true,
            },
            'wanted_quantity': m['wanted_quantity'],
            'sources': _stringList(m['sources']),
            'offer': {
              'binder_item_id': m['binder_item_id']?.toString(),
              'quantity': m['available_quantity'],
              'condition': m['condition'],
              'is_foil': m['is_foil'],
              'language': m['language'],
              'for_trade': m['for_trade'],
              'for_sale': m['for_sale'],
              'price': _toDouble(m['price']),
              'currency': m['currency'],
              'notes': m['notes'],
              'updated_at': _dateString(m['offer_updated_at']),
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
      'source':
          includeDeckMissing
              ? 'deck_missing_and_wishlist'
              : 'all_deck_missing_and_wishlist',
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
