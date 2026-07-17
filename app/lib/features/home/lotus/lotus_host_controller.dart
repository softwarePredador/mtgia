import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/observability/app_observability.dart';
import '../../../core/theme/app_theme.dart';
import '../life_counter/life_counter_day_night_state.dart';
import '../life_counter/life_counter_day_night_state_store.dart';
import '../life_counter/life_counter_game_timer_state.dart';
import '../life_counter/life_counter_game_timer_state_store.dart';
import '../life_counter/life_counter_history.dart';
import '../life_counter/life_counter_history_store.dart';
import '../life_counter/life_counter_settings.dart';
import '../life_counter/life_counter_settings_store.dart';
import '../life_counter/life_counter_session.dart';
import '../life_counter/life_counter_session_store.dart';
import '../life_counter/life_counter_tabletop_engine.dart';
import 'lotus_host.dart';
import 'lotus_life_counter_game_timer_adapter.dart';
import 'lotus_js_bridges.dart';
import 'lotus_life_counter_settings_adapter.dart';
import 'lotus_life_counter_session_adapter.dart';
import 'lotus_runtime_flags.dart';
import 'lotus_shell_policy.dart';
import 'lotus_storage_snapshot.dart';
import 'lotus_storage_snapshot_store.dart';
import 'lotus_ui_snapshot.dart';
import 'lotus_ui_snapshot_store.dart';
import 'lotus_visual_skin.dart';
import 'lotus_webview_contract.dart';

const Set<String> lotusReloadLifecycleSnapshotReasons = <String>{
  'document_hidden',
  'pagehide',
  'beforeunload',
};

bool shouldSuppressLotusReloadLifecycleSnapshot({
  required String? reason,
  required String? sessionId,
  required String? suppressedSessionId,
  required DateTime? suppressUntil,
  required DateTime now,
}) {
  return sessionId != null &&
      sessionId == suppressedSessionId &&
      suppressUntil != null &&
      now.isBefore(suppressUntil) &&
      lotusReloadLifecycleSnapshotReasons.contains(reason);
}

Future<Map<String, String>> buildLotusFallbackBootstrapValues({
  required LifeCounterDayNightStateStore dayNightStateStore,
  required LifeCounterGameTimerStateStore gameTimerStateStore,
  required LifeCounterHistoryStore historyStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  final dayNightState = await dayNightStateStore.load();
  final gameTimerState = await gameTimerStateStore.load();
  var history = await historyStore.load();
  final session = await sessionStore.load();
  final settings = await settingsStore.load();
  if (session != null) {
    history = await historyStore.ensureCurrentGameMeta(
      history: history,
      session: session,
    );
  }
  final values = <String, String>{};
  if (dayNightState != null) {
    values['__manaloom_day_night_mode'] = dayNightState.mode;
  }
  if (gameTimerState != null) {
    values.addAll(
      LotusLifeCounterGameTimerAdapter.buildSnapshotValues(gameTimerState),
    );
  }
  if (settings != null) {
    values.addAll(
      LotusLifeCounterSettingsAdapter.buildSnapshotValues(settings),
    );
  }
  if (session != null) {
    values.addAll(
      LotusLifeCounterSessionAdapter.buildSnapshotValues(
        session,
        history: history,
        settings: settings,
      ),
    );
  }
  if (session == null && history != null) {
    values.addAll(history.buildLotusSnapshotValues());
  }
  return values;
}

Map<String, String> mergeLotusBootstrapValues({
  Map<String, String>? snapshotValues,
  required Map<String, String> fallbackValues,
}) {
  final mergedValues = <String, String>{...?snapshotValues};
  mergedValues.addAll(fallbackValues);
  return mergedValues;
}

String lotusStorageValuesFingerprint(Map<String, String> values) {
  final sortedKeys = values.keys.toList()..sort();
  return jsonEncode(<String, String>{
    for (final key in sortedKeys)
      key: _normalizeLotusStorageFingerprintValue(values[key]!),
  });
}

String _normalizeLotusStorageFingerprintValue(String value) {
  try {
    return jsonEncode(_sortLotusStorageFingerprintJson(jsonDecode(value)));
  } catch (_) {
    return value;
  }
}

Object? _sortLotusStorageFingerprintJson(Object? value) {
  if (value is List) {
    return value.map(_sortLotusStorageFingerprintJson).toList(growable: false);
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _sortLotusStorageFingerprintJson(value[key]),
    };
  }
  return value;
}

bool isSuccessfulLotusStorageBridgeResult(Object? rawResult) {
  return _decodeLotusStorageBridgeResult(rawResult)?['ok'] == true;
}

Map<String, Object?>? _decodeLotusStorageBridgeResult(Object? rawResult) {
  Object? decoded = rawResult;
  for (var attempt = 0; attempt < 2 && decoded is String; attempt += 1) {
    try {
      decoded = jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }

  if (decoded is! Map) {
    return null;
  }
  return decoded.map(
    (key, value) => MapEntry<String, Object?>(key.toString(), value),
  );
}

enum LotusStoragePersistRejection {
  inactiveSession,
  invalidEnvelope,
  staleSequence,
  staleRevision,
  authoritativeStateChanged,
}

@immutable
class LotusStoragePersistDecision {
  const LotusStoragePersistDecision.accepted()
    : rejection = null,
      wasAlreadyPersisted = false;

  const LotusStoragePersistDecision.alreadyPersisted()
    : rejection = LotusStoragePersistRejection.staleSequence,
      wasAlreadyPersisted = true;

  const LotusStoragePersistDecision.rejected(this.rejection)
    : wasAlreadyPersisted = false;

  final LotusStoragePersistRejection? rejection;
  final bool wasAlreadyPersisted;

  bool get shouldPersist => rejection == null && !wasAlreadyPersisted;

  bool get shouldRebase =>
      rejection == LotusStoragePersistRejection.staleRevision ||
      rejection == LotusStoragePersistRejection.authoritativeStateChanged;
}

class LotusStorageBridgeState {
  String? _activeSessionId;
  String? _bootstrapRequestId;
  int _revision = 0;
  int _lastSequence = 0;
  int? _lastAcceptedSequence;
  String? _lastAcceptedIncomingFingerprint;
  String? _authoritativeFingerprint;

  String? get activeSessionId => _activeSessionId;
  int get revision => _revision;

  bool isActiveSession(String? sessionId) =>
      sessionId != null && sessionId == _activeSessionId;

  int beginBootstrap({
    required String sessionId,
    required String requestId,
    required String authoritativeFingerprint,
  }) {
    final isRetry =
        sessionId == _activeSessionId && requestId == _bootstrapRequestId;
    if (!isRetry) {
      _activeSessionId = sessionId;
      _bootstrapRequestId = requestId;
      _lastSequence = 0;
      _lastAcceptedSequence = null;
      _lastAcceptedIncomingFingerprint = null;
      _revision += 1;
    } else if (_authoritativeFingerprint != authoritativeFingerprint) {
      _revision += 1;
    }

    _authoritativeFingerprint = authoritativeFingerprint;
    return _revision;
  }

  LotusStoragePersistDecision evaluatePersist({
    required String? sessionId,
    required int? sequence,
    required int? baseRevision,
    required String currentAuthoritativeFingerprint,
    required String incomingFingerprint,
  }) {
    if (!isActiveSession(sessionId)) {
      return const LotusStoragePersistDecision.rejected(
        LotusStoragePersistRejection.inactiveSession,
      );
    }
    if (sequence == null ||
        sequence <= 0 ||
        baseRevision == null ||
        baseRevision < 0) {
      return const LotusStoragePersistDecision.rejected(
        LotusStoragePersistRejection.invalidEnvelope,
      );
    }
    if (sequence <= _lastSequence) {
      if (sequence == _lastAcceptedSequence &&
          incomingFingerprint == _lastAcceptedIncomingFingerprint) {
        return const LotusStoragePersistDecision.alreadyPersisted();
      }
      return const LotusStoragePersistDecision.rejected(
        LotusStoragePersistRejection.staleSequence,
      );
    }

    _lastSequence = sequence;
    if (baseRevision != _revision) {
      return const LotusStoragePersistDecision.rejected(
        LotusStoragePersistRejection.staleRevision,
      );
    }

    final baseline = _authoritativeFingerprint;
    if (baseline != null &&
        currentAuthoritativeFingerprint != baseline &&
        incomingFingerprint != currentAuthoritativeFingerprint) {
      return const LotusStoragePersistDecision.rejected(
        LotusStoragePersistRejection.authoritativeStateChanged,
      );
    }

    return const LotusStoragePersistDecision.accepted();
  }

  bool recordNativePatch({
    required String? sessionId,
    required int? revision,
    required String authoritativeFingerprint,
  }) {
    if (!isActiveSession(sessionId) ||
        revision == null ||
        revision <= _revision) {
      return false;
    }

    _revision = revision;
    _authoritativeFingerprint = authoritativeFingerprint;
    return true;
  }

  void recordAcceptedSnapshot(
    String authoritativeFingerprint, {
    required int sequence,
    required String incomingFingerprint,
  }) {
    _authoritativeFingerprint = authoritativeFingerprint;
    _lastAcceptedSequence = sequence;
    _lastAcceptedIncomingFingerprint = incomingFingerprint;
  }

  int beginRebase(String authoritativeFingerprint) {
    _revision += 1;
    _authoritativeFingerprint = authoritativeFingerprint;
    return _revision;
  }
}

LifeCounterDayNightState? buildLotusDayNightStateFromSnapshot(
  LotusStorageSnapshot snapshot,
) {
  final rawMode = snapshot.values['__manaloom_day_night_mode'];
  if (rawMode == 'night') {
    return const LifeCounterDayNightState(isNight: true);
  }
  if (rawMode == 'day') {
    return const LifeCounterDayNightState(isNight: false);
  }
  return null;
}

class LotusCanonicalMirrorResult {
  const LotusCanonicalMirrorResult({
    required this.dayNightState,
    required this.gameTimerState,
    required this.history,
    required this.historyDomainPresent,
    required this.session,
    required this.settings,
  });

  final LifeCounterDayNightState? dayNightState;
  final LifeCounterGameTimerState? gameTimerState;
  final LifeCounterHistoryState history;
  final bool historyDomainPresent;
  final LifeCounterSession? session;
  final LifeCounterSettings? settings;
}

Future<LotusCanonicalMirrorResult> persistCanonicalMirrorFromLotusSnapshot({
  required LifeCounterDayNightStateStore dayNightStateStore,
  required LifeCounterGameTimerStateStore gameTimerStateStore,
  required LifeCounterHistoryStore historyStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
  required LotusStorageSnapshot snapshot,
}) async {
  final previousSession = await sessionStore.load();
  final previousHistory = await historyStore.load();
  final historyDomainPresent = LifeCounterHistoryState.hasSnapshotDomain(
    snapshot,
  );
  final derivedDayNight = buildLotusDayNightStateFromSnapshot(snapshot);
  final parsedSession = LotusLifeCounterSessionAdapter.tryBuildSession(
    snapshot,
  );
  final derivedSettings = LotusLifeCounterSettingsAdapter.tryBuildSettings(
    snapshot,
  );
  final normalizedSession =
      parsedSession == null || derivedSettings == null
          ? parsedSession
          : LifeCounterTabletopEngine.normalizeOwnedBoardSession(
            parsedSession,
            settings: derivedSettings,
          );
  final derivedSession =
      normalizedSession == null || previousSession == null
          ? normalizedSession
          : normalizedSession.copyWith(
            playSessionId: previousSession.playSessionId,
            deckId: previousSession.deckId,
            deckName: previousSession.deckName,
            startedAtEpochMs: previousSession.startedAtEpochMs,
          );
  final parsedGameTimer = LotusLifeCounterGameTimerAdapter.tryBuildState(
    snapshot,
  );
  // Lotus creates an internal gameTimerState on every boot, even when the
  // timer feature is disabled. Do not promote that hidden implementation
  // detail to canonical app state; otherwise merely opening the table starts
  // a timer and races a native reset/start action.
  final derivedGameTimer =
      derivedSettings?.gameTimer == false ? null : parsedGameTimer;
  final derivedHistory = _reconcilePendingLotusLifeHistory(
    previousSession: previousSession,
    derivedSession: derivedSession,
    previousHistory: previousHistory,
    derivedHistory: LifeCounterHistoryState.fromSources(
      session: derivedSession,
      snapshot: snapshot,
    ),
  );

  if (derivedDayNight != null) {
    await dayNightStateStore.save(derivedDayNight);
  } else {
    await dayNightStateStore.clear();
  }
  if (derivedSession != null) {
    await sessionStore.save(derivedSession);
  } else {
    await sessionStore.clear();
  }
  if (derivedSettings != null) {
    await settingsStore.save(derivedSettings);
  } else {
    await settingsStore.clear();
  }
  if (derivedGameTimer != null) {
    await gameTimerStateStore.save(derivedGameTimer);
  } else {
    await gameTimerStateStore.clear();
  }
  if (historyDomainPresent || derivedHistory.hasContent) {
    await historyStore.save(derivedHistory);
  } else {
    await historyStore.clear();
  }

  return LotusCanonicalMirrorResult(
    dayNightState: derivedDayNight,
    gameTimerState: derivedGameTimer,
    history: derivedHistory,
    historyDomainPresent: historyDomainPresent,
    session: derivedSession,
    settings: derivedSettings,
  );
}

final RegExp _pendingLotusLifeEventPattern = RegExp(
  r'^player: (\d+) • change: (-?\d+) • life: (-?\d+)$',
);

LifeCounterHistoryState _reconcilePendingLotusLifeHistory({
  required LifeCounterSession? previousSession,
  required LifeCounterSession? derivedSession,
  required LifeCounterHistoryState? previousHistory,
  required LifeCounterHistoryState derivedHistory,
}) {
  if (previousSession == null ||
      derivedSession == null ||
      previousSession.playerCount != derivedSession.playerCount ||
      !_isSameCurrentGame(previousHistory, derivedHistory)) {
    return derivedHistory;
  }

  final derivedMessages =
      derivedHistory.currentGameEntries.map((entry) => entry.message).toSet();
  final pendingEntries = <LifeCounterHistoryEntry>[];
  for (final entry in previousHistory?.currentGameEntries ?? const []) {
    if (_tryParsePendingLotusLifeEvent(entry) == null ||
        derivedMessages.contains(entry.message)) {
      continue;
    }
    pendingEntries.add(entry);
  }

  for (var index = 0; index < derivedSession.playerCount; index += 1) {
    final previousLife = previousSession.lives[index];
    final nextLife = derivedSession.lives[index];
    if (previousLife == nextLife) {
      continue;
    }

    var totalChange = nextLife - previousLife;
    final priorPendingIndex = pendingEntries.indexWhere((entry) {
      final parsed = _tryParsePendingLotusLifeEvent(entry);
      return parsed != null &&
          parsed.playerIndex == index &&
          parsed.finalLife == previousLife;
    });
    if (priorPendingIndex >= 0) {
      final priorPending =
          _tryParsePendingLotusLifeEvent(
            pendingEntries.removeAt(priorPendingIndex),
          )!;
      totalChange += priorPending.change;
    }

    final message = 'player: $index • change: $totalChange • life: $nextLife';
    if (!derivedMessages.contains(message)) {
      pendingEntries.insert(
        0,
        LifeCounterHistoryEntry(
          message: message,
          source: LifeCounterHistoryEntrySource.fallback,
        ),
      );
    }
  }

  if (pendingEntries.isEmpty) {
    return derivedHistory;
  }
  return derivedHistory.copyWith(
    currentGameEntries: <LifeCounterHistoryEntry>[
      ...pendingEntries,
      ...derivedHistory.currentGameEntries,
    ],
  );
}

bool _isSameCurrentGame(
  LifeCounterHistoryState? previous,
  LifeCounterHistoryState next,
) {
  if (previous == null) {
    return true;
  }

  String? readId(LifeCounterHistoryState state) {
    final value = state.currentGameMeta?['id'];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  final previousId = readId(previous);
  final nextId = readId(next);
  if (previousId != null || nextId != null) {
    return previousId != null && previousId == nextId;
  }

  final previousStartDate = previous.currentGameMeta?['startDate'];
  final nextStartDate = next.currentGameMeta?['startDate'];
  if (previousStartDate is num || nextStartDate is num) {
    return previousStartDate is num &&
        nextStartDate is num &&
        previousStartDate.toInt() == nextStartDate.toInt();
  }

  return previous.gameCounter == next.gameCounter &&
      previous.currentGameName == next.currentGameName;
}

_PendingLotusLifeEvent? _tryParsePendingLotusLifeEvent(
  LifeCounterHistoryEntry entry,
) {
  if (entry.source != LifeCounterHistoryEntrySource.fallback) {
    return null;
  }
  final match = _pendingLotusLifeEventPattern.firstMatch(entry.message);
  if (match == null) {
    return null;
  }

  final playerIndex = int.tryParse(match.group(1)!);
  final change = int.tryParse(match.group(2)!);
  final finalLife = int.tryParse(match.group(3)!);
  if (playerIndex == null || change == null || finalLife == null) {
    return null;
  }
  return _PendingLotusLifeEvent(
    playerIndex: playerIndex,
    change: change,
    finalLife: finalLife,
  );
}

@immutable
class _PendingLotusLifeEvent {
  const _PendingLotusLifeEvent({
    required this.playerIndex,
    required this.change,
    required this.finalLife,
  });

  final int playerIndex;
  final int change;
  final int finalLife;
}

bool shouldSkipLotusStoragePersistObservability({
  required bool didRecordStoragePersistThisLoad,
  required bool didRecordCanonicalSessionMirrorThisLoad,
  required bool didRecordCanonicalSettingsMirrorThisLoad,
  required bool didRecordCanonicalGameTimerMirrorThisLoad,
  required bool didRecordCanonicalDayNightMirrorThisLoad,
  required bool didRecordCanonicalHistoryMirrorThisLoad,
  required bool historyDomainPresent,
  required LifeCounterSession? derivedSession,
  required LifeCounterSettings? derivedSettings,
  required LifeCounterGameTimerState? derivedGameTimer,
  required LifeCounterDayNightState? derivedDayNight,
  required LifeCounterHistoryState derivedHistory,
}) {
  if (!didRecordStoragePersistThisLoad) {
    return false;
  }

  return (derivedSession == null || didRecordCanonicalSessionMirrorThisLoad) &&
      (derivedSettings == null || didRecordCanonicalSettingsMirrorThisLoad) &&
      (derivedDayNight == null || didRecordCanonicalDayNightMirrorThisLoad) &&
      (derivedGameTimer == null || didRecordCanonicalGameTimerMirrorThisLoad) &&
      (!(historyDomainPresent || derivedHistory.hasContent) ||
          didRecordCanonicalHistoryMirrorThisLoad);
}

class _LotusAuthoritativeStorageState {
  const _LotusAuthoritativeStorageState({
    required this.snapshot,
    required this.fallbackValues,
    required this.values,
  });

  final LotusStorageSnapshot? snapshot;
  final Map<String, String> fallbackValues;
  final Map<String, String> values;

  String get fingerprint => lotusStorageValuesFingerprint(values);
  String get fallbackFingerprint =>
      lotusStorageValuesFingerprint(fallbackValues);
}

enum _LotusStorageMessageOutcome {
  ignored,
  accepted,
  alreadyAccepted,
  rejected;

  bool get confirmsPersistence =>
      this == _LotusStorageMessageOutcome.accepted ||
      this == _LotusStorageMessageOutcome.alreadyAccepted;
}

class LotusHostController
    implements
        LotusHost,
        LotusCanonicalStorageRebaser,
        LotusCanonicalStorageMutationCoordinator,
        LotusLiveStoragePatchCoordinator,
        LotusStorageFlushBarrier {
  static const String _bundleLoadErrorMessage =
      'O ManaLoom não conseguiu abrir o contador de vida. '
      'Tente carregar novamente.';
  static const String _storageBootstrapErrorMessage =
      'O ManaLoom não conseguiu restaurar o estado do contador de vida. '
      'Tente carregar novamente.';

  LotusHostController({
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
  }) : webViewController = WebViewController(),
       isLoading = ValueNotifier<bool>(true),
       errorMessage = ValueNotifier<String?>(null),
       _dayNightStateStore = LifeCounterDayNightStateStore(),
       _gameTimerStateStore = LifeCounterGameTimerStateStore(),
       _historyStore = LifeCounterHistoryStore(),
       _settingsStore = LifeCounterSettingsStore(),
       _sessionStore = LifeCounterSessionStore(),
       _storageSnapshotStore = LotusStorageSnapshotStore(),
       _uiSnapshotStore = LotusUiSnapshotStore(),
       _onShellMessageRequested = onShellMessageRequested {
    _configure(onAppReviewRequested: onAppReviewRequested);
  }

  final WebViewController webViewController;
  @override
  final ValueNotifier<bool> isLoading;
  @override
  final ValueNotifier<String?> errorMessage;
  final LifeCounterDayNightStateStore _dayNightStateStore;
  final LifeCounterGameTimerStateStore _gameTimerStateStore;
  final LifeCounterHistoryStore _historyStore;
  final LifeCounterSettingsStore _settingsStore;
  final LifeCounterSessionStore _sessionStore;
  final LotusStorageSnapshotStore _storageSnapshotStore;
  final LotusUiSnapshotStore _uiSnapshotStore;
  final LotusShellMessageCallback _onShellMessageRequested;
  final LotusStorageBridgeState _storageBridgeState = LotusStorageBridgeState();

  late final LotusStorageMessageQueue _storageMessageQueue;

  bool _didRunBridgeProbe = false;
  bool _isDisposed = false;
  bool _didInjectDebugBundleFailure = false;
  bool _didRecordStoragePersistThisLoad = false;
  bool _didRecordCanonicalSessionMirrorThisLoad = false;
  bool _didRecordCanonicalSettingsMirrorThisLoad = false;
  bool _didRecordCanonicalGameTimerMirrorThisLoad = false;
  bool _didRecordCanonicalDayNightMirrorThisLoad = false;
  bool _didRecordCanonicalHistoryMirrorThisLoad = false;
  Timer? _loadingOverlayFallbackTimer;
  DateTime? _ignoreReloadLifecycleSnapshotUntil;
  String? _ignoreReloadLifecycleSnapshotSessionId;
  DateTime? _lastUiSnapshotCapturedAt;

  @override
  Widget buildView(BuildContext context) {
    return WebViewWidget(controller: webViewController);
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {
    _ignoreReloadLifecycleSnapshotSessionId =
        _storageBridgeState.activeSessionId;
    _ignoreReloadLifecycleSnapshotUntil = DateTime.now().add(
      const Duration(seconds: 2),
    );
  }

  @override
  Future<void> loadBundle() async {
    final isRetry = errorMessage.value != null;
    final bundleEntry = _resolveBundleEntry();
    errorMessage.value = null;
    isLoading.value = true;
    _didRecordStoragePersistThisLoad = false;
    _didRecordCanonicalSessionMirrorThisLoad = false;
    _didRecordCanonicalSettingsMirrorThisLoad = false;
    _didRecordCanonicalGameTimerMirrorThisLoad = false;
    _didRecordCanonicalDayNightMirrorThisLoad = false;
    _didRecordCanonicalHistoryMirrorThisLoad = false;
    unawaited(
      AppObservability.instance.recordEvent(
        isRetry ? 'bundle_retry_requested' : 'bundle_load_started',
        category: 'life_counter.host',
        data: {'entry': bundleEntry, 'is_retry': isRetry},
      ),
    );

    try {
      await webViewController.loadFlutterAsset(bundleEntry);
    } catch (error, stackTrace) {
      debugPrint('$lotusLogPrefix load bundle error: $error');
      errorMessage.value = _bundleLoadErrorMessage;
      dismissLoadingOverlay();
      unawaited(
        AppObservability.instance.recordEvent(
          'bundle_load_failed',
          category: 'life_counter.host',
          level: SentryLevel.error,
          data: {'error': error.toString()},
        ),
      );
      unawaited(
        AppObservability.instance.captureException(
          error,
          stackTrace: stackTrace,
          tags: const {'source': 'life_counter_host', 'stage': 'bundle_load'},
          extras: {'entry': bundleEntry, 'is_retry': isRetry},
        ),
      );
    }
  }

  @override
  Future<void> runJavaScript(String script) {
    return webViewController.runJavaScript(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    return webViewController.runJavaScriptReturningResult(script);
  }

  @override
  Future<bool> flushStorageSnapshot({String reason = 'flutter_exit'}) async {
    if (_isDisposed) {
      return false;
    }

    final normalizedReason =
        reason.trim().isEmpty ? 'flutter_exit' : reason.trim();
    try {
      final rawResult = await webViewController.runJavaScriptReturningResult('''
        (() => {
          const bridge = window.__ManaloomLotusStorageBridge;
          if (!bridge || typeof bridge.flushSnapshot !== 'function') {
            return JSON.stringify({ ok: false, reason: 'bridge_missing' });
          }
          const result = bridge.flushSnapshot(${jsonEncode(normalizedReason)});
          return JSON.stringify(
            result && typeof result === 'object'
              ? result
              : { ok: false, reason: 'invalid_bridge_result' }
          );
        })()
        ''');
      final result = _decodeLotusStorageBridgeResult(rawResult);
      final rawPayload = result?['payload'];
      if (rawPayload is! Map) {
        return false;
      }

      final payload = rawPayload.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
      if (payload['type'] != 'persist_snapshot') {
        return false;
      }

      // The JavaScript channel callback and this evaluated result can arrive in
      // either order on different WebView implementations. Enqueue the same
      // existing persist envelope as an awaited task: whichever copy arrives
      // first persists, while the sequence guard safely rejects the duplicate.
      final outcome = await _storageMessageQueue.enqueueTask(
        () => _processStorageMessage(jsonEncode(payload)),
      );
      return !_isDisposed && outcome.confirmsPersistence;
    } catch (error) {
      debugPrint('$lotusLogPrefix storage flush barrier error: $error');
      return false;
    }
  }

  @override
  Future<bool> applyLiveStoragePatch(Map<String, String?> values) async {
    if (_isDisposed || values.isEmpty) {
      return false;
    }

    try {
      return await _storageMessageQueue.enqueueTask(() async {
        final sessionId = _storageBridgeState.activeSessionId;
        if (_isDisposed || sessionId == null) {
          return false;
        }

        final rawResult = await webViewController.runJavaScriptReturningResult(
          '''
          (() => {
            const bridge = window.__ManaloomLotusStorageBridge;
            if (!bridge || typeof bridge.receivePatch !== 'function') {
              return JSON.stringify({ ok: false, reason: 'bridge_missing' });
            }
            const result = bridge.receivePatch(${jsonEncode(<String, Object?>{'values': values})});
            return JSON.stringify(
              result && typeof result === 'object'
                ? result
                : { ok: false, reason: 'invalid_bridge_result' }
            );
          })()
          ''',
        );
        final result = _decodeLotusStorageBridgeResult(rawResult);
        final revision = result?['revision'];
        if (result?['ok'] != true || revision is! int || revision <= 0) {
          return false;
        }

        final authoritativeState = await _loadAuthoritativeStorageState();
        return _storageBridgeState.recordNativePatch(
          sessionId: sessionId,
          revision: revision,
          authoritativeFingerprint: authoritativeState.fingerprint,
        );
      });
    } catch (error) {
      debugPrint('$lotusLogPrefix live storage patch error: $error');
      return false;
    }
  }

  @override
  Future<bool> rebaseStorageFromCanonical({
    String reason = 'native_canonical_sync',
  }) {
    return mutateCanonicalStorageAndRebase(
      mutation: () async {},
      reason: reason,
      reloadRuntime: true,
    );
  }

  @override
  Future<bool> mutateCanonicalStorageAndRebase({
    required LotusCanonicalStorageMutation mutation,
    required String reason,
    bool reloadRuntime = false,
  }) async {
    if (_isDisposed) {
      // A storage message may already be inside its canonical mirror phase when
      // the host is disposed. Preserve the same write barrier even though no
      // runtime rebase can be delivered anymore.
      await _storageMessageQueue.idle;
      await mutation();
      return false;
    }
    try {
      return await _storageMessageQueue.enqueueTask(() async {
        await mutation();
        if (_isDisposed || _storageBridgeState.activeSessionId == null) {
          return false;
        }
        return _sendStorageRebaseSnapshot(
          await _loadAuthoritativeStorageState(),
          reason:
              reason.trim().isEmpty ? 'native_canonical_sync' : reason.trim(),
          reloadRuntime: reloadRuntime,
        );
      });
    } catch (error, stackTrace) {
      debugPrint('$lotusLogPrefix canonical storage mutation error: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _storageMessageQueue.close();
    _loadingOverlayFallbackTimer?.cancel();
    isLoading.dispose();
    errorMessage.dispose();
  }

  void _configure({required LotusAppReviewCallback onAppReviewRequested}) {
    _storageMessageQueue = LotusJavaScriptBridges.register(
      webViewController,
      onAppReviewRequested: onAppReviewRequested,
      onShellMessageRequested: _handleShellMessage,
      onStorageMessageRequested: _handleStorageMessage,
    );

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.lifeCounterBlack)
      ..enableZoom(false)
      ..setOnConsoleMessage(_handleConsoleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _handleProgress,
          onPageFinished: _handlePageFinished,
          onNavigationRequest: _handleNavigationRequest,
          onWebResourceError: _handleWebResourceError,
        ),
      );

    _loadingOverlayFallbackTimer = Timer(
      lotusLoadingOverlayTimeout,
      dismissLoadingOverlay,
    );
  }

  Future<void> _handleStorageMessage(String message) async {
    await _processStorageMessage(message);
  }

  Future<_LotusStorageMessageOutcome> _processStorageMessage(
    String message,
  ) async {
    if (_isDisposed) {
      return _LotusStorageMessageOutcome.ignored;
    }

    final payload = _tryDecodeShellPayload(message);
    if (payload == null) {
      debugPrint('$lotusLogPrefix storage bridge received invalid payload');
      return _LotusStorageMessageOutcome.ignored;
    }

    final type = payload['type'];
    if (type == 'request_bootstrap') {
      await _sendStorageBootstrapSnapshot(payload);
      return _LotusStorageMessageOutcome.ignored;
    }

    if (type == 'native_patch_applied') {
      await _recordNativeStoragePatch(payload);
      return _LotusStorageMessageOutcome.ignored;
    }

    if (type == 'bootstrap_failed') {
      _recordStorageBootstrapFailure(payload);
      return _LotusStorageMessageOutcome.ignored;
    }

    if (type != 'persist_snapshot') {
      return _LotusStorageMessageOutcome.ignored;
    }

    final snapshot = LotusStorageSnapshot.tryFromJson(payload);
    if (snapshot == null) {
      return _LotusStorageMessageOutcome.rejected;
    }

    final reason =
        payload['reason'] is String ? payload['reason'] as String : null;
    final sessionId =
        payload['sessionId'] is String ? payload['sessionId'] as String : null;
    if (shouldSuppressLotusReloadLifecycleSnapshot(
      reason: reason,
      sessionId: sessionId,
      suppressedSessionId: _ignoreReloadLifecycleSnapshotSessionId,
      suppressUntil: _ignoreReloadLifecycleSnapshotUntil,
      now: DateTime.now(),
    )) {
      return _LotusStorageMessageOutcome.ignored;
    }

    final sequence =
        payload['sequence'] is int ? payload['sequence'] as int : null;
    final baseRevision =
        payload['baseRevision'] is int ? payload['baseRevision'] as int : null;
    final authoritativeBefore = await _loadAuthoritativeStorageState();
    final persistDecision = _storageBridgeState.evaluatePersist(
      sessionId: sessionId,
      sequence: sequence,
      baseRevision: baseRevision,
      currentAuthoritativeFingerprint: authoritativeBefore.fingerprint,
      incomingFingerprint: lotusStorageValuesFingerprint(snapshot.values),
    );
    if (persistDecision.wasAlreadyPersisted) {
      return _LotusStorageMessageOutcome.alreadyAccepted;
    }
    if (!persistDecision.shouldPersist) {
      debugPrint(
        '$lotusLogPrefix rejected storage snapshot: '
        '${persistDecision.rejection?.name ?? 'unknown'}',
      );
      if (persistDecision.shouldRebase) {
        await _sendStorageRebaseSnapshot(
          authoritativeBefore,
          reason: persistDecision.rejection!.name,
        );
      }
      return _LotusStorageMessageOutcome.rejected;
    }

    await _storageSnapshotStore.save(snapshot);
    final fallbackAfterSnapshotSave = await _buildFallbackBootstrapValues();
    if (lotusStorageValuesFingerprint(fallbackAfterSnapshotSave) !=
        authoritativeBefore.fallbackFingerprint) {
      await _sendStorageRebaseSnapshot(
        await _loadAuthoritativeStorageState(),
        reason: 'canonical_state_changed_during_persist',
      );
      return _LotusStorageMessageOutcome.rejected;
    }

    final incomingSession = LotusLifeCounterSessionAdapter.tryBuildSession(
      snapshot,
    );
    final mirror = await persistCanonicalMirrorFromLotusSnapshot(
      dayNightStateStore: _dayNightStateStore,
      gameTimerStateStore: _gameTimerStateStore,
      historyStore: _historyStore,
      sessionStore: _sessionStore,
      settingsStore: _settingsStore,
      snapshot: snapshot,
    );
    final committedState = await _loadAuthoritativeStorageState();
    _storageBridgeState.recordAcceptedSnapshot(
      committedState.fingerprint,
      sequence: sequence!,
      incomingFingerprint: lotusStorageValuesFingerprint(snapshot.values),
    );
    final derivedDayNight = mirror.dayNightState;
    final derivedGameTimer = mirror.gameTimerState;
    final derivedHistory = mirror.history;
    final historyDomainPresent = mirror.historyDomainPresent;
    final derivedSession = mirror.session;
    final derivedSettings = mirror.settings;
    if (incomingSession != null &&
        derivedSession != null &&
        incomingSession.toJsonString() != derivedSession.toJsonString()) {
      await _sendStorageRebaseSnapshot(
        committedState,
        reason: 'canonical_session_normalized',
        reloadRuntime: true,
      );
    }

    if (shouldSkipLotusStoragePersistObservability(
      didRecordStoragePersistThisLoad: _didRecordStoragePersistThisLoad,
      didRecordCanonicalSessionMirrorThisLoad:
          _didRecordCanonicalSessionMirrorThisLoad,
      didRecordCanonicalSettingsMirrorThisLoad:
          _didRecordCanonicalSettingsMirrorThisLoad,
      didRecordCanonicalGameTimerMirrorThisLoad:
          _didRecordCanonicalGameTimerMirrorThisLoad,
      didRecordCanonicalDayNightMirrorThisLoad:
          _didRecordCanonicalDayNightMirrorThisLoad,
      didRecordCanonicalHistoryMirrorThisLoad:
          _didRecordCanonicalHistoryMirrorThisLoad,
      historyDomainPresent: historyDomainPresent,
      derivedSession: derivedSession,
      derivedSettings: derivedSettings,
      derivedGameTimer: derivedGameTimer,
      derivedDayNight: derivedDayNight,
      derivedHistory: derivedHistory,
    )) {
      return _LotusStorageMessageOutcome.accepted;
    }

    if (!_didRecordStoragePersistThisLoad) {
      _didRecordStoragePersistThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'storage_snapshot_persisted',
          category: 'life_counter.storage',
          data: {'entry_count': snapshot.entryCount, 'reason': reason},
        ),
      );
    }

    if (derivedSession != null && !_didRecordCanonicalSessionMirrorThisLoad) {
      _didRecordCanonicalSessionMirrorThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'canonical_session_mirrored_from_lotus',
          category: 'life_counter.session',
          data: {
            'player_count': derivedSession.playerCount,
            'starting_life': derivedSession.startingLife,
          },
        ),
      );
    }

    if (derivedSettings != null && !_didRecordCanonicalSettingsMirrorThisLoad) {
      _didRecordCanonicalSettingsMirrorThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'canonical_settings_mirrored_from_lotus',
          category: 'life_counter.settings',
          data: {
            'auto_kill': derivedSettings.autoKill,
            'game_timer': derivedSettings.gameTimer,
            'show_counters_on_player_card':
                derivedSettings.showCountersOnPlayerCard,
          },
        ),
      );
    }

    if (derivedDayNight != null && !_didRecordCanonicalDayNightMirrorThisLoad) {
      _didRecordCanonicalDayNightMirrorThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'canonical_day_night_mirrored_from_lotus',
          category: 'life_counter.day_night',
          data: {'mode': derivedDayNight.mode},
        ),
      );
    }

    if (derivedGameTimer != null &&
        !_didRecordCanonicalGameTimerMirrorThisLoad) {
      _didRecordCanonicalGameTimerMirrorThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'canonical_game_timer_mirrored_from_lotus',
          category: 'life_counter.game_timer',
          data: {
            'is_active': derivedGameTimer.isActive,
            'is_paused': derivedGameTimer.isPaused,
            'has_paused_time': derivedGameTimer.pausedTimeEpochMs != null,
          },
        ),
      );
    }

    if ((historyDomainPresent || derivedHistory.hasContent) &&
        !_didRecordCanonicalHistoryMirrorThisLoad) {
      _didRecordCanonicalHistoryMirrorThisLoad = true;
      unawaited(
        AppObservability.instance.recordEvent(
          'canonical_history_mirrored_from_lotus',
          category: 'life_counter.history',
          data: {
            'history_domain_present': historyDomainPresent,
            'current_game_entries': derivedHistory.currentGameEntries.length,
            'archive_entries': derivedHistory.archiveEntries.length,
            'game_counter': derivedHistory.gameCounter,
            'has_last_table_event': derivedHistory.lastTableEvent != null,
          },
        ),
      );
    }

    unawaited(_captureUiSnapshot());
    return _LotusStorageMessageOutcome.accepted;
  }

  Future<void> _sendStorageBootstrapSnapshot(
    Map<String, dynamic> request,
  ) async {
    final sessionId =
        request['sessionId'] is String ? request['sessionId'] as String : null;
    final requestId =
        request['requestId'] is String ? request['requestId'] as String : null;
    if (sessionId == null ||
        sessionId.isEmpty ||
        requestId == null ||
        requestId.isEmpty) {
      debugPrint('$lotusLogPrefix storage bootstrap envelope is invalid');
      return;
    }

    final authoritativeState = await _loadAuthoritativeStorageState();
    final revision = _storageBridgeState.beginBootstrap(
      sessionId: sessionId,
      requestId: requestId,
      authoritativeFingerprint: authoritativeState.fingerprint,
    );
    final payload = <String, Object?>{
      'type': 'bootstrap_snapshot',
      'sessionId': sessionId,
      'requestId': requestId,
      'revision': revision,
      'hasSnapshot': authoritativeState.values.isNotEmpty,
      'values': authoritativeState.values,
    };

    try {
      await webViewController.runJavaScript('''
        if (
          window.__ManaloomLotusStorageBridge &&
          typeof window.__ManaloomLotusStorageBridge.receiveBootstrap === 'function'
        ) {
          window.__ManaloomLotusStorageBridge.receiveBootstrap(${jsonEncode(payload)});
        }
        ''');
      unawaited(
        AppObservability.instance.recordEvent(
          authoritativeState.values.isEmpty
              ? 'storage_bootstrap_missing'
              : (authoritativeState.snapshot == null
                  ? 'storage_bootstrap_restored_from_canonical'
                  : 'storage_bootstrap_restored'),
          category: 'life_counter.storage',
          data: {
            'entry_count': authoritativeState.values.length,
            'used_fallback': authoritativeState.fallbackValues.isNotEmpty,
            'revision': revision,
          },
        ),
      );
    } catch (error) {
      debugPrint('$lotusLogPrefix storage bootstrap error: $error');
    }
  }

  Future<void> _recordNativeStoragePatch(Map<String, dynamic> payload) async {
    final sessionId =
        payload['sessionId'] is String ? payload['sessionId'] as String : null;
    final revision =
        payload['revision'] is int ? payload['revision'] as int : null;
    if (!_storageBridgeState.isActiveSession(sessionId) ||
        revision == null ||
        revision <= 0) {
      return;
    }

    final authoritativeState = await _loadAuthoritativeStorageState();
    final didRecord = _storageBridgeState.recordNativePatch(
      sessionId: sessionId,
      revision: revision,
      authoritativeFingerprint: authoritativeState.fingerprint,
    );
    if (!didRecord && revision < _storageBridgeState.revision) {
      await _sendStorageRebaseSnapshot(
        authoritativeState,
        reason: 'stale_native_patch_revision',
      );
    }
  }

  void _recordStorageBootstrapFailure(Map<String, dynamic> payload) {
    final sessionId =
        payload['sessionId'] is String ? payload['sessionId'] as String : null;
    if (!_storageBridgeState.isActiveSession(sessionId) || _isDisposed) {
      return;
    }

    errorMessage.value = _storageBootstrapErrorMessage;
    dismissLoadingOverlay();
    unawaited(
      AppObservability.instance.recordEvent(
        'storage_bootstrap_failed',
        category: 'life_counter.storage',
        level: SentryLevel.error,
        data: {'attempts': payload['attempts'], 'reason': payload['reason']},
      ),
    );
  }

  Future<bool> _sendStorageRebaseSnapshot(
    _LotusAuthoritativeStorageState authoritativeState, {
    required String reason,
    bool reloadRuntime = false,
  }) async {
    final sessionId = _storageBridgeState.activeSessionId;
    if (sessionId == null || _isDisposed) {
      return false;
    }

    final revision = _storageBridgeState.beginRebase(
      authoritativeState.fingerprint,
    );
    final payload = <String, Object?>{
      'type': 'rebase_snapshot',
      'sessionId': sessionId,
      'revision': revision,
      'reason': reason,
      'reloadRuntime': reloadRuntime,
      'values': authoritativeState.values,
    };

    try {
      if (reloadRuntime) {
        suppressStaleBeforeUnloadSnapshot();
      }
      final rawResult = await webViewController.runJavaScriptReturningResult('''
        (() => {
          const bridge = window.__ManaloomLotusStorageBridge;
          if (!bridge || typeof bridge.receiveRebase !== 'function') {
            return JSON.stringify({ ok: false, reason: 'bridge_missing' });
          }
          const result = bridge.receiveRebase(${jsonEncode(payload)});
          return JSON.stringify(
            result && typeof result === 'object'
              ? result
              : { ok: false, reason: 'invalid_bridge_result' }
          );
        })()
        ''');
      if (!isSuccessfulLotusStorageBridgeResult(rawResult)) {
        debugPrint('$lotusLogPrefix storage rebase was rejected by WebView');
        return false;
      }
      unawaited(
        AppObservability.instance.recordEvent(
          'storage_snapshot_rebased',
          category: 'life_counter.storage',
          data: {
            'entry_count': authoritativeState.values.length,
            'reason': reason,
            'revision': revision,
          },
        ),
      );
      return true;
    } catch (error) {
      debugPrint('$lotusLogPrefix storage rebase error: $error');
      return false;
    }
  }

  Future<_LotusAuthoritativeStorageState>
  _loadAuthoritativeStorageState() async {
    final snapshot = await _storageSnapshotStore.load();
    final fallbackValues = await _buildFallbackBootstrapValues();
    return _LotusAuthoritativeStorageState(
      snapshot: snapshot,
      fallbackValues: fallbackValues,
      values: mergeLotusBootstrapValues(
        snapshotValues: snapshot?.values,
        fallbackValues: fallbackValues,
      ),
    );
  }

  Future<Map<String, String>> _buildFallbackBootstrapValues() async {
    return buildLotusFallbackBootstrapValues(
      dayNightStateStore: _dayNightStateStore,
      gameTimerStateStore: _gameTimerStateStore,
      historyStore: _historyStore,
      sessionStore: _sessionStore,
      settingsStore: _settingsStore,
    );
  }

  void dismissLoadingOverlay() {
    if (_isDisposed || !isLoading.value) {
      return;
    }

    isLoading.value = false;
  }

  void _handleProgress(int progress) {
    if (progress >= lotusLoadingOverlayDismissProgress) {
      dismissLoadingOverlay();
    }
  }

  void _handlePageFinished(String _) {
    unawaited(
      AppObservability.instance.recordEvent(
        'bundle_load_succeeded',
        category: 'life_counter.host',
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 300),
      dismissLoadingOverlay,
    );
    unawaited(_applyShellCleanupIfNeeded());
    unawaited(_runBridgeProbeIfNeeded());
    unawaited(_runDomProbeIfNeeded());
  }

  void _handleWebResourceError(WebResourceError error) {
    debugPrint(
      '$lotusLogPrefix WebView error: '
      '${error.errorCode} ${error.description}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'web_resource_error',
        category: 'life_counter.host',
        level: SentryLevel.error,
        data: {
          'code': error.errorCode,
          'description': error.description,
          'is_main_frame': error.isForMainFrame ?? true,
        },
      ),
    );

    if (error.isForMainFrame ?? true) {
      errorMessage.value = _bundleLoadErrorMessage;
    }

    dismissLoadingOverlay();
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    if (!lotusShouldEnforceShellCleanup) {
      return NavigationDecision.navigate;
    }

    if (!lotusShouldPreventNavigation(request)) {
      return NavigationDecision.navigate;
    }

    debugPrint(
      '$lotusLogPrefix blocked top-level navigation to ${request.url}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'blocked_top_level_navigation',
        category: 'life_counter.shell',
        data: {'url': request.url},
      ),
    );
    _notifyBlockedNavigation(request.url);
    return NavigationDecision.prevent;
  }

  Future<void> _applyShellCleanupIfNeeded() async {
    if (!lotusShouldEnforceShellCleanup || _isDisposed) {
      return;
    }

    try {
      await webViewController.runJavaScript(lotusInjectedContractScript);
      await webViewController.runJavaScript(lotusInjectedVisualSkinScript);
      await webViewController.runJavaScript(lotusShellCleanupScript);
      if (lotusHasVisualProof) {
        final proofScript = lotusInjectedVisualProofScript;
        if (proofScript != null) {
          await webViewController.runJavaScript(proofScript);
        }
      }
    } catch (error) {
      debugPrint('$lotusLogPrefix shell cleanup error: $error');
    }
  }

  Future<void> _runBridgeProbeIfNeeded() async {
    if (!lotusShouldRunBridgeProbe || _didRunBridgeProbe || _isDisposed) {
      return;
    }

    _didRunBridgeProbe = true;

    try {
      final bridgeState = await webViewController.runJavaScriptReturningResult(
        '''
        JSON.stringify({
          cordova: !!window.cordova,
          appReview: !!(
            window.cordova &&
            window.cordova.plugins &&
            window.cordova.plugins.AppReview &&
            window.cordova.plugins.AppReview.requestReview
          ),
          insomnia: !!(
            window.plugins &&
            window.plugins.insomnia &&
            window.plugins.insomnia.keepAwake
          ),
          clipboard: !!(
            navigator.clipboard &&
            navigator.clipboard.writeText
          )
        })
        ''',
      );
      debugPrint('$lotusLogPrefix bridge probe: $bridgeState');

      await webViewController.runJavaScript(
        "navigator.clipboard.writeText('__lotus_clipboard_probe__');",
      );
    } catch (error) {
      debugPrint('$lotusLogPrefix bridge probe error: $error');
    }
  }

  Future<void> _runDomProbeIfNeeded() async {
    if (!lotusShouldRunDomProbe || _isDisposed) {
      return;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (_isDisposed) {
        return;
      }

      final snapshot = await webViewController.runJavaScriptReturningResult('''
        (() => {
          const describeNode = (node) => {
            const style = window.getComputedStyle(node);
            const rect = node.getBoundingClientRect();
            return {
              tag: node.tagName,
              className: node.className,
              id: node.id,
              text: (node.innerText || '').trim().slice(0, 80),
              display: style.display,
              visibility: style.visibility,
              opacity: style.opacity,
              background: style.background,
              color: style.color,
              width: rect.width,
              height: rect.height,
              top: rect.top,
              left: rect.left,
            };
          };

          const firstPlayerCard = document.querySelector('${LotusDomSelectors.playerCard}');
          const firstOverlay = document.querySelector('${LotusDomSelectors.overlay}');

          return JSON.stringify({
            readyState: document.readyState,
            title: document.title,
            bodyChildCount: document.body ? document.body.children.length : -1,
            bodyTextLength: document.body ? (document.body.innerText || '').length : -1,
            bodyClassName: document.body ? document.body.className : null,
            bodyBackground: document.body ? window.getComputedStyle(document.body).background : null,
            bodyColor: document.body ? window.getComputedStyle(document.body).color : null,
            htmlClassName: document.documentElement ? document.documentElement.className : null,
            innerWidth: window.innerWidth,
            innerHeight: window.innerHeight,
            screenWidth: window.screen ? window.screen.width : null,
            screenHeight: window.screen ? window.screen.height : null,
            styleSheetCount: document.styleSheets ? document.styleSheets.length : -1,
            hasContentGlobal: typeof Content !== 'undefined',
            contentIsConnected: typeof Content !== 'undefined' ? Content.isConnected : null,
            contentInnerHtmlLength: typeof Content !== 'undefined' ? Content.innerHTML.length : -1,
            playerCardCount: document.querySelectorAll('${LotusDomSelectors.playerCard}').length,
            emptyPlayerCardCount: document.querySelectorAll('.empty-player-card').length,
            overlayCount: document.querySelectorAll('${LotusDomSelectors.overlay}').length,
            firstPlayerCard: firstPlayerCard ? describeNode(firstPlayerCard) : null,
            firstOverlay: firstOverlay ? describeNode(firstOverlay) : null,
            firstBodyChildren: document.body
              ? Array.from(document.body.children).slice(0, 12).map(describeNode)
              : [],
          });
        })()
        ''');
      debugPrint('$lotusLogPrefix DOM probe: $snapshot');
    } catch (error) {
      debugPrint('$lotusLogPrefix DOM probe error: $error');
    }
  }

  Future<void> _captureUiSnapshot() async {
    if (_isDisposed || !kDebugMode) {
      return;
    }

    final now = DateTime.now();
    if (_lastUiSnapshotCapturedAt != null &&
        now.difference(_lastUiSnapshotCapturedAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastUiSnapshotCapturedAt = now;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (_isDisposed) {
        return;
      }

      final requestId = DateTime.now().microsecondsSinceEpoch;
      await webViewController.runJavaScript('''
        (() => {
          try {
            const safeStyle = (node) => node ? window.getComputedStyle(node) : null;
            const root = document.documentElement;
            const body = document.body;
            const fontSet = document.fonts;
            const firstLifeNode = document.querySelector(
              '.player-life-count .font, .player-life-count, ${LotusDomSelectors.playerCard} .font'
            );
            const gameTimerNode = document.querySelector(
              '${LotusDomSelectors.mainGameTimer}'
            );
            const turnTrackerNode = document.querySelector(
              '${LotusDomSelectors.turnTracker}'
            );
            const bodyStyle = safeStyle(body);
            const firstLifeStyle = safeStyle(firstLifeNode);
            const firstPlayerNameNode = document.querySelector(
              '${LotusDomSelectors.playerCard} .player-name'
            );
            const firstPlayerNameStyle = safeStyle(firstPlayerNameNode);
            const firstLifeContainerNode = document.querySelector(
              '.player-life-count'
            );
            const firstLifeContainerRect = firstLifeContainerNode
              ? firstLifeContainerNode.getBoundingClientRect()
              : null;
            const gameTimerStyle = safeStyle(gameTimerNode);
            const turnTrackerStyle = safeStyle(turnTrackerNode);
            const scrollWidth = Math.max(
              document.body ? document.body.scrollWidth : 0,
              root ? root.scrollWidth : 0,
            );
            const scrollHeight = Math.max(
              document.body ? document.body.scrollHeight : 0,
              root ? root.scrollHeight : 0,
            );

            FlutterManaLoomShellBridge.postMessage(JSON.stringify({
              type: 'debug_ui_snapshot',
              request_id: $requestId,
              document_scroll_width: scrollWidth,
              document_scroll_height: scrollHeight,
              horizontal_overflow_px: Math.max(
                0,
                scrollWidth - (window.innerWidth || 0),
              ),
              vertical_overflow_px: Math.max(
                0,
                scrollHeight - (window.innerHeight || 0),
              ),
              visual_skin_applied: !!document.getElementById(
                '${LotusVisualSkinStyleIds.primary}'
              ),
              ui_font_family: bodyStyle ? bodyStyle.fontFamily || '' : '',
              document_fonts_status: fontSet ? fontSet.status || '' : 'unsupported',
              ui_font_ready: bodyStyle
                ? (bodyStyle.fontFamily || '').includes('Inter')
                : (fontSet ? fontSet.check('16px "Inter"') : false),
              display_font_ready: firstPlayerNameStyle
                ? (firstPlayerNameStyle.fontFamily || '').includes('Fraunces')
                : (fontSet ? fontSet.check('16px "Fraunces"') : false),
              first_player_name_font_family: firstPlayerNameStyle
                ? firstPlayerNameStyle.fontFamily || ''
                : '',
              first_player_name_font_size: firstPlayerNameStyle
                ? parseFloat(firstPlayerNameStyle.fontSize || '0') || 0
                : 0,
              first_player_life_box_width: firstLifeContainerRect
                ? firstLifeContainerRect.width || 0
                : 0,
              first_player_life_box_height: firstLifeContainerRect
                ? firstLifeContainerRect.height || 0
                : 0,
              first_life_count_font_family: firstLifeStyle
                ? firstLifeStyle.fontFamily || ''
                : '',
              first_life_count_font_size: firstLifeStyle
                ? parseFloat(firstLifeStyle.fontSize || '0') || 0
                : 0,
              game_timer_font_family: gameTimerStyle
                ? gameTimerStyle.fontFamily || ''
                : '',
              game_timer_font_size: gameTimerStyle
                ? parseFloat(gameTimerStyle.fontSize || '0') || 0
                : 0,
              turn_tracker_font_family: turnTrackerStyle
                ? turnTrackerStyle.fontFamily || ''
                : '',
              turn_tracker_font_size: turnTrackerStyle
                ? parseFloat(turnTrackerStyle.fontSize || '0') || 0
                : 0,
              captured_at_epoch_ms: Date.now(),
              body_class_name: document.body ? document.body.className : '',
              viewport_width: window.innerWidth || 0,
              viewport_height: window.innerHeight || 0,
              screen_width: window.screen ? window.screen.width || 0 : 0,
              screen_height: window.screen ? window.screen.height || 0 : 0,
              set_life_by_tap_enabled: !!(
                document.body &&
                document.body.classList.contains('set-life-by-tap-enabled')
              ),
              vertical_tap_areas_enabled: !!(
                document.body &&
                document.body.classList.contains('vertical-tap-areas')
              ),
              clean_look_enabled: !!(
                document.body &&
                document.body.classList.contains('clean-look')
              ),
              regular_counter_count: document.querySelectorAll(
                '${LotusDomSelectors.regularCounters}'
              ).length,
              commander_damage_counter_count: document.querySelectorAll(
                '${LotusDomSelectors.commanderDamageCounters}'
              ).length,
              game_timer_count: document.querySelectorAll(
                '${LotusDomSelectors.mainGameTimer}'
              ).length,
              game_timer_paused_count: document.querySelectorAll(
                '${LotusDomSelectors.mainGameTimer}.paused'
              ).length,
              game_timer_text: (() => {
                const node = document.querySelector(
                  '${LotusDomSelectors.mainGameTimer}'
                );
                return node ? (node.textContent || '').trim() : '';
              })(),
              clock_count: document.querySelectorAll('${LotusDomSelectors.currentTimeClock}').length,
              clock_with_game_timer_count: document.querySelectorAll(
                '${LotusDomSelectors.currentTimeClock}.with-game-timer'
              ).length,
              first_player_card_width: (() => {
                const node = document.querySelector('${LotusDomSelectors.playerCard}');
                if (!node) return 0;
                return node.getBoundingClientRect().width || 0;
              })(),
              first_player_card_height: (() => {
                const node = document.querySelector('${LotusDomSelectors.playerCard}');
                if (!node) return 0;
                return node.getBoundingClientRect().height || 0;
              })(),
              player_card_count: document.querySelectorAll('${LotusDomSelectors.playerCard}').length
            }));
          } catch (e) {
            FlutterManaLoomShellBridge.postMessage(JSON.stringify({
              type: 'debug_ui_snapshot',
              request_id: $requestId,
              error: true,
              message: String(e),
            }));
          }
        })()
      ''');
    } catch (error) {
      debugPrint('$lotusLogPrefix UI snapshot error: $error');
    }
  }

  void _notifyBlockedNavigation(String url) {
    _onShellMessageRequested('ManaLoom blocked an external link: $url');
  }

  void _handleConsoleMessage(JavaScriptConsoleMessage message) {
    debugPrint(
      '$lotusLogPrefix console ${message.level.name}: ${message.message}',
    );
    _recordConsoleEvent(message.message);
  }

  void _recordConsoleEvent(String message) {
    final normalizedMessage = message.trim();
    final markers = <String, ({String category, String name})>{
      'Start Cordova Plugins': (
        category: 'life_counter.host',
        name: 'cordova_plugins_started',
      ),
      'Turn and Time Tracker added': (
        category: 'life_counter.gameplay',
        name: 'turn_tracker_enabled',
      ),
      'Planechase: Open Settings': (
        category: 'life_counter.settings',
        name: 'planechase_settings_opened',
      ),
      'Archenemy: Open Settings': (
        category: 'life_counter.settings',
        name: 'archenemy_settings_opened',
      ),
      'Bounty: Click Settings': (
        category: 'life_counter.settings',
        name: 'bounty_settings_opened',
      ),
      'Life History Overlay': (
        category: 'life_counter.history',
        name: 'history_overlay_opened',
      ),
      'Card Search Overlay': (
        category: 'life_counter.search',
        name: 'card_search_overlay_opened',
      ),
    };

    for (final entry in markers.entries) {
      if (!normalizedMessage.contains(entry.key)) {
        continue;
      }

      unawaited(
        AppObservability.instance.recordEvent(
          entry.value.name,
          category: entry.value.category,
          data: {'console_message': normalizedMessage},
        ),
      );
      return;
    }
  }

  void _handleShellMessage(String message) {
    final payload = _tryDecodeShellPayload(message);
    if (payload == null) {
      _onShellMessageRequested(message);
      return;
    }

    final type = payload['type'];
    if (type == 'debug_ui_snapshot') {
      final snapshot = LotusUiSnapshot.tryFromJson(payload);
      if (snapshot != null) {
        unawaited(_uiSnapshotStore.save(snapshot));
      }
    }

    if (type == LotusShellMessageTypes.analytics) {
      final name = payload['name'];
      final category = payload['category'];
      if (name is String && category is String) {
        final data = <String, Object?>{};
        final rawData = payload['data'];
        if (rawData is Map) {
          for (final entry in rawData.entries) {
            final key = entry.key;
            if (key is String) {
              data[key] = entry.value;
            }
          }
        }

        unawaited(
          AppObservability.instance.recordEvent(
            name,
            category: category,
            data: data,
          ),
        );
      }
      return;
    }

    if (type == LotusShellMessageTypes.blockedLink ||
        type == LotusShellMessageTypes.blockedWindowOpen) {
      final href = payload['href'];
      unawaited(
        AppObservability.instance.recordEvent(
          'blocked_external_link',
          category: 'life_counter.shell',
          data: {'type': type, 'href': href},
        ),
      );
    }

    _onShellMessageRequested(message);
  }

  Map<String, dynamic>? _tryDecodeShellPayload(String message) {
    try {
      final decoded = lotusDecodeShellPayload(message);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _resolveBundleEntry() {
    if (debugLotusForceBundleFailure) {
      return lotusMissingFlutterAssetEntry;
    }

    if (debugLotusFailFirstBundleLoad && !_didInjectDebugBundleFailure) {
      _didInjectDebugBundleFailure = true;
      return lotusMissingFlutterAssetEntry;
    }

    return lotusFlutterAssetEntry;
  }
}
