import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final data = await SocialSafetyService(
    context.read<Pool>(),
  ).listBlockedUsers(context.read<String>());
  return Response.json(body: {'data': data, 'total': data.length});
}
