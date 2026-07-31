import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_native_surface_bridge.dart';
import 'package:manaloom/features/home/lotus/lotus_webview_contract.dart';

void main() {
  group('Lotus native surface bridge', () {
    test('routes player surfaces through the ManaLoom shell channel', () {
      final script = lotusInjectedNativeSurfaceBridgeScript;

      expect(script, contains(LotusJavaScriptBridges.shellChannelName));
      expect(script, contains(LotusDomSelectors.optionCard));
      expect(script, contains(LotusDomSelectors.infoCard));
      expect(script, contains(LotusDomSelectors.regularCounters));
      expect(script, contains(LotusDomSelectors.commanderDamageCounters));
      expect(script, contains(LotusDomSelectors.lifeTotal));
      expect(script, contains('open-native-player-state'));
      expect(script, contains('open-native-player-counter'));
      expect(script, contains('open-lotus-commander-damage'));
      expect(script, contains('open-native-set-life'));
      expect(script, contains('player_option_card_presented'));
      expect(script, isNot(contains('commander_damage_info_card_presented')));
      expect(script, isNot(contains('open-native-commander-damage')));
      expect(script, contains('targetPlayerIndex'));
      expect(script, contains('counterKey'));
    });

    test('owns table shortcuts without invoking Lotus overlays', () {
      final script = lotusInjectedNativeSurfaceBridgeScript;

      expect(script, contains(LotusDomSelectors.menuUtilityBar));
      expect(script, contains(LotusDomSelectors.playerToolsShortcut));
      expect(script, contains(LotusDomSelectors.commanderDamageShortcut));
      expect(script, contains(LotusDomSelectors.settingsShortcut));
      expect(script, contains(LotusDomSelectors.highRollShortcut));
      expect(script, contains(LotusDomSelectors.diceShortcut));
      expect(script, contains(LotusDomSelectors.historyShortcut));
      expect(script, contains(LotusDomSelectors.cardSearchShortcut));
      expect(script, contains(LotusDomSelectors.monarchShortcut));
      expect(script, contains(LotusDomSelectors.initiativeShortcut));
      expect(script, contains(LotusDomSelectors.dayNightShortcut));
      expect(script, contains(LotusDomSelectors.planechaseShortcut));
      expect(script, contains(LotusDomSelectors.archenemyShortcut));
      expect(script, contains(LotusDomSelectors.bountyShortcut));
      expect(script, contains('open-native-settings'));
      expect(script, contains('open-native-dice'));
      expect(script, contains('open-native-history'));
      expect(script, contains('open-native-card-search'));
      expect(script, contains('open-native-table-state'));
      expect(script, contains('open-native-day-night'));
      expect(script, contains('open-native-game-modes'));
      expect(script, contains('table_player_tools_shortcut_pressed'));
      expect(script, contains('table_commander_damage_shortcut_pressed'));
      expect(script, contains("label: 'Marcadores'"));
      expect(script, contains("label: 'Dano comandante'"));
      expect(
        script,
        contains('payload.targetPlayerIndex = shortcut.targetPlayerIndex'),
      );
      expect(
        script,
        contains('payload.preferredMode = shortcut.preferredMode'),
      );
      expect(script, contains('stopImmediatePropagation'));
    });

    test('hides takeover surfaces and exposes a diagnostic snapshot', () {
      final script = lotusInjectedNativeSurfaceBridgeScript;

      expect(script, contains(LotusNativeSurfaceBridgeStyleIds.takeover));
      expect(script, contains('data-manaloom-native-takeover'));
      expect(script, contains('visibility: hidden !important'));
      expect(script, contains('dispatchSurfaceReset'));
      expect(script, contains('window.__ManaLoomNativeSurfaceBridge'));
      expect(script, contains('snapshot: () =>'));
      expect(script, contains('MutationObserver'));
    });

    test('supports deliberate mouse and touch drags on a player card', () {
      final script = lotusInjectedNativeSurfaceBridgeScript;

      expect(script, contains("document.addEventListener('pointerdown'"));
      expect(script, contains("document.addEventListener('pointermove'"));
      expect(script, contains("document.addEventListener('pointerup'"));
      expect(script, contains("document.addEventListener('mousedown'"));
      expect(script, contains("document.addEventListener('mousemove'"));
      expect(script, contains("document.addEventListener('mouseup'"));
      expect(script, contains('playerDragThreshold = 42'));
      expect(script, contains('playerDragDistance'));
      expect(script, contains('drag.claimed = true'));
      expect(script, contains('cancelLegacyPlayerGesture'));
      expect(script, contains("new PointerEvent('pointercancel'"));
      expect(script, contains("new MouseEvent('mouseup'"));
      expect(script, contains('activeMouseDrag.handledByPointer = true'));
      expect(script, contains('drag?.handledByPointer'));
      expect(script, contains('schedulePlayerSwipeReset(drag.playerCard)'));
      expect(script, contains('resetPlayerSwipe(card), 120'));
      expect(script, contains('internalSurfaceReset'));
      expect(script, contains('ensurePlayerSwipeGuard'));
      expect(
        script,
        contains("this?.element?.matches?.(SELECTORS.playerCard)"),
      );
      expect(script, contains("'swipedown'"));
      expect(script, contains('updatePlayerDragFeedback'));
      expect(script, contains('resetPlayerDragFeedback'));
      expect(script, contains('data-manaloom-player-drag'));
      expect(script, contains('--manaloom-player-drag-x'));
      expect(script, contains('openLegacyCommanderDamage'));
      expect(script, contains('openLegacyCommanderDamageForPlayer'));
      expect(script, contains('card.__manaloomTriggerSwipe'));
      expect(script, contains("legacyDirection = direction < 0 ? 'left'"));
      expect(
        script,
        contains('triggerLegacySwipe.call(card, legacyDirection)'),
      );
      expect(script, contains('openCommanderDamage: (targetPlayerIndex = 0)'));
      expect(script, contains("'player_vertical_drag'"));
      expect(script, contains("event.pointerType === 'mouse'"));
      expect(script, contains('Math.hypot('));
      expect(script, contains('targetPlayerIndex: drag.targetPlayerIndex'));
      expect(script, contains('suppressedPlayerClick'));
      expect(script, contains('Date.now() + 750'));
      expect(script, contains('activeMouseDrag'));
      expect(script, contains('mouseDragFallback: true'));
      expect(script, contains('if (completePlayerDrag(event, drag))'));
      expect(script, contains('consumeEvent(event)'));
      expect(script, isNot(contains('.increase-button, .decrease-button')));
      expect(
        script,
        isNot(contains('input, select, textarea, [role="button"]')),
      );
      expect(
        script,
        isNot(contains("'[' + ACTION_ATTR + '], .menu-button-overlay")),
      );
    });

    test(
      'bundled Lotus runtime exposes its original commander swipe',
      () async {
        final runtime = await File('assets/lotus/js/app.min.js').readAsString();

        expect(runtime, contains('f.__manaloomTriggerSwipe=e=>{F(e)}'));
        expect(runtime, contains('<b>Dano de comandante</b>recebido'));
        expect(runtime, contains('Voltar ao jogo'));
      },
    );
  });
}
