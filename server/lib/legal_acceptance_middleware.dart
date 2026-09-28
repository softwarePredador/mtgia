/// Reaceite de Termos e Privacidade (BT-LEGAL-ACCEPT-001, D-24).
///
/// Quando a versão atual dos Termos ou da Política muda, a conta que ainda
/// não aceitou a nova (ou nunca aceitou: versão nula) é bloqueada só no que
/// cria ou compartilha dado: deck novo, import e IA, mais o relatório
/// público do deck. Login, leitura, edição do que já existe, exportação e
/// exclusão seguem livres.
///
/// A trava só vale com `MANALOOM_LEGAL_REACCEPTANCE=enforce`. Fica desligada
/// por padrão, inclusive na produção, até o app ter a tela de reaceite: sem
/// ela, a conta bloqueada não teria como sair do bloqueio.
library;

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';

import 'database.dart';
import 'legal_acceptance_service.dart';
import 'runtime_environment.dart';

/// Variável que liga a trava do reaceite.
const legalReacceptanceEnvironment = 'MANALOOM_LEGAL_REACCEPTANCE';

bool? _enforcedOverride;

@visibleForTesting
void overrideLegalReacceptanceForTesting(bool? enforced) {
  _enforcedOverride = enforced;
}

/// Só `enforce` liga; qualquer outro valor, ou nenhum, deixa desligada.
bool isLegalReacceptanceEnforced([Map<String, String>? environment]) {
  final override = _enforcedOverride;
  if (override != null) return override;
  final String? value;
  if (environment != null) {
    value = environment[legalReacceptanceEnvironment];
  } else {
    final runtime = loadRuntimeEnvironment();
    value = runtime[legalReacceptanceEnvironment];
  }
  return (value ?? '').trim().toLowerCase() == 'enforce';
}

/// Corpo da recusa: código estável, frase acionável e o que aceitar.
Map<String, Object?> legalAcceptanceRequiredBody(
  LegalAcceptanceStatus status,
) => {
  'error': 'legal_acceptance_required',
  'message':
      'Os Termos de uso ou a Política de privacidade mudaram. Leia e aceite '
      'a versão atual para continuar.',
  'legal': status.toJson(),
};

/// 403 quando a trava está ligada e a conta não aceitou a versão atual, ou
/// `null` para seguir. Conta que não existe fica para a autenticação.
Future<Response?> legalAcceptanceRequiredResponse({
  required String userId,
  required Pool pool,
}) async {
  if (!isLegalReacceptanceEnforced()) return null;
  final status = await LegalAcceptanceService(pool).status(userId);
  if (status == null || status.upToDate) return null;
  return Response.json(
    statusCode: HttpStatus.forbidden,
    body: legalAcceptanceRequiredBody(status),
  );
}

/// Exige o aceite vigente nas escritas que [appliesTo] escolhe. Roda depois
/// do `authMiddleware`, que põe o id da conta no contexto.
Middleware legalAcceptanceForWrites({
  required bool Function(Request request) appliesTo,
}) {
  return (handler) {
    return (context) async {
      final method = context.request.method;
      if (method == HttpMethod.get ||
          method == HttpMethod.head ||
          method == HttpMethod.options) {
        return handler(context);
      }
      if (!appliesTo(context.request)) return handler(context);
      if (!isLegalReacceptanceEnforced()) return handler(context);
      final String userId;
      try {
        userId = context.read<String>();
      } on StateError {
        // Sem conta no contexto, quem responde é a autenticação da rota.
        return handler(context);
      }
      Pool pool;
      try {
        pool = context.read<Pool>();
      } on StateError {
        pool = Database().connection;
      }
      final blocked = await legalAcceptanceRequiredResponse(
        userId: userId,
        pool: pool,
      );
      return blocked ?? handler(context);
    };
  };
}

String _normalize(String path) =>
    path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;

bool _isPost(Request request) => request.method == HttpMethod.post;

/// Sob `/decks`: deck novo, relatório público do deck e análise por IA.
bool isLegalGatedDeckRequest(Request request) {
  if (!_isPost(request)) return false;
  final path = _normalize(request.uri.path);
  return path == '/decks' ||
      RegExp(r'^/decks/[^/]+/reports$').hasMatch(path) ||
      RegExp(r'^/decks/[^/]+/ai-analysis$').hasMatch(path);
}

/// Sob `/import`: importar cria ou troca a lista de um deck. A validação
/// (`/import/validate`) só confere e segue livre.
bool isLegalGatedImportRequest(Request request) {
  if (!_isPost(request)) return false;
  final path = _normalize(request.uri.path);
  return path == '/import' || path == '/import/to-deck';
}

/// No fichário, só o import aplicado cria dado em lote.
bool isLegalGatedBinderRequest(Request request) =>
    _isPost(request) && _normalize(request.uri.path) == '/binder/import/apply';

/// Sob `/ai`: toda escrita manda dado para a IA ou para o motor de regras,
/// menos as exceções abaixo (rota nova nasce exigindo o aceite).
bool isLegalGatedAiRequest(Request request) {
  if (!_isPost(request)) return false;
  final path = _normalize(request.uri.path);
  if (path != '/ai' && !path.startsWith('/ai/')) return false;
  return !legalReacceptanceAiExemptions.any(
    (exemption) => exemption.hasMatch(path),
  );
}

/// Escritas sob `/ai` que não criam nem compartilham dado novo: telemetria,
/// e ações sobre um trabalho ou uma partida que já existem (uma partida em
/// curso não é interrompida por uma versão nova dos Termos).
final legalReacceptanceAiExemptions = <RegExp>[
  RegExp(r'^/ai/optimize/telemetry$'),
  RegExp(r'^/ai/ml-status$'),
  RegExp(r'^/ai/(generate|optimize)/jobs/.+$'),
  RegExp(r'^/ai/battle/jobs/.+$'),
  RegExp(r'^/ai/battle/sessions/[^/]+/.+$'),
];
