import 'dart:convert';

class JsonObjectValidationException implements Exception {
  const JsonObjectValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> decodeOptionalJsonObject(String rawBody) {
  final normalized = rawBody.trim();
  if (normalized.isEmpty) return <String, dynamic>{};
  try {
    return requireJsonObject(jsonDecode(normalized));
  } on JsonObjectValidationException {
    rethrow;
  } catch (_) {
    throw const JsonObjectValidationException('JSON invalido');
  }
}

Map<String, dynamic> requireJsonObject(Object? decoded) {
  if (decoded is! Map) {
    throw const JsonObjectValidationException('JSON invalido');
  }
  try {
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    throw const JsonObjectValidationException('JSON invalido');
  }
}

String? readOptionalJsonString(
  Map<String, dynamic> body,
  String key, {
  int maxLength = 300,
}) {
  final value = body[key];
  if (value == null) return null;
  if (value is! String) {
    throw JsonObjectValidationException('$key must be a string');
  }
  final normalized = value.trim();
  if (normalized.length > maxLength) {
    throw JsonObjectValidationException('$key exceeds the allowed size');
  }
  return normalized;
}

bool readOptionalJsonBool(
  Map<String, dynamic> body,
  String key, {
  bool fallback = false,
}) {
  final value = body[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw JsonObjectValidationException('$key must be a boolean');
  }
  return value;
}
