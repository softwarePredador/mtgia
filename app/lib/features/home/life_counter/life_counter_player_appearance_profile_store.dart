import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'life_counter_session.dart';

const String lifeCounterPlayerAppearanceProfilesPrefsKey =
    'life_counter_player_appearance_profiles_v1';

typedef LifeCounterAppearanceProfilesPreferencesLoader =
    Future<SharedPreferences> Function();

@immutable
class LifeCounterPlayerAppearanceProfile {
  const LifeCounterPlayerAppearanceProfile({
    required this.id,
    required this.name,
    required this.appearance,
  });

  final String id;
  final String name;
  final LifeCounterPlayerAppearance appearance;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'appearance': appearance.toJson(),
    };
  }

  static LifeCounterPlayerAppearanceProfile? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final payload = raw.cast<String, dynamic>();
    final id = payload['id'];
    final name = payload['name'];
    final appearance = LifeCounterPlayerAppearance.tryFromJson(
      payload['appearance'],
    );
    if (id is! String || id.trim().isEmpty) {
      return null;
    }
    if (name is! String || name.trim().isEmpty) {
      return null;
    }
    if (appearance == null) {
      return null;
    }

    return LifeCounterPlayerAppearanceProfile(
      id: id.trim(),
      name: name.trim(),
      appearance: appearance,
    );
  }
}

class LifeCounterPlayerAppearanceProfileStore {
  LifeCounterPlayerAppearanceProfileStore({
    LifeCounterAppearanceProfilesPreferencesLoader? preferencesLoader,
    this.prefsKey = lifeCounterPlayerAppearanceProfilesPrefsKey,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance;

  final LifeCounterAppearanceProfilesPreferencesLoader _preferencesLoader;
  final String prefsKey;

  Future<List<LifeCounterPlayerAppearanceProfile>> load() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      return const <LifeCounterPlayerAppearanceProfile>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LifeCounterPlayerAppearanceProfile>[];
      }

      final profiles = <LifeCounterPlayerAppearanceProfile>[];
      for (final item in decoded) {
        final profile = LifeCounterPlayerAppearanceProfile.tryFromJson(item);
        if (profile != null) {
          profiles.add(profile);
        }
      }
      return List<LifeCounterPlayerAppearanceProfile>.unmodifiable(profiles);
    } catch (_) {
      return const <LifeCounterPlayerAppearanceProfile>[];
    }
  }

  Future<List<LifeCounterPlayerAppearanceProfile>> saveAll(
    List<LifeCounterPlayerAppearanceProfile> profiles,
  ) async {
    final prefs = await _preferencesLoader();
    final normalized = List<LifeCounterPlayerAppearanceProfile>.unmodifiable(
      profiles,
    );
    await prefs.setString(
      prefsKey,
      jsonEncode(
        normalized.map((profile) => profile.toJson()).toList(growable: false),
      ),
    );
    return normalized;
  }

  Future<List<LifeCounterPlayerAppearanceProfile>> saveProfile({
    required String name,
    required LifeCounterPlayerAppearance appearance,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return load();
    }

    final profiles = List<LifeCounterPlayerAppearanceProfile>.from(
      await load(),
    );
    final existingIndex = profiles.indexWhere(
      (profile) => profile.name.toLowerCase() == normalizedName.toLowerCase(),
    );

    final profile = LifeCounterPlayerAppearanceProfile(
      id:
          existingIndex >= 0
              ? profiles[existingIndex].id
              : DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
      appearance: appearance,
    );

    if (existingIndex >= 0) {
      profiles[existingIndex] = profile;
    } else {
      profiles.add(profile);
    }

    return saveAll(profiles);
  }

  Future<List<LifeCounterPlayerAppearanceProfile>> deleteProfile(
    String profileId,
  ) async {
    final profiles = List<LifeCounterPlayerAppearanceProfile>.from(await load())
      ..removeWhere((profile) => profile.id == profileId);
    return saveAll(profiles);
  }

  Future<void> clear() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(prefsKey);
  }
}
