import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/community_engagement_service.dart';
import '../../../../../lib/community_request_auth.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

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
    final report = await service.reportContent(
      reporterUserId: userId,
      targetType: 'deck',
      targetId: id,
      reason: body['reason']?.toString() ?? 'other',
      details: body['details']?.toString() ?? '',
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'report': report},
    );
  } on FormatException catch (error) {
    return badRequest(error.message);
  } on SocialSafetyException catch (error) {
    final status = switch (error.code) {
      'rate_limited' => HttpStatus.tooManyRequests,
      'duplicate_report' => HttpStatus.conflict,
      'target_not_found' => HttpStatus.notFound,
      _ => HttpStatus.badRequest,
    };
    return Response.json(
      statusCode: status,
      body: {'error': error.code, 'message': error.message},
    );
  } catch (error) {
    return internalServerError('Falha ao registrar denuncia', details: error);
  }
}
