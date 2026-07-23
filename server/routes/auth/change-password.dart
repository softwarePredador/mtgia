import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final user = await _authenticatedUser(context.request);
  if (user == null) return _unauthorized();

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final result = await AuthService().changePassword(
      userId: user['id'] as String,
      currentPassword: body['current_password'] as String? ?? '',
      newPassword: body['new_password'] as String? ?? '',
    );
    return Response.json(body: result.toJson());
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

Future<Map<String, dynamic>?> _authenticatedUser(Request request) async {
  final header = request.headers[HttpHeaders.authorizationHeader];
  if (header == null || !header.startsWith('Bearer ')) return null;
  return AuthService().getUserFromToken(header.substring(7));
}

Response _unauthorized() => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: const {
    'error': 'Token inválido ou expirado',
    'message': 'Faça login novamente para continuar.',
  },
);
