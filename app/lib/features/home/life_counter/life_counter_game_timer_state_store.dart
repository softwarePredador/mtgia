import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_game_timer_state.dart';
import 'life_counter_account_scope.dart';

typedef LifeCounterGameTimerStatePreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterGameTimerStateStore {
  LifeCounterGameTimerStateStore({
    LifeCounterGameTimerStatePreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lifeCounterGameTimerStatePrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LifeCounterGameTimerState?> load() async {
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, state.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
