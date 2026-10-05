import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'auth_service.dart';
import 'email_verification_policy.dart';

bool? _verifiedEmailRequiredOverride;

/// Frase da resposta 403 de e-mail não verificado. Não cita troca, conversa
/// nem publicação, que a beta não oferece (SCOPE-P0-TRD-00): a mesma resposta
/// vale para o fichário, os decks e o import.
const verifiedEmailRequiredMessage = 'Confirme seu e-mail para continuar.';

/// Liga ou desliga a exigência nos testes, sem depender do ambiente do
/// processo (em produção ela é sempre exigida). `null` volta ao ambiente.
@visibleForTesting
void overrideVerifiedEmailRequirementForTesting(bool? required) {
  _verifiedEmailRequiredOverride = required;
}

/// Exige e-mail verificado nas escritas (métodos que não são GET, HEAD ou
/// OPTIONS). [appliesTo] restringe a quais escritas a exigência vale; sem
/// ele, vale para todas.
Middleware verifiedEmailForMutations({
  bool Function(Request request)? appliesTo,
}) {
  return (handler) {
    return (context) async {
      final method = context.request.method;
      if (method == HttpMethod.get ||
          method == HttpMethod.head ||
          method == HttpMethod.options) {
        return handler(context);
      }
      if (appliesTo != null && !appliesTo(context.request)) {
        return handler(context);
      }
      final blocked = await verifiedEmailRequiredResponse(context.request);
      return blocked ?? handler(context);
    };
  };
}

/// Resposta de bloqueio quando a exigência está ligada e a conta do token
/// ainda não verificou o e-mail, ou `null` para seguir.
///
/// O middleware usa esta função; rotas que só às vezes gravam (como
/// `POST /ai/rebuild` com `save_mode=draft_clone`) chamam dentro do handler.
Future<Response?> verifiedEmailRequiredResponse(Request request) async {
  if (!(_verifiedEmailRequiredOverride ?? isVerifiedEmailRequired())) {
    return null;
  }

  final header = request.headers[HttpHeaders.authorizationHeader];
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
        'message': verifiedEmailRequiredMessage,
      },
    );
  }
  return null;
}
