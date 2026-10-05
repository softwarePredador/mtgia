import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_session.dart';
import 'life_counter_account_scope.dart';

typedef LifeCounterPreferencesLoader = Future<SharedPreferences> Function();

class LifeCounterSessionStore {
  LifeCounterSessionStore({
    LifeCounterPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: legacyLifeCounterSessionPrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LifeCounterSession?> load() async {
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, session.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
