import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_history.dart';

const String legacyLifeCounterHistoryPrefsKey = 'life_counter_history_v1';

typedef LifeCounterHistoryPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterHistoryStore {
  LifeCounterHistoryStore({
    LifeCounterHistoryPreferencesLoader? preferencesLoader,
    this.prefsKey = legacyLifeCounterHistoryPrefsKey,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterHistoryPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LifeCounterHistoryState?> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decodedJson = jsonDecode(raw);
      if (decodedJson is! Map) {
        return null;
      }
      final decoded = LifeCounterHistoryState.tryFromJson(
        decodedJson.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (decoded == null) {
        return null;
      }
      final normalizedRaw = decoded.toJsonString();
      if (normalizedRaw != raw) {
        await prefs.setString(prefsKey, normalizedRaw);
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LifeCounterHistoryState history) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, history.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
