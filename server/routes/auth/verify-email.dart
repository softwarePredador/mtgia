import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    await AuthService().verifyEmail(body['token'] as String? ?? '');
    return Response.json(
      body: const {
        'email_verified': true,
        'message': 'Email verificado. Recursos da comunidade liberados.',
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
      body: const {'error': 'invalid_request', 'message': 'Dados inválidos.'},
    );
  }
}
