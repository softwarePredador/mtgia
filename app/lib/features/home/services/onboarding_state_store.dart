import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingDisposition { pending, completed, skipped }

class OnboardingState {
  const OnboardingState({
    this.disposition = OnboardingDisposition.pending,
    this.selectedFormat = 'commander',
    this.updatedAt,
  });

  final OnboardingDisposition disposition;
  final String selectedFormat;
  final DateTime? updatedAt;

  bool get isSettled => disposition != OnboardingDisposition.pending;

  OnboardingState copyWith({
    OnboardingDisposition? disposition,
    String? selectedFormat,
    DateTime? updatedAt,
  }) {
    return OnboardingState(
      disposition: disposition ?? this.disposition,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

abstract interface class OnboardingStateRepository {
  Future<OnboardingState> load(String userId);

  Future<void> saveProgress(String userId, {required String selectedFormat});

  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
  });
}

typedef OnboardingPreferencesLoader = Future<SharedPreferences> Function();

class OnboardingPersistenceException implements Exception {
  const OnboardingPersistenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Device-local, per-user source of truth for the versioned first-run flow.
///
/// Analytics events are deliberately not read here. A missing, malformed or
/// future-version value is treated as pending so telemetry can never skip a
/// required product step.
class OnboardingStateStore implements OnboardingStateRepository {
  OnboardingStateStore({OnboardingPreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const currentVersion = 1;
  static const _keyPrefix = 'manaloom.onboarding.v1.user.';
  static const supportedFormats = <String>{
    'commander',
    'standard',
    'modern',
    'pioneer',
    'legacy',
    'vintage',
    'pauper',
  };

  final OnboardingPreferencesLoader _preferencesLoader;

  @override
  Future<OnboardingState> load(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(_keyFor(normalizedUserId));
    if (raw == null || raw.trim().isEmpty) {
      return const OnboardingState();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != currentVersion) {
        return const OnboardingState();
      }
      final disposition = OnboardingDisposition.values.firstWhere(
        (value) => value.name == decoded['disposition'],
        orElse: () => OnboardingDisposition.pending,
      );
      final rawFormat = decoded['selected_format']?.toString().toLowerCase();
      final selectedFormat = supportedFormats.contains(rawFormat)
          ? rawFormat!
          : 'commander';
      final updatedAt = DateTime.tryParse(
        decoded['updated_at']?.toString() ?? '',
      );
      return OnboardingState(
        disposition: disposition,
        selectedFormat: selectedFormat,
        updatedAt: updatedAt,
      );
    } catch (_) {
      return const OnboardingState();
    }
  }

  @override
  Future<void> saveProgress(
    String userId, {
    required String selectedFormat,
  }) async {
    final current = await load(userId);
    await _write(
      userId,
      current.copyWith(
        selectedFormat: _normalizeFormat(selectedFormat),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
  }) async {
    if (disposition == OnboardingDisposition.pending) {
      throw const OnboardingPersistenceException(
        'O estado final do onboarding não pode permanecer pendente.',
      );
    }
    await _write(
      userId,
      OnboardingState(
        disposition: disposition,
        selectedFormat: _normalizeFormat(selectedFormat),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _write(String userId, OnboardingState state) async {
    final normalizedUserId = _normalizeUserId(userId);
    final preferences = await _preferencesLoader();
    final persisted = await preferences.setString(
      _keyFor(normalizedUserId),
      jsonEncode({
        'version': currentVersion,
        'disposition': state.disposition.name,
        'selected_format': state.selectedFormat,
        'updated_at': state.updatedAt?.toIso8601String(),
      }),
    );
    if (!persisted) {
      throw const OnboardingPersistenceException(
        'O dispositivo recusou a gravação do progresso.',
      );
    }
  }

  String _normalizeUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw const OnboardingPersistenceException(
        'Usuário inválido para salvar o progresso.',
      );
    }
    return normalized;
  }

  String _normalizeFormat(String selectedFormat) {
    final normalized = selectedFormat.trim().toLowerCase();
    if (!supportedFormats.contains(normalized)) {
      throw const OnboardingPersistenceException(
        'Formato inválido para salvar o progresso.',
      );
    }
    return normalized;
  }

  String _keyFor(String userId) => '$_keyPrefix${Uri.encodeComponent(userId)}';
}
