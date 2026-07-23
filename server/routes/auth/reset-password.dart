import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final token = (body['token'] as String?)?.trim() ?? '';
    final newPassword = body['new_password'] as String? ?? '';
    await AuthService().resetPassword(token: token, newPassword: newPassword);
    return Response.json(
      body: {
        'password_reset': true,
        'message': 'Senha alterada. Entre novamente em todos os dispositivos.',
      },
    );
  } on AccountSecurityException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.code, 'message': error.message},
    );
  } on FormatException {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: const {
        'error': 'invalid_request',
        'message': 'Solicitação de recuperação inválida.',
      },
    );
  }
}
