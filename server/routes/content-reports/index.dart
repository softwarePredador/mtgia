import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'invalid_json', 'message': 'JSON invalido.'},
    );
  }

  try {
    final evidence =
        body['evidence'] is Map
            ? (body['evidence'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final report = await SocialSafetyService(
      context.read<Pool>(),
    ).reportContent(
      reporterUserId: context.read<String>(),
      targetType: body['target_type']?.toString() ?? '',
      targetId: body['target_id']?.toString() ?? '',
      reason: body['reason']?.toString() ?? '',
      details: body['details']?.toString() ?? '',
      evidence: evidence,
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'report': report},
    );
  } on SocialSafetyException catch (error) {
    return _socialSafetyError(error);
  }
}

Response _socialSafetyError(SocialSafetyException error) {
  final status = switch (error.code) {
    'rate_limited' => HttpStatus.tooManyRequests,
    'duplicate_report' => HttpStatus.conflict,
    'target_not_found' => HttpStatus.notFound,
    _ => HttpStatus.badRequest,
  };
  return Response.json(
    statusCode: status,
    body: {'error': error.code, 'message': error.message},
    headers:
        error.code == 'rate_limited' ? const {'Retry-After': '3600'} : const {},
  );
}
