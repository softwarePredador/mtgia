import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/community_following_feed_service.dart';
import '../../../../lib/community_request_auth.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context) async {
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
