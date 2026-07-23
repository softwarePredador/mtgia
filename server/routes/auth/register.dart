import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_service.dart';
import '../../lib/email_verification_delivery_service.dart';
import '../../lib/email_verification_policy.dart';
import '../../lib/legal_policy.dart';
import '../../lib/observability.dart';
import '../../lib/password_policy.dart';
import '../../lib/runtime_environment.dart';

/// Registro de novo usuário com gravação no banco de dados
///
/// POST /auth/register
/// Body: {"username": "joao", "email": "joao@example.com", "password": "senha123"}
///
/// Retorna:
/// - 201: {token, user: {id, username, email}}
/// - 400: Validação falhou ou username/email já existe
/// - 500: Erro interno
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final username = (body['username'] as String?)?.trim();
    final email = (body['email'] as String?)?.trim();
    final password = body['password'] as String?;
    final runtime = loadRuntimeEnvironment();
    final environment = <String, String>{
      if (runtime['ENVIRONMENT'] case final String value) 'ENVIRONMENT': value,
      if (runtime[requireLegalAcceptanceEnvironment] case final String value)
        requireLegalAcceptanceEnvironment: value,
    };
    final legalAcceptance = LegalAcceptancePolicy.parse(
      body,
      required: LegalAcceptancePolicy.isRequired(environment),
    );

    // Validações básicas
    if (username == null || username.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Nome de usuário é obrigatório'},
      );
    }

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email é obrigatório'},
      );
    }

    if (password == null || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Senha é obrigatória'},
      );
    }

    if (username.length < 3) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Nome de usuário deve ter no mínimo 3 caracteres'},
      );
    }

    final passwordValidation = PasswordPolicy.validate(
      password,
      username: username,
      email: email,
    );
    if (!passwordValidation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': passwordValidation.code,
          'message': passwordValidation.message,
        },
      );
    }

    // Registrar no banco de dados
    final authService = AuthService();
    final result = await authService.register(
      username: username,
      email: email,
      password: password,
      legalAcceptance: legalAcceptance,
    );
    final verificationRequest = EmailVerificationRequest(
      email: result['email'] as String,
      token: result['emailVerificationToken'] as String,
      expiresAt: result['emailVerificationExpiresAt'] as DateTime,
    );
    var verificationSent = false;
    try {
      verificationSent = await EmailVerificationDeliveryService().deliver(
        email: verificationRequest.email,
        token: verificationRequest.token,
        expiresAt: verificationRequest.expiresAt,
      );
    } catch (error, stackTrace) {
      await captureRouteException(
        context,
        error,
        stackTrace: stackTrace,
        tags: const {'route': 'auth_register_email_verification'},
      );
    }
    final verificationEnvironment = emailVerificationEnvironmentValues();

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'token': result['token'],
        'user': {
          'id': result['userId'],
          'username': result['username'],
          'email': result['email'],
          'email_verified': false,
        },
        'verification_sent': verificationSent,
        if (mayExposeEmailVerificationTokenForTesting(verificationEnvironment))
          'test_verification_token': verificationRequest.token,
      },
    );
  } on LegalAcceptanceException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.code, 'message': error.message},
    );
  } on Exception catch (e) {
    print('[ERROR] handler: $e');
    // Erros de negócio (username/email duplicado, etc)
    final message = e.toString().replaceFirst('Exception: ', '');
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': message},
    );
  } catch (e, stackTrace) {
    print('[ERROR] handler: $e');
    print('Erro ao criar conta: $e');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'auth_register'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Erro ao criar conta'},
    );
  }
}
