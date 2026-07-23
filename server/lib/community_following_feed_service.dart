import 'package:postgres/postgres.dart';

import 'scryfall_image_url.dart';

class CommunityFollowingFeedService {
  const CommunityFollowingFeedService(this.pool);

  final Pool pool;

  Future<Map<String, dynamic>> list({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 50);
    final offset = (safePage - 1) * safeLimit;
    const visibilitySql = '''
      uf.follower_id = @userId
      AND d.is_public = TRUE
      AND d.deleted_at IS NULL
      AND u.deleted_at IS NULL
      AND u.profile_visibility = 'public'
      AND NOT EXISTS (
        SELECT 1
        FROM user_blocks b
        WHERE (b.blocker_id = @userId AND b.blocked_id = d.user_id)
           OR (b.blocker_id = d.user_id AND b.blocked_id = @userId)
      )
    ''';

    final countResult = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM decks d
        JOIN users u ON u.id = d.user_id
        JOIN user_follows uf ON uf.following_id = d.user_id
        WHERE $visibilitySql
      '''),
      parameters: {'userId': userId},
    );
    final total = (countResult.first[0] as int?) ?? 0;

    final result = await pool.execute(
      Sql.named('''
        SELECT
          d.id,
          d.name,
          d.format,
          d.description,
          d.synergy_score,
          d.created_at,
          u.username AS owner_username,
          u.id AS owner_id,
          cmd.commander_name,
          COALESCE(
            cmd.commander_image_url,
            first_card.first_image_url
          ) AS commander_image_url,
          COALESCE(SUM(dc.quantity), 0)::int AS card_count
        FROM decks d
        JOIN users u ON u.id = d.user_id
        JOIN user_follows uf ON uf.following_id = d.user_id
        LEFT JOIN LATERAL (
          SELECT
            c.name AS commander_name,
            c.image_url AS commander_image_url
          FROM deck_cards dc_cmd
          JOIN cards c ON c.id = dc_cmd.card_id
          WHERE dc_cmd.deck_id = d.id
            AND dc_cmd.is_commander = TRUE
          LIMIT 1
        ) cmd ON TRUE
        LEFT JOIN LATERAL (
          SELECT c.image_url AS first_image_url
          FROM deck_cards dc_fc
          JOIN cards c ON c.id = dc_fc.card_id
          WHERE dc_fc.deck_id = d.id
            AND c.image_url IS NOT NULL
            AND c.image_url <> ''
          ORDER BY dc_fc.quantity DESC, c.name
          LIMIT 1
        ) first_card ON TRUE
        LEFT JOIN deck_cards dc ON d.id = dc.deck_id
        WHERE $visibilitySql
        GROUP BY
          d.id,
          u.username,
          u.id,
          cmd.commander_name,
          cmd.commander_image_url,
          first_card.first_image_url
        ORDER BY d.created_at DESC, d.id DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {'userId': userId, 'limit': safeLimit, 'offset': offset},
    );

    final decks = result
        .map((row) {
          final map = row.toColumnMap();
          if (map['created_at'] is DateTime) {
            map['created_at'] =
                (map['created_at'] as DateTime).toUtc().toIso8601String();
          }
          map['commander_image_url'] = normalizeScryfallImageUrl(
            map['commander_image_url']?.toString(),
          );
          return map;
        })
        .toList(growable: false);
    return {
      'data': decks,
      'page': safePage,
      'limit': safeLimit,
      'total': total,
    };
  }
}
