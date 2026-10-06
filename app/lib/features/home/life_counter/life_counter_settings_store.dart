import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_settings.dart';
import 'life_counter_account_scope.dart';

typedef LifeCounterSettingsPreferencesLoader =
    Future<SharedPreferences> Function();

class LifeCounterSettingsStore {
  LifeCounterSettingsStore({
    LifeCounterSettingsPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lifeCounterSettingsPrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LifeCounterSettings?> load() async {
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, settings.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
