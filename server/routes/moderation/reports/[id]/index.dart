import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/request_trace.dart';
import '../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
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

  String? moderatorUserId;
  try {
    moderatorUserId = context.read<String>();
  } catch (_) {
    moderatorUserId = null;
  }
  try {
    final evidence =
        body['evidence'] is Map
            ? (body['evidence'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final report = await SocialSafetyService(
      context.read<Pool>(),
    ).moderateReport(
      reportId: id,
      action: body['action']?.toString() ?? '',
      rationale: body['rationale']?.toString() ?? '',
      moderatorUserId: moderatorUserId,
      requestId: _requestId(context),
      evidence: evidence,
    );
    return Response.json(body: {'report': report});
  } on SocialSafetyException catch (error) {
    final status =
        error.code == 'report_not_found'
            ? HttpStatus.notFound
            : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'error': error.code, 'message': error.message},
    );
  }
}

String _requestId(RequestContext context) {
  try {
    return context.read<RequestTrace>().requestId;
  } catch (_) {
    return context.request.headers['x-request-id'] ?? 'n/a';
  }
}
