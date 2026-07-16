import 'dart:convert';

import 'ai_log_service.dart';

class AiProviderTokenUsage {
  const AiProviderTokenUsage({this.inputTokens, this.outputTokens});

  final int? inputTokens;
  final int? outputTokens;
}

AiProviderTokenUsage parseAiProviderTokenUsage(List<int>? responseBodyBytes) {
  if (responseBodyBytes == null || responseBodyBytes.isEmpty) {
    return const AiProviderTokenUsage();
  }
  try {
    final decoded = jsonDecode(utf8.decode(responseBodyBytes));
    if (decoded is! Map || decoded['usage'] is! Map) {
      return const AiProviderTokenUsage();
    }
    final usage = decoded['usage'] as Map;
    return AiProviderTokenUsage(
      inputTokens: _usageInt(usage['prompt_tokens']),
      outputTokens: _usageInt(usage['completion_tokens']),
    );
  } catch (_) {
    return const AiProviderTokenUsage();
  }
}

Future<bool> recordAiProviderCall({
  required dynamic db,
  required String endpoint,
  required String model,
  required int latencyMs,
  required bool success,
  String? userId,
  String? deckId,
  List<int>? responseBodyBytes,
  String? failureCode,
}) {
  final usage = parseAiProviderTokenUsage(responseBodyBytes);
  return AiLogService(db).log(
    userId: userId,
    deckId: deckId,
    endpoint:
        endpoint.startsWith('provider:') ? endpoint : 'provider:$endpoint',
    model: model,
    latencyMs: latencyMs,
    inputTokens: usage.inputTokens,
    outputTokens: usage.outputTokens,
    success: success,
    errorMessage: success ? null : (failureCode ?? 'provider_call_failed'),
  );
}

int? _usageInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
