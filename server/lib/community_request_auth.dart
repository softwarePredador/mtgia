import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'auth_service.dart';

String? readAuthenticatedUserId(RequestContext context) {
  final authHeader = context.request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  final token = authHeader.substring(7);
  final payload = AuthService().verifyToken(token);
  return payload?['userId'] as String?;
}

Response authenticationRequired([
  String message = 'Autenticacao necessaria.',
]) =>
    Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': message},
    );
