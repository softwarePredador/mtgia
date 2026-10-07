import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/observability/app_observability.dart';
import 'life_counter_browser_storage_purge_stub.dart'
    if (dart.library.js_interop) 'life_counter_browser_storage_purge_web.dart'
    as browser_storage;

typedef LifeCounterScopePreferencesLoader =
    Future<SharedPreferences> Function();

/// Prefix shared by every device-local key that belongs to the life counter,
/// its Lotus mirrors and the post-game outbox (LC-P0-01).
const String lifeCounterLocalStoragePrefix = 'manaloom.local.v1.';

/// Receipt written when unscoped data from before LC-P0-01 is removed.
const String lifeCounterLegacyPurgeReceiptKey =
    'manaloom.local.life_counter_legacy_purge_receipt_v1';

/// Unscoped SharedPreferences keys written before LC-P0-01. Their owner can't
/// be proven (logout never cleared them), so they are removed, never migrated.
const Set<String> lifeCounterLegacyPreferenceKeys = <String>{
  'life_counter_session_v1',
  'life_counter_history_v1',
  'life_counter_settings_v1',
  'life_counter_game_timer_state_v1',
  'life_counter_day_night_state_v1',
  'life_counter_player_appearance_profiles_v1',
  'life_counter_lotus_local_storage_v1',
  'lotus_ui_snapshot_v1',
  'lotus_lifecycle_diagnostic_trace_v1',
};

/// Unscoped prefix of the post-game notes and their outbox before LC-P0-01.
const String lifeCounterLegacyPostGamePrefix = 'manaloom.post_game_notes.';

/// Unscoped browser localStorage keys of the Web Lotus host before LC-P0-01.
const Set<String> lifeCounterLegacyBrowserStorageKeys = <String>{
  'manaloom_lotus_web_storage_v1',
  'manaloom_lotus_web_storage_pending_fingerprint_v1',
};

/// Thrown when a store bound to one account is used after the signed-in
/// account changed. Reads and writes fail closed instead of touching the
/// next account's data.
class LifeCounterStorageScopeClosedException implements Exception {
  const LifeCounterStorageScopeClosedException(this.namespace);

  final LifeCounterStorageNamespace namespace;

  @override
  String toString() =>
      'LifeCounterStorageScopeClosedException: os dados locais desta conta '
      'foram fechados (geração ${namespace.generation}).';
}

/// The account namespace a store was opened in. A store keeps the namespace it
/// was created with; once the signed-in account changes it stops working.
@immutable
class LifeCounterStorageNamespace {
  const LifeCounterStorageNamespace._(
    this._scope,
    this.accountId,
    this.generation,
  );

  final LifeCounterAccountScope _scope;

  /// Signed-in account, or `null` for the ephemeral signed-out namespace.
  final String? accountId;
  final int generation;

  bool get isSignedOut => accountId == null;

  String get keyPrefix => accountId == null
      ? lifeCounterSignedOutKeyPrefix
      : lifeCounterAccountKeyPrefix(accountId!);

  String keyFor(String baseKey) => '$keyPrefix$baseKey';

  /// Whether the account this namespace was opened for is still signed in.
  bool get isCurrent => _scope.generation == generation;

  /// Waits for pending purges, then throws if the account changed.
  Future<void> ensureOpen() async {
    await _scope.settled;
    if (!isCurrent) {
      throw LifeCounterStorageScopeClosedException(this);
    }
  }
}

const String lifeCounterSignedOutKeyPrefix =
    '${lifeCounterLocalStoragePrefix}signed_out.';

String lifeCounterAccountKeyPrefix(String accountId) =>
    '${lifeCounterLocalStoragePrefix}account.'
    '${Uri.encodeComponent(accountId.trim())}.';

/// Keys and a guarded preferences loader for one store.
class LifeCounterStorageBinding {
  LifeCounterStorageBinding._(this.namespace, this.prefsKey, this._loader);

  /// [prefsKey] overrides the namespaced key (tests and diagnostics only); the
  /// namespace guard still applies.
  factory LifeCounterStorageBinding.resolve({
    required String baseKey,
    LifeCounterStorageNamespace? namespace,
    String? prefsKey,
    LifeCounterScopePreferencesLoader? preferencesLoader,
  }) {
    final resolvedNamespace =
        namespace ?? LifeCounterAccountScope.instance.current;
    return LifeCounterStorageBinding._(
      resolvedNamespace,
      prefsKey ?? resolvedNamespace.keyFor(baseKey),
      preferencesLoader ?? SharedPreferences.getInstance,
    );
  }

  final LifeCounterStorageNamespace namespace;
  final String prefsKey;
  final LifeCounterScopePreferencesLoader _loader;

  Future<SharedPreferences> preferences() async {
    await namespace.ensureOpen();
    return _loader();
  }
}

/// Which account owns the device-local life counter and post-game data.
///
/// The [AuthProvider] binds the signed-in account and unbinds it on logout or
/// session expiry. Each change opens a new generation, so stores created for
/// the previous account stop reading and writing. Data of a signed-out account
/// stays on the device under its own prefix until [purgeAccount] (account
/// deletion); the signed-out namespace is wiped at every transition.
class LifeCounterAccountScope extends ChangeNotifier {
  LifeCounterAccountScope({
    LifeCounterScopePreferencesLoader? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static LifeCounterAccountScope instance = LifeCounterAccountScope();

  @visibleForTesting
  static void resetForTesting({
    LifeCounterScopePreferencesLoader? preferencesLoader,
  }) {
    instance = LifeCounterAccountScope(preferencesLoader: preferencesLoader);
  }

  final LifeCounterScopePreferencesLoader _preferencesLoader;
  String? _accountId;
  int _generation = 0;
  Future<void> _maintenance = Future<void>.value();
  int _pendingMaintenance = 0;
  bool _legacyChecked = false;

  String? get accountId => _accountId;
  int get generation => _generation;

  LifeCounterStorageNamespace get current =>
      LifeCounterStorageNamespace._(this, _accountId, _generation);

  /// Completes when every queued purge has run.
  // A fresh future when idle: a completed one kept from another zone (a
  // previous widget test, for instance) would never deliver its callbacks.
  Future<void> get settled =>
      _pendingMaintenance == 0 ? Future<void>.value() : _maintenance;

  /// Opens [accountId]'s namespace. Same account again is a no-op.
  void bind(String accountId) {
    final normalized = accountId.trim();
    if (normalized.isEmpty) {
      unbind();
      return;
    }
    if (normalized == _accountId) return;
    _accountId = normalized;
    _generation += 1;
    _enqueue('bind', () async {
      final prefs = await _preferencesLoader();
      await _purgePrefix(prefs, lifeCounterSignedOutKeyPrefix);
      await _purgeLegacyOnce(prefs);
    });
    notifyListeners();
  }

  /// Closes the signed-in namespace (logout, forced logout, token expiry).
  /// The account's data stays on the device for its next sign-in.
  void unbind() {
    if (_accountId == null) return;
    _accountId = null;
    _generation += 1;
    _enqueue('unbind', () async {
      final prefs = await _preferencesLoader();
      await _purgePrefix(prefs, lifeCounterSignedOutKeyPrefix);
    });
    notifyListeners();
  }

  /// Removes everything [accountId] stored on this device (account deletion).
  /// Closes the namespace first when that account is the signed-in one.
  Future<int> purgeAccount(String accountId) {
    final normalized = accountId.trim();
    if (normalized.isEmpty) return Future<int>.value(0);
    if (_accountId == normalized) {
      unbind();
    }
    var removed = 0;
    final task = _enqueue('purge_account', () async {
      final prefs = await _preferencesLoader();
      final prefix = lifeCounterAccountKeyPrefix(normalized);
      removed = await _purgePrefix(prefs, prefix);
      removed += browser_storage.purgeBrowserLocalStorage(
        (key) => key.startsWith(prefix),
      );
    });
    return task.then((_) => removed);
  }

  Future<void> _enqueue(String operation, Future<void> Function() task) {
    final previous = settled;
    _pendingMaintenance += 1;
    final next = previous.then((_) => task()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      // A failed purge leaves inert data: stores only read their own prefix.
      unawaited(
        AppObservability.instance.captureProviderException(
          error,
          stackTrace: stackTrace,
          provider: 'LifeCounterAccountScope',
          operation: operation,
        ),
      );
    });
    final tracked = next.whenComplete(() => _pendingMaintenance -= 1);
    _maintenance = tracked;
    return tracked;
  }

  Future<int> _purgePrefix(SharedPreferences prefs, String prefix) async {
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
    return keys.length;
  }

  Future<void> _purgeLegacyOnce(SharedPreferences prefs) async {
    if (_legacyChecked) return;
    _legacyChecked = true;
    final removedKeys = <String>{};
    var droppedPendingUpserts = 0;
    var droppedPendingDeletes = 0;
    for (final key in prefs.getKeys().toList(growable: false)) {
      final isLegacy =
          lifeCounterLegacyPreferenceKeys.contains(key) ||
          key.startsWith(lifeCounterLegacyPostGamePrefix);
      if (!isLegacy) continue;
      if (key.startsWith(
        '${lifeCounterLegacyPostGamePrefix}pending_upserts.',
      )) {
        droppedPendingUpserts += _countJsonList(prefs.getString(key));
      } else if (key.startsWith(
        '${lifeCounterLegacyPostGamePrefix}pending_deletes.',
      )) {
        droppedPendingDeletes += prefs.getStringList(key)?.length ?? 0;
      }
      await prefs.remove(key);
      removedKeys.add(_redactLegacyKey(key));
    }
    final removedBrowserKeys = browser_storage.purgeBrowserLocalStorage(
      lifeCounterLegacyBrowserStorageKeys.contains,
    );
    if (removedKeys.isEmpty && removedBrowserKeys == 0) return;
    final sortedKeys = removedKeys.toList()..sort();
    await prefs.setString(
      lifeCounterLegacyPurgeReceiptKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'task': 'LC-P0-01',
        'decision': 'purged_unscoped_owner_unprovable',
        'purged_at': DateTime.now().toUtc().toIso8601String(),
        'removed_preference_keys': sortedKeys,
        'removed_browser_storage_keys': removedBrowserKeys,
        'dropped_post_game_pending_upserts': droppedPendingUpserts,
        'dropped_post_game_pending_deletes': droppedPendingDeletes,
      }),
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'legacy_local_data_purged',
        category: 'life_counter.storage',
        data: <String, Object?>{
          'removed_preference_keys': removedKeys.length,
          'removed_browser_storage_keys': removedBrowserKeys,
          'dropped_post_game_pending_upserts': droppedPendingUpserts,
          'dropped_post_game_pending_deletes': droppedPendingDeletes,
        },
      ),
    );
  }

  static int _countJsonList(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.length : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Post-game keys carry a deck id; the receipt keeps only their kind.
  static String _redactLegacyKey(String key) {
    if (!key.startsWith(lifeCounterLegacyPostGamePrefix)) return key;
    final rest = key.substring(lifeCounterLegacyPostGamePrefix.length);
    if (rest.startsWith('pending_upserts.')) {
      return '${lifeCounterLegacyPostGamePrefix}pending_upserts.<deck>';
    }
    if (rest.startsWith('pending_deletes.')) {
      return '${lifeCounterLegacyPostGamePrefix}pending_deletes.<deck>';
    }
    return '$lifeCounterLegacyPostGamePrefix<deck>';
  }
}
