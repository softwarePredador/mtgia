import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/auth_middleware.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/privacy/privacy_export_request_log.dart';
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
///
/// Cada pedido que chega aqui deixa uma linha `MANALOOM_PRIVACY_EXPORT_REQUEST`
/// com quando, o resultado e uma referência pseudônima de quem pediu (D-71).
Future<Response> onRequest(RequestContext context) async {
  final userId = getUserId(context);
  final (response, result) = await _export(context, userId);
  // A linha vai direto ao stdout, como a de demanda do catálogo (D-63): o
  // JSON já não leva o ID, a senha nem o conteúdo.
  // ignore: avoid_print
  print(
    privacyExportRequestLogLine(
      userId: userId,
      result: result,
      serverSecret: privacyExportRequesterSecret(),
    ),
  );
  return response;
}

Future<(Response, PrivacyExportRequestResult)> _export(
  RequestContext context,
  String userId,
) async {
  if (context.request.method != HttpMethod.post) {
    return (methodNotAllowed(), PrivacyExportRequestResult.methodNotAllowed);
  }

  final password = await _readPassword(context.request);
  if (password == null) {
    return (
      Response.json(
        statusCode: HttpStatus.badRequest,
        body: const {
          'error': 'password_required',
          'message': 'Senha obrigatória.',
        },
      ),
      PrivacyExportRequestResult.passwordRequired,
    );
  }

  try {
    final limited = await accountReverificationRateLimitResponse(
      context,
      userId: userId,
    );
    if (limited != null) {
      return (limited, PrivacyExportRequestResult.rateLimited);
    }

    final service = UserDataPrivacyService(context.read<Pool>());
    await service.verifyCurrentPassword(userId: userId, password: password);
    final payload = await service.exportUserData(userId);
    return (
      Response.json(
        body: payload,
        headers: {
          'Cache-Control': 'no-store, max-age=0',
          'Pragma': 'no-cache',
          'Content-Disposition':
              'attachment; filename="brewtact-user-data-$userId.json"',
        },
      ),
      PrivacyExportRequestResult.ok,
    );
  } on InvalidAccountPasswordException {
    return (
      Response.json(
        statusCode: HttpStatus.unauthorized,
        body: const {
          'error': 'invalid_password',
          'message': 'Senha atual inválida.',
        },
      ),
      PrivacyExportRequestResult.invalidPassword,
    );
  } on UserDataNotFoundException {
    return (
      notFound('Conta não encontrada.'),
      PrivacyExportRequestResult.notFound,
    );
  } catch (_) {
    return (
      internalServerError('Falha ao exportar os dados da conta.'),
      PrivacyExportRequestResult.error,
    );
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
