import 'package:shared_preferences/shared_preferences.dart';

import 'lotus_storage_snapshot.dart';
import '../life_counter/life_counter_account_scope.dart';

typedef LotusPreferencesLoader = Future<SharedPreferences> Function();

class LotusStorageSnapshotStore {
  LotusStorageSnapshotStore({
    LotusPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lotusStorageSnapshotPrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;

  Future<LotusStorageSnapshot?> load() async {
    final prefs = await _binding.preferences();
    return LotusStorageSnapshot.tryParse(prefs.getString(prefsKey));
  }

  Future<void> save(LotusStorageSnapshot snapshot) async {
    final prefs = await _binding.preferences();
    await prefs.setString(prefsKey, snapshot.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
