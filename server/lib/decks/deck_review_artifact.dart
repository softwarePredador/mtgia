import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../runtime_environment.dart';

/// `DeckReviewArtifact v1` (DCK-P0-02; decisão D-29 do dono): o artefato único
/// que liga o preview de uma mudança de deck ao commit dela.
///
/// O preview emite o artefato; o commit o verifica antes de qualquer escrita.
/// O artefato liga:
/// - o dono (`owner_id`): outro usuário falha;
/// - o deck (`deck_id`) e o estado dele no preview: a revisão
///   (`deck_revision`, quando o fluxo a conhece) e a assinatura do conteúdo
///   (`deck_signature`); deck mudado depois do preview falha como velho;
/// - o hash canônico das entradas (`input_hash`) e das restrições
///   (`constraints_hash`): qualquer mudança semântica invalida;
/// - o tipo do fluxo (`kind`): artefato de um fluxo não vale em outro;
/// - a expiração: 24 horas, reutilizável pelo mesmo usuário enquanto valer
///   (D-29: sem tabela de uso único).
///
/// Formato: `drv1.<payload>.<assinatura>`, em base64url sem padding. A
/// assinatura é HMAC-SHA256 sobre `drv1.<payload>`; adulterar qualquer parte
/// falha em tempo constante.
const deckReviewArtifactVersion = 'deck_review_artifact_v1';
const deckReviewArtifactAlgo = 'hmac-sha256';
const deckReviewArtifactLifetime = Duration(hours: 24);
const deckReviewArtifactTokenPrefix = 'drv1';

/// Chaves do payload que o módulo controla; as demais são do fluxo (por
/// exemplo, as trocas autorizadas pelo Optimize).
const deckReviewArtifactClaimKeys = <String>{
  'version',
  'kind',
  'owner_id',
  'deck_id',
  'deck_revision',
  'deck_signature',
  'input_hash',
  'constraints_hash',
  'issued_at',
  'expires_at',
};

/// O segredo que assina os artefatos: a chave dedicada às prévias
/// (`OPTIMIZATION_APPLY_SIGNING_SECRET`, que nasceu com o Optimize) ou, sem
/// ela, o `JWT_SECRET`. Vazio: nenhuma prévia recebe artefato e nenhum commit
/// passa (falha fechado).
String resolveDeckReviewSigningSecret({Map<String, String>? environment}) {
  String? read(String key) =>
      environment != null ? environment[key] : loadRuntimeEnvironment()[key];
  final dedicated = read('OPTIMIZATION_APPLY_SIGNING_SECRET')?.trim() ?? '';
  if (dedicated.isNotEmpty) return dedicated;
  return read('JWT_SECRET')?.trim() ?? '';
}

class DeckReviewArtifactVerification {
  const DeckReviewArtifactVerification({
    required this.valid,
    required this.code,
    this.payload = const <String, dynamic>{},
  });

  final bool valid;

  /// `ok` ou o motivo da recusa: `signing_secret_unavailable`,
  /// `malformed_token`, `invalid_signature`, `invalid_payload`,
  /// `unsupported_version`, `kind_mismatch`, `owner_binding_mismatch`,
  /// `deck_binding_mismatch`, `expired_token`, `stale_deck_revision`,
  /// `stale_deck_signature`, `input_mismatch` ou `constraints_mismatch`.
  final String code;
  final Map<String, dynamic> payload;
}

/// Emite o artefato de um preview.
String issueDeckReviewArtifact({
  required String signingSecret,
  required String kind,
  required String ownerId,
  required String? deckId,
  int? deckRevision,
  String? deckSignature,
  required String inputHash,
  required String constraintsHash,
  Map<String, Object?> body = const <String, Object?>{},
  DateTime? issuedAt,
  Duration lifetime = deckReviewArtifactLifetime,
}) {
  if (signingSecret.trim().isEmpty) {
    throw ArgumentError.value('', 'signingSecret', 'segredo vazio');
  }
  final reserved = body.keys.where(deckReviewArtifactClaimKeys.contains);
  if (reserved.isNotEmpty) {
    throw ArgumentError.value(
      reserved.toList(),
      'body',
      'o fluxo não pode usar chaves reservadas do artefato',
    );
  }
  final now = (issuedAt ?? DateTime.now().toUtc()).toUtc();
  final payload = <String, Object?>{
    'version': deckReviewArtifactVersion,
    'kind': kind,
    'owner_id': ownerId,
    'deck_id': deckId,
    'deck_revision': deckRevision,
    'deck_signature': deckSignature,
    'input_hash': inputHash,
    'constraints_hash': constraintsHash,
    ...body,
    'issued_at': now.millisecondsSinceEpoch ~/ 1000,
    'expires_at': now.add(lifetime).millisecondsSinceEpoch ~/ 1000,
  };
  final signed =
      '$deckReviewArtifactTokenPrefix.'
      '${_base64UrlNoPadding(utf8.encode(jsonEncode(payload)))}';
  return '$signed.${_base64UrlNoPadding(_sign(signingSecret, signed))}';
}

/// Verifica o artefato no commit. Sem recusa, devolve `valid` com o payload
/// inteiro (as chaves do fluxo ficam no mesmo mapa).
///
/// [currentDeckRevision] e [currentDeckSignature] são o estado do deck no
/// commit, lido sob `FOR UPDATE`, e têm de ser iguais aos do artefato: o
/// artefato sem revisão não vale num commit que conhece a revisão, e o
/// contrário também não. [expectedInputHash] e
/// [expectedConstraintsHash], quando o commit reenvia as entradas, têm de
/// bater com os do preview.
DeckReviewArtifactVerification verifyDeckReviewArtifact({
  required String signingSecret,
  required String token,
  required String expectedKind,
  required String ownerId,
  required String? deckId,
  int? currentDeckRevision,
  String? currentDeckSignature,
  String? expectedInputHash,
  String? expectedConstraintsHash,
  DateTime? now,
}) {
  if (signingSecret.trim().isEmpty) {
    return const DeckReviewArtifactVerification(
      valid: false,
      code: 'signing_secret_unavailable',
    );
  }
  final parts = token.trim().split('.');
  if (parts.length != 3 ||
      parts[0] != deckReviewArtifactTokenPrefix ||
      parts[1].isEmpty ||
      parts[2].isEmpty) {
    return const DeckReviewArtifactVerification(
      valid: false,
      code: 'malformed_token',
    );
  }

  final Map<String, dynamic> payload;
  try {
    final received = _decodeBase64UrlNoPadding(parts[2]);
    if (!_constantTimeEquals(
      _sign(signingSecret, '${parts[0]}.${parts[1]}'),
      received,
    )) {
      return const DeckReviewArtifactVerification(
        valid: false,
        code: 'invalid_signature',
      );
    }
    final decoded = jsonDecode(
      utf8.decode(_decodeBase64UrlNoPadding(parts[1])),
    );
    if (decoded is! Map) {
      return const DeckReviewArtifactVerification(
        valid: false,
        code: 'invalid_payload',
      );
    }
    payload = decoded.cast<String, dynamic>();
  } on FormatException {
    return const DeckReviewArtifactVerification(
      valid: false,
      code: 'malformed_token',
    );
  }

  DeckReviewArtifactVerification fail(String code) =>
      DeckReviewArtifactVerification(
        valid: false,
        code: code,
        payload: payload,
      );

  if (payload['version'] != deckReviewArtifactVersion) {
    return fail('unsupported_version');
  }
  if (payload['kind'] != expectedKind) return fail('kind_mismatch');
  if (payload['owner_id']?.toString() != ownerId) {
    return fail('owner_binding_mismatch');
  }
  if (payload['deck_id']?.toString() != deckId) {
    return fail('deck_binding_mismatch');
  }
  final expiresAt = _readInt(payload['expires_at']);
  final currentEpoch =
      (now ?? DateTime.now().toUtc()).toUtc().millisecondsSinceEpoch ~/ 1000;
  if (expiresAt == null || expiresAt < currentEpoch) {
    return fail('expired_token');
  }
  // O estado do deck no commit tem de ser o do preview: revisão e assinatura
  // iguais, e ausentes só quando ausentes dos dois lados (fluxo sem deck).
  if (_readInt(payload['deck_revision']) != currentDeckRevision) {
    return fail('stale_deck_revision');
  }
  if (payload['deck_signature']?.toString() != currentDeckSignature) {
    return fail('stale_deck_signature');
  }
  if (expectedInputHash != null &&
      payload['input_hash']?.toString() != expectedInputHash) {
    return fail('input_mismatch');
  }
  if (expectedConstraintsHash != null &&
      payload['constraints_hash']?.toString() != expectedConstraintsHash) {
    return fail('constraints_mismatch');
  }
  return DeckReviewArtifactVerification(
    valid: true,
    code: 'ok',
    payload: payload,
  );
}

/// Hash canônico (SHA-256, hex) de um valor JSON: mapas com as chaves em
/// ordem em todos os níveis, para que a ordem de montagem não mude o hash.
String canonicalDeckReviewHash(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

Object? _canonical(Object? value) {
  if (value is Map) {
    final entries =
        value.entries.toList()
          ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
    return {
      for (final entry in entries) '${entry.key}': _canonical(entry.value),
    };
  }
  if (value is Iterable) return [for (final item in value) _canonical(item)];
  return value;
}

List<int> _sign(String secret, String message) =>
    Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(message)).bytes;

String _base64UrlNoPadding(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

List<int> _decodeBase64UrlNoPadding(String value) {
  final padding = (4 - value.length % 4) % 4;
  return base64Url.decode('$value${'=' * padding}');
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var index = 0; index < a.length; index++) {
    difference |= a[index] ^ b[index];
  }
  return difference == 0;
}

int? _readInt(Object? raw) => switch (raw) {
  int value => value,
  num value => value.toInt(),
  String value => int.tryParse(value.trim()),
  _ => null,
};
