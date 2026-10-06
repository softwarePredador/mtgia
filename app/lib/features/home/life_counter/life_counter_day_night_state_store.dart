import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_day_night_state.dart';
import 'life_counter_account_scope.dart';

typedef LifeCounterDayNightPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterDayNightStateStore {
  LifeCounterDayNightStateStore({
    LifeCounterDayNightPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lifeCounterDayNightStatePrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LifeCounterDayNightState?> load() async {
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, state.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
