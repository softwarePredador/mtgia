import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../life_counter/life_counter_account_scope.dart';

typedef LotusLifecycleDiagnosticPreferencesLoader =
    Future<SharedPreferences> Function();

const String lotusLifecycleDiagnosticPrefsKey =
    'lotus_lifecycle_diagnostic_trace_v1';

class LotusLifecycleDiagnosticStore {
  LotusLifecycleDiagnosticStore({
    LotusLifecycleDiagnosticPreferencesLoader? preferencesLoader,
    String? prefsKey,
    LifeCounterStorageNamespace? namespace,
    this.maxEntries = 40,
  }) : _binding = LifeCounterStorageBinding.resolve(
         baseKey: lotusLifecycleDiagnosticPrefsKey,
         namespace: namespace,
         prefsKey: prefsKey,
         preferencesLoader: preferencesLoader,
       );

  final LifeCounterStorageBinding _binding;
  String get prefsKey => _binding.prefsKey;
  LifeCounterStorageNamespace get namespace => _binding.namespace;
  final int maxEntries;

  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await _binding.preferences();
    final rawEntries = prefs.getStringList(prefsKey) ?? const <String>[];
    final parsedEntries = <Map<String, dynamic>>[];

    for (final rawEntry in rawEntries) {
      try {
        final decoded = jsonDecode(rawEntry);
        if (decoded is Map) {
          parsedEntries.add(
            decoded.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
        }
      } catch (_) {}
    }

    return parsedEntries;
  }

  Future<void> append(Map<String, Object?> entry) async {
    final prefs = await _binding.preferences();
    final existing = prefs.getStringList(prefsKey) ?? <String>[];
    existing.add(jsonEncode(entry));
    final trimmed = existing.length > maxEntries
        ? existing.sublist(existing.length - maxEntries)
        : existing;
    await prefs.setStringList(prefsKey, trimmed);
  }

  Future<void> clear() async {
    final prefs = await _binding.preferences();
    await prefs.remove(prefsKey);
  }
}
