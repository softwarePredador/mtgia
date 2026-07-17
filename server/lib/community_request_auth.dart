import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'auth_service.dart';

Future<String?> readAuthenticatedUserId(RequestContext context) async {
  final authHeader = context.request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  final token = authHeader.substring(7);
  final user = await AuthService().getUserFromToken(token);
  return user?['id'] as String?;
}

Response authenticationRequired([
  String message = 'Autenticacao necessaria.',
]) => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: {'error': message},
);
