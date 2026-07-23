import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'endpoint_cache.dart';
import 'commander_bracket.dart';
import 'openai_runtime_config.dart';
import 'ai_job_lifecycle.dart';

// Bump whenever the player-facing generate response contract changes. Cached
// payloads are returned as-is, so an older key could omit safety diagnostics
// such as deckbuilding_contract until its TTL expires.
const aiGenerateCacheContractVersion = 'v3';
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
    required this.constraints,
  });

  final Map<String, dynamic> body;
  final String prompt;
  final String format;
  final String? commanderName;
  final AiGenerateConstraints constraints;
}

class AiGenerateConstraints {
  const AiGenerateConstraints({
    required this.preferCollection,
    required this.collectionOnly,
    required this.budgetLimitBrl,
  });

  const AiGenerateConstraints.empty()
    : preferCollection = false,
      collectionOnly = false,
      budgetLimitBrl = null;

  final bool preferCollection;
  final bool collectionOnly;
  final int? budgetLimitBrl;

  bool get isRequested =>
      preferCollection || collectionOnly || budgetLimitBrl != null;

  Map<String, dynamic> toJson() => {
    if (preferCollection || collectionOnly) 'prefer_collection': true,
    if (collectionOnly) 'collection_only': true,
    if (budgetLimitBrl != null) 'budget_limit_brl': budgetLimitBrl,
  };
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

  final constraints = parseAiGenerateConstraints(
    body['generation_constraints'],
    wasPresent: body.containsKey('generation_constraints'),
  );

  try {
    final requestKey = normalizeOptionalAiJobRequestKey(body['request_key']);
    if (requestKey == null) {
      body.remove('request_key');
    } else {
      body['request_key'] = requestKey;
    }
  } on AiJobRequestKeyException catch (error) {
    throw AiGenerateRequestValidationException(error.message);
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
  if (constraints.isRequested) {
    body['generation_constraints'] = constraints.toJson();
  } else {
    body.remove('generation_constraints');
  }

  return AiGenerateRequestInput(
    body: body,
    prompt: prompt,
    format: format,
    commanderName: commanderName,
    constraints: constraints,
  );
}

AiGenerateConstraints parseAiGenerateConstraints(
  Object? raw, {
  bool wasPresent = true,
}) {
  if (!wasPresent || raw == null) return const AiGenerateConstraints.empty();
  if (raw is! Map) {
    throw const AiGenerateRequestValidationException(
      'generation_constraints must be an object',
    );
  }
  final values = raw.cast<Object?, Object?>();
  const knownKeys = {
    'prefer_collection',
    'collection_only',
    'budget_limit_brl',
  };
  final unknown = values.keys
      .map((key) => key?.toString() ?? '')
      .where((key) => !knownKeys.contains(key))
      .toList(growable: false);
  if (unknown.isNotEmpty) {
    throw const AiGenerateRequestValidationException(
      'generation_constraints contains unsupported fields',
    );
  }

  bool readBool(String key) {
    final value = values[key];
    if (value == null) return false;
    if (value is bool) return value;
    throw AiGenerateRequestValidationException('$key must be a boolean');
  }

  final rawBudget = values['budget_limit_brl'];
  final budget = switch (rawBudget) {
    null => null,
    int() => rawBudget,
    num() when rawBudget == rawBudget.roundToDouble() => rawBudget.toInt(),
    _ =>
      throw const AiGenerateRequestValidationException(
        'budget_limit_brl must be an integer',
      ),
  };
  if (budget != null && (budget < 0 || budget > 100000)) {
    throw const AiGenerateRequestValidationException(
      'budget_limit_brl must be between 0 and 100000',
    );
  }
  final collectionOnly = readBool('collection_only');
  return AiGenerateConstraints(
    preferCollection: readBool('prefer_collection') || collectionOnly,
    collectionOnly: collectionOnly,
    budgetLimitBrl: budget,
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
  AiGenerateConstraints constraints = const AiGenerateConstraints.empty(),
}) {
  final normalizedCommander = normalizeAiGenerateCommanderName(commanderName);
  final normalizedProfileVersion = referenceProfileVersion?.trim() ?? '';
  final payload = {
    'version': 3,
    'prompt': normalizeAiGeneratePrompt(prompt),
    'format': normalizeAiGenerateFormat(format),
    'bracket': normalizeAiGenerateBracket(bracket),
    if (normalizedCommander.isNotEmpty) 'commander_name': normalizedCommander,
    if (normalizedProfileVersion.isNotEmpty)
      'reference_profile_version': normalizedProfileVersion,
    if (constraints.isRequested) 'generation_constraints': constraints.toJson(),
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
  payload.remove('request_key');
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
