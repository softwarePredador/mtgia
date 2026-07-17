import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../life_counter/life_counter_day_night_state_store.dart';
import '../life_counter/life_counter_game_timer_state_store.dart';
import '../life_counter/life_counter_history_store.dart';
import '../life_counter/life_counter_settings_store.dart';
import '../life_counter/life_counter_session_store.dart';
import 'lotus_host.dart';
import 'lotus_host_controller.dart'
    show
        buildLotusFallbackBootstrapValues,
        lotusStorageValuesFingerprint,
        mergeLotusBootstrapValues,
        persistCanonicalMirrorFromLotusSnapshot;
import 'lotus_js_bridges.dart';
import 'lotus_native_surface_bridge.dart';
import 'lotus_runtime_flags.dart';
import 'lotus_shell_policy.dart';
import 'lotus_storage_snapshot.dart';
import 'lotus_storage_snapshot_store.dart';
import 'lotus_visual_skin.dart';
import 'lotus_web_document.dart';
import 'lotus_webview_contract.dart';

LotusHost createDefaultLotusHost({
  required LotusAppReviewCallback onAppReviewRequested,
  required LotusShellMessageCallback onShellMessageRequested,
}) {
  return LotusWebHostController(
    onAppReviewRequested: onAppReviewRequested,
    onShellMessageRequested: onShellMessageRequested,
  );
}

class LotusWebHostController
    implements
        LotusHost,
        LotusCanonicalStorageRebaser,
        LotusCanonicalStorageMutationCoordinator,
        LotusLiveStoragePatchCoordinator,
        LotusStorageFlushBarrier {
  LotusWebHostController({
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
    Future<String> Function()? sourceHtmlLoader,
    Future<void> Function(Map<String, String>)?
    canonicalMirrorBarrierForTesting,
    Future<void> Function()? canonicalMutationAfterMutationBarrierForTesting,
  }) : _onAppReviewRequested = onAppReviewRequested,
       _onShellMessageRequested = onShellMessageRequested,
       _sourceHtmlLoader = sourceHtmlLoader,
       _canonicalMirrorBarrierForTesting = canonicalMirrorBarrierForTesting,
       _canonicalMutationAfterMutationBarrierForTesting =
           canonicalMutationAfterMutationBarrierForTesting,
       _viewType = 'manaloom-lotus-web-${_nextViewId++}',
       _bridgeToken = _createBridgeToken() {
    _frame
      // Lotus is a trusted, bundled runtime and requires IndexedDB. Keeping a
      // same-origin sandbox enables that API; localStorage remains replaced by
      // the scoped bridge below so the tabletop snapshot stays isolated.
      ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-downloads allow-modals',
      )
      ..setAttribute('allow', 'clipboard-write')
      ..setAttribute('title', 'ManaLoom Life Counter');
    _frame.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%'
      ..display = 'block'
      ..backgroundColor = '#000000';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _frame);
    _messageSubscription = web.window.onMessage.listen(_handleMessage);
  }

  static int _nextViewId = 0;
  static int _nextBridgeTokenId = 0;
  static const Duration _loadTimeout = Duration(seconds: 9);
  static const Duration _evaluationTimeout = Duration(seconds: 6);
  static const int _storageReadStabilityAttempts = 8;

  static const String _loadErrorMessage =
      'O ManaLoom não conseguiu abrir o contador de vida neste navegador. '
      'Recarregue a página e tente novamente.';

  static String _createBridgeToken() =>
      'lotus-${DateTime.now().microsecondsSinceEpoch}-${_nextBridgeTokenId++}';

  final LotusAppReviewCallback _onAppReviewRequested;
  final LotusShellMessageCallback _onShellMessageRequested;
  final Future<String> Function()? _sourceHtmlLoader;
  final Future<void> Function(Map<String, String>)?
  _canonicalMirrorBarrierForTesting;
  final Future<void> Function()?
  _canonicalMutationAfterMutationBarrierForTesting;
  final String _viewType;
  String _bridgeToken;
  final web.HTMLIFrameElement _frame = web.HTMLIFrameElement();
  final Map<int, Completer<Object?>> _pendingEvaluations =
      <int, Completer<Object?>>{};
  final LifeCounterDayNightStateStore _dayNightStateStore =
      LifeCounterDayNightStateStore();
  final LifeCounterGameTimerStateStore _gameTimerStateStore =
      LifeCounterGameTimerStateStore();
  final LifeCounterHistoryStore _historyStore = LifeCounterHistoryStore();
  final LifeCounterSettingsStore _settingsStore = LifeCounterSettingsStore();
  final LifeCounterSessionStore _sessionStore = LifeCounterSessionStore();
  final LotusStorageSnapshotStore _storageSnapshotStore =
      LotusStorageSnapshotStore();

  late final StreamSubscription<web.MessageEvent> _messageSubscription;
  Completer<void>? _readyCompleter;
  Future<void> _storageMirrorQueue = Future<void>.value();
  Future<void> _canonicalMutationQueue = Future<void>.value();
  int _nextEvaluationId = 0;
  bool _isCanonicalMutationInProgress = false;
  bool _isDisposed = false;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  @override
  Widget buildView(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }

  @visibleForTesting
  void mountFrameForTesting() {
    if (!_frame.isConnected) {
      web.document.body?.appendChild(_frame);
    }
  }

  @visibleForTesting
  Future<void> settleStorageMirrorForTesting() => _storageMirrorQueue;

  @override
  Future<void> loadBundle() async {
    if (_isDisposed) {
      return;
    }

    // Invalidate the active document before the first await. If loading the
    // replacement fails early, delayed messages from the stale iframe still
    // cannot cross back into canonical storage.
    _bridgeToken = _createBridgeToken();
    isLoading.value = true;
    errorMessage.value = null;
    final readyCompleter = Completer<void>();
    _readyCompleter = readyCompleter;

    try {
      await _storageMirrorQueue;
      final sourceHtml =
          await (_sourceHtmlLoader?.call() ??
              rootBundle.loadString(lotusFlutterAssetEntry));
      final initialStorage = await _loadCanonicalStorageValues();
      final document = buildLotusWebDocument(
        sourceHtml: sourceHtml,
        assetBaseUrl: Uri.base.resolve('assets/assets/lotus/').toString(),
        bridgeToken: _bridgeToken,
        initialStorage: initialStorage,
        injectedScripts: <String>[
          lotusInjectedContractScript,
          lotusInjectedVisualSkinScript,
          lotusShellCleanupScript,
          lotusInjectedNativeSurfaceBridgeScript,
        ],
      );
      _frame.srcdoc = document.toJS;
      await readyCompleter.future.timeout(_loadTimeout);
      if (!_isDisposed) {
        isLoading.value = false;
      }
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      if (identical(_readyCompleter, readyCompleter)) {
        _readyCompleter = null;
      }
      debugPrint('$lotusLogPrefix web host load error: $error');
      errorMessage.value = _loadErrorMessage;
      isLoading.value = false;
    }
  }

  @override
  Future<void> runJavaScript(String script) async {
    await _evaluate(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    return _evaluate(script);
  }

  @override
  Future<bool> applyLiveStoragePatch(Map<String, String?> values) async {
    if (_isDisposed || values.isEmpty) return false;
    try {
      final result = await _evaluate('''
(() => {
  const bridge = window.__ManaloomLotusStorageBridge;
  if (!bridge || typeof bridge.receivePatch !== 'function') {
    return JSON.stringify({ ok: false, reason: 'bridge_missing' });
  }
  return JSON.stringify(bridge.receivePatch(${jsonEncode(<String, Object?>{'values': values})}));
})()
''');
      final succeeded = _isSuccessfulBridgeResult(result);
      if (succeeded) {
        await _storageMirrorQueue.timeout(_evaluationTimeout);
      }
      return succeeded;
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage patch error: $error');
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
  }) {
    final result = Completer<bool>();
    final previousMutation = _canonicalMutationQueue;
    _canonicalMutationQueue = () async {
      await previousMutation;
      try {
        result.complete(
          await _performCanonicalStorageMutation(
            mutation: mutation,
            reason: reason,
            reloadRuntime: reloadRuntime,
          ),
        );
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    }();
    return result.future;
  }

  Future<bool> _performCanonicalStorageMutation({
    required LotusCanonicalStorageMutation mutation,
    required String reason,
    required bool reloadRuntime,
  }) async {
    await _storageMirrorQueue;
    if (_isDisposed) {
      await mutation();
      return false;
    }

    _isCanonicalMutationInProgress = true;
    _invalidatePendingStorageFingerprint();
    try {
      await mutation();
      if (_isDisposed) return false;
      await _canonicalMutationAfterMutationBarrierForTesting?.call();
      if (_isDisposed) return false;

      final currentValues = _loadPersistedStorage();
      final authoritativeValues = await _loadCanonicalStorageValues();
      final patch = <String, String?>{
        for (final key in currentValues.keys)
          if (!authoritativeValues.containsKey(key)) key: null,
        ...authoritativeValues,
      };
      await _commitAuthoritativeStorageValues(authoritativeValues);
      final patched = await applyLiveStoragePatch(patch);
      if (!patched) {
        // Do not reactivate persistence from an iframe that could not accept
        // the authoritative patch. Reloading rotates its bridge token, so any
        // delayed messages from that stale document remain rejected even when
        // the fallback load itself fails.
        if (!_isDisposed) {
          await loadBundle();
        }
        return false;
      }
      if (!reloadRuntime || _isDisposed) return true;

      await loadBundle();
      return !_isDisposed && errorMessage.value == null;
    } finally {
      _invalidatePendingStorageFingerprint();
      _isCanonicalMutationInProgress = false;
    }
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {}

  @override
  Future<bool> flushStorageSnapshot({String reason = 'flutter_exit'}) async {
    try {
      final result = await _evaluate('''
(() => {
  const bridge = window.__ManaloomLotusStorageBridge;
  if (!bridge || typeof bridge.flushSnapshot !== 'function') {
    return false;
  }
  const result = bridge.flushSnapshot(${jsonEncode(reason)});
  return !!(result && result.ok === true);
})()
''');
      await _storageMirrorQueue.timeout(_evaluationTimeout);
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    unawaited(_messageSubscription.cancel());
    _frame.remove();
    final error = StateError('Lotus web host was disposed.');
    for (final completer in _pendingEvaluations.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingEvaluations.clear();
    final readyCompleter = _readyCompleter;
    if (readyCompleter != null && !readyCompleter.isCompleted) {
      readyCompleter.completeError(error);
    }
    isLoading.dispose();
    errorMessage.dispose();
  }

  Future<Object?> _evaluate(String script) async {
    if (_isDisposed) {
      throw StateError('Lotus web host is disposed.');
    }
    final readyCompleter = _readyCompleter;
    if (readyCompleter == null) {
      throw StateError('Lotus web host is not loaded.');
    }
    await readyCompleter.future.timeout(_loadTimeout);

    final contentWindow = _frame.contentWindow;
    if (contentWindow == null) {
      throw StateError('Lotus web frame is unavailable.');
    }
    final evaluationId = _nextEvaluationId++;
    final completer = Completer<Object?>();
    _pendingEvaluations[evaluationId] = completer;
    contentWindow.postMessage(
      <String, Object?>{
        'manaloomLotusWeb': true,
        'token': _bridgeToken,
        'kind': 'eval',
        'id': evaluationId,
        'script': script,
      }.jsify(),
      '*'.toJS,
    );

    try {
      return await completer.future.timeout(_evaluationTimeout);
    } finally {
      _pendingEvaluations.remove(evaluationId);
    }
  }

  void _handleMessage(web.MessageEvent event) {
    if (_isDisposed) {
      return;
    }
    final rawData = event.data?.dartify();
    if (rawData is! Map) {
      return;
    }
    final data = rawData.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
    if (data['manaloomLotusWeb'] != true || data['token'] != _bridgeToken) {
      return;
    }

    switch (data['kind']) {
      case 'ready':
        final readyCompleter = _readyCompleter;
        if (data['runtimeReady'] != true) {
          debugPrint(
            '$lotusLogPrefix web host did not detect a ready Lotus runtime.',
          );
          errorMessage.value = _loadErrorMessage;
          isLoading.value = false;
          if (readyCompleter != null && !readyCompleter.isCompleted) {
            readyCompleter.completeError(
              StateError('Lotus web runtime did not become ready.'),
            );
          }
          return;
        }
        if (readyCompleter != null && !readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
        return;
      case 'storage':
        _persistStorage(data['values']);
        return;
      case 'shell':
        final message = data['message'];
        if (message is String) {
          _onShellMessageRequested(message);
        }
        return;
      case 'clipboard':
        final message = data['message'];
        if (message is String) {
          unawaited(Clipboard.setData(ClipboardData(text: message)));
        }
        return;
      case 'app-review':
        final message = data['message'];
        if (message is String) {
          _onAppReviewRequested(message);
        }
        return;
      case 'eval-result':
        final id = data['id'];
        if (id is! num) {
          return;
        }
        final completer = _pendingEvaluations[id.toInt()];
        if (completer == null || completer.isCompleted) {
          return;
        }
        final error = data['error'];
        if (error is String && error.isNotEmpty) {
          completer.completeError(StateError(error));
        } else {
          completer.complete(data['result']);
        }
        return;
      case 'fatal':
        final detail = data['detail'];
        debugPrint('$lotusLogPrefix web host fatal error: $detail');
        errorMessage.value = _loadErrorMessage;
        isLoading.value = false;
        final readyCompleter = _readyCompleter;
        if (readyCompleter != null && !readyCompleter.isCompleted) {
          readyCompleter.completeError(
            StateError(detail?.toString() ?? 'fatal'),
          );
        }
        return;
    }
  }

  Map<String, String> _loadPersistedStorage() {
    try {
      final rawValue = web.window.localStorage.getItem(lotusWebStorageKey);
      if (rawValue == null || rawValue.isEmpty) {
        return const <String, String>{};
      }
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        return const <String, String>{};
      }
      return <String, String>{
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<Map<String, String>> _loadCanonicalStorageValues() async {
    for (
      var attempt = 0;
      attempt < _storageReadStabilityAttempts;
      attempt += 1
    ) {
      final observedMirrorQueue = _storageMirrorQueue;
      await observedMirrorQueue;
      if (!identical(observedMirrorQueue, _storageMirrorQueue)) {
        continue;
      }

      final browserStateBefore = _readStorageJournalState();
      final canonicalSnapshot = await _storageSnapshotStore.load();
      final fallbackValues = await buildLotusFallbackBootstrapValues(
        dayNightStateStore: _dayNightStateStore,
        gameTimerStateStore: _gameTimerStateStore,
        historyStore: _historyStore,
        sessionStore: _sessionStore,
        settingsStore: _settingsStore,
      );
      final browserStateAfter = _readStorageJournalState();
      if (!identical(observedMirrorQueue, _storageMirrorQueue) ||
          !browserStateBefore.hasSameJournalAs(browserStateAfter)) {
        continue;
      }

      if (!browserStateAfter.hasCurrentPendingMirror) {
        if (!_removeStalePendingStorageFingerprint(browserStateAfter)) {
          continue;
        }
        return mergeLotusBootstrapValues(
          snapshotValues: <String, String>{
            ...browserStateAfter.values,
            ...?canonicalSnapshot?.values,
          },
          fallbackValues: fallbackValues,
        );
      }

      // The browser mirror is a complete Lotus snapshot. A matching pending
      // fingerprint means the app was reloaded before its canonical mirror
      // finished, so repair every canonical store from that exact snapshot
      // before booting the board. Keeping the normal precedence otherwise
      // prevents an old browser mirror from reviving a superseded game.
      await _enqueueCanonicalStorageMirror(
        browserStateAfter.values,
        fingerprint: browserStateAfter.valuesFingerprint,
      );
      final repairedBrowserState = _readStorageJournalState();
      if (repairedBrowserState.valuesFingerprint !=
          browserStateAfter.valuesFingerprint) {
        continue;
      }
      if (repairedBrowserState.pendingFingerprint != null &&
          repairedBrowserState.pendingFingerprint !=
              browserStateAfter.pendingFingerprint) {
        continue;
      }
      return browserStateAfter.values;
    }

    throw StateError(
      'Lotus browser storage did not stabilize during bootstrap.',
    );
  }

  bool _isSuccessfulBridgeResult(Object? rawResult) {
    Object? decoded = rawResult;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        return false;
      }
    }
    return decoded is Map && decoded['ok'] == true;
  }

  void _persistStorage(Object? rawValues) {
    if (_isCanonicalMutationInProgress) {
      return;
    }
    if (rawValues is! Map) {
      return;
    }
    final values = <String, String>{
      for (final entry in rawValues.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
    final fingerprint = _storageFingerprint(values);
    try {
      web.window.localStorage.setItem(
        lotusWebStoragePendingFingerprintKey,
        fingerprint,
      );
      web.window.localStorage.setItem(lotusWebStorageKey, jsonEncode(values));
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage persist error: $error');
    }
    unawaited(_enqueueCanonicalStorageMirror(values, fingerprint: fingerprint));
  }

  String _storageFingerprint(Map<String, String> values) {
    return sha256
        .convert(utf8.encode(lotusStorageValuesFingerprint(values)))
        .toString();
  }

  String? _loadPendingStorageFingerprint() {
    try {
      return web.window.localStorage.getItem(
        lotusWebStoragePendingFingerprintKey,
      );
    } catch (_) {
      return null;
    }
  }

  _LotusWebStorageJournalState _readStorageJournalState() {
    final values = Map<String, String>.unmodifiable(_loadPersistedStorage());
    return _LotusWebStorageJournalState(
      values: values,
      valuesFingerprint: _storageFingerprint(values),
      pendingFingerprint: _loadPendingStorageFingerprint(),
    );
  }

  bool _removeStalePendingStorageFingerprint(
    _LotusWebStorageJournalState observedState,
  ) {
    if (observedState.pendingFingerprint == null) {
      return true;
    }
    try {
      final currentState = _readStorageJournalState();
      if (!observedState.hasSameJournalAs(currentState)) {
        return false;
      }
      web.window.localStorage.removeItem(lotusWebStoragePendingFingerprintKey);
      return true;
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage journal cleanup error: $error');
      return true;
    }
  }

  void _invalidatePendingStorageFingerprint() {
    try {
      web.window.localStorage.removeItem(lotusWebStoragePendingFingerprintKey);
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage journal cleanup error: $error');
    }
  }

  Future<void> _commitAuthoritativeStorageValues(
    Map<String, String> rawValues,
  ) async {
    final values = Map<String, String>.unmodifiable(rawValues);
    final snapshot = LotusStorageSnapshot(values: values);
    await _storageSnapshotStore.save(snapshot);
    await persistCanonicalMirrorFromLotusSnapshot(
      dayNightStateStore: _dayNightStateStore,
      gameTimerStateStore: _gameTimerStateStore,
      historyStore: _historyStore,
      sessionStore: _sessionStore,
      settingsStore: _settingsStore,
      snapshot: snapshot,
    );
    try {
      web.window.localStorage.setItem(lotusWebStorageKey, jsonEncode(values));
      web.window.localStorage.removeItem(lotusWebStoragePendingFingerprintKey);
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage commit error: $error');
    }
  }

  Future<void> _enqueueCanonicalStorageMirror(
    Map<String, String> rawValues, {
    required String fingerprint,
  }) {
    final values = Map<String, String>.unmodifiable(rawValues);
    final previousMirror = _storageMirrorQueue;
    final mirror = () async {
      try {
        await previousMirror;
        await _canonicalMirrorBarrierForTesting?.call(values);
        final snapshot = LotusStorageSnapshot(values: values);
        await _storageSnapshotStore.save(snapshot);
        await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: _dayNightStateStore,
          gameTimerStateStore: _gameTimerStateStore,
          historyStore: _historyStore,
          sessionStore: _sessionStore,
          settingsStore: _settingsStore,
          snapshot: snapshot,
        );
        _clearPendingStorageFingerprintIfCurrent(fingerprint);
      } catch (error) {
        debugPrint('$lotusLogPrefix web canonical mirror error: $error');
      }
    }();
    _storageMirrorQueue = mirror;
    return mirror;
  }

  void _clearPendingStorageFingerprintIfCurrent(String fingerprint) {
    try {
      final pendingFingerprint = _loadPendingStorageFingerprint();
      final currentFingerprint = _storageFingerprint(_loadPersistedStorage());
      if (!shouldClearLotusWebStoragePendingFingerprint(
        pendingFingerprint: pendingFingerprint,
        completedFingerprint: fingerprint,
        currentStorageFingerprint: currentFingerprint,
      )) {
        return;
      }
      web.window.localStorage.removeItem(lotusWebStoragePendingFingerprintKey);
    } catch (error) {
      debugPrint('$lotusLogPrefix web storage journal cleanup error: $error');
    }
  }
}

class _LotusWebStorageJournalState {
  const _LotusWebStorageJournalState({
    required this.values,
    required this.valuesFingerprint,
    required this.pendingFingerprint,
  });

  final Map<String, String> values;
  final String valuesFingerprint;
  final String? pendingFingerprint;

  bool get hasCurrentPendingMirror =>
      isLotusWebStoragePendingFingerprintCurrent(
        pendingFingerprint: pendingFingerprint,
        currentStorageFingerprint: valuesFingerprint,
      );

  bool hasSameJournalAs(_LotusWebStorageJournalState other) {
    return valuesFingerprint == other.valuesFingerprint &&
        pendingFingerprint == other.pendingFingerprint;
  }
}
