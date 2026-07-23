import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/community_engagement_service.dart';
import '../../../../../lib/community_request_auth.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.get) {
    return _list(context, id);
  }
  if (context.request.method == HttpMethod.post) {
    return _create(context, id);
  }
  return methodNotAllowed();
}

Future<Response> _list(RequestContext context, String deckId) async {
  final service = CommunityEngagementService(context.read<Pool>());
  final viewerUserId = await readAuthenticatedUserId(context);
  final limit =
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '50') ?? 50;
  final page =
      int.tryParse(context.request.uri.queryParameters['page'] ?? '1') ?? 1;

  try {
    if (!await service.publicDeckExists(deckId, viewerUserId: viewerUserId)) {
      return notFound('Deck publico nao encontrado.');
    }
    final comments = await service.listDeckComments(
      deckId: deckId,
      viewerUserId: viewerUserId,
      limit: limit,
      offset: (page - 1).clamp(0, 999999) * limit.clamp(1, 100),
    );
    return Response.json(
      body: {'data': comments, 'page': page, 'limit': limit.clamp(1, 100)},
    );
  } catch (error) {
    return internalServerError('Falha ao carregar comentarios', details: error);
  }
}

Future<Response> _create(RequestContext context, String deckId) async {
  final userId = await readAuthenticatedUserId(context);
  if (userId == null) return authenticationRequired();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  final service = CommunityEngagementService(context.read<Pool>());
  try {
    if (!await service.publicDeckExists(deckId, viewerUserId: userId)) {
      return notFound('Deck publico nao encontrado.');
    }
    final comment = await service.createDeckComment(
      deckId: deckId,
      userId: userId,
      body: body['body']?.toString() ?? '',
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'comment': comment},
    );
  } on FormatException catch (error) {
    return badRequest(error.message);
  } on SocialSafetyException catch (error) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'error': error.code, 'message': error.message},
    );
  } catch (error) {
    return internalServerError('Falha ao criar comentario', details: error);
  }
}
