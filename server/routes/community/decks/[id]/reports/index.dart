import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/community_engagement_service.dart';
import '../../../../../lib/community_request_auth.dart';
import '../../../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = readAuthenticatedUserId(context);
  if (userId == null) return authenticationRequired();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  final service = CommunityEngagementService(context.read<Pool>());
  try {
    if (!await service.publicDeckExists(id)) {
      return notFound('Deck publico nao encontrado.');
    }
    final targetType = body['target_type']?.toString().trim().isNotEmpty == true
        ? body['target_type'].toString()
        : 'deck';
    final targetId = body['target_id']?.toString().trim().isNotEmpty == true
        ? body['target_id'].toString()
        : id;
    final report = await service.reportContent(
      reporterUserId: userId,
      targetType: targetType,
      targetId: targetId,
      reason: body['reason']?.toString() ?? 'other',
      details: body['details']?.toString() ?? '',
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'report': report},
    );
  } on FormatException catch (error) {
    return badRequest(error.message);
  } catch (error) {
    return internalServerError('Falha ao registrar denuncia', details: error);
  }
}
