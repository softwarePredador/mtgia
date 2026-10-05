import 'package:shared_preferences/shared_preferences.dart';

import 'lotus_ui_snapshot.dart';
import '../life_counter/life_counter_account_scope.dart';

typedef LotusUiSnapshotPreferencesLoader = Future<SharedPreferences> Function();

class LotusUiSnapshotStore {
  LotusUiSnapshotStore({
    LotusUiSnapshotPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lotusUiSnapshotPrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LotusUiSnapshot?> load() async {
    final prefs = await _binding.preferences();
    return LotusUiSnapshot.tryParse(prefs.getString(prefsKey));
  }

  Future<void> save(LotusUiSnapshot snapshot) async {
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, snapshot.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
