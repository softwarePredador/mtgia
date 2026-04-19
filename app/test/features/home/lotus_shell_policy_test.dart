import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_shell_policy.dart';

void main() {
  group('lotus shell policy', () {
    test('suppresses legacy tutorial overlays', () {
      expect(
        lotusSuppressedShellSelectors,
        containsAll(<String>[
          '.first-time-user-overlay',
          '.own-commander-damage-hint-overlay',
          '.turn-tracker-hint-overlay',
          '.show-counters-hint-overlay',
        ]),
      );
    });

    test('marks legacy tutorial hints as completed', () {
      expect(
        lotusShellCleanupScript,
        contains("ensureLocalFlag(TUTORIAL_OVERLAY_KEY);"),
      );
      expect(
        lotusShellCleanupScript,
        contains("ensureLocalFlag(OWN_COMMANDER_DAMAGE_HINT_KEY);"),
      );
      expect(
        lotusShellCleanupScript,
        contains("ensureLocalFlag(TURN_TRACKER_HINT_KEY);"),
      );
      expect(
        lotusShellCleanupScript,
        contains("ensureLocalFlag(COUNTERS_HINT_KEY);"),
      );
    });

    test(
      'keeps dice, tracker, timer, table state and day night on Lotus visuals',
      () {
        expect(lotusShellCleanupScript, isNot(contains('.dice-btn')));
        expect(lotusShellCleanupScript, isNot(contains('.turn-time-tracker')));
        expect(
          lotusShellCleanupScript,
          isNot(contains('.game-timer:not(.current-time-clock)')),
        );
        expect(lotusShellCleanupScript, isNot(contains('.current-time-clock')));
        expect(lotusShellCleanupScript, isNot(contains('.monarch-btn')));
        expect(lotusShellCleanupScript, isNot(contains('.initiative-btn')));
        expect(lotusShellCleanupScript, isNot(contains('.life-history-btn')));
        expect(lotusShellCleanupScript, isNot(contains('.card-search-btn')));
        expect(lotusShellCleanupScript, isNot(contains('.settings,')));
        expect(
          lotusShellCleanupScript,
          contains("queryWithin(root, '.day-night-switcher')[0] ??"),
        );
      },
    );

    test('does not hijack the Lotus menu button into native quick actions', () {
      expect(lotusShellCleanupScript, isNot(contains('.menu-button,')));
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-quick-actions'")),
      );
    });

    test('does not hijack the Lotus settings button into native settings', () {
      expect(lotusShellCleanupScript, isNot(contains('.settings,')));
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-settings'")),
      );
    });

    test('does not hijack history or card search menu actions', () {
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-history'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-card-search'")),
      );
    });

    test(
      'does not hijack tracker, timer, table state or day night actions',
      () {
        expect(
          lotusShellCleanupScript,
          isNot(contains("type: 'open-native-dice'")),
        );
        expect(
          lotusShellCleanupScript,
          isNot(contains("type: 'open-native-turn-tracker'")),
        );
        expect(
          lotusShellCleanupScript,
          isNot(contains("type: 'open-native-game-timer'")),
        );
        expect(
          lotusShellCleanupScript,
          isNot(contains("type: 'open-native-table-state'")),
        );
        expect(
          lotusShellCleanupScript,
          isNot(contains("type: 'open-native-day-night'")),
        );
      },
    );

    test('does not hijack player surfaces away from Lotus visuals', () {
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-commander-damage'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-player-counter'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-player-state'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-player-appearance'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-set-life'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('.commander-damage-counter')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('.counters-on-card .counter')),
      );
      expect(lotusShellCleanupScript, isNot(contains('.player-life-count')));
      expect(
        lotusShellCleanupScript,
        isNot(contains('.player-card-inner.option-card')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('.player-card-inner .killed-overlay')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('.option-entry.background')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('.background.option-entry')),
      );
    });

    test('does not hijack game mode buttons away from Lotus visuals', () {
      expect(lotusShellCleanupScript, isNot(contains('.planechase-btn')));
      expect(lotusShellCleanupScript, isNot(contains('.archenemy-btn')));
      expect(lotusShellCleanupScript, isNot(contains('.bounty-btn')));
      expect(
        lotusShellCleanupScript,
        isNot(contains("type: 'open-native-game-modes'")),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('planechase_mode_pressed')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('archenemy_mode_pressed')),
      );
      expect(lotusShellCleanupScript, isNot(contains('bounty_mode_pressed')));
      expect(
        lotusShellCleanupScript,
        isNot(contains('planechase_cards_pressed')),
      );
      expect(
        lotusShellCleanupScript,
        isNot(contains('archenemy_cards_pressed')),
      );
      expect(lotusShellCleanupScript, isNot(contains('bounty_cards_pressed')));
    });

    test('still observes Lotus game mode overlays for telemetry', () {
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(root, '.card-search-overlay', 'card_search_overlay_opened');",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(root, '.planechase-overlay', 'planechase_overlay_opened');",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(root, '.archenemy-overlay', 'archenemy_overlay_opened');",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(root, '.bounty-overlay', 'bounty_overlay_opened');",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains("'.edit-planechase-cards-overlay'"),
      );
      expect(
        lotusShellCleanupScript,
        contains("'planechase_card_pool_overlay_opened'"),
      );
      expect(
        lotusShellCleanupScript,
        contains("'.edit-archenemy-cards-overlay'"),
      );
      expect(
        lotusShellCleanupScript,
        contains("'archenemy_card_pool_overlay_opened'"),
      );
      expect(lotusShellCleanupScript, contains("'.edit-bounty-cards-overlay'"));
      expect(
        lotusShellCleanupScript,
        contains("'bounty_card_pool_overlay_opened'"),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(\n      root,\n      '.game-mode-info-overlay',\n      'game_mode_info_overlay_opened'",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(\n      root,\n      '.max-game-modes-warning',\n      'max_game_modes_warning_opened'",
        ),
      );
    });
  });
}
