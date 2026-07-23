import 'dart:convert';

import 'package:crypto/crypto.dart';

const externalBattleExecutionSchema = 'external_battle_execution_v2';
const externalBattleRequestSchema = 'external_battle_request_v2';
const externalBattleDeckHashSchema = 'external_battle_deck_hash_v1';
const externalBattleSidecarProtocol = 'external_battle_sidecar_v2';

const pinnedXmageCommit = '34d81ea4995ce15d7e1a788dc6d2a3595d35bcec';
const pinnedForgeCommit = 'a62915f500c2411484689294659c6bb84ea215f8';
const pinnedXmageVersion = '1.4.60';
const pinnedForgeVersion = '2.0.14-SNAPSHOT';

final class BattleEngineConfigurationException implements Exception {
  const BattleEngineConfigurationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

final class ExternalBattleEngineIdentity {
  const ExternalBattleEngineIdentity({
    required this.engine,
    required this.version,
    required this.commit,
    required this.aiProfile,
    required this.telemetryField,
    required this.telemetryVersion,
    required this.seedSemantics,
    required this.deterministic,
  });

  final String engine;
  final String version;
  final String commit;
  final String aiProfile;
  final String telemetryField;
  final String telemetryVersion;
  final String seedSemantics;
  final bool deterministic;

  String get buildIdentity => '$engine-sidecar-v2@$commit';
}

final class BattleEngineConfig {
  const BattleEngineConfig({
    required this.mode,
    required this.xmageSidecarUrl,
    required this.forgeSidecarUrl,
    required this.nativeSidecarUrl,
    required this.xmageIdentity,
    required this.forgeIdentity,
    required this.allowLegacySidecarIdentity,
  });

  factory BattleEngineConfig.fromEnvironment(Map<String, String> environment) {
    final mode = (environment['BATTLE_ENGINE'] ?? 'auto').trim().toLowerCase();
    if (!const {'auto', 'xmage', 'forge', 'native'}.contains(mode)) {
      throw const BattleEngineConfigurationException(
        'battle_engine_invalid_configuration',
        'BATTLE_ENGINE must be auto, xmage, forge, or native',
      );
    }

    final xmageSidecarUrl = (environment['XMAGE_SIDECAR_URL'] ?? '').trim();
    final forgeSidecarUrl = (environment['FORGE_SIDECAR_URL'] ?? '').trim();
    final nativeSidecarUrl =
        (environment['NATIVE_BATTLE_SIDECAR_URL'] ?? '').trim();

    if ((mode == 'auto' || mode == 'xmage') && xmageSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_not_configured',
        'XMAGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }
    if ((mode == 'auto' || mode == 'forge') && forgeSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_not_configured',
        'FORGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }
    if ((mode == 'auto' || mode == 'native') && nativeSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_native_not_configured',
        'NATIVE_BATTLE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }

    final xmageCommit = _expectedCommit(
      environment,
      key: 'XMAGE_EXPECTED_COMMIT',
      fallback: pinnedXmageCommit,
    );
    final forgeCommit = _expectedCommit(
      environment,
      key: 'FORGE_EXPECTED_COMMIT',
      fallback: pinnedForgeCommit,
    );
    final xmageVersion = _expectedVersion(
      environment,
      key: 'XMAGE_EXPECTED_VERSION',
      fallback: pinnedXmageVersion,
    );
    final forgeVersion = _expectedVersion(
      environment,
      key: 'FORGE_EXPECTED_VERSION',
      fallback: pinnedForgeVersion,
    );
    final allowLegacySidecarIdentity = _strictBoolean(
      environment,
      key: 'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
      fallback: false,
    );

    return BattleEngineConfig(
      mode: mode,
      xmageSidecarUrl: xmageSidecarUrl,
      forgeSidecarUrl: forgeSidecarUrl,
      nativeSidecarUrl: nativeSidecarUrl,
      xmageIdentity: ExternalBattleEngineIdentity(
        engine: 'xmage',
        version: xmageVersion,
        commit: xmageCommit,
        aiProfile: 'computer_mad',
        telemetryField: 'normalizer_version',
        telemetryVersion: 'xmage_replay_normalizer_v2',
        seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
        deterministic: false,
      ),
      forgeIdentity: ExternalBattleEngineIdentity(
        engine: 'forge',
        version: forgeVersion,
        commit: forgeCommit,
        aiProfile: 'forge_default_ai',
        telemetryField: 'parser_version',
        telemetryVersion: 'forge_log_parser_v2',
        seedSemantics: 'engine_rng_seeded_not_replay_guarantee',
        deterministic: false,
      ),
      allowLegacySidecarIdentity: allowLegacySidecarIdentity,
    );
  }

  final String mode;
  final String xmageSidecarUrl;
  final String forgeSidecarUrl;
  final String nativeSidecarUrl;
  final ExternalBattleEngineIdentity xmageIdentity;
  final ExternalBattleEngineIdentity forgeIdentity;
  final bool allowLegacySidecarIdentity;

  bool get isNative => mode == 'native';
  bool get isStrictXmage => mode == 'xmage';
  bool get isStrictForge => mode == 'forge';
}

Map<String, dynamic> buildExternalBattleRequestEnvelope({
  required Map<String, dynamic> request,
  required ExternalBattleEngineIdentity identity,
}) {
  final deckA = _requiredMap(request['deck_a'], 'deck_a');
  final deckB = _requiredMap(request['deck_b'], 'deck_b');
  final forceMode =
      _stringValue(
        request['force_focus_access_mode'],
        fallback: 'none',
      ).toLowerCase();
  if (forceMode != 'none') {
    throw const BattleEngineConfigurationException(
      'external_battle_control_unsupported',
      'External battle engines do not support forced card access',
    );
  }

  final deckHashes = <String, dynamic>{
    'schema_version': externalBattleDeckHashSchema,
    'algorithm': 'sha256',
    'deck_a': canonicalExternalBattleDeckHash(deckA),
    'deck_b': canonicalExternalBattleDeckHash(deckB),
  };
  final result = <String, dynamic>{
    ...request,
    'request_schema_version': externalBattleRequestSchema,
    'expected_engine': identity.engine,
    'expected_engine_version': identity.version,
    'expected_engine_commit': identity.commit,
    'ai_profile': identity.aiProfile,
    'max_turns': _requiredInt(request['max_turns'], 'max_turns'),
    'focus_cards': _stringList(request['focus_cards']),
    'force_focus_access_mode': forceMode,
    'same_lane': request['same_lane'] == true,
    'natural_sample': request['natural_sample'] != false,
    'deck_hashes': deckHashes,
  };
  result['request_hash'] = canonicalExternalBattleRequestHash(result);
  return result;
}

String canonicalExternalBattleDeckHash(Map<String, dynamic> deck) {
  final cards = deck['cards'];
  if (cards is! List || cards.isEmpty) {
    throw ArgumentError('deck.cards is required for canonical hashing');
  }
  final records =
      cards.map((raw) {
          final card = _requiredMap(raw, 'card');
          final quantity = _requiredInt(card['quantity'], 'card.quantity');
          return <String>[
            card['is_commander'] == true ? '1' : '0',
            '$quantity',
            _base64Field(_stringValue(card['name'])),
            _base64Field(_stringValue(card['set_code'])),
            _base64Field(_stringValue(card['collector_number'])),
          ].join('|');
        }).toList()
        ..sort();
  final material = '$externalBattleDeckHashSchema\n${records.join('\n')}\n';
  return sha256.convert(utf8.encode(material)).toString();
}

String canonicalExternalBattleRequestHash(Map<String, dynamic> request) {
  final deckHashes = _requiredMap(request['deck_hashes'], 'deck_hashes');
  final deckA = _requiredMap(request['deck_a'], 'deck_a');
  final deckB = _requiredMap(request['deck_b'], 'deck_b');
  final focusCards = _stringList(request['focus_cards']);
  final material = <String>[
    externalBattleRequestSchema,
    'request_id=${_base64Field(_stringValue(request['request_id']))}',
    'seed=${_requiredInt(request['seed'], 'seed')}',
    'timeout_ms=${_requiredInt(request['timeout_ms'], 'timeout_ms')}',
    'max_turns=${_requiredInt(request['max_turns'], 'max_turns')}',
    'focus_cards=${focusCards.map(_base64Field).join(',')}',
    'force_focus_access_mode=${_stringValue(request['force_focus_access_mode'], fallback: 'none')}',
    'same_lane=${request['same_lane'] == true ? 1 : 0}',
    'natural_sample=${request['natural_sample'] != false ? 1 : 0}',
    'deck_a_id=${_base64Field(_stringValue(deckA['id'], fallback: 'deck_a'))}',
    'deck_b_id=${_base64Field(_stringValue(deckB['id'], fallback: 'deck_b'))}',
    'deck_a_hash=${_stringValue(deckHashes['deck_a'])}',
    'deck_b_hash=${_stringValue(deckHashes['deck_b'])}',
    'engine=${_stringValue(request['expected_engine'])}',
    'engine_version=${_base64Field(_stringValue(request['expected_engine_version']))}',
    'engine_commit=${_stringValue(request['expected_engine_commit'])}',
    'ai_profile=${_base64Field(_stringValue(request['ai_profile']))}',
  ].join('\n');
  return sha256.convert(utf8.encode('$material\n')).toString();
}

String? externalBattleIdentityValidationError(
  Map<String, dynamic> body, {
  required ExternalBattleEngineIdentity expected,
  bool allowLegacy = false,
}) {
  final schema = body['schema_version']?.toString();
  if (schema != externalBattleExecutionSchema) {
    if (!allowLegacy || schema != null) {
      return 'unexpected response schema';
    }
    if (body['engine'] != null && body['engine'] != expected.engine) {
      return 'legacy response engine mismatch';
    }
    if (body['engine_version'] != null &&
        body['engine_version'] != expected.version) {
      return 'legacy response version mismatch';
    }
    if (body['engine_commit'] != null &&
        body['engine_commit'] != expected.commit) {
      return 'legacy response commit mismatch';
    }
    return null;
  }
  if (body['engine'] != expected.engine) return 'engine mismatch';
  if (body['engine_version'] != expected.version) {
    return 'engine version mismatch';
  }
  if (body['engine_commit'] != expected.commit) return 'engine commit mismatch';
  if (body['sidecar_protocol_version'] != externalBattleSidecarProtocol) {
    return 'sidecar protocol mismatch';
  }
  if (body['sidecar_build_identity'] != expected.buildIdentity) {
    return 'sidecar build identity mismatch';
  }
  if (body['ai_profile'] != expected.aiProfile) return 'AI profile mismatch';
  if (body[expected.telemetryField] != expected.telemetryVersion) {
    return 'telemetry version mismatch';
  }
  if (body['seed_semantics'] != expected.seedSemantics) {
    return 'seed semantics mismatch';
  }
  if (body['deterministic'] != expected.deterministic) {
    return 'determinism claim mismatch';
  }
  if (!_nonEmptyString(body['sidecar_process_id'])) {
    return 'missing sidecar process identity';
  }
  if (!_validTimestamp(body['sidecar_started_at'])) {
    return 'invalid sidecar start identity';
  }
  return null;
}

String? externalBattleCorrelationValidationError(
  Map<String, dynamic> body,
  Map<String, dynamic> request,
) {
  if (request['request_schema_version'] != externalBattleRequestSchema) {
    return null;
  }
  for (final key in const [
    'request_id',
    'seed',
    'timeout_ms',
    'request_hash',
    'ai_profile',
  ]) {
    if (body[key] != request[key]) return '$key mismatch';
  }
  final expectedHashes = request['deck_hashes'];
  final actualHashes = body['deck_hashes'];
  if (expectedHashes is! Map || actualHashes is! Map) {
    return 'missing deck hashes';
  }
  for (final key in const ['schema_version', 'algorithm', 'deck_a', 'deck_b']) {
    if (actualHashes[key] != expectedHashes[key]) return 'deck hash mismatch';
  }
  final contract = body['request_contract'];
  if (contract is! Map ||
      contract['schema_version'] != externalBattleRequestSchema) {
    return 'request contract mismatch';
  }
  final controls = contract['controls'];
  if (controls is! Map) return 'missing control declarations';
  for (final key in const [
    'max_turns',
    'focus_cards',
    'force_focus_access_mode',
    'same_lane',
    'natural_sample',
  ]) {
    if (controls[key] is! Map || !(controls[key] as Map).containsKey('value')) {
      return 'missing $key control declaration';
    }
  }
  return null;
}

String? externalBattleSuccessValidationError(
  Map<String, dynamic> body,
  Map<String, dynamic> request,
) {
  final correlationError = externalBattleCorrelationValidationError(
    body,
    request,
  );
  if (correlationError != null) return correlationError;
  final status = body['status'];
  if (status != 'completed' && status != 'censored') {
    return 'invalid execution status';
  }
  if (body['error'] != null) return 'error-bearing success payload';
  final turns = body['turns'];
  if (turns is! int || turns <= 0) return 'invalid turn count';
  if (!_nonEmptyString(body['fallback_reason'])) {
    return 'missing fallback reason';
  }
  final outcome = body['execution_outcome'];
  if (outcome is! Map || outcome['status'] != status) {
    return 'execution outcome mismatch';
  }
  if (outcome['timed_out'] != false) return 'success marked as timeout';
  final maxTurns = _requiredInt(request['max_turns'], 'max_turns');
  final censored = status == 'censored';
  if (outcome['censored'] != censored) return 'censoring flag mismatch';
  if (censored) {
    if (turns <= maxTurns || outcome['censor_reason'] != 'max_turns_exceeded') {
      return 'invalid max-turn censoring';
    }
    if (body['winner'] != null ||
        body['winner_deck_key'] != null ||
        body['winner_deck_id'] != null) {
      return 'censored result exposed a winner';
    }
  } else if (turns > maxTurns) {
    return 'uncensored result exceeded max_turns';
  }
  return null;
}

String _expectedCommit(
  Map<String, String> environment, {
  required String key,
  required String fallback,
}) {
  final value = (environment[key] ?? fallback).trim().toLowerCase();
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(value)) {
    throw BattleEngineConfigurationException(
      'battle_engine_invalid_identity',
      '$key must be a full 40-character Git commit',
    );
  }
  return value;
}

String _expectedVersion(
  Map<String, String> environment, {
  required String key,
  required String fallback,
}) {
  final value = (environment[key] ?? fallback).trim();
  if (value.isEmpty || value.length > 80) {
    throw BattleEngineConfigurationException(
      'battle_engine_invalid_identity',
      '$key must be a non-empty engine version',
    );
  }
  return value;
}

bool _strictBoolean(
  Map<String, String> environment, {
  required String key,
  required bool fallback,
}) {
  final raw = environment[key]?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (raw == 'true') return true;
  if (raw == 'false') return false;
  throw BattleEngineConfigurationException(
    'battle_engine_invalid_configuration',
    '$key must be true or false',
  );
}

Map<String, dynamic> _requiredMap(Object? value, String key) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw ArgumentError('$key must be an object');
}

int _requiredInt(Object? value, String key) {
  if (value is int) return value;
  throw ArgumentError('$key must be an integer');
}

List<String> _stringList(Object? value) =>
    value is List
        ? value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const [];

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String _base64Field(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');

bool _nonEmptyString(Object? value) =>
    value is String && value.trim().isNotEmpty;

bool _validTimestamp(Object? value) =>
    value is String && DateTime.tryParse(value) != null;
