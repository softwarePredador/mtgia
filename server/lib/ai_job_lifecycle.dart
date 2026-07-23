import 'dart:math';

const aiJobRequestKeyMaxLength = 128;

class AiJobRequestKeyException implements Exception {
  const AiJobRequestKeyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiJobIdempotencyConflict implements Exception {
  const AiJobIdempotencyConflict();

  @override
  String toString() => 'A chave de idempotencia ja foi usada com outro pedido.';
}

class AiJobCreation {
  const AiJobCreation({
    required this.jobId,
    required this.requestKey,
    required this.isNew,
  });

  final String jobId;
  final String requestKey;
  final bool isNew;
}

String? normalizeOptionalAiJobRequestKey(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const AiJobRequestKeyException('request_key precisa ser uma string.');
  }
  final value = raw.trim();
  if (value.isEmpty || value.length > aiJobRequestKeyMaxLength) {
    throw const AiJobRequestKeyException(
      'request_key precisa ter entre 1 e 128 caracteres.',
    );
  }
  if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value)) {
    throw const AiJobRequestKeyException(
      'request_key contem caracteres invalidos.',
    );
  }
  return value;
}

String createServerAiJobRequestKey(String prefix) {
  final random = Random.secure();
  final suffix =
      List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  return '$prefix:$suffix';
}
