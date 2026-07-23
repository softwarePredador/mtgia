import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  return _getFollowers(context, id);
}

/// GET /users/:id/followers?page=1&limit=20
/// Lista os seguidores de um usuário.
Future<Response> _getFollowers(RequestContext context, String userId) async {
  try {
    final conn = context.read<Pool>();
    final viewerId = context.read<String>();
    final params = context.request.uri.queryParameters;
    final page = int.tryParse(params['page'] ?? '') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '') ?? 20).clamp(1, 50);
    final offset = (page - 1) * limit;

    // Count total followers
    final countResult = await conn.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM user_follows uf
        JOIN users u ON u.id = uf.follower_id
        WHERE uf.following_id = @id
          AND u.deleted_at IS NULL
          AND u.profile_visibility = 'public'
          AND NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (
              b.blocker_id = @viewerId
              AND b.blocked_id = u.id
            ) OR (
              b.blocked_id = @viewerId
              AND b.blocker_id = u.id
            )
          )
          AND EXISTS (
            SELECT 1
            FROM users target
            WHERE target.id = @id
              AND target.deleted_at IS NULL
              AND (
                target.profile_visibility = 'public'
                OR target.id = @viewerId
              )
              AND (
                target.id = @viewerId
                OR NOT EXISTS (
                  SELECT 1
                  FROM user_blocks target_block
                  WHERE (
                    target_block.blocker_id = @viewerId
                    AND target_block.blocked_id = target.id
                  ) OR (
                    target_block.blocked_id = @viewerId
                    AND target_block.blocker_id = target.id
                  )
                )
              )
          )
      '''),
      parameters: {'id': userId, 'viewerId': viewerId},
    );
    final total = (countResult.first[0] as int?) ?? 0;

    // Fetch followers
    final result = await conn.execute(
      Sql.named('''
        SELECT
          u.id,
          u.username,
          u.display_name,
          u.avatar_url,
          uf.created_at as followed_at
        FROM user_follows uf
        JOIN users u ON u.id = uf.follower_id
        WHERE uf.following_id = @userId
          AND u.deleted_at IS NULL
          AND u.profile_visibility = 'public'
          AND NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (
              b.blocker_id = @viewerId
              AND b.blocked_id = u.id
            ) OR (
              b.blocked_id = @viewerId
              AND b.blocker_id = u.id
            )
          )
          AND EXISTS (
            SELECT 1
            FROM users target
            WHERE target.id = @userId
              AND target.deleted_at IS NULL
              AND (
                target.profile_visibility = 'public'
                OR target.id = @viewerId
              )
              AND (
                target.id = @viewerId
                OR NOT EXISTS (
                  SELECT 1
                  FROM user_blocks target_block
                  WHERE (
                    target_block.blocker_id = @viewerId
                    AND target_block.blocked_id = target.id
                  ) OR (
                    target_block.blocked_id = @viewerId
                    AND target_block.blocker_id = target.id
                  )
                )
              )
          )
        ORDER BY uf.created_at DESC
        LIMIT @lim OFFSET @off
      '''),
      parameters: {
        'userId': userId,
        'viewerId': viewerId,
        'lim': limit,
        'off': offset,
      },
    );

    final followers =
        result.map((row) {
          final m = row.toColumnMap();
          if (m['followed_at'] is DateTime) {
            m['followed_at'] = (m['followed_at'] as DateTime).toIso8601String();
          }
          return m;
        }).toList();

    return Response.json(
      body: {'data': followers, 'page': page, 'limit': limit, 'total': total},
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'user_followers_route',
      extras: {'operation': 'get_followers'},
    );
    Log.e(
      '[social_route] server_error endpoint=GET /users/:id/followers error=$e',
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
