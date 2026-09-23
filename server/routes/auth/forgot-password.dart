import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';
import '../../lib/observability.dart';
import '../../lib/password_recovery_dispatcher.dart';
import '../../lib/rate_limit_middleware.dart';

const _publicMessage =
    'Se o email estiver cadastrado, enviaremos as instruções de recuperação.';

/// POST /auth/forgot-password
///
/// Responde 202 com a mesma mensagem para qualquer e-mail. A resposta não
/// espera nada que dependa da conta: achar a conta, criar o token e entregar
/// o e-mail rodam depois dela (`PasswordRecoveryDispatcher`), então o tempo
/// de resposta não denuncia quais e-mails têm conta (BT-AUTH-003, D-21).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  String email;
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    email = (body['email'] as String?)?.trim() ?? '';
  } catch (_) {
    email = '';
  }

  final exposeTokenForTesting = passwordResetTokenExposureEnabled();
  PasswordResetRequest? resetRequest;
  if (email.isNotEmpty && email.contains('@')) {
    try {
      // Limite por e-mail (D-21); o limite por IP roda no middleware de /auth.
      final limited = await credentialEmailRateLimitResponse(
        context,
        email: email,
        bucket: CredentialEmailBucket.recovery,
      );
      if (limited != null) return limited;
      final dispatcher = passwordRecoveryDispatcherFor(context);
      if (exposeTokenForTesting) {
        resetRequest = await dispatcher.createNowAndDispatchDelivery(email);
      } else {
        dispatcher.dispatch(email);
      }
    } catch (error, stackTrace) {
      // The public response stays neutral for unknown accounts and delivery
      // failures. Observability receives no raw token or password.
      await captureRouteException(
        context,
        error,
        stackTrace: stackTrace,
        tags: const {'route': 'auth_forgot_password'},
      );
    }
  }

  return Response.json(
    statusCode: HttpStatus.accepted,
    body: {
      'message': _publicMessage,
      if (resetRequest != null && exposeTokenForTesting)
        'test_reset_token': resetRequest.token,
    },
  );
}
