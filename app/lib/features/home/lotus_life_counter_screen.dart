import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/observability/app_observability.dart';
import 'life_counter/life_counter_game_timer_state.dart';
import 'life_counter/life_counter_game_timer_state_store.dart';
import 'life_counter/life_counter_history.dart';
import 'life_counter/life_counter_history_transfer.dart';
import 'life_counter/life_counter_native_card_search_sheet.dart';
import 'life_counter/life_counter_native_game_timer_sheet.dart';
import 'life_counter/life_counter_native_history_sheet.dart';
import 'life_counter/life_counter_native_settings_sheet.dart';
import 'life_counter/life_counter_native_turn_tracker_sheet.dart';
import 'life_counter/life_counter_settings.dart';
import 'life_counter/life_counter_settings_store.dart';
import 'life_counter/life_counter_session.dart';
import 'life_counter/life_counter_session_store.dart';
import 'life_counter_route.dart';
import 'lotus/lotus_life_counter_settings_adapter.dart';
import 'lotus/lotus_life_counter_session_adapter.dart';
import 'lotus/lotus_host.dart';
import 'lotus/lotus_host_controller.dart';
import 'lotus/lotus_host_overlays.dart';
import 'lotus/lotus_life_counter_game_timer_adapter.dart';
import 'lotus/lotus_runtime_flags.dart';
import 'lotus/lotus_storage_snapshot.dart';
import 'lotus/lotus_storage_snapshot_store.dart';

class LotusLifeCounterScreen extends StatefulWidget {
  const LotusLifeCounterScreen({super.key, this.hostFactory});

  final LotusHostFactory? hostFactory;

  @override
  State<LotusLifeCounterScreen> createState() => _LotusLifeCounterScreenState();
}

class _LotusLifeCounterScreenState extends State<LotusLifeCounterScreen> {
  late final LotusHost _hostController;
  final LifeCounterGameTimerStateStore _gameTimerStateStore =
      LifeCounterGameTimerStateStore();
  final LifeCounterSettingsStore _settingsStore = LifeCounterSettingsStore();
  final LifeCounterSessionStore _sessionStore = LifeCounterSessionStore();
  final LotusStorageSnapshotStore _snapshotStore = LotusStorageSnapshotStore();
  DateTime? _lastShellMessageAt;
  OverlayEntry? _loadingOverlayEntry;
  OverlayEntry? _errorOverlayEntry;
  bool _isNativeSettingsSheetOpen = false;
  bool _isNativeHistorySheetOpen = false;
  bool _isNativeCardSearchSheetOpen = false;
  bool _isNativeTurnTrackerSheetOpen = false;
  bool _isNativeGameTimerSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _hostController = (widget.hostFactory ?? LotusHostController.new)(
      onAppReviewRequested: _handleAppReviewRequested,
      onShellMessageRequested: _handleShellMessageRequested,
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'opened',
        category: 'life_counter.screen',
        data: {
          'route': lifeCounterRoutePath,
          'implementation': 'embedded_lotus',
        },
      ),
    );
    _hostController.isLoading.addListener(_syncLoadingOverlay);
    _hostController.errorMessage.addListener(_syncErrorOverlay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _syncLoadingOverlay();
      _syncErrorOverlay();
      unawaited(_hostController.loadBundle());
    });
  }

  @override
  void dispose() {
    _hostController.isLoading.removeListener(_syncLoadingOverlay);
    _hostController.errorMessage.removeListener(_syncErrorOverlay);
    _removeLoadingOverlay();
    _removeErrorOverlay();
    unawaited(
      AppObservability.instance.recordEvent(
        'closed',
        category: 'life_counter.screen',
        data: {
          'route': lifeCounterRoutePath,
          'implementation': 'embedded_lotus',
        },
      ),
    );
    _hostController.dispose();
    super.dispose();
  }

  void _syncLoadingOverlay() {
    if (!mounted) {
      return;
    }

    if (_hostController.isLoading.value) {
      _ensureLoadingOverlay();
      return;
    }

    _removeLoadingOverlay();
  }

  void _syncErrorOverlay() {
    if (!mounted) {
      return;
    }

    final errorMessage = _hostController.errorMessage.value;
    if (errorMessage == null) {
      _removeErrorOverlay();
      return;
    }

    _ensureErrorOverlay();
    _errorOverlayEntry?.markNeedsBuild();
  }

  void _ensureLoadingOverlay() {
    if (_loadingOverlayEntry != null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => const LotusLoadingOverlay(),
    );
    overlay.insert(_loadingOverlayEntry!);
  }

  void _removeLoadingOverlay() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
  }

  void _ensureErrorOverlay() {
    if (_errorOverlayEntry != null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _errorOverlayEntry = OverlayEntry(
      builder:
          (context) => LotusErrorOverlay(
            message: _hostController.errorMessage.value ?? '',
            onRetry: () {
              _removeErrorOverlay();
              unawaited(_hostController.loadBundle());
            },
          ),
    );
    overlay.insert(_errorOverlayEntry!);
  }

  void _removeErrorOverlay() {
    _errorOverlayEntry?.remove();
    _errorOverlayEntry = null;
  }

  void _handleAppReviewRequested(String message) {
    debugPrint('$lotusLogPrefix AppReview requested: $message');
    unawaited(
      AppObservability.instance.recordEvent(
        'app_review_requested',
        category: 'life_counter.shell',
        data: {'message': message},
      ),
    );
  }

  void _handleShellMessageRequested(String message) {
    if (!mounted) {
      return;
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        if (decoded['type'] == 'open-native-settings') {
          unawaited(
            _openNativeSettingsSheet(
              source: (decoded['source'] as String?) ?? 'shell_shortcut',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-history') {
          unawaited(
            _openNativeHistorySheet(
              source: (decoded['source'] as String?) ?? 'shell_shortcut',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-card-search') {
          unawaited(
            _openNativeCardSearchSheet(
              source: (decoded['source'] as String?) ?? 'shell_shortcut',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-turn-tracker') {
          unawaited(
            _openNativeTurnTrackerSheet(
              source:
                  (decoded['source'] as String?) ??
                  'turn_tracker_surface_pressed',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-game-timer') {
          unawaited(
            _openNativeGameTimerSheet(
              source:
                  (decoded['source'] as String?) ??
                  'game_timer_surface_pressed',
            ),
          );
          return;
        }
      }
    } catch (_) {}

    final now = DateTime.now();
    if (_lastShellMessageAt != null &&
        now.difference(_lastShellMessageAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastShellMessageAt = now;

    var displayMessage =
        'External shortcut disabled while ManaLoom owns the life counter shell.';
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'];
        if (type == 'blocked-window-open' || type == 'blocked-link') {
          displayMessage =
              'External shortcut disabled while ManaLoom owns the life counter shell.';
        }
      } else if (message.startsWith('ManaLoom blocked an external link:')) {
        displayMessage =
            'External shortcut disabled while ManaLoom owns the life counter shell.';
      }
    } catch (_) {
      if (message.startsWith('ManaLoom blocked an external link:')) {
        displayMessage =
            'External shortcut disabled while ManaLoom owns the life counter shell.';
      }
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> debugHandleShellMessage(String message) async {
    _handleShellMessageRequested(message);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _openNativeSettingsSheet({required String source}) async {
    if (!mounted || _isNativeSettingsSheetOpen) {
      return;
    }

    _isNativeSettingsSheetOpen = true;
    final initialSettings =
        await _settingsStore.load() ?? LifeCounterSettings.defaults;
    if (!mounted) {
      _isNativeSettingsSheetOpen = false;
      return;
    }
    unawaited(
      AppObservability.instance.recordEvent(
        'native_settings_opened',
        category: 'life_counter.settings',
        data: {'source': source},
      ),
    );

    final updatedSettings = await showLifeCounterNativeSettingsSheet(
      context,
      initialSettings: initialSettings,
    );
    _isNativeSettingsSheetOpen = false;

    if (!mounted || updatedSettings == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_settings_dismissed',
          category: 'life_counter.settings',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSettings.toJsonString() == initialSettings.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_settings_dismissed',
          category: 'life_counter.settings',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeSettings(updatedSettings, source: source);
  }

  Future<void> _applyNativeSettings(
    LifeCounterSettings settings, {
    required String source,
  }) async {
    await _settingsStore.save(settings);

    final snapshot = await _snapshotStore.load();
    if (snapshot != null) {
      final mergedValues = <String, String>{
        ...snapshot.values,
        ...LotusLifeCounterSettingsAdapter.buildSnapshotValues(settings),
      };
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(mergedValues),
        ),
      );
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_settings_applied',
        category: 'life_counter.settings',
        data: {
          'source': source,
          'game_timer': settings.gameTimer,
          'show_counters_on_player_card': settings.showCountersOnPlayerCard,
          'clean_look': settings.cleanLook,
        },
      ),
    );

    unawaited(_hostController.loadBundle());
  }

  Future<void> _openNativeHistorySheet({required String source}) async {
    if (!mounted || _isNativeHistorySheetOpen) {
      return;
    }

    _isNativeHistorySheetOpen = true;
    final session = await _sessionStore.load();
    final snapshot = await _snapshotStore.load();
    if (!mounted) {
      _isNativeHistorySheetOpen = false;
      return;
    }

    final history = LifeCounterHistorySnapshot.fromSources(
      session: session,
      snapshot: snapshot,
    );

    unawaited(
      AppObservability.instance.recordEvent(
        'native_history_opened',
        category: 'life_counter.history',
        data: {
          'source': source,
          'current_game_events': history.currentGameEventCount,
          'archived_games': history.archivedGameCount,
          'archived_events': history.archivedEventCount,
        },
      ),
    );

    await showLifeCounterNativeHistorySheet(
      context,
      history: history,
      onExportPressed: () => _exportNativeHistory(history, source: source),
      onImportSubmitted:
          (rawPayload) => _importNativeHistory(rawPayload, source: source),
    );
    _isNativeHistorySheetOpen = false;

    if (!mounted) {
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_history_dismissed',
        category: 'life_counter.history',
        data: {'source': source, 'had_content': history.hasContent},
      ),
    );
  }

  Future<void> _exportNativeHistory(
    LifeCounterHistorySnapshot history, {
    required String source,
  }) async {
    final transfer = LifeCounterHistoryTransfer.fromSnapshot(history);
    await Clipboard.setData(ClipboardData(text: transfer.toJsonString()));
    unawaited(
      AppObservability.instance.recordEvent(
        'native_history_exported',
        category: 'life_counter.history',
        data: {
          'source': source,
          'current_game_events': history.currentGameEventCount,
          'archived_events': history.archivedEventCount,
        },
      ),
    );
  }

  Future<bool> _importNativeHistory(
    String rawPayload, {
    required String source,
  }) async {
    final transfer = LifeCounterHistoryTransfer.tryParse(rawPayload);
    if (transfer == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_history_import_failed',
          category: 'life_counter.history',
          data: {'source': source, 'reason': 'invalid_payload'},
        ),
      );
      return false;
    }

    final snapshot = await _snapshotStore.load();
    final mergedValues = <String, String>{...?snapshot?.values};

    final currentGameMeta = _decodeSnapshotValueMap(
      mergedValues['currentGameMeta'],
    );
    if (transfer.currentGameName != null) {
      currentGameMeta['name'] = transfer.currentGameName;
    }
    mergedValues['currentGameMeta'] = jsonEncode(currentGameMeta);
    mergedValues['gameHistory'] = jsonEncode(
      transfer.currentGameEntries
          .map(
            (entry) => {
              'message': entry.message,
              if (entry.occurredAt != null)
                'timestamp': entry.occurredAt!.millisecondsSinceEpoch,
            },
          )
          .toList(growable: false),
    );
    mergedValues['allGamesHistory'] = jsonEncode(
      transfer.archiveEntries.isEmpty
          ? const <Object?>[]
          : [
            {
              'name': transfer.currentGameName ?? 'Imported History',
              'history': transfer.archiveEntries
                  .map(
                    (entry) => {
                      'message': entry.message,
                      if (entry.occurredAt != null)
                        'timestamp': entry.occurredAt!.millisecondsSinceEpoch,
                    },
                  )
                  .toList(growable: false),
            },
          ],
    );

    await _snapshotStore.save(
      LotusStorageSnapshot(
        values: Map<String, String>.unmodifiable(mergedValues),
      ),
    );

    final session = await _sessionStore.load();
    if (session != null) {
      final payload = <String, dynamic>{
        ...session.toJson(),
        'last_table_event': transfer.lastTableEvent,
      };
      final importedSession = LifeCounterSession.tryFromJson(payload);
      if (importedSession != null) {
        await _sessionStore.save(importedSession);
      }
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_history_imported',
        category: 'life_counter.history',
        data: {
          'source': source,
          'current_game_events': transfer.currentGameEntries.length,
          'archived_events': transfer.archiveEntries.length,
        },
      ),
    );
    return true;
  }

  Map<String, Object?> _decodeSnapshotValueMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{
        'id': 'manaloom-imported-history',
        'name': 'Imported History',
        'startDate': DateTime.now().millisecondsSinceEpoch,
      };
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return <String, Object?>{...decoded};
      }
      if (decoded is Map) {
        return decoded.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {}

    return <String, Object?>{
      'id': 'manaloom-imported-history',
      'name': 'Imported History',
      'startDate': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> _openNativeCardSearchSheet({required String source}) async {
    if (!mounted || _isNativeCardSearchSheetOpen) {
      return;
    }

    _isNativeCardSearchSheetOpen = true;
    unawaited(
      AppObservability.instance.recordEvent(
        'native_card_search_opened',
        category: 'life_counter.search',
        data: {'source': source},
      ),
    );

    await showLifeCounterNativeCardSearchSheet(context);
    _isNativeCardSearchSheetOpen = false;

    if (!mounted) {
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_card_search_dismissed',
        category: 'life_counter.search',
        data: {'source': source},
      ),
    );
  }

  Future<void> _openNativeTurnTrackerSheet({required String source}) async {
    if (!mounted || _isNativeTurnTrackerSheetOpen) {
      return;
    }

    _isNativeTurnTrackerSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativeTurnTrackerSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_turn_tracker_opened',
        category: 'life_counter.turn_tracker',
        data: {
          'source': source,
          'is_active': session.turnTrackerActive,
          'current_turn': session.currentTurnNumber,
        },
      ),
    );

    final updatedSession = await showLifeCounterNativeTurnTrackerSheet(
      context,
      initialSession: session,
    );
    _isNativeTurnTrackerSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_turn_tracker_dismissed',
          category: 'life_counter.turn_tracker',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_turn_tracker_dismissed',
          category: 'life_counter.turn_tracker',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeTurnTracker(updatedSession, source: source);
  }

  Future<void> _applyNativeTurnTracker(
    LifeCounterSession session, {
    required String source,
  }) async {
    await _sessionStore.save(session);

    final settings = await _settingsStore.load();
    final snapshot = await _snapshotStore.load();
    if (snapshot != null) {
      final mergedValues = <String, String>{
        ...snapshot.values,
        ...LotusLifeCounterSessionAdapter.buildTurnTrackerSnapshotValues(
          session,
          layoutType: LotusLifeCounterSessionAdapter.tryReadLayoutType(
            snapshot,
          ),
        ),
      };
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(mergedValues),
        ),
      );
    } else {
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(
            LotusLifeCounterSessionAdapter.buildSnapshotValues(
              session,
              settings: settings,
            ),
          ),
        ),
      );
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_turn_tracker_applied',
        category: 'life_counter.turn_tracker',
        data: {
          'source': source,
          'is_active': session.turnTrackerActive,
          'current_turn': session.currentTurnNumber,
          'current_player_index': session.currentTurnPlayerIndex,
          'starting_player_index': session.firstPlayerIndex,
          'turn_timer_active': session.turnTimerActive,
        },
      ),
    );

    unawaited(_hostController.loadBundle());
  }

  Future<void> _openNativeGameTimerSheet({required String source}) async {
    if (!mounted || _isNativeGameTimerSheetOpen) {
      return;
    }

    _isNativeGameTimerSheetOpen = true;
    final initialState =
        await _gameTimerStateStore.load() ??
        const LifeCounterGameTimerState(
          startTimeEpochMs: null,
          isPaused: false,
          pausedTimeEpochMs: null,
        );
    if (!mounted) {
      _isNativeGameTimerSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_game_timer_opened',
        category: 'life_counter.game_timer',
        data: {
          'source': source,
          'is_active': initialState.isActive,
          'is_paused': initialState.isPaused,
        },
      ),
    );

    final updatedState = await showLifeCounterNativeGameTimerSheet(
      context,
      initialState: initialState,
    );
    _isNativeGameTimerSheetOpen = false;

    if (!mounted || updatedState == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_game_timer_dismissed',
          category: 'life_counter.game_timer',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedState.toJsonString() == initialState.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_game_timer_dismissed',
          category: 'life_counter.game_timer',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeGameTimerState(updatedState, source: source);
  }

  Future<void> _applyNativeGameTimerState(
    LifeCounterGameTimerState state, {
    required String source,
  }) async {
    if (state.isActive) {
      await _gameTimerStateStore.save(state);
    } else {
      await _gameTimerStateStore.clear();
    }

    final snapshot = await _snapshotStore.load();
    if (snapshot != null) {
      final mergedValues = <String, String>{...snapshot.values};
      mergedValues.remove(LotusLifeCounterGameTimerAdapter.gameTimerStateKey);
      mergedValues.addAll(
        LotusLifeCounterGameTimerAdapter.buildSnapshotValues(state),
      );
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(mergedValues),
        ),
      );
    } else if (state.isActive) {
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(
            LotusLifeCounterGameTimerAdapter.buildSnapshotValues(state),
          ),
        ),
      );
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_game_timer_applied',
        category: 'life_counter.game_timer',
        data: {
          'source': source,
          'is_active': state.isActive,
          'is_paused': state.isPaused,
          'has_paused_time': state.pausedTimeEpochMs != null,
        },
      ),
    );

    unawaited(_hostController.loadBundle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // A plain body avoids the zero-sized viewport issue we hit when wrapping
      // this PlatformView in a Stack on Android.
      body: _hostController.buildView(context),
    );
  }
}
