import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_session.dart';

typedef LifeCounterPreferencesLoader = Future<SharedPreferences> Function();

class LifeCounterSessionStore {
  LifeCounterSessionStore({
    LifeCounterPreferencesLoader? preferencesLoader,
    this.prefsKey = legacyLifeCounterSessionPrefsKey,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LifeCounterSession?> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    final session = LifeCounterSession.tryParse(raw);
    if (session == null) {
      return null;
    }

    final normalizedRaw = session.toJsonString();
    if (raw != normalizedRaw) {
      await prefs.setString(prefsKey, normalizedRaw);
    }

    return session;
  }

  Future<void> save(LifeCounterSession session) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, session.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
