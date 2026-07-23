import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/auth_service.dart';
import '../../lib/observability.dart';
import '../../lib/password_reset_delivery_service.dart';
import '../../lib/runtime_environment.dart';

const _publicMessage =
    'Se o email estiver cadastrado, enviaremos as instruções de recuperação.';

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

  PasswordResetRequest? resetRequest;
  if (email.isNotEmpty && email.contains('@')) {
    try {
      resetRequest = await AuthService().createPasswordResetRequest(
        email: email,
      );
      if (resetRequest != null) {
        await PasswordResetDeliveryService().deliver(
          email: resetRequest.email,
          token: resetRequest.token,
          expiresAt: resetRequest.expiresAt,
        );
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

  final environment = loadRuntimeEnvironment();
  final testExposureEnvironment = <String, String>{
    if (environment['ENVIRONMENT'] case final String value)
      'ENVIRONMENT': value,
    if (environment[passwordResetTestResponseEnvironment]
        case final String value)
      passwordResetTestResponseEnvironment: value,
  };
  return Response.json(
    statusCode: HttpStatus.accepted,
    body: {
      'message': _publicMessage,
      if (resetRequest != null &&
          mayExposePasswordResetTokenForTesting(testExposureEnvironment))
        'test_reset_token': resetRequest.token,
    },
  );
}
