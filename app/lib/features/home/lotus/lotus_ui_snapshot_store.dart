import 'package:shared_preferences/shared_preferences.dart';

import 'lotus_ui_snapshot.dart';

typedef LotusUiSnapshotPreferencesLoader = Future<SharedPreferences> Function();

class LotusUiSnapshotStore {
  LotusUiSnapshotStore({
    LotusUiSnapshotPreferencesLoader? preferencesLoader,
    this.prefsKey = lotusUiSnapshotPrefsKey,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final LotusUiSnapshotPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<LotusUiSnapshot?> load() async {
    final prefs = await _preferencesLoader();
    return LotusUiSnapshot.tryParse(prefs.getString(prefsKey));
  }

  Future<void> save(LotusUiSnapshot snapshot) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(prefsKey, snapshot.toJsonString());
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
