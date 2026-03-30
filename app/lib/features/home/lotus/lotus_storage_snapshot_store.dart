import 'package:shared_preferences/shared_preferences.dart';

import 'lotus_storage_snapshot.dart';

typedef LotusPreferencesLoader = Future<SharedPreferences> Function();

class LotusStorageSnapshotStore {
  LotusStorageSnapshotStore({
    LotusPreferencesLoader? preferencesLoader,
    this.prefsKey = lotusStorageSnapshotPrefsKey,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final LotusPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LotusStorageSnapshot?> load() async {
    final prefs = await _preferencesLoader();
    return LotusStorageSnapshot.tryParse(prefs.getString(prefsKey));
  }

  Future<void> save(LotusStorageSnapshot snapshot) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, snapshot.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
