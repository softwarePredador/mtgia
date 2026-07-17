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
      expect(script, contains('open-native-commander-damage'));
      expect(script, contains('open-native-set-life'));
      expect(script, contains('player_option_card_presented'));
      expect(script, contains('commander_damage_info_card_presented'));
      expect(script, contains('targetPlayerIndex'));
      expect(script, contains('counterKey'));
    });

    test('owns table shortcuts without invoking Lotus overlays', () {
      final script = lotusInjectedNativeSurfaceBridgeScript;

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
  });
}
