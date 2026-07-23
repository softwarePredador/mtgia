import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/request_trace.dart';
import '../../../../lib/social_safety_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _block(context, id),
    HttpMethod.delete => _unblock(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _get(RequestContext context, String targetUserId) async {
  final userId = context.read<String>();
  final pool = context.read<Pool>();
  final result = await pool.execute(
    Sql.named('''
      SELECT
        EXISTS (
          SELECT 1
          FROM user_blocks
          WHERE blocker_id = CAST(@actor AS uuid)
            AND blocked_id = CAST(@target AS uuid)
        ) AS blocked_by_me,
        EXISTS (
          SELECT 1
          FROM user_blocks
          WHERE blocker_id = CAST(@target AS uuid)
            AND blocked_id = CAST(@actor AS uuid)
        ) AS blocked_me
    '''),
    parameters: {'actor': userId, 'target': targetUserId},
  );
  final row = result.first.toColumnMap();
  return Response.json(
    body: {
      'target_user_id': targetUserId,
      'blocked_by_me': row['blocked_by_me'] == true,
      'interaction_blocked':
          row['blocked_by_me'] == true || row['blocked_me'] == true,
    },
  );
}

Future<Response> _block(RequestContext context, String targetUserId) async {
  Map<String, dynamic> body = const {};
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    // An empty body is valid for block.
  }
  try {
    final result = await SocialSafetyService(context.read<Pool>()).blockUser(
      actorUserId: context.read<String>(),
      targetUserId: targetUserId,
      reason: body['reason']?.toString(),
      requestId: _requestId(context),
    );
    return Response.json(body: result);
  } on SocialSafetyException catch (error) {
    final status =
        error.code == 'target_not_found'
            ? HttpStatus.notFound
            : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'error': error.code, 'message': error.message},
    );
  }
}

Future<Response> _unblock(RequestContext context, String targetUserId) async {
  final result = await SocialSafetyService(context.read<Pool>()).unblockUser(
    actorUserId: context.read<String>(),
    targetUserId: targetUserId,
    requestId: _requestId(context),
  );
  return Response.json(body: result);
}

String _requestId(RequestContext context) {
  try {
    return context.read<RequestTrace>().requestId;
  } catch (_) {
    return context.request.headers['x-request-id'] ?? 'n/a';
  }
}
