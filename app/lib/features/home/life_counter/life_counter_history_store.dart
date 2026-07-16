import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_history.dart';
import 'life_counter_session.dart';

const String legacyLifeCounterHistoryPrefsKey = 'life_counter_history_v1';

typedef LifeCounterHistoryPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterHistoryStore {
  LifeCounterHistoryStore({
    LifeCounterHistoryPreferencesLoader? preferencesLoader,
    this.prefsKey = legacyLifeCounterHistoryPrefsKey,
    DateTime Function()? nowProvider,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _nowProvider = nowProvider ?? DateTime.now;

  final LifeCounterHistoryPreferencesLoader _preferencesLoader;
  final DateTime Function() _nowProvider;
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
      final stabilized = _stabilizeCurrentGameMeta(decoded);
      final normalizedRaw = stabilized.toJsonString();
      if (normalizedRaw != raw) {
        await prefs.setString(prefsKey, normalizedRaw);
      }
      return stabilized;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LifeCounterHistoryState history) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(
      prefsKey,
      _stabilizeCurrentGameMeta(history).toJsonString(),
    );
  }

  Future<LifeCounterHistoryState> ensureCurrentGameMeta({
    LifeCounterHistoryState? history,
    LifeCounterSession? session,
  }) async {
    final base =
        history ?? await load() ?? const LifeCounterHistoryState.empty();
    final stabilized = _stabilizeCurrentGameMeta(base, session: session);
    if (stabilized.toJsonString() != base.toJsonString() || history == null) {
      final prefs = await _preferencesLoader();
      await prefs.setString(prefsKey, stabilized.toJsonString());
    }
    return stabilized;
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }

  LifeCounterHistoryState _stabilizeCurrentGameMeta(
    LifeCounterHistoryState history, {
    LifeCounterSession? session,
  }) {
    final persistedStartDate = history.currentGameMeta?['startDate'];
    final startDateEpochMs =
        persistedStartDate is num &&
                persistedStartDate.isFinite &&
                persistedStartDate.toInt() >= 0
            ? persistedStartDate.toInt()
            : _nowProvider().millisecondsSinceEpoch;
    return history.withStableCurrentGameMeta(
      startDateEpochMs: startDateEpochMs,
      session: session,
    );
  }
}
