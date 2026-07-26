import 'dart:convert';

import 'package:crypto/crypto.dart';

const battleJobRequestSchema = 'battle_job_request_v1';
const battleRequestCorrelationSchema = 'battle_request_correlation_v1';
const nativeBattleDispatchSchema = 'native_battle_dispatch_v1';

const sidecarEchoValidatedCorrelation = 'sidecar_echo_validated';
const serverDispatchRecordedCorrelation = 'server_dispatch_recorded';

String canonicalBattleJobRequestHash(Map<String, dynamic> payload) =>
    canonicalBattlePayloadHash(payload, excludedKeys: const {'request_hash'});

String canonicalNativeBattleDispatchHash(Map<String, dynamic> payload) =>
    canonicalBattlePayloadHash(payload, excludedKeys: const {'request_hash'});

String canonicalBattlePayloadHash(
  Map<String, dynamic> payload, {
  Set<String> excludedKeys = const {},
}) {
  final normalized = _canonicalValue(payload, excludedKeys: excludedKeys);
  return sha256.convert(utf8.encode('${jsonEncode(normalized)}\n')).toString();
}

Object? _canonicalValue(Object? value, {required Set<String> excludedKeys}) {
  if (value is Map) {
    final keys = value.keys
      .map((key) => key.toString())
      .where((key) => !excludedKeys.contains(key))
      .toList(growable: false)..sort();
    return <String, dynamic>{
      for (final key in keys)
        key: _canonicalValue(value[key], excludedKeys: excludedKeys),
    };
  }
  if (value is List) {
    return value
        .map((entry) => _canonicalValue(entry, excludedKeys: excludedKeys))
        .toList(growable: false);
  }
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  throw ArgumentError.value(
    value.runtimeType,
    'payload',
    'Battle request hashing only accepts JSON values.',
  );
}

class BattleEngineDispatchRecord {
  const BattleEngineDispatchRecord({
    required this.engine,
    required this.requestSchemaVersion,
    required this.requestHash,
    required this.correlationSource,
    required this.outcome,
    this.errorCode,
  });

  final String engine;
  final String requestSchemaVersion;
  final String requestHash;
  final String correlationSource;
  final String outcome;
  final String? errorCode;

  Map<String, dynamic> toJson() => {
    'engine': engine,
    'request_schema_version': requestSchemaVersion,
    'request_hash': requestHash,
    'correlation_source': correlationSource,
    'outcome': outcome,
    if (errorCode != null) 'error_code': errorCode,
  };
}

class BattleRequestCorrelation {
  const BattleRequestCorrelation({
    required this.engineRequestSchemaVersion,
    required this.engineRequestHash,
    required this.correlationSource,
    required this.dispatchTrace,
    this.jobRequestSchemaVersion,
    this.jobRequestHash,
  });

  final String? jobRequestSchemaVersion;
  final String? jobRequestHash;
  final String engineRequestSchemaVersion;
  final String engineRequestHash;
  final String correlationSource;
  final List<BattleEngineDispatchRecord> dispatchTrace;

  Map<String, dynamic> toJson() => {
    'schema_version': battleRequestCorrelationSchema,
    if (jobRequestSchemaVersion != null)
      'job_request_schema_version': jobRequestSchemaVersion,
    if (jobRequestHash != null) 'job_request_hash': jobRequestHash,
    'engine_request_schema_version': engineRequestSchemaVersion,
    'engine_request_hash': engineRequestHash,
    'correlation_source': correlationSource,
    'dispatch_trace': dispatchTrace
        .map((record) => record.toJson())
        .toList(growable: false),
  };
}
