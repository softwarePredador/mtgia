import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_day_night_state.dart';

typedef LifeCounterDayNightPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterDayNightStateStore {
  LifeCounterDayNightStateStore({
    LifeCounterDayNightPreferencesLoader? preferencesLoader,
    this.prefsKey = lifeCounterDayNightStatePrefsKey,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterDayNightPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LifeCounterDayNightState?> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    final state = LifeCounterDayNightState.tryParse(raw);
    if (state == null) {
      return null;
    }

    final normalizedRaw = state.toJsonString();
    if (raw != normalizedRaw) {
      await prefs.setString(prefsKey, normalizedRaw);
    }

    return state;
  }

  Future<void> save(LifeCounterDayNightState state) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, state.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
