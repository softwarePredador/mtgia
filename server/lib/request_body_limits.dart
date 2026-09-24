/// Limites de requisição antes do parse (BT-AUTH-002, D-21).
///
/// O middleware raiz confere a requisição depois da decisão de capability e
/// antes da observabilidade, do banco e do handler, então nada acima do limite
/// é alocado nem gravado:
///   - URL (caminho e query) acima de 8 KiB: 414;
///   - `Content-Encoding` diferente de `identity`: 415 (corpo comprimido não é
///     aceito; nada é descomprimido);
///   - `Transfer-Encoding` (corpo em partes, sem tamanho declarado): 411;
///   - `Content-Length` inválido: 400; acima do limite da URL: 413, sem ler o
///     corpo;
///   - corpo dentro do limite: lido uma vez (o dart_frog guarda o texto para o
///     handler) e, se for JSON, conferido antes de decodificar (profundidade,
///     numa varredura sem recursão) e depois (texto por campo e número de
///     itens): acima do teto, 413.
///
/// Tetos (D-21: 1 MB, maior só no import): 1 MiB por padrão; 5 MiB nas rotas
/// de import; 16 KiB nas rotas de `/auth`. Texto por campo: 32 K caracteres
/// fora do import (o import leva a lista inteira num campo).
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Corpo padrão (D-21).
const defaultRequestBodyLimitBytes = 1024 * 1024;

/// Import de lista de deck e de fichário (D-21: "maior só no import").
const importRequestBodyLimitBytes = 5 * 1024 * 1024;

/// Credenciais de `/auth`: nenhum formulário de conta passa de poucos KB.
const authRequestBodyLimitBytes = 16 * 1024;

/// Texto de um campo JSON, fora do import.
const defaultJsonFieldMaxChars = 32 * 1024;

/// Profundidade e itens de um JSON.
const jsonMaxDepth = 32;
const jsonMaxNodes = 50000;

/// URL inteira (caminho e query), em caracteres.
const requestUriMaxChars = 8 * 1024;

/// Campos da conta. E-mail: 254 (RFC 5321). Nome de usuário: 30. Senha no
/// login: 1024 (o cadastro já limita a 256; o teto do login só corta abuso).
const accountEmailMaxChars = 254;
const accountUsernameMaxChars = 30;
const loginPasswordMaxChars = 1024;

/// E-mail com formato mínimo (`algo@dominio.tld`, sem espaço) e no teto.
bool isAcceptableAccountEmail(String email) {
  final candidate = email.trim();
  return candidate.length <= accountEmailMaxChars &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(candidate);
}

const _importPaths = {
  '/import',
  '/import/to-deck',
  '/import/validate',
  '/binder/import/preview',
  '/binder/import/apply',
};

String _normalize(String path) =>
    path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;

bool isImportRequestPath(String path) =>
    _importPaths.contains(_normalize(path));

/// Teto do corpo da requisição, em bytes.
int requestBodyLimitFor(String path) {
  final normalized = _normalize(path);
  if (_importPaths.contains(normalized)) return importRequestBodyLimitBytes;
  if (normalized == '/auth' || normalized.startsWith('/auth/')) {
    return authRequestBodyLimitBytes;
  }
  return defaultRequestBodyLimitBytes;
}

/// Teto de texto por campo JSON: o import leva a lista inteira num campo.
int jsonFieldMaxCharsFor(String path) =>
    isImportRequestPath(path)
        ? importRequestBodyLimitBytes
        : defaultJsonFieldMaxChars;

/// Recusa pública da requisição, no formato da D-21.
class RequestLimitRejection {
  const RequestLimitRejection(
    this.statusCode,
    this.code,
    this.message, {
    this.limit,
  });

  final int statusCode;
  final String code;
  final String message;
  final int? limit;

  Map<String, Object?> toJson({String? requestId}) => {
    'error': code,
    'message': message,
    if (limit != null) 'limit': limit,
    if (requestId != null) 'request_id': requestId,
  };
}

String? _header(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name) return entry.value;
  }
  return null;
}

/// Tamanho declarado do corpo, depois de [checkRequestHeaders] aceitar.
int declaredContentLength(Map<String, String> headers) =>
    int.tryParse(_header(headers, 'content-length')?.trim() ?? '') ?? 0;

/// URL longa demais: decide antes da capability, sem olhar mais nada.
RequestLimitRejection? checkRequestUri(Uri uri) {
  if (uri.toString().length <= requestUriMaxChars) return null;
  return const RequestLimitRejection(
    HttpStatus.requestUriTooLong,
    'request_uri_too_long',
    'O endereço da requisição é longo demais.',
    limit: requestUriMaxChars,
  );
}

/// Decide pelos cabeçalhos, sem ler o corpo.
RequestLimitRejection? checkRequestHeaders({
  required String path,
  required Map<String, String> headers,
}) {
  final encoding = _header(headers, 'content-encoding')?.trim().toLowerCase();
  if (encoding != null && encoding.isNotEmpty && encoding != 'identity') {
    return const RequestLimitRejection(
      HttpStatus.unsupportedMediaType,
      'request_body_encoding_unsupported',
      'Corpo comprimido não é aceito. Envie o JSON sem compressão.',
    );
  }
  final transfer = _header(headers, 'transfer-encoding')?.trim().toLowerCase();
  if (transfer != null && transfer.isNotEmpty && transfer != 'identity') {
    return const RequestLimitRejection(
      HttpStatus.lengthRequired,
      'request_body_length_required',
      'Envie o corpo com Content-Length; corpo em partes não é aceito.',
    );
  }
  final limit = requestBodyLimitFor(path);
  final rawLength = _header(headers, 'content-length')?.trim();
  if (rawLength != null && rawLength.isNotEmpty) {
    final length =
        RegExp(r'^\d{1,15}$').hasMatch(rawLength) ? int.parse(rawLength) : null;
    if (length == null) {
      return const RequestLimitRejection(
        HttpStatus.badRequest,
        'request_body_length_invalid',
        'Content-Length inválido.',
      );
    }
    if (length > limit) {
      return RequestLimitRejection(
        HttpStatus.requestEntityTooLarge,
        'request_body_too_large',
        'O corpo da requisição passa do limite de ${_humanBytes(limit)}.',
        limit: limit,
      );
    }
  }
  return null;
}

/// Lê o corpo declarado uma vez (o dart_frog guarda o texto para o handler)
/// e confere a forma do JSON. Chame depois de [checkRequestHeaders].
Future<RequestLimitRejection?> checkRequestBody(Request request) async {
  if (declaredContentLength(request.headers) <= 0) return null;
  final String body;
  try {
    body = await request.body();
  } on Object {
    // Corpo que não é texto UTF-8 ou conexão que caiu no meio.
    return const RequestLimitRejection(
      HttpStatus.badRequest,
      'request_body_unreadable',
      'Não foi possível ler o corpo da requisição. Envie JSON em UTF-8.',
    );
  }
  return checkJsonBody(request.uri.path, body);
}

/// Confere o corpo já lido. Só olha JSON (objeto ou lista); JSON inválido
/// não é recusado aqui: o handler responde como sempre.
RequestLimitRejection? checkJsonBody(String path, String body) {
  final start = _firstNonSpace(body);
  if (start < 0) return null;
  final first = body.codeUnitAt(start);
  if (first != 0x7B && first != 0x5B) return null; // { [
  if (_exceedsDepth(body, start, jsonMaxDepth)) {
    return const RequestLimitRejection(
      HttpStatus.requestEntityTooLarge,
      'request_json_too_deep',
      'O JSON tem níveis demais.',
      limit: jsonMaxDepth,
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  final maxChars = jsonFieldMaxCharsFor(path);
  var nodes = 0;
  RequestLimitRejection? visit(Object? value) {
    if (++nodes > jsonMaxNodes) {
      return const RequestLimitRejection(
        HttpStatus.requestEntityTooLarge,
        'request_json_too_many_items',
        'O JSON tem itens demais.',
        limit: jsonMaxNodes,
      );
    }
    if (value is String) {
      return value.length > maxChars
          ? RequestLimitRejection(
            HttpStatus.requestEntityTooLarge,
            'request_field_too_large',
            'Um campo do corpo passa do limite de $maxChars caracteres.',
            limit: maxChars,
          )
          : null;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final rejection = visit(entry.key) ?? visit(entry.value);
        if (rejection != null) return rejection;
      }
    } else if (value is List) {
      for (final item in value) {
        final rejection = visit(item);
        if (rejection != null) return rejection;
      }
    }
    return null;
  }

  // A profundidade já foi limitada acima: a recursão tem no máximo
  // [jsonMaxDepth] níveis.
  return visit(decoded);
}

int _firstNonSpace(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit != 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) {
      return i;
    }
  }
  return -1;
}

/// Varredura sem recursão: conta `{`/`[` fora de strings.
bool _exceedsDepth(String text, int start, int maxDepth) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (unit == 0x5C) {
        escaped = true; // \
      } else if (unit == 0x22) {
        inString = false; // "
      }
      continue;
    }
    if (unit == 0x22) {
      inString = true;
    } else if (unit == 0x7B || unit == 0x5B) {
      if (++depth > maxDepth) return true;
    } else if (unit == 0x7D || unit == 0x5D) {
      depth--;
    }
  }
  return false;
}

String _humanBytes(int bytes) =>
    bytes >= 1024 * 1024
        ? '${bytes ~/ (1024 * 1024)} MB'
        : '${bytes ~/ 1024} KB';
