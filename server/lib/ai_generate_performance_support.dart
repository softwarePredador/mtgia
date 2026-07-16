import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'endpoint_cache.dart';
import 'commander_bracket.dart';
import 'openai_runtime_config.dart';

// Bump whenever the player-facing generate response contract changes. Cached
// payloads are returned as-is, so an older key could omit safety diagnostics
// such as deckbuilding_contract until its TTL expires.
const aiGenerateCacheContractVersion = 'v2';
const aiGenerateMaxPromptLength = 8000;
const aiGenerateMaxFormatLength = 80;
const aiGenerateMaxCommanderNameLength = 300;

class AiGenerateRequestValidationException implements Exception {
  const AiGenerateRequestValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiGenerateRequestInput {
  const AiGenerateRequestInput({
    required this.body,
    required this.prompt,
    required this.format,
    required this.commanderName,
  });

  final Map<String, dynamic> body;
  final String prompt;
  final String format;
  final String? commanderName;
}

AiGenerateRequestInput parseAiGenerateRequestInput(Object? decoded) {
  if (decoded is! Map) {
    throw const AiGenerateRequestValidationException('JSON invalido');
  }

  late final Map<String, dynamic> body;
  try {
    body = Map<String, dynamic>.from(decoded);
  } catch (_) {
    throw const AiGenerateRequestValidationException('JSON invalido');
  }

  final rawPrompt = body['prompt'];
  if (rawPrompt is! String || rawPrompt.trim().isEmpty) {
    throw const AiGenerateRequestValidationException('Prompt is required');
  }
  final prompt = rawPrompt.trim();
  if (prompt.length > aiGenerateMaxPromptLength) {
    throw const AiGenerateRequestValidationException(
      'Prompt exceeds the allowed size',
    );
  }

  final rawFormat = body['format'];
  if (rawFormat != null && rawFormat is! String) {
    throw const AiGenerateRequestValidationException('Format must be a string');
  }
  final normalizedFormat = (rawFormat as String?)?.trim() ?? '';
  final format = normalizedFormat.isEmpty ? 'Commander' : normalizedFormat;
  if (format.length > aiGenerateMaxFormatLength) {
    throw const AiGenerateRequestValidationException(
      'Format exceeds the allowed size',
    );
  }

  final rawCommanderName = body['commander_name'];
  if (rawCommanderName != null && rawCommanderName is! String) {
    throw const AiGenerateRequestValidationException(
      'Commander name must be a string',
    );
  }
  final normalizedCommanderName = (rawCommanderName as String?)?.trim() ?? '';
  if (normalizedCommanderName.length > aiGenerateMaxCommanderNameLength) {
    throw const AiGenerateRequestValidationException(
      'Commander name exceeds the allowed size',
    );
  }
  final commanderName =
      normalizedCommanderName.isEmpty ? null : normalizedCommanderName;

  final bracketResult = parseCommanderBracket(body['bracket']);
  if (bracketResult.error != null) {
    throw AiGenerateRequestValidationException(bracketResult.error!);
  }

  body['prompt'] = prompt;
  body['format'] = format;
  if (commanderName == null) {
    body.remove('commander_name');
  } else {
    body['commander_name'] = commanderName;
  }
  if (bracketResult.value == null) {
    body.remove('bracket');
  } else {
    body['bracket'] = bracketResult.value;
  }

  return AiGenerateRequestInput(
    body: body,
    prompt: prompt,
    format: format,
    commanderName: commanderName,
  );
}

String normalizeAiGeneratePrompt(String prompt) {
  return prompt.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeAiGenerateFormat(String format) {
  final normalized = format.trim().toLowerCase();
  if (normalized == 'edh') return 'commander';
  return normalized.isEmpty ? 'commander' : normalized;
}

String normalizeAiGenerateBracket(Object? bracket) {
  final raw = bracket?.toString().trim().toLowerCase() ?? '';
  return raw.isEmpty ? 'unspecified' : raw;
}

String normalizeAiGenerateCommanderName(String? commanderName) {
  final raw = commanderName?.trim().toLowerCase() ?? '';
  return raw.isEmpty ? '' : raw.replaceAll(RegExp(r'\s+'), ' ');
}

String buildAiGenerateCacheKey({
  required String prompt,
  required String format,
  Object? bracket,
  String? commanderName,
  String? referenceProfileVersion,
}) {
  final normalizedCommander = normalizeAiGenerateCommanderName(commanderName);
  final normalizedProfileVersion = referenceProfileVersion?.trim() ?? '';
  final payload = {
    'version': 2,
    'prompt': normalizeAiGeneratePrompt(prompt),
    'format': normalizeAiGenerateFormat(format),
    'bracket': normalizeAiGenerateBracket(bracket),
    if (normalizedCommander.isNotEmpty) 'commander_name': normalizedCommander,
    if (normalizedProfileVersion.isNotEmpty)
      'reference_profile_version': normalizedProfileVersion,
  };
  final material = jsonEncode(payload);
  final digest = sha256.convert(utf8.encode(material)).toString();
  return 'ai_generate:$aiGenerateCacheContractVersion:$digest';
}

bool isAiGenerateAsyncRequested(Map<String, dynamic> body) {
  final asyncValue = body['async'];
  if (asyncValue == true) return true;
  if (asyncValue is String && asyncValue.trim().toLowerCase() == 'true') {
    return true;
  }

  for (final key in const ['profile', 'response_mode', 'mode']) {
    final value = body[key]?.toString().trim().toLowerCase();
    if (value == 'async' || value == 'background') return true;
  }

  return false;
}

Map<String, dynamic> buildAiGenerateSyncPayloadForAsyncJob(
  Map<String, dynamic> body,
) {
  final payload = Map<String, dynamic>.from(body);
  payload.remove('async');
  for (final key in const ['profile', 'response_mode', 'mode']) {
    final value = payload[key]?.toString().trim().toLowerCase();
    if (value == 'async' || value == 'background') {
      payload.remove(key);
    }
  }
  return payload;
}

class AiGenerateOpenAiTimeoutSelection {
  const AiGenerateOpenAiTimeoutSelection({
    required this.timeout,
    required this.envKey,
    required this.referenceGuidanceBudget,
  });

  final Duration timeout;
  final String envKey;
  final bool referenceGuidanceBudget;
}

bool isCommanderReferenceGuidanceFormat(String normalizedFormat) {
  return normalizedFormat == 'commander' || normalizedFormat == 'brawl';
}

AiGenerateOpenAiTimeoutSelection selectAiGenerateOpenAiTimeout({
  required OpenAiRuntimeConfig config,
  required String normalizedFormat,
  required bool referenceGuidanceEnabled,
}) {
  final baseTimeout = config.timeoutFor(
    key: 'OPENAI_TIMEOUT_GENERATE_SECONDS',
    fallback: const Duration(seconds: 8),
    devFallback: const Duration(seconds: 8),
    stagingFallback: const Duration(seconds: 8),
    prodFallback: const Duration(seconds: 12),
    min: const Duration(seconds: 3),
    max: const Duration(seconds: 90),
  );

  if (!referenceGuidanceEnabled ||
      !isCommanderReferenceGuidanceFormat(normalizedFormat)) {
    return AiGenerateOpenAiTimeoutSelection(
      timeout: baseTimeout,
      envKey: 'OPENAI_TIMEOUT_GENERATE_SECONDS',
      referenceGuidanceBudget: false,
    );
  }

  final hasReferenceOverride =
      (config.env['OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS'] ?? '')
          .trim()
          .isNotEmpty;
  final referenceTimeout = config.timeoutFor(
    key: 'OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS',
    fallback: const Duration(seconds: 24),
    devFallback: const Duration(seconds: 24),
    stagingFallback: const Duration(seconds: 24),
    prodFallback: const Duration(seconds: 24),
    min: const Duration(seconds: 3),
    max: const Duration(seconds: 90),
  );
  final selectedTimeout =
      !hasReferenceOverride && baseTimeout > referenceTimeout
          ? baseTimeout
          : referenceTimeout;

  return AiGenerateOpenAiTimeoutSelection(
    timeout: selectedTimeout,
    envKey: 'OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS',
    referenceGuidanceBudget: true,
  );
}

Map<String, dynamic> cloneAiGenerateJsonMap(Map<String, dynamic> payload) {
  return (jsonDecode(jsonEncode(payload)) as Map).cast<String, dynamic>();
}

Map<String, dynamic>? readAiGenerateCache(String cacheKey) {
  final cached = EndpointCache.instance.get(cacheKey);
  if (cached == null) return null;

  final payload = cloneAiGenerateJsonMap(cached);
  payload.remove('timings');
  payload['cache'] = {
    ...(payload['cache'] as Map? ?? const {}),
    'hit': true,
    'cache_key': cacheKey,
  };
  return payload;
}

void writeAiGenerateCache({
  required String cacheKey,
  required Map<String, dynamic> payload,
  required Duration ttl,
}) {
  final cachedPayload = cloneAiGenerateJsonMap(payload);
  cachedPayload['cache'] = {
    ...(cachedPayload['cache'] as Map? ?? const {}),
    'hit': false,
    'cache_key': cacheKey,
    'ttl_seconds': ttl.inSeconds,
  };
  EndpointCache.instance.set(cacheKey, cachedPayload, ttl: ttl);
}

Map<String, dynamic> withAiGenerateRuntimeMetadata({
  required Map<String, dynamic> payload,
  required String cacheKey,
  required bool cacheHit,
  required Map<String, int> timings,
}) {
  return {
    ...payload,
    'cache': {
      ...(payload['cache'] as Map? ?? const {}),
      'hit': cacheHit,
      'cache_key': cacheKey,
    },
    'timings': {...(payload['timings'] as Map? ?? const {}), ...timings},
  };
}
