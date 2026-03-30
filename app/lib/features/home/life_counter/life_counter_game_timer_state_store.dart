import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_game_timer_state.dart';

typedef LifeCounterGameTimerStatePreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterGameTimerStateStore {
  LifeCounterGameTimerStateStore({
    LifeCounterGameTimerStatePreferencesLoader? preferencesLoader,
    this.prefsKey = lifeCounterGameTimerStatePrefsKey,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterGameTimerStatePreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LifeCounterGameTimerState?> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    final state = LifeCounterGameTimerState.tryParse(raw);
    if (state == null) {
      return null;
    }

    final normalizedRaw = state.toJsonString();
    if (raw != normalizedRaw) {
      await prefs.setString(prefsKey, normalizedRaw);
    }

    return state;
  }

  Future<void> save(LifeCounterGameTimerState state) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, state.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
