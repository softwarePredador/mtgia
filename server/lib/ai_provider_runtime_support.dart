import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const aiProviderUnavailableMessage =
    'O serviço de IA está temporariamente indisponível. Tente novamente em instantes.';

enum AiProviderFailureCategory {
  timeout,
  rateLimited,
  unavailable,
  rejected,
  transport,
}

class AiProviderFailureContract {
  const AiProviderFailureContract({
    required this.category,
    required this.httpStatus,
    required this.errorCode,
    required this.providerStatus,
    required this.retryable,
  });

  final AiProviderFailureCategory category;
  final int httpStatus;
  final String errorCode;
  final String providerStatus;
  final bool retryable;
}

Map<String, String> aiSafetyIdentifierPayload(String? userIdentifier) {
  final normalized = userIdentifier?.trim();
  if (normalized == null || normalized.isEmpty) return const {};

  final digest = sha256.convert(utf8.encode('manaloom:$normalized'));
  return {'safety_identifier': 'manaloom_$digest'};
}

AiProviderFailureContract classifyAiProviderHttpFailure(
  int upstreamStatusCode,
) {
  if (upstreamStatusCode == HttpStatus.requestTimeout) {
    return const AiProviderFailureContract(
      category: AiProviderFailureCategory.timeout,
      httpStatus: HttpStatus.gatewayTimeout,
      errorCode: 'provider_timeout',
      providerStatus: 'timeout',
      retryable: true,
    );
  }
  if (upstreamStatusCode == HttpStatus.tooManyRequests) {
    return const AiProviderFailureContract(
      category: AiProviderFailureCategory.rateLimited,
      httpStatus: HttpStatus.serviceUnavailable,
      errorCode: 'provider_rate_limited',
      providerStatus: 'rate_limited',
      retryable: true,
    );
  }
  if (upstreamStatusCode == HttpStatus.unauthorized ||
      upstreamStatusCode == HttpStatus.forbidden) {
    return const AiProviderFailureContract(
      category: AiProviderFailureCategory.unavailable,
      httpStatus: HttpStatus.serviceUnavailable,
      errorCode: 'provider_unavailable',
      providerStatus: 'unavailable',
      retryable: false,
    );
  }
  if (upstreamStatusCode >= 500) {
    return const AiProviderFailureContract(
      category: AiProviderFailureCategory.unavailable,
      httpStatus: HttpStatus.serviceUnavailable,
      errorCode: 'provider_unavailable',
      providerStatus: 'unavailable',
      retryable: true,
    );
  }
  return const AiProviderFailureContract(
    category: AiProviderFailureCategory.rejected,
    httpStatus: HttpStatus.badGateway,
    errorCode: 'provider_rejected',
    providerStatus: 'rejected',
    retryable: false,
  );
}

int? parseAiProviderRetryAfterSeconds(
  String? rawValue, {
  DateTime? now,
  int maximumSeconds = 3600,
}) {
  final normalized = rawValue?.trim();
  if (normalized == null || normalized.isEmpty || maximumSeconds < 0) {
    return null;
  }

  final seconds = int.tryParse(normalized);
  if (seconds != null) {
    if (seconds < 0) return null;
    return seconds.clamp(0, maximumSeconds);
  }

  try {
    final retryAt = HttpDate.parse(normalized).toUtc();
    final current = (now ?? DateTime.now()).toUtc();
    final deltaMilliseconds = retryAt.difference(current).inMilliseconds;
    if (deltaMilliseconds <= 0) return 0;
    final roundedSeconds = (deltaMilliseconds / 1000).ceil();
    return roundedSeconds.clamp(0, maximumSeconds);
  } on FormatException {
    return null;
  } on HttpException {
    return null;
  }
}

const aiProviderTransportFailureContract = AiProviderFailureContract(
  category: AiProviderFailureCategory.transport,
  httpStatus: HttpStatus.serviceUnavailable,
  errorCode: 'provider_transport_error',
  providerStatus: 'unavailable',
  retryable: true,
);

int mapAiProviderHttpStatus(int upstreamStatusCode) =>
    classifyAiProviderHttpFailure(upstreamStatusCode).httpStatus;
