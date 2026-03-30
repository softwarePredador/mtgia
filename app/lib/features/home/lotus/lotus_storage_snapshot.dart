import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lotusStorageSnapshotPrefsKey =
    'life_counter_lotus_local_storage_v1';

@immutable
class LotusStorageSnapshot {
  const LotusStorageSnapshot({
    required this.values,
  });

  final Map<String, String> values;

  bool get isEmpty => values.isEmpty;
  int get entryCount => values.length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'values': values,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LotusStorageSnapshot? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      return tryFromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static LotusStorageSnapshot? tryFromJson(Map<String, dynamic> payload) {
    final rawValues = payload['values'];
    if (rawValues is! Map) {
      return null;
    }

    final values = <String, String>{};
    for (final entry in rawValues.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value == null) {
        continue;
      }
      values[key] = value.toString();
    }

    return LotusStorageSnapshot(values: Map<String, String>.unmodifiable(values));
  }
}
