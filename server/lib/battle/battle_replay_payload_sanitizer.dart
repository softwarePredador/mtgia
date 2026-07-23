import 'dart:collection';
import 'dart:convert';

import '../log_sanitizer.dart';

const battleReplaySecurityContract = <String, dynamic>{
  'schema_version': 'battle_replay_security_v1',
  'hidden_zone_policy': 'counts_only',
  'sensitive_field_policy': 'redacted',
};

class BattleReplayPayloadException implements Exception {
  const BattleReplayPayloadException(this.code);

  final String code;

  @override
  String toString() => 'BattleReplayPayloadException($code)';
}

Map<String, dynamic> sanitizeBattleReplayForStorage(
  Map<String, dynamic> payload,
) {
  final sanitized = _sanitizeMap(
    payload,
    depth: 0,
    ancestors: HashSet<Object>.identity(),
  );
  sanitized['replay_security'] = battleReplaySecurityContract;
  return sanitized;
}

Object sanitizePersistedBattleReplay(Object? payload) {
  final decoded = _decodePersistedJson(payload);
  if (decoded is! Map && decoded is! List) {
    throw const BattleReplayPayloadException('invalid_replay_root');
  }
  final sanitized = _sanitizeValue(
    decoded,
    depth: 0,
    ancestors: HashSet<Object>.identity(),
  );
  if (sanitized == null) {
    throw const BattleReplayPayloadException('invalid_replay_root');
  }
  return sanitized;
}

Map<String, dynamic> sanitizePersistedBattleMetrics(Object? payload) {
  if (payload == null) return <String, dynamic>{};
  final decoded = _decodePersistedJson(payload);
  if (decoded is! Map) {
    throw const BattleReplayPayloadException('invalid_metrics_root');
  }
  return _sanitizeMap(decoded, depth: 0, ancestors: HashSet<Object>.identity());
}

String? sanitizeBattleReplayText(Object? value) {
  if (value == null) return null;
  return sanitizeLogMessage(value.toString());
}

Object? _decodePersistedJson(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    throw const BattleReplayPayloadException('invalid_json');
  }
}

Object? _sanitizeValue(
  Object? value, {
  required int depth,
  required HashSet<Object> ancestors,
}) {
  if (depth > 64) {
    throw const BattleReplayPayloadException('maximum_depth_exceeded');
  }
  if (value == null || value is bool || value is int) return value;
  if (value is double) {
    if (!value.isFinite) {
      throw const BattleReplayPayloadException('non_finite_number');
    }
    return value;
  }
  if (value is String) return sanitizeLogMessage(value);
  if (value is Map) {
    return _sanitizeMap(value, depth: depth, ancestors: ancestors);
  }
  if (value is List) {
    if (!ancestors.add(value)) {
      throw const BattleReplayPayloadException('cyclic_payload');
    }
    try {
      return value
          .map(
            (entry) =>
                _sanitizeValue(entry, depth: depth + 1, ancestors: ancestors),
          )
          .toList(growable: false);
    } finally {
      ancestors.remove(value);
    }
  }
  throw const BattleReplayPayloadException('unsupported_value');
}

Map<String, dynamic> _sanitizeMap(
  Map<dynamic, dynamic> value, {
  required int depth,
  required HashSet<Object> ancestors,
}) {
  if (!ancestors.add(value)) {
    throw const BattleReplayPayloadException('cyclic_payload');
  }
  try {
    final sanitized = <String, dynamic>{};
    final hiddenZoneCounts = <String, int>{};
    final hidesIdentity = _isHiddenObject(value);

    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const BattleReplayPayloadException('non_string_key');
      }
      final normalizedKey = _normalizeKey(key);
      if (_isSensitiveKey(normalizedKey)) continue;
      if (hidesIdentity && _hiddenIdentityKeys.contains(normalizedKey)) {
        continue;
      }

      final hiddenCountKey = _hiddenZoneCountKeys[normalizedKey];
      if (hiddenCountKey != null && entry.value is List) {
        hiddenZoneCounts[hiddenCountKey] = (entry.value as List).length;
        continue;
      }

      sanitized[key] = _sanitizeValue(
        entry.value,
        depth: depth + 1,
        ancestors: ancestors,
      );
    }

    for (final entry in hiddenZoneCounts.entries) {
      sanitized.putIfAbsent(entry.key, () => entry.value);
    }
    return sanitized;
  } finally {
    ancestors.remove(value);
  }
}

bool _isHiddenObject(Map<dynamic, dynamic> value) {
  for (final entry in value.entries) {
    if (entry.key is! String) continue;
    final key = _normalizeKey(entry.key as String);
    if ((key == 'hidden' || key == 'is_hidden' || key == 'face_down') &&
        entry.value == true) {
      return true;
    }
    if (key == 'visibility') {
      final visibility = entry.value?.toString().trim().toLowerCase();
      if (visibility == 'hidden' || visibility == 'private') return true;
    }
  }
  return false;
}

bool _isSensitiveKey(String key) {
  if (_sensitiveKeys.contains(key)) return true;
  return key.endsWith('_password') ||
      key.endsWith('_passphrase') ||
      key.endsWith('_api_key') ||
      key.endsWith('_access_token') ||
      key.endsWith('_refresh_token') ||
      key.endsWith('_private_key') ||
      key.endsWith('_secret');
}

String _normalizeKey(String key) =>
    key.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), '_');

const _sensitiveKeys = <String>{
  'authorization',
  'proxy_authorization',
  'cookie',
  'set_cookie',
  'password',
  'passphrase',
  'api_key',
  'apikey',
  'access_token',
  'refresh_token',
  'id_token',
  'jwt',
  'jwt_secret',
  'client_secret',
  'private_key',
  'database_url',
  'db_password',
  'dsn',
  'secret',
};

const _hiddenZoneCountKeys = <String, String>{
  'hand': 'hand_size',
  'hand_cards': 'hand_size',
  'private_hand': 'hand_size',
  'library': 'library_size',
  'library_cards': 'library_size',
  'draw_pile': 'library_size',
  'draw_pile_cards': 'library_size',
};

const _hiddenIdentityKeys = <String>{
  'id',
  'card_id',
  'oracle_id',
  'scryfall_id',
  'name',
  'card',
  'card_name',
  'source_card_id',
  'source_card_name',
  'image_url',
  'oracle_text',
};
