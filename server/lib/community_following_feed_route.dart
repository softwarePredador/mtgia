import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'community_following_feed_service.dart';
import 'community_request_auth.dart';
import 'logger.dart';
import 'observability.dart';

/// Canonical handler for `GET /community/decks/following`.
///
/// The public path is dispatched by the dynamic deck route so Dart Frog does
/// not generate two competing route patterns for `following` and `[id]`.
Future<Response> handleCommunityFollowingFeed(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = await readAuthenticatedUserId(context);
  if (userId == null) return authenticationRequired();
  final query = context.request.uri.queryParameters;
  try {
    final payload = await CommunityFollowingFeedService(
      context.read<Pool>(),
    ).list(
      userId: userId,
      page: int.tryParse(query['page'] ?? '') ?? 1,
      limit: int.tryParse(query['limit'] ?? '') ?? 20,
    );
    return Response.json(
      body: payload,
      headers: const {'Cache-Control': 'private, no-store'},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      source: 'community_following_feed_route',
      extras: {'operation': 'get_following_feed'},
    );
    Log.e(
      '[community_route] server_error '
      'endpoint=GET /community/decks/following error=$error',
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
