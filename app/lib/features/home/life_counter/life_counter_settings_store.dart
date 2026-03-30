import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_settings.dart';

typedef LifeCounterSettingsPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterSettingsStore {
  LifeCounterSettingsStore({
    LifeCounterSettingsPreferencesLoader? preferencesLoader,
    this.prefsKey = lifeCounterSettingsPrefsKey,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterSettingsPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LifeCounterSettings?> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    final settings = LifeCounterSettings.tryParse(raw);
    if (settings == null) {
      return null;
    }

    final normalizedRaw = settings.toJsonString();
    if (raw != normalizedRaw) {
      await prefs.setString(prefsKey, normalizedRaw);
    }

    return settings;
  }

  Future<void> save(LifeCounterSettings settings) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, settings.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
