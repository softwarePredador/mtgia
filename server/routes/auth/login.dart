import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_service.dart';
import '../../lib/observability.dart';
import '../../lib/rate_limit_middleware.dart';

/// Login com autenticação real no banco de dados
///
/// POST /auth/login
/// Body: {"email": "user@example.com", "password": "senha123"}
///
/// Retorna:
/// - 200: {token, user: {id, username, email}}
/// - 400: Validação falhou
/// - 401: Credenciais inválidas (conta inexistente ou senha errada, iguais)
/// - 429: Muitas tentativas para este e-mail (o limite por IP fica no
///   middleware de `/auth`)
/// - 500: Erro interno
///
/// Nenhuma resposta repete o texto de uma exceção (D-21).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String? email;
  final String? password;
  try {
    final body = await context.request.json();
    if (body is! Map<String, dynamic>) return _invalidRequest();
    final rawEmail = body['email'];
    final rawPassword = body['password'];
    if ((rawEmail != null && rawEmail is! String) ||
        (rawPassword != null && rawPassword is! String)) {
      return _invalidRequest();
    }
    email = (rawEmail as String?)?.trim();
    password = rawPassword as String?;
  } on FormatException {
    return _invalidRequest();
  }

  // Validação básica
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

  try {
    final limited = await credentialEmailRateLimitResponse(
      context,
      email: email,
      bucket: CredentialEmailBucket.login,
    );
    if (limited != null) return limited;

    // Autenticar com banco de dados
    final authService = AuthService();
    final result = await authService.login(email: email, password: password);

    return Response.json(
      statusCode: HttpStatus.ok,
      body: {
        'token': result['token'],
        'user': {
          'id': result['userId'],
          'username': result['username'],
          'email': result['email'],
          'email_verified': result['emailVerified'],
        },
      },
    );
  } on InvalidCredentialsException {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'message': InvalidCredentialsException.message},
    );
  } catch (e, stackTrace) {
    print('[ERROR] Erro ao fazer login: ${e.runtimeType}');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'auth_login'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Erro ao fazer login'},
    );
  }
}

Response _invalidRequest() => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'message': 'Dados inválidos.'},
);
