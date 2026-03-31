import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/observability/app_observability.dart';
import 'life_counter/life_counter_day_night_state.dart';
import 'life_counter/life_counter_day_night_state_store.dart';
import 'life_counter/life_counter_game_timer_state.dart';
import 'life_counter/life_counter_game_timer_state_store.dart';
import 'life_counter/life_counter_history.dart';
import 'life_counter/life_counter_history_transfer.dart';
import 'life_counter/life_counter_native_card_search_sheet.dart';
import 'life_counter/life_counter_native_commander_damage_sheet.dart';
import 'life_counter/life_counter_native_day_night_sheet.dart';
import 'life_counter/life_counter_native_dice_sheet.dart';
import 'life_counter/life_counter_native_game_modes_sheet.dart';
import 'life_counter/life_counter_native_game_timer_sheet.dart';
import 'life_counter/life_counter_native_history_sheet.dart';
import 'life_counter/life_counter_native_player_appearance_sheet.dart';
import 'life_counter/life_counter_native_player_counter_sheet.dart';
import 'life_counter/life_counter_native_quick_actions_sheet.dart';
import 'life_counter/life_counter_native_set_life_sheet.dart';
import 'life_counter/life_counter_native_player_state_sheet.dart';
import 'life_counter/life_counter_native_settings_sheet.dart';
import 'life_counter/life_counter_native_table_state_sheet.dart';
import 'life_counter/life_counter_native_turn_tracker_sheet.dart';
import 'life_counter/life_counter_player_appearance_profile_store.dart';
import 'life_counter/life_counter_player_appearance_transfer.dart';
import 'life_counter/life_counter_settings.dart';
import 'life_counter/life_counter_settings_store.dart';
import 'life_counter/life_counter_session.dart';
import 'life_counter/life_counter_session_store.dart';
import 'life_counter/life_counter_tabletop_engine.dart';
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
  static const Set<String> _playerStateSurfaceResetSources = <String>{
    'player_option_card_presented',
  };
  static const Set<String> _playerAppearanceSurfaceResetSources = <String>{
    'player_background_surface_pressed',
    'player_background_color_card_presented',
  };

  late final LotusHost _hostController;
  final LifeCounterGameTimerStateStore _gameTimerStateStore =
      LifeCounterGameTimerStateStore();
  final LifeCounterDayNightStateStore _dayNightStateStore =
      LifeCounterDayNightStateStore();
  final LifeCounterPlayerAppearanceProfileStore _appearanceProfileStore =
      LifeCounterPlayerAppearanceProfileStore();
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
  bool _isNativeDiceSheetOpen = false;
  bool _isNativeGameModesSheetOpen = false;
  bool _isNativeQuickActionsSheetOpen = false;
  bool _isNativeCommanderDamageSheetOpen = false;
  bool _isNativePlayerAppearanceSheetOpen = false;
  bool _isNativePlayerCounterSheetOpen = false;
  bool _isNativePlayerStateSheetOpen = false;
  bool _isNativeSetLifeSheetOpen = false;
  bool _isNativeTableStateSheetOpen = false;
  bool _isNativeDayNightSheetOpen = false;

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
      unawaited(_loadBundleAndSyncOwnedShellState());
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
              unawaited(_loadBundleAndSyncOwnedShellState());
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
        if (decoded['type'] == 'open-native-game-modes') {
          unawaited(
            _openNativeGameModesSheet(
              source: (decoded['source'] as String?) ?? 'game_modes_shortcut',
              preferredAction: _decodePreferredGameModeAction(
                decoded['preferredMode'] as String?,
              ),
              preferredIntent: _decodePreferredGameModeIntent(
                decoded['intent'] as String?,
              ),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-dice') {
          unawaited(
            _openNativeDiceSheet(
              source: (decoded['source'] as String?) ?? 'dice_shortcut_pressed',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-quick-actions') {
          unawaited(
            _openNativeQuickActionsSheet(
              source: (decoded['source'] as String?) ?? 'menu_button_pressed',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-commander-damage') {
          unawaited(
            _openNativeCommanderDamageSheet(
              source:
                  (decoded['source'] as String?) ??
                  'commander_damage_surface_pressed',
              targetPlayerIndex:
                  (decoded['targetPlayerIndex'] as num?)?.toInt(),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-player-appearance') {
          unawaited(
            _openNativePlayerAppearanceSheet(
              source:
                  (decoded['source'] as String?) ??
                  'player_background_surface_pressed',
              targetPlayerIndex:
                  (decoded['targetPlayerIndex'] as num?)?.toInt(),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-player-counter') {
          unawaited(
            _openNativePlayerCounterSheet(
              source:
                  (decoded['source'] as String?) ??
                  'player_counter_surface_pressed',
              targetPlayerIndex:
                  (decoded['targetPlayerIndex'] as num?)?.toInt(),
              counterKey: (decoded['counterKey'] as String?)?.trim(),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-player-state') {
          unawaited(
            _openNativePlayerStateSheet(
              source:
                  (decoded['source'] as String?) ??
                  'player_state_surface_pressed',
              targetPlayerIndex:
                  (decoded['targetPlayerIndex'] as num?)?.toInt(),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-set-life') {
          unawaited(
            _openNativeSetLifeSheet(
              source:
                  (decoded['source'] as String?) ??
                  'player_life_total_surface_pressed',
              targetPlayerIndex:
                  (decoded['targetPlayerIndex'] as num?)?.toInt(),
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-table-state') {
          unawaited(
            _openNativeTableStateSheet(
              source: (decoded['source'] as String?) ?? 'table_state_surface',
            ),
          );
          return;
        }
        if (decoded['type'] == 'open-native-day-night') {
          unawaited(
            _openNativeDayNightSheet(
              source: (decoded['source'] as String?) ?? 'day_night_surface',
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

  Future<void> _reloadLotusBundleFromOwnedSnapshot() async {
    _hostController.suppressStaleBeforeUnloadSnapshot();
    await _loadBundleAndSyncOwnedShellState(
      suppressStaleBeforeUnloadSnapshot: false,
    );
  }

  Future<void> _loadBundleAndSyncOwnedShellState({
    bool suppressStaleBeforeUnloadSnapshot = false,
  }) async {
    if (suppressStaleBeforeUnloadSnapshot) {
      _hostController.suppressStaleBeforeUnloadSnapshot();
    }
    await _hostController.loadBundle();
    await _applyOwnedDayNightPreference();
  }

  Future<void> _applyOwnedDayNightPreference() async {
    final state = await _dayNightStateStore.load();
    if (state == null) {
      return;
    }

    final script = '''
(() => {
  try {
    localStorage.setItem('__manaloom_day_night_mode', '${state.mode}');
    const switcher = document.querySelector('.day-night-switcher');
    if (switcher) {
      switcher.classList.toggle('night', ${state.isNight ? 'true' : 'false'});
    }
  } catch (_) {}
})();
''';
    try {
      await _hostController.runJavaScript(script);
    } catch (_) {}
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

  Future<void> _openNativeQuickActionsSheet({required String source}) async {
    if (!mounted || _isNativeQuickActionsSheetOpen) {
      return;
    }

    _isNativeQuickActionsSheetOpen = true;
    unawaited(
      AppObservability.instance.recordEvent(
        'native_quick_actions_opened',
        category: 'life_counter.quick_actions',
        data: {'source': source},
      ),
    );

    final selectedAction = await showLifeCounterNativeQuickActionsSheet(
      context,
    );
    _isNativeQuickActionsSheetOpen = false;

    if (!mounted || selectedAction == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_quick_actions_dismissed',
          category: 'life_counter.quick_actions',
          data: {'source': source, 'selected': false},
        ),
      );
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_quick_actions_selected',
        category: 'life_counter.quick_actions',
        data: {
          'source': source,
          'action': selectedAction.name,
        },
      ),
    );

    switch (selectedAction) {
      case LifeCounterQuickAction.settings:
        await _openNativeSettingsSheet(source: 'quick_actions_settings');
      case LifeCounterQuickAction.history:
        await _openNativeHistorySheet(source: 'quick_actions_history');
      case LifeCounterQuickAction.cardSearch:
        await _openNativeCardSearchSheet(source: 'quick_actions_card_search');
      case LifeCounterQuickAction.turnTracker:
        await _openNativeTurnTrackerSheet(
          source: 'quick_actions_turn_tracker',
        );
      case LifeCounterQuickAction.gameTimer:
        await _openNativeGameTimerSheet(source: 'quick_actions_game_timer');
      case LifeCounterQuickAction.dice:
        await _openNativeDiceSheet(source: 'quick_actions_dice');
      case LifeCounterQuickAction.gameModes:
        await _openNativeGameModesSheet(source: 'quick_actions_game_modes');
      case LifeCounterQuickAction.tableState:
        await _openNativeTableStateSheet(source: 'quick_actions_table_state');
      case LifeCounterQuickAction.dayNight:
        await _openNativeDayNightSheet(source: 'quick_actions_day_night');
    }
  }

  Future<void> _openNativeGameModesSheet({
    required String source,
    LifeCounterGameModesAction? preferredAction,
    LifeCounterGameModesEntryIntent preferredIntent =
        LifeCounterGameModesEntryIntent.openMode,
  }) async {
    if (!mounted || _isNativeGameModesSheetOpen) {
      return;
    }

    _isNativeGameModesSheetOpen = true;
    final availability = await _readNativeGameModesAvailability();
    if (!mounted) {
      _isNativeGameModesSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_game_modes_opened',
        category: 'life_counter.game_modes',
        data: {
          'source': source,
          'preferred_intent': preferredIntent.name,
          'planechase_available': availability.planechaseAvailable,
          'planechase_active': availability.planechaseActive,
          'planechase_card_pool_active': availability.planechaseCardPoolActive,
          'archenemy_available': availability.archenemyAvailable,
          'archenemy_active': availability.archenemyActive,
          'archenemy_card_pool_active': availability.archenemyCardPoolActive,
          'bounty_available': availability.bountyAvailable,
          'bounty_active': availability.bountyActive,
          'bounty_card_pool_active': availability.bountyCardPoolActive,
          'active_mode_count': availability.activeModeCount,
          'max_active_modes': availability.maxActiveModes,
        },
      ),
    );

    final action = await showLifeCounterNativeGameModesSheet(
      context,
      availability: availability,
      preferredAction: preferredAction,
      preferredIntent: preferredIntent,
    );
    _isNativeGameModesSheetOpen = false;

    if (!mounted) {
      return;
    }

    if (action != null) {
      switch (action) {
        case LifeCounterGameModesAction.openPlanechase:
          await _triggerEmbeddedGameMode(
            selector: '.planechase-btn',
            modeName: 'planechase',
            source: source,
            followUpSelector:
                preferredIntent == LifeCounterGameModesEntryIntent.editCards
                    ? '.edit-planechase-cards'
                    : null,
          );
        case LifeCounterGameModesAction.openArchenemy:
          await _triggerEmbeddedGameMode(
            selector: '.archenemy-btn',
            modeName: 'archenemy',
            source: source,
            followUpSelector:
                preferredIntent == LifeCounterGameModesEntryIntent.editCards
                    ? '.edit-archenemy-cards'
                    : null,
          );
        case LifeCounterGameModesAction.openBounty:
          await _triggerEmbeddedGameMode(
            selector: '.bounty-btn',
            modeName: 'bounty',
            source: source,
            followUpSelector:
                preferredIntent == LifeCounterGameModesEntryIntent.editCards
                    ? '.edit-bounty-cards'
                    : null,
          );
        case LifeCounterGameModesAction.editPlanechaseCards:
          await _triggerEmbeddedGameMode(
            selector: '.planechase-btn',
            modeName: 'planechase',
            source: source,
            followUpSelector: '.edit-planechase-cards',
          );
        case LifeCounterGameModesAction.closePlanechaseCardPool:
          await _closeEmbeddedGameModeCardPool(
            selector: '.close-edit-planechase-cards-overlay',
            modeName: 'planechase',
            source: source,
          );
        case LifeCounterGameModesAction.editArchenemyCards:
          await _triggerEmbeddedGameMode(
            selector: '.archenemy-btn',
            modeName: 'archenemy',
            source: source,
            followUpSelector: '.edit-archenemy-cards',
          );
        case LifeCounterGameModesAction.closeArchenemyCardPool:
          await _closeEmbeddedGameModeCardPool(
            selector: '.close-edit-archenemy-cards-overlay',
            modeName: 'archenemy',
            source: source,
          );
        case LifeCounterGameModesAction.editBountyCards:
          await _triggerEmbeddedGameMode(
            selector: '.bounty-btn',
            modeName: 'bounty',
            source: source,
            followUpSelector: '.edit-bounty-cards',
          );
        case LifeCounterGameModesAction.closeBountyCardPool:
          await _closeEmbeddedGameModeCardPool(
            selector: '.close-edit-bounty-cards-overlay',
            modeName: 'bounty',
            source: source,
          );
        case LifeCounterGameModesAction.closePlanechase:
          await _closeEmbeddedGameModeOverlay(
            selector: '.close-planechase-overlay-btn',
            modeName: 'planechase',
            source: source,
          );
        case LifeCounterGameModesAction.closeArchenemy:
          await _closeEmbeddedGameModeOverlay(
            selector: '.close-archenemy-overlay-btn',
            modeName: 'archenemy',
            source: source,
          );
        case LifeCounterGameModesAction.closeBounty:
          await _closeEmbeddedGameModeOverlay(
            selector: '.close-bounty-overlay-btn',
            modeName: 'bounty',
            source: source,
          );
        case LifeCounterGameModesAction.openSettings:
          await _openNativeSettingsSheet(source: 'game_modes_settings');
      }
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_game_modes_dismissed',
        category: 'life_counter.game_modes',
        data: {
          'source': source,
          'preferred_intent': preferredIntent.name,
          'selected_action': action?.name,
        },
      ),
    );
  }

  Future<LifeCounterGameModesAvailability>
  _readNativeGameModesAvailability() async {
    try {
      final rawResult = await _hostController.runJavaScriptReturningResult('''
        (() => JSON.stringify({
          planechaseAvailable: !!document.querySelector('.planechase-btn'),
          planechaseActive: !!document.querySelector('.planechase-overlay'),
          planechaseCardPoolActive: !!document.querySelector('.edit-planechase-cards-overlay'),
          archenemyAvailable: !!document.querySelector('.archenemy-btn'),
          archenemyActive: !!document.querySelector('.archenemy-overlay'),
          archenemyCardPoolActive: !!document.querySelector('.edit-archenemy-cards-overlay'),
          bountyAvailable: !!document.querySelector('.bounty-btn'),
          bountyActive: !!document.querySelector('.bounty-overlay'),
          bountyCardPoolActive: !!document.querySelector('.edit-bounty-cards-overlay'),
          maxActiveModes: 2
        }))()
      ''');
      final decoded = _decodeJavaScriptResult(rawResult);
      if (decoded is Map<String, dynamic>) {
        final planechaseActive = decoded['planechaseActive'] == true;
        final archenemyActive = decoded['archenemyActive'] == true;
        final bountyActive = decoded['bountyActive'] == true;
        final activeModeCount =
            (planechaseActive ? 1 : 0) +
            (archenemyActive ? 1 : 0) +
            (bountyActive ? 1 : 0);
        return LifeCounterGameModesAvailability(
          planechaseAvailable: decoded['planechaseAvailable'] == true,
          planechaseActive: planechaseActive,
          planechaseCardPoolActive:
              decoded['planechaseCardPoolActive'] == true,
          archenemyAvailable: decoded['archenemyAvailable'] == true,
          archenemyActive: archenemyActive,
          archenemyCardPoolActive:
              decoded['archenemyCardPoolActive'] == true,
          bountyAvailable: decoded['bountyAvailable'] == true,
          bountyActive: bountyActive,
          bountyCardPoolActive: decoded['bountyCardPoolActive'] == true,
          activeModeCount: activeModeCount,
          maxActiveModes: (decoded['maxActiveModes'] as num?)?.toInt() ?? 2,
        );
      }
    } catch (_) {}

    return const LifeCounterGameModesAvailability(
      planechaseAvailable: false,
      archenemyAvailable: false,
      bountyAvailable: false,
    );
  }

  Future<void> _triggerEmbeddedGameMode({
    required String selector,
    required String modeName,
    required String source,
    String? followUpSelector,
  }) async {
    await _hostController.runJavaScript('''
      (() => {
        const button = document.querySelector('$selector');
        if (button instanceof HTMLElement) {
          button.click();
        }
        ${followUpSelector == null ? '' : '''
        window.setTimeout(() => {
          const followUpButton = document.querySelector('$followUpSelector');
          if (followUpButton instanceof HTMLElement) {
            followUpButton.click();
          }
        }, 120);
        '''}
      })();
    ''');

    unawaited(
      AppObservability.instance.recordEvent(
        'embedded_game_mode_requested',
        category: 'life_counter.game_modes',
        data: {
          'source': source,
          'mode': modeName,
          'follow_up_selector': followUpSelector,
        },
      ),
    );
  }

  Future<void> _closeEmbeddedGameModeOverlay({
    required String selector,
    required String modeName,
    required String source,
  }) async {
    await _hostController.runJavaScript('''
      (() => {
        const button = document.querySelector('$selector');
        if (button instanceof HTMLElement) {
          button.click();
        }
      })();
    ''');

    unawaited(
      AppObservability.instance.recordEvent(
        'embedded_game_mode_overlay_closed',
        category: 'life_counter.game_modes',
        data: {
          'source': source,
          'mode': modeName,
          'selector': selector,
        },
      ),
    );
  }

  Future<void> _closeEmbeddedGameModeCardPool({
    required String selector,
    required String modeName,
    required String source,
  }) async {
    await _hostController.runJavaScript('''
      (() => {
        const button = document.querySelector('$selector');
        if (button instanceof HTMLElement) {
          button.click();
        }
      })();
    ''');

    unawaited(
      AppObservability.instance.recordEvent(
        'embedded_game_mode_card_pool_closed',
        category: 'life_counter.game_modes',
        data: {
          'source': source,
          'mode': modeName,
          'selector': selector,
        },
      ),
    );
  }

  LifeCounterGameModesAction? _decodePreferredGameModeAction(String? rawMode) {
    switch (rawMode) {
      case 'planechase':
        return LifeCounterGameModesAction.openPlanechase;
      case 'archenemy':
        return LifeCounterGameModesAction.openArchenemy;
      case 'bounty':
        return LifeCounterGameModesAction.openBounty;
      default:
        return null;
    }
  }

  LifeCounterGameModesEntryIntent _decodePreferredGameModeIntent(
    String? rawIntent,
  ) {
    switch (rawIntent) {
      case 'edit-cards':
        return LifeCounterGameModesEntryIntent.editCards;
      default:
        return LifeCounterGameModesEntryIntent.openMode;
    }
  }

  Object? _decodeJavaScriptResult(Object? rawResult) {
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

  Future<void> _openNativeDayNightSheet({required String source}) async {
    if (!mounted || _isNativeDayNightSheetOpen) {
      return;
    }

    _isNativeDayNightSheetOpen = true;
    final initialState =
        await _dayNightStateStore.load() ??
        const LifeCounterDayNightState(isNight: false);
    if (!mounted) {
      _isNativeDayNightSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_day_night_opened',
        category: 'life_counter.day_night',
        data: {'source': source, 'is_night': initialState.isNight},
      ),
    );

    final updatedState = await showLifeCounterNativeDayNightSheet(
      context,
      initialState: initialState,
    );
    _isNativeDayNightSheetOpen = false;

    if (!mounted || updatedState == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_day_night_dismissed',
          category: 'life_counter.day_night',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedState.isNight == initialState.isNight) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_day_night_dismissed',
          category: 'life_counter.day_night',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeDayNightState(updatedState, source: source);
  }

  Future<void> _applyNativeDayNightState(
    LifeCounterDayNightState state, {
    required String source,
  }) async {
    await _dayNightStateStore.save(state);

    final snapshot = await _snapshotStore.load();
    final mergedValues = <String, String>{
      ...?snapshot?.values,
      '__manaloom_day_night_mode': state.mode,
    };
    await _snapshotStore.save(
      LotusStorageSnapshot(values: Map<String, String>.unmodifiable(mergedValues)),
    );

    await _applyOwnedDayNightPreference();

    unawaited(
      AppObservability.instance.recordEvent(
        'native_day_night_applied',
        category: 'life_counter.day_night',
        data: {'source': source, 'is_night': state.isNight},
      ),
    );
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

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
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

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
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

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativeDiceSheet({required String source}) async {
    if (!mounted || _isNativeDiceSheetOpen) {
      return;
    }

    _isNativeDiceSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativeDiceSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_dice_opened',
        category: 'life_counter.dice',
        data: {
          'source': source,
          'player_count': session.playerCount,
          'has_pending_high_roll_tie':
              session.lastHighRolls.whereType<int>().isNotEmpty &&
              session.lastHighRolls.whereType<int>().toSet().length <
                  session.lastHighRolls.whereType<int>().length,
        },
      ),
    );

    final updatedSession = await showLifeCounterNativeDiceSheet(
      context,
      initialSession: session,
    );
    _isNativeDiceSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_dice_dismissed',
          category: 'life_counter.dice',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_dice_dismissed',
          category: 'life_counter.dice',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeDiceSession(updatedSession, source: source);
  }

  Future<void> _applyNativeDiceSession(
    LifeCounterSession session, {
      required String source,
    }) async {
      final adjustedSession = await _normalizeOwnedPlayerRuntimeSession(session);
      await _persistOwnedSessionSnapshot(adjustedSession);

      unawaited(
        AppObservability.instance.recordEvent(
          'native_dice_applied',
          category: 'life_counter.dice',
          data: {
            'source': source,
            'first_player_index': adjustedSession.firstPlayerIndex,
            'has_last_event': adjustedSession.lastTableEvent != null,
            'has_high_rolls':
                adjustedSession.lastHighRolls.whereType<int>().isNotEmpty,
          },
        ),
      );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativeCommanderDamageSheet({
    required String source,
    required int? targetPlayerIndex,
  }) async {
    if (!mounted || _isNativeCommanderDamageSheetOpen) {
      return;
    }

    _isNativeCommanderDamageSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativeCommanderDamageSheetOpen = false;
      return;
    }

    final normalizedTargetIndex =
        targetPlayerIndex == null ||
                targetPlayerIndex < 0 ||
                targetPlayerIndex >= session.playerCount
            ? 0
            : targetPlayerIndex;

    unawaited(
      AppObservability.instance.recordEvent(
        'native_commander_damage_opened',
        category: 'life_counter.commander_damage',
        data: {
          'source': source,
          'target_player_index': normalizedTargetIndex,
          'player_count': session.playerCount,
        },
      ),
    );

    final updatedSession = await showLifeCounterNativeCommanderDamageSheet(
      context,
      initialSession: session,
      initialTargetPlayerIndex: normalizedTargetIndex,
    );
    _isNativeCommanderDamageSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_commander_damage_dismissed',
          category: 'life_counter.commander_damage',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_commander_damage_dismissed',
          category: 'life_counter.commander_damage',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeCommanderDamage(updatedSession, source: source);
  }

  Future<LifeCounterSettings> _loadOwnedLifeCounterSettings() async {
    return await _settingsStore.load() ?? LifeCounterSettings.defaults;
  }

  Future<LifeCounterSession> _normalizeOwnedPlayerRuntimeSession(
    LifeCounterSession session,
  ) async {
    final settings = await _loadOwnedLifeCounterSettings();
    return LifeCounterTabletopEngine.normalizeOwnedBoardSession(
      session,
      settings: settings,
    );
  }

  Future<void> _persistOwnedSessionSnapshot(
    LifeCounterSession session, {
    bool playerRuntimeOnly = true,
  }) async {
    await _sessionStore.save(session);

    final settings = await _loadOwnedLifeCounterSettings();
    final snapshot = await _snapshotStore.load();
    if (snapshot != null && playerRuntimeOnly) {
      final mergedValues = <String, String>{
        ...snapshot.values,
        ...LotusLifeCounterSessionAdapter.buildPlayerRuntimeSnapshotValues(
          session,
        ),
      };
      await _snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(mergedValues),
        ),
      );
      return;
    }

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

  Future<void> _applyNativeCommanderDamage(
    LifeCounterSession session, {
      required String source,
    }) async {
    final adjustedSession = await _normalizeOwnedPlayerRuntimeSession(session);
    await _persistOwnedSessionSnapshot(adjustedSession);

    unawaited(
        AppObservability.instance.recordEvent(
          'native_commander_damage_applied',
          category: 'life_counter.commander_damage',
          data: {
            'source': source,
            'player_count': adjustedSession.playerCount,
          },
        ),
      );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativePlayerAppearanceSheet({
    required String source,
    required int? targetPlayerIndex,
  }) async {
    if (!mounted || _isNativePlayerAppearanceSheetOpen) {
      return;
    }

    _isNativePlayerAppearanceSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativePlayerAppearanceSheetOpen = false;
      return;
    }
    final profiles = await _appearanceProfileStore.load();
    if (!mounted) {
      _isNativePlayerAppearanceSheetOpen = false;
      return;
    }

    final normalizedTargetIndex =
        targetPlayerIndex == null ||
                targetPlayerIndex < 0 ||
                targetPlayerIndex >= session.playerCount
            ? 0
            : targetPlayerIndex;
    final shouldResetLotusSurface =
        _playerAppearanceSurfaceResetSources.contains(source);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_opened',
        category: 'life_counter.player_appearance',
        data: {'source': source, 'target_player_index': normalizedTargetIndex},
      ),
    );

    final updatedSession = await showLifeCounterNativePlayerAppearanceSheet(
      context,
      initialSession: session,
      initialTargetPlayerIndex: normalizedTargetIndex,
      initialProfiles: profiles,
      onExportPressed: _exportNativePlayerAppearance,
      onImportSubmitted: _importNativePlayerAppearance,
      onSaveProfilePressed: _saveNativePlayerAppearanceProfile,
      onDeleteProfilePressed: _deleteNativePlayerAppearanceProfile,
    );
    _isNativePlayerAppearanceSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_appearance_dismissed',
          category: 'life_counter.player_appearance',
          data: {'source': source, 'changed': false},
        ),
      );
      if (shouldResetLotusSurface) {
        unawaited(_hostController.loadBundle());
      }
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_appearance_dismissed',
          category: 'life_counter.player_appearance',
          data: {'source': source, 'changed': false},
        ),
      );
      if (shouldResetLotusSurface) {
        unawaited(_hostController.loadBundle());
      }
      return;
    }

    await _applyNativePlayerAppearance(updatedSession, source: source);
  }

  Future<void> _applyNativePlayerAppearance(
    LifeCounterSession session, {
    required String source,
  }) async {
    await _persistOwnedSessionSnapshot(session);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_applied',
        category: 'life_counter.player_appearance',
        data: {'source': source},
      ),
    );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _exportNativePlayerAppearance(
    LifeCounterSession session,
    int targetPlayerIndex,
  ) async {
    final appearance = session.resolvedPlayerAppearances[targetPlayerIndex];
    final transfer = LifeCounterPlayerAppearanceTransfer.fromAppearance(
      appearance,
    );
    await Clipboard.setData(ClipboardData(text: transfer.toJsonString()));
    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_exported',
        category: 'life_counter.player_appearance',
        data: {
          'target_player_index': targetPlayerIndex,
          'has_nickname': appearance.nickname.isNotEmpty,
          'has_background_image': appearance.backgroundImage != null,
          'has_partner_background_image':
              appearance.backgroundImagePartner != null,
        },
      ),
    );
  }

  Future<LifeCounterSession?> _importNativePlayerAppearance(
    String rawPayload,
    LifeCounterSession session,
    int targetPlayerIndex,
  ) async {
    final transfer = LifeCounterPlayerAppearanceTransfer.tryParse(rawPayload);
    if (transfer == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_appearance_import_failed',
          category: 'life_counter.player_appearance',
          data: {
            'target_player_index': targetPlayerIndex,
            'reason': 'invalid_payload',
          },
        ),
      );
      return null;
    }

    final playerAppearances = List<LifeCounterPlayerAppearance>.from(
      session.resolvedPlayerAppearances,
    );
    playerAppearances[targetPlayerIndex] = transfer.appearance;
    final updatedSession = session.copyWith(playerAppearances: playerAppearances);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_imported',
        category: 'life_counter.player_appearance',
        data: {
          'target_player_index': targetPlayerIndex,
          'has_nickname': transfer.appearance.nickname.isNotEmpty,
          'has_background_image': transfer.appearance.backgroundImage != null,
          'has_partner_background_image':
              transfer.appearance.backgroundImagePartner != null,
        },
      ),
    );
    return updatedSession;
  }

  Future<List<LifeCounterPlayerAppearanceProfile>>
  _saveNativePlayerAppearanceProfile(
    String name,
    LifeCounterPlayerAppearance appearance,
  ) async {
    final profiles = await _appearanceProfileStore.saveProfile(
      name: name,
      appearance: appearance,
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_profile_saved',
        category: 'life_counter.player_appearance',
        data: {
          'profile_name': name.trim(),
          'has_nickname': appearance.nickname.isNotEmpty,
          'has_background_image': appearance.backgroundImage != null,
          'has_partner_background_image':
              appearance.backgroundImagePartner != null,
        },
      ),
    );
    return profiles;
  }

  Future<List<LifeCounterPlayerAppearanceProfile>>
  _deleteNativePlayerAppearanceProfile(String profileId) async {
    final profiles = await _appearanceProfileStore.deleteProfile(profileId);
    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_appearance_profile_deleted',
        category: 'life_counter.player_appearance',
        data: {'profile_id': profileId},
      ),
    );
    return profiles;
  }

  Future<void> _openNativePlayerCounterSheet({
    required String source,
    required int? targetPlayerIndex,
    required String? counterKey,
  }) async {
    if (!mounted || _isNativePlayerCounterSheetOpen) {
      return;
    }
    if (counterKey == null || counterKey.isEmpty) {
      return;
    }

    _isNativePlayerCounterSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativePlayerCounterSheetOpen = false;
      return;
    }

    final normalizedTargetIndex =
        targetPlayerIndex == null ||
                targetPlayerIndex < 0 ||
                targetPlayerIndex >= session.playerCount
            ? 0
            : targetPlayerIndex;

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_counter_opened',
        category: 'life_counter.player_counter',
        data: {
          'source': source,
          'target_player_index': normalizedTargetIndex,
          'counter_key': counterKey,
        },
      ),
    );

    final updatedSession = await showLifeCounterNativePlayerCounterSheet(
      context,
      initialSession: session,
      initialTargetPlayerIndex: normalizedTargetIndex,
      counterKey: counterKey,
    );
    _isNativePlayerCounterSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_counter_dismissed',
          category: 'life_counter.player_counter',
          data: {'source': source, 'counter_key': counterKey, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_counter_dismissed',
          category: 'life_counter.player_counter',
          data: {'source': source, 'counter_key': counterKey, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativePlayerCounter(
      updatedSession,
      source: source,
      counterKey: counterKey,
    );
  }

  Future<void> _applyNativePlayerCounter(
    LifeCounterSession session, {
      required String source,
      required String counterKey,
    }) async {
    final adjustedSession = await _normalizeOwnedPlayerRuntimeSession(session);
    await _persistOwnedSessionSnapshot(adjustedSession);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_counter_applied',
        category: 'life_counter.player_counter',
        data: {'source': source, 'counter_key': counterKey},
      ),
    );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativePlayerStateSheet({
    required String source,
    required int? targetPlayerIndex,
  }) async {
    if (!mounted || _isNativePlayerStateSheetOpen) {
      return;
    }

    _isNativePlayerStateSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativePlayerStateSheetOpen = false;
      return;
    }

    final normalizedTargetIndex =
        targetPlayerIndex == null ||
                targetPlayerIndex < 0 ||
                targetPlayerIndex >= session.playerCount
            ? 0
            : targetPlayerIndex;

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_state_opened',
        category: 'life_counter.player_state',
        data: {'source': source, 'target_player_index': normalizedTargetIndex},
      ),
    );

    final updatedSession = await showLifeCounterNativePlayerStateSheet(
      context,
      initialSession: session,
      initialTargetPlayerIndex: normalizedTargetIndex,
    );
    _isNativePlayerStateSheetOpen = false;
    final shouldResetLotusSurface = _playerStateSurfaceResetSources.contains(
      source,
    );

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_state_dismissed',
          category: 'life_counter.player_state',
          data: {'source': source, 'changed': false},
        ),
      );
      if (shouldResetLotusSurface) {
        unawaited(_hostController.loadBundle());
      }
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_player_state_dismissed',
          category: 'life_counter.player_state',
          data: {'source': source, 'changed': false},
        ),
      );
      if (shouldResetLotusSurface) {
        unawaited(_hostController.loadBundle());
      }
      return;
    }

    await _applyNativePlayerState(updatedSession, source: source);
  }

  Future<void> _applyNativePlayerState(
    LifeCounterSession session, {
      required String source,
    }) async {
    final adjustedSession = await _normalizeOwnedPlayerRuntimeSession(session);
    await _persistOwnedSessionSnapshot(adjustedSession);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_player_state_applied',
        category: 'life_counter.player_state',
        data: {'source': source},
      ),
    );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativeSetLifeSheet({
    required String source,
    required int? targetPlayerIndex,
  }) async {
    if (!mounted || _isNativeSetLifeSheetOpen) {
      return;
    }

    _isNativeSetLifeSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativeSetLifeSheetOpen = false;
      return;
    }

    final normalizedTargetIndex =
        targetPlayerIndex == null ||
                targetPlayerIndex < 0 ||
                targetPlayerIndex >= session.playerCount
            ? 0
            : targetPlayerIndex;

    unawaited(
      AppObservability.instance.recordEvent(
        'native_set_life_opened',
        category: 'life_counter.set_life',
        data: {
          'source': source,
          'target_player_index': normalizedTargetIndex,
          'current_life': session.lives[normalizedTargetIndex],
        },
      ),
    );

    final updatedSession = await showLifeCounterNativeSetLifeSheet(
      context,
      initialSession: session,
      initialTargetPlayerIndex: normalizedTargetIndex,
    );
    _isNativeSetLifeSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_set_life_dismissed',
          category: 'life_counter.set_life',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_set_life_dismissed',
          category: 'life_counter.set_life',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeSetLife(
      updatedSession,
      source: source,
      targetPlayerIndex: normalizedTargetIndex,
    );
  }

  Future<void> _applyNativeSetLife(
    LifeCounterSession session, {
      required String source,
      required int targetPlayerIndex,
    }) async {
    final adjustedSession = await _normalizeOwnedPlayerRuntimeSession(session);
    await _persistOwnedSessionSnapshot(adjustedSession);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_set_life_applied',
        category: 'life_counter.set_life',
          data: {
            'source': source,
            'target_player_index': targetPlayerIndex,
            'life': adjustedSession.lives[targetPlayerIndex],
          },
        ),
      );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
  }

  Future<void> _openNativeTableStateSheet({required String source}) async {
    if (!mounted || _isNativeTableStateSheetOpen) {
      return;
    }

    _isNativeTableStateSheetOpen = true;
    final session =
        await _sessionStore.load() ??
        LifeCounterSession.initial(playerCount: 4);
    if (!mounted) {
      _isNativeTableStateSheetOpen = false;
      return;
    }

    unawaited(
      AppObservability.instance.recordEvent(
        'native_table_state_opened',
        category: 'life_counter.table_state',
        data: {
          'source': source,
          'storm_count': session.stormCount,
          'monarch_player': session.monarchPlayer,
          'initiative_player': session.initiativePlayer,
        },
      ),
    );

    final updatedSession = await showLifeCounterNativeTableStateSheet(
      context,
      initialSession: session,
    );
    _isNativeTableStateSheetOpen = false;

    if (!mounted || updatedSession == null) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_table_state_dismissed',
          category: 'life_counter.table_state',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    if (updatedSession.toJsonString() == session.toJsonString()) {
      unawaited(
        AppObservability.instance.recordEvent(
          'native_table_state_dismissed',
          category: 'life_counter.table_state',
          data: {'source': source, 'changed': false},
        ),
      );
      return;
    }

    await _applyNativeTableState(updatedSession, source: source);
  }

  Future<void> _applyNativeTableState(
    LifeCounterSession session, {
    required String source,
  }) async {
    await _persistOwnedSessionSnapshot(session);

    unawaited(
      AppObservability.instance.recordEvent(
        'native_table_state_applied',
        category: 'life_counter.table_state',
        data: {
          'source': source,
          'storm_count': session.stormCount,
          'monarch_player': session.monarchPlayer,
          'initiative_player': session.initiativePlayer,
        },
      ),
    );

    unawaited(_reloadLotusBundleFromOwnedSnapshot());
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
