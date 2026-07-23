import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';
import '../../lib/email_verification_delivery_service.dart';
import '../../lib/email_verification_policy.dart';
import '../../lib/observability.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final header = context.request.headers[HttpHeaders.authorizationHeader];
  if (header == null || !header.startsWith('Bearer ')) {
    return _unauthorized();
  }
  final user = await AuthService().getUserFromToken(header.substring(7));
  if (user == null) return _unauthorized();

  final verification = await AuthService().createEmailVerificationRequest(
    userId: user['id'] as String,
  );
  if (verification == null) {
    return Response.json(
      body: const {
        'email_verified': true,
        'already_verified': true,
        'message': 'Este email já está verificado.',
      },
    );
  }

  var sent = false;
  try {
    sent = await EmailVerificationDeliveryService().deliver(
      email: verification.email,
      token: verification.token,
      expiresAt: verification.expiresAt,
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'auth_resend_verification'},
    );
  }
  final environment = emailVerificationEnvironmentValues();
  return Response.json(
    statusCode: HttpStatus.accepted,
    body: {
      'email_verified': false,
      'verification_sent': sent,
      'message': 'Se necessário, enviaremos um novo link de verificação.',
      if (mayExposeEmailVerificationTokenForTesting(environment))
        'test_verification_token': verification.token,
    },
  );
}

Response _unauthorized() => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: const {
    'error': 'invalid_session',
    'message': 'Faça login novamente para continuar.',
  },
);
