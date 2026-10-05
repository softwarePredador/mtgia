import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import '../runtime_environment.dart';

/// D-71 (BT-PRIV-001): cada pedido de exportação vira uma linha de log
/// estruturado, com quando, o resultado e uma referência pseudônima de quem
/// pediu. Nunca leva o ID cru, a senha nem o conteúdo exportado.
///
/// Segue o formato do `MANALOOM_CATALOG_CARD_DEMAND` (D-63): marcador e JSON
/// numa linha do stdout, contada a partir do log, sem tabela nova.
const privacyExportRequestLogMarker = 'MANALOOM_PRIVACY_EXPORT_REQUEST';
const privacyExportRequestEvent = 'privacy_export_request';

/// Rótulo da derivação: a chave da referência nunca é o `JWT_SECRET` em si.
const privacyExportRequesterKeyLabel = 'manaloom-privacy-export-requester-v1';

/// Tamanho da referência, em caracteres hexadecimais (64 bits).
const privacyExportRequesterReferenceLength = 16;

/// Como terminou o pedido.
enum PrivacyExportRequestResult {
  ok('ok'),
  methodNotAllowed('method_not_allowed'),
  passwordRequired('password_required'),
  invalidPassword('invalid_password'),
  rateLimited('rate_limited'),
  notFound('not_found'),
  error('error');

  const PrivacyExportRequestResult(this.wireName);
  final String wireName;
}

/// Chave da referência, derivada do segredo do servidor com um rótulo
/// próprio.
List<int> derivePrivacyExportRequesterKey(String serverSecret) =>
    Hmac(
      sha256,
      utf8.encode(serverSecret),
    ).convert(utf8.encode(privacyExportRequesterKeyLabel)).bytes;

/// Referência estável da conta que pediu, sem o ID: HMAC-SHA256 do ID com a
/// chave derivada, truncado. Nulo quando o servidor não tem segredo.
String? privacyExportRequesterReference(String userId, String serverSecret) {
  if (serverSecret.trim().isEmpty) return null;
  final digest = Hmac(
    sha256,
    derivePrivacyExportRequesterKey(serverSecret),
  ).convert(utf8.encode(userId.trim().toLowerCase()));
  return digest.toString().substring(0, privacyExportRequesterReferenceLength);
}

/// A linha do pedido: marcador e JSON com evento, horário, resultado e
/// referência.
String privacyExportRequestLogLine({
  required String userId,
  required PrivacyExportRequestResult result,
  required String serverSecret,
  DateTime? at,
}) {
  final fields = <String, Object?>{
    'event': privacyExportRequestEvent,
    'at': (at ?? DateTime.now()).toUtc().toIso8601String(),
    'result': result.wireName,
    'requester': privacyExportRequesterReference(userId, serverSecret),
  };
  return '$privacyExportRequestLogMarker ${jsonEncode(fields)}';
}

String? _secretOverride;
String? _runtimeSecret;

/// O segredo do servidor (`JWT_SECRET`), lido uma vez.
String privacyExportRequesterSecret() =>
    _secretOverride ??
    (_runtimeSecret ??= loadRuntimeEnvironment()['JWT_SECRET'] ?? '');

@visibleForTesting
void overridePrivacyExportRequesterSecretForTesting(String? secret) {
  _secretOverride = secret;
}
