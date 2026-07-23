import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final query = context.request.uri.queryParameters;
  try {
    final data = await SocialSafetyService(
      context.read<Pool>(),
    ).listModerationQueue(
      status: query['status'] ?? 'open',
      limit: int.tryParse(query['limit'] ?? '') ?? 50,
      offset: int.tryParse(query['offset'] ?? '') ?? 0,
    );
    return Response.json(body: {'data': data, 'total': data.length});
  } on SocialSafetyException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.code, 'message': error.message},
    );
  }
}
