import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'endpoint_cache.dart';

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

String buildAiGenerateCacheKey({
  required String prompt,
  required String format,
  Object? bracket,
}) {
  final material = jsonEncode({
    'version': 1,
    'prompt': normalizeAiGeneratePrompt(prompt),
    'format': normalizeAiGenerateFormat(format),
    'bracket': normalizeAiGenerateBracket(bracket),
  });
  final digest = sha256.convert(utf8.encode(material)).toString();
  return 'ai_generate:v1:$digest';
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
    'timings': {
      ...(payload['timings'] as Map? ?? const {}),
      ...timings,
    },
  };
}
