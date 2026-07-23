import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'auth_service.dart';
import 'email_verification_policy.dart';

Middleware verifiedEmailForMutations() {
  return (handler) {
    return (context) async {
      final method = context.request.method;
      if (!isVerifiedEmailRequired() ||
          method == HttpMethod.get ||
          method == HttpMethod.head ||
          method == HttpMethod.options) {
        return handler(context);
      }

      final header = context.request.headers[HttpHeaders.authorizationHeader];
      if (header == null || !header.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: const {
            'error': 'authentication_required',
            'message': 'Entre para continuar.',
          },
        );
      }
      final user = await AuthService().getUserFromToken(header.substring(7));
      if (user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: const {
            'error': 'invalid_session',
            'message': 'Faça login novamente para continuar.',
          },
        );
      }
      if (user['email_verified'] != true) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: const {
            'error': 'email_verification_required',
            'message':
                'Verifique seu email antes de publicar, conversar ou negociar.',
          },
        );
      }
      return handler(context);
    };
  };
}
