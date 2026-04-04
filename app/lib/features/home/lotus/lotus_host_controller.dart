import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/observability/app_observability.dart';
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

Future<Map<String, String>> buildLotusFallbackBootstrapValues({
  required LifeCounterDayNightStateStore dayNightStateStore,
  required LifeCounterGameTimerStateStore gameTimerStateStore,
  required LifeCounterHistoryStore historyStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  final dayNightState = await dayNightStateStore.load();
  final gameTimerState = await gameTimerStateStore.load();
  final history = await historyStore.load();
  final session = await sessionStore.load();
  final settings = await settingsStore.load();
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
  final historyDomainPresent = LifeCounterHistoryState.hasSnapshotDomain(
    snapshot,
  );
  final derivedDayNight = buildLotusDayNightStateFromSnapshot(snapshot);
  final derivedSession = LotusLifeCounterSessionAdapter.tryBuildSession(
    snapshot,
  );
  final derivedSettings = LotusLifeCounterSettingsAdapter.tryBuildSettings(
    snapshot,
  );
  final derivedGameTimer = LotusLifeCounterGameTimerAdapter.tryBuildState(
    snapshot,
  );
  final derivedHistory = LifeCounterHistoryState.fromSources(
    session: derivedSession,
    snapshot: snapshot,
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

class LotusHostController implements LotusHost {
  static const String _bundleLoadErrorMessage =
      'ManaLoom could not open the embedded life counter. '
      'Check the local bundle and try again.';

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
  DateTime? _ignoreBeforeUnloadSnapshotUntil;

  @override
  Widget buildView(BuildContext context) {
    return WebViewWidget(controller: webViewController);
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {
    _ignoreBeforeUnloadSnapshotUntil = DateTime.now().add(
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
  void dispose() {
    _isDisposed = true;
    _loadingOverlayFallbackTimer?.cancel();
    isLoading.dispose();
    errorMessage.dispose();
  }

  void _configure({required LotusAppReviewCallback onAppReviewRequested}) {
    LotusJavaScriptBridges.register(
      webViewController,
      onAppReviewRequested: onAppReviewRequested,
      onShellMessageRequested: _handleShellMessage,
      onStorageMessageRequested: _handleStorageMessage,
    );

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
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
    final payload = _tryDecodeShellPayload(message);
    if (payload == null) {
      debugPrint('$lotusLogPrefix storage bridge received invalid payload');
      return;
    }

    final type = payload['type'];
    if (type == 'request_bootstrap') {
      await _sendStorageBootstrapSnapshot();
      return;
    }

    if (type != 'persist_snapshot') {
      return;
    }

    final snapshot = LotusStorageSnapshot.tryFromJson(payload);
    if (snapshot == null) {
      return;
    }

    final reason = payload['reason'] as String?;
    if (reason == 'beforeunload' &&
        _ignoreBeforeUnloadSnapshotUntil != null &&
        DateTime.now().isBefore(_ignoreBeforeUnloadSnapshotUntil!)) {
      return;
    }

    await _storageSnapshotStore.save(snapshot);
    final mirror = await persistCanonicalMirrorFromLotusSnapshot(
      dayNightStateStore: _dayNightStateStore,
      gameTimerStateStore: _gameTimerStateStore,
      historyStore: _historyStore,
      sessionStore: _sessionStore,
      settingsStore: _settingsStore,
      snapshot: snapshot,
    );
    final derivedDayNight = mirror.dayNightState;
    final derivedGameTimer = mirror.gameTimerState;
    final derivedHistory = mirror.history;
    final historyDomainPresent = mirror.historyDomainPresent;
    final derivedSession = mirror.session;
    final derivedSettings = mirror.settings;

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
      return;
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
  }

  Future<void> _sendStorageBootstrapSnapshot() async {
    final snapshot = await _storageSnapshotStore.load();
    final fallbackValues = await _buildFallbackBootstrapValues();
    final mergedValues = mergeLotusBootstrapValues(
      snapshotValues: snapshot?.values,
      fallbackValues: fallbackValues,
    );
    final payload = <String, Object?>{
      'type': 'bootstrap_snapshot',
      'hasSnapshot': mergedValues.isNotEmpty,
      'values': mergedValues,
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
          mergedValues.isEmpty
              ? 'storage_bootstrap_missing'
              : (snapshot == null
                  ? 'storage_bootstrap_restored_from_canonical'
                  : 'storage_bootstrap_restored'),
          category: 'life_counter.storage',
          data: {
            'entry_count': mergedValues.length,
            'used_fallback': fallbackValues.isNotEmpty,
          },
        ),
      );
    } catch (error) {
      debugPrint('$lotusLogPrefix storage bootstrap error: $error');
    }
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
    if (_isDisposed) {
      return;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (_isDisposed) {
        return;
      }

      final rawSnapshot = await webViewController.runJavaScriptReturningResult(
        '''
        (() => JSON.stringify({
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
        }))()
      ''',
      );

      final decoded = _decodeJavaScriptJsonResult(rawSnapshot);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final snapshot = LotusUiSnapshot.tryFromJson(decoded);
      if (snapshot == null) {
        return;
      }

      await _uiSnapshotStore.save(snapshot);
    } catch (error) {
      debugPrint('$lotusLogPrefix UI snapshot error: $error');
    }
  }

  Object? _decodeJavaScriptJsonResult(Object? rawResult) {
    Object? value = rawResult;

    for (var attempt = 0; attempt < 3; attempt += 1) {
      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return value.cast<String, dynamic>();
      }

      if (value is! String || value.isEmpty) {
        return value;
      }

      try {
        value = jsonDecode(value);
      } catch (_) {
        return value;
      }
    }

    return value;
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
