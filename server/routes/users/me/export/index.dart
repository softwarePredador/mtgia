import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/auth_middleware.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/rate_limit_middleware.dart';
import '../../../../lib/user_data_privacy_service.dart';

/// Exportação portátil dos dados da conta.
///
/// POST /users/me/export
/// Body: {"password": "senha atual da conta"}
///
/// A senha é conferida a cada requisição (D-20): o token de sessão sozinho
/// não exporta nada (D-19). A tentativa conta no bucket de credenciais por
/// IP (middleware de `/users`) e no limite por conta.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();

  final userId = getUserId(context);
  final password = await _readPassword(context.request);
  if (password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: const {
        'error': 'password_required',
        'message': 'Senha obrigatória.',
      },
    );
  }

  try {
    final limited = await accountReverificationRateLimitResponse(
      context,
      userId: userId,
    );
    if (limited != null) return limited;

    final service = UserDataPrivacyService(context.read<Pool>());
    await service.verifyCurrentPassword(userId: userId, password: password);
    final payload = await service.exportUserData(userId);
    return Response.json(
      body: payload,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
        'Pragma': 'no-cache',
        'Content-Disposition':
            'attachment; filename="brewtact-user-data-$userId.json"',
      },
    );
  } on InvalidAccountPasswordException {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: const {
        'error': 'invalid_password',
        'message': 'Senha atual inválida.',
      },
    );
  } on UserDataNotFoundException {
    return notFound('Conta não encontrada.');
  } catch (_) {
    return internalServerError('Falha ao exportar os dados da conta.');
  }
}

Future<String?> _readPassword(Request request) async {
  try {
    final body = await request.json();
    if (body is! Map) return null;
    final password = body['password'];
    return password is String && password.isNotEmpty ? password : null;
  } catch (_) {
    return null;
  }
}
