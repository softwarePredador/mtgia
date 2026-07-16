import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const aiProviderUnavailableMessage =
    'O serviço de IA está temporariamente indisponível. Tente novamente em instantes.';

Map<String, String> aiSafetyIdentifierPayload(String? userIdentifier) {
  final normalized = userIdentifier?.trim();
  if (normalized == null || normalized.isEmpty) return const {};

  final digest = sha256.convert(utf8.encode('manaloom:$normalized'));
  return {'safety_identifier': 'manaloom_$digest'};
}

int mapAiProviderHttpStatus(int upstreamStatusCode) {
  if (upstreamStatusCode == HttpStatus.requestTimeout) {
    return HttpStatus.gatewayTimeout;
  }
  if (upstreamStatusCode == HttpStatus.unauthorized ||
      upstreamStatusCode == HttpStatus.forbidden ||
      upstreamStatusCode == HttpStatus.tooManyRequests ||
      upstreamStatusCode >= 500) {
    return HttpStatus.serviceUnavailable;
  }
  return HttpStatus.badGateway;
}
