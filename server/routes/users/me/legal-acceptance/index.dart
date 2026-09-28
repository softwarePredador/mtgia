import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/http_responses.dart';
import '../../../../lib/legal_acceptance_service.dart';
import '../../../../lib/legal_policy.dart';
import '../../../../lib/request_trace.dart';

/// Aceite de Termos e Privacidade da conta (BT-LEGAL-ACCEPT-001, D-24).
///
/// GET /users/me/legal-acceptance
///   200 `{legal: {accepted_*, current_*, reacceptance_required,
///   accept_path}}`.
///
/// POST /users/me/legal-acceptance
///   Body: `legal_accepted: true`, `terms_version` e `privacy_version`
///   iguais às atuais. 200 com a situação nova; 400
///   `legal_acceptance_required` (com as versões atuais) quando falta o aceite
///   ou a versão não é a atual. Aceitar de novo o que já está aceito não
///   duplica o histórico.
///
/// Fica no plano de controle: a conta bloqueada pelo reaceite precisa desta
/// rota para sair do bloqueio, com qualquer capability desligada.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _status(context),
    HttpMethod.post => _accept(context),
    _ => Future.value(methodNotAllowed()),
  };
}

Future<Response> _status(RequestContext context) async {
  final userId = context.read<String>();
  final status = await LegalAcceptanceService(
    context.read<Pool>(),
  ).status(userId);
  if (status == null) return _accountNotFound();
  return Response.json(body: {'legal': status.toJson()});
}

Future<Response> _accept(RequestContext context) async {
  final userId = context.read<String>();
  final Object? decoded;
  try {
    decoded = await context.request.json();
  } on FormatException {
    return _invalidBody();
  }
  if (decoded is! Map<String, dynamic>) return _invalidBody();

  final LegalAcceptance acceptance;
  try {
    acceptance = LegalAcceptancePolicy.parse(decoded, required: true)!;
  } on LegalAcceptanceException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': error.code,
        'message': error.message,
        'legal': const {
          'current_terms_version': currentTermsVersion,
          'current_privacy_version': currentPrivacyVersion,
        },
      },
    );
  }

  final status = await LegalAcceptanceService(
    context.read<Pool>(),
  ).accept(userId, acceptance, requestId: _requestId(context));
  if (status == null) return _accountNotFound();
  return Response.json(body: {'legal': status.toJson()});
}

Response _invalidBody() => Response.json(
  statusCode: HttpStatus.badRequest,
  body: const {
    'error': 'request_json_invalid',
    'message': 'Envie um objeto JSON com o aceite.',
  },
);

Response _accountNotFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: const {
    'error': 'account_not_found',
    'message': 'Conta não encontrada.',
  },
);

String? _requestId(RequestContext context) {
  try {
    return context.read<RequestTrace>().requestId;
  } on StateError {
    return null;
  }
}
