import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/community_engagement_service.dart';
import '../../../../../../lib/community_request_auth.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String commentId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = await readAuthenticatedUserId(context);
  if (userId == null) return authenticationRequired();
  final deleted = await CommunityEngagementService(
    context.read<Pool>(),
  ).deleteDeckComment(deckId: id, commentId: commentId, userId: userId);
  if (!deleted) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'comment_not_found'},
    );
  }
  return Response.json(
    body: {'id': commentId, 'status': 'deleted'},
    headers: const {'Cache-Control': 'no-store'},
  );
}
