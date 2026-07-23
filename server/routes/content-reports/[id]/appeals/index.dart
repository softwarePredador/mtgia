import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
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
    final appeal = await SocialSafetyService(context.read<Pool>()).appealReport(
      reportId: id,
      appellantUserId: context.read<String>(),
      reason: body['reason']?.toString() ?? '',
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'appeal': appeal},
    );
  } on SocialSafetyException catch (error) {
    final status = switch (error.code) {
      'report_not_found' => HttpStatus.notFound,
      'appeal_forbidden' => HttpStatus.forbidden,
      'duplicate_appeal' => HttpStatus.conflict,
      _ => HttpStatus.badRequest,
    };
    return Response.json(
      statusCode: status,
      body: {'error': error.code, 'message': error.message},
    );
  }
}
