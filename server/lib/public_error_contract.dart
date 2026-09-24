/// Erros públicos tipados (BT-AUTH-001, D-21).
///
/// Todo erro que sai para o cliente leva um código estável `dominio_motivo` em
/// snake_case ao lado da frase em português (a frase não é substituída), e o
/// request-id da requisição: sempre no header `x-request-id` e, nos envelopes
/// de erro, também no corpo (`request_id`). Texto de exceção, SQL, mensagem do
/// PostgreSQL e stack nunca saem: ficam no log.
///
/// [sanitizePublicErrorResponse] é a rede de segurança do middleware raiz:
/// roda em toda resposta 4xx e 5xx, depois do handler.
///   - Corpo com detalhe interno (em qualquer campo) nunca passa: vira a frase
///     genérica, com o código que a rota deu (ou o do status) e o request-id.
///   - 5xx com envelope de erro (`error` ou `message`): só passa o que já tem
///     código estável em `error`, e ganha `request_id`; o resto vira o código
///     do status com a frase genérica (o código estável que a rota deu, em
///     `error`, `code` ou `error_code`, é mantido).
///   - 5xx JSON sem envelope de erro (o 503 da prontidão, com os checks) passa
///     intacto: é diagnóstico já tipado.
///   - 4xx com envelope de erro: a frase fica onde a rota pôs (o app lê
///     `error` ou `message`); sem código estável, ganha `code` pelo status
///     ([publicErrorCodeForStatus]); e ganha `request_id`.
///   - 4xx sem envelope de erro (corpo estruturado) passa intacto.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Erro interno (5xx) sem código próprio.
const serverInternalErrorCode = 'server_internal_error';
const serverInternalErrorMessage =
    'Erro interno do servidor. Tente de novo em instantes; se continuar, '
    'informe o código da requisição.';

/// Erro de requisição (4xx) cujo texto original tinha detalhe interno.
const requestFailedErrorCode = 'request_failed';
const requestFailedMessage =
    'Não foi possível concluir a ação. Revise os dados e tente de novo.';

/// Banco fora do ar antes do handler.
const serviceDatabaseUnavailableCode = 'service_database_unavailable';
const serviceDatabaseUnavailableMessage =
    'Serviço temporariamente indisponível. Tente de novo em instantes.';

/// Código estável pelo status, para o erro cuja rota ainda não dá um código
/// de domínio. É o piso do catálogo: a rota que tem motivo próprio usa o seu
/// (`deck_not_found`, `invite_required`, ...).
const publicErrorCodesByStatus = <int, String>{
  400: 'request_invalid',
  401: 'auth_unauthorized',
  402: 'payment_required',
  403: 'access_forbidden',
  404: 'resource_not_found',
  405: 'method_not_allowed',
  406: 'request_not_acceptable',
  408: 'request_timeout',
  409: 'resource_conflict',
  410: 'resource_gone',
  411: 'request_length_required',
  412: 'request_precondition_failed',
  413: 'request_too_large',
  414: 'request_uri_too_long',
  415: 'request_media_type_unsupported',
  422: 'request_unprocessable',
  423: 'resource_locked',
  428: 'request_precondition_required',
  429: 'rate_limited',
  431: 'request_headers_too_large',
  500: serverInternalErrorCode,
  501: 'server_not_implemented',
  502: 'upstream_failed',
  503: 'service_unavailable',
  504: 'upstream_timeout',
};

/// Código do status; 4xx e 5xx fora da tabela caem em `request_failed` e
/// `server_internal_error`.
String publicErrorCodeForStatus(int status) =>
    publicErrorCodesByStatus[status] ??
    (status >= 500 ? serverInternalErrorCode : requestFailedErrorCode);

String _serverErrorMessageFor(int status) => switch (status) {
  HttpStatus.serviceUnavailable => serviceDatabaseUnavailableMessage,
  _ => serverInternalErrorMessage,
};

final _stableCodePattern = RegExp(r'^[a-z][a-z0-9_]{2,63}$');

/// Código estável: minúsculas, dígitos e sublinhado, sem espaço.
bool isStablePublicErrorCode(Object? value) =>
    value is String && _stableCodePattern.hasMatch(value);

/// Texto que denuncia detalhe interno: nome de exceção ou erro do Dart, texto
/// do PostgreSQL (SQLSTATE, severidade, relação, coluna, constraint), trecho
/// de stack e `toString` de objeto.
final internalDetailPattern = RegExp(
  [
    // Dart: nome de exceção ou erro, e o `Exception: ...` genérico.
    r'\b[A-Z][A-Za-z0-9]*(?:Exception|Error)\b',
    r'\bException\b',
    r'Null check operator',
    r'is not a subtype of',
    r"Instance of '",
    // `toString` dos erros do núcleo do Dart, que não trazem o nome do tipo.
    r'Bad state:',
    r'Invalid argument',
    r'Unsupported operation:',
    r'Concurrent modification during',
    r'Assertion failed',
    r'Out of Memory',
    r'Stack Overflow',
    // Rede e sistema operacional (SocketException, HttpException).
    r'OS Error',
    r'errno = \d',
    r'Connection refused',
    r'Connection reset by peer',
    r'Failed host lookup',
    // PostgreSQL.
    r'\bSQLSTATE\b',
    r'\bPostgreSQL\b',
    r'\bSeverity\.',
    r'duplicate key value',
    r'violates [a-z -]*constraint',
    r'relation "[^"]*"',
    r'column "[^"]*"',
    r'syntax error at or near',
    r'invalid input syntax for type',
    r'value too long for type',
    r'deadlock detected',
    r'could not serialize access',
    r'canceling statement due to',
    r'current transaction is aborted',
    r'permission denied for (?:table|relation|schema|function|sequence)',
    // Stack.
    r'\bStackTrace\b',
    r'\bpackage:[a-z_]',
    r'\bdart:[a-z_]',
    r'\.dart:\d+',
    r'(?:^|\n)#\d+\s',
  ].join('|'),
);

/// Se algum texto do corpo tem detalhe interno.
bool containsInternalDetail(Object? value) {
  if (value is String) return internalDetailPattern.hasMatch(value);
  if (value is Map) return value.values.any(containsInternalDetail);
  if (value is Iterable) return value.any(containsInternalDetail);
  return false;
}

/// Corpo público de erro no formato da D-21.
Map<String, Object?> publicErrorBody({
  required String code,
  required String message,
  String? requestId,
}) => {
  'error': code,
  'message': message,
  if (requestId != null) 'request_id': requestId,
};

/// Rede de segurança do middleware raiz. [onSanitized] recebe o motivo
/// (`leak` ou `untyped`) e o corpo original quando o corpo foi trocado, para
/// o log: o cliente só vê a frase genérica e o request-id.
Future<Response> sanitizePublicErrorResponse(
  Response response, {
  required String requestId,
  void Function(String reason, String original)? onSanitized,
}) async {
  final status = response.statusCode;
  if (status < 400) return response;
  final contentType = _header(response.headers, 'content-type').toLowerCase();
  final isJson = contentType.contains('json');
  final isText = contentType.isEmpty || contentType.startsWith('text/');
  if (!isJson && !isText) return response;

  final raw = await response.body();
  Object? decoded;
  if (isJson && raw.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
  }
  final json = decoded is Map<String, dynamic> ? decoded : null;
  final leaked = containsInternalDetail(json ?? raw);
  // Código estável que a rota deu: em `error` (D-21) ou nas formas antigas,
  // `code` (fichário, trocas) e `error_code` (decks).
  final typedCode = _stableCode(json, 'error');
  final legacyCode = _stableCode(json, 'code');
  final legacyErrorCode = _stableCode(json, 'error_code');
  final envelope = json != null && _isErrorEnvelope(json);

  if (!leaked) {
    if (json != null && !envelope) {
      // Corpo estruturado sem envelope de erro: passa como está.
      return response.copyWith(body: raw);
    }
    if (status < 500 && json != null && envelope) {
      final hasCode =
          typedCode != null || legacyCode != null || legacyErrorCode != null;
      // Um `code` que a rota já mandou nunca é sobrescrito.
      final addCode = !hasCode && !json.containsKey('code');
      if (!addCode && json.containsKey('request_id')) {
        return response.copyWith(body: raw);
      }
      return _rebuildJson(response, {
        ...json,
        if (addCode) 'code': publicErrorCodeForStatus(status),
        'request_id': json['request_id'] ?? requestId,
      });
    }
    if (status >= 500 && typedCode != null) {
      return _rebuildJson(response, {
        ...json!,
        'request_id': json['request_id'] ?? requestId,
      });
    }
    if (status < 500) {
      // 4xx sem corpo JSON (o 405 vazio já virou JSON antes): intacto.
      return response.copyWith(body: raw);
    }
  }

  onSanitized?.call(leaked ? 'leak' : 'untyped', raw);
  if (status >= 500) {
    return _rebuildJson(
      response,
      publicErrorBody(
        code:
            typedCode ??
            legacyCode ??
            legacyErrorCode ??
            publicErrorCodeForStatus(status),
        message: _serverErrorMessageFor(status),
        requestId: requestId,
      ),
    );
  }
  // 4xx com detalhe interno. Mantém a forma que a rota usava: com código em
  // `error` (D-21), o código fica e a frase vai para `message`; com a frase
  // em `error` (forma antiga, que o app mostra), a frase genérica fica em
  // `error` e o código continua em `code` ou `error_code`.
  if (typedCode != null) {
    return _rebuildJson(
      response,
      publicErrorBody(
        code: typedCode,
        message: requestFailedMessage,
        requestId: requestId,
      ),
    );
  }
  return _rebuildJson(response, {
    'error': requestFailedMessage,
    'code': legacyCode ?? publicErrorCodeForStatus(status),
    if (legacyErrorCode != null) 'error_code': legacyErrorCode,
    'request_id': requestId,
  });
}

String? _stableCode(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return isStablePublicErrorCode(value) ? value as String : null;
}

/// Corpo que se apresenta como erro: tem `error` ou `message`.
bool _isErrorEnvelope(Map<String, dynamic> json) =>
    json.containsKey('error') || json.containsKey('message');

Response _rebuildJson(Response original, Map<String, Object?> body) {
  final headers = <String, Object>{
    for (final entry in original.headers.entries)
      if (entry.key.toLowerCase() != 'content-length' &&
          entry.key.toLowerCase() != 'content-type')
        entry.key: entry.value,
    HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
  };
  return Response.json(
    statusCode: original.statusCode,
    body: body,
    headers: headers,
  );
}

String _header(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name) return entry.value;
  }
  return '';
}
