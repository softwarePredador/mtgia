import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_shell_policy.dart';

void main() {
  group('lotus shell policy', () {
    test('suppresses legacy tutorial overlays', () {
      expect(
        lotusSuppressedShellSelectors,
        containsAll(<String>[
          '.turn-tracker-hint-overlay',
          '.show-counters-hint-overlay',
        ]),
      );
    });

    test('marks legacy tutorial hints as completed', () {
      expect(
        lotusShellCleanupScript,
        contains("localStorage.setItem(TURN_TRACKER_HINT_KEY, 'true');"),
      );
      expect(
        lotusShellCleanupScript,
        contains("localStorage.setItem(COUNTERS_HINT_KEY, 'true');"),
      );
    });

    test('tracks dice button as a native shell surface', () {
      expect(lotusShellCleanupScript, contains('.menu-button'));
      expect(lotusShellCleanupScript, contains('.dice-btn'));
      expect(lotusShellCleanupScript, contains('.life-history-btn'));
    });

    test('tracks embedded game mode buttons through the owned shell', () {
      expect(lotusShellCleanupScript, contains('.planechase-btn'));
      expect(lotusShellCleanupScript, contains('.archenemy-btn'));
      expect(lotusShellCleanupScript, contains('.bounty-btn'));
      expect(lotusShellCleanupScript, contains('.edit-planechase-cards'));
      expect(lotusShellCleanupScript, contains('.edit-archenemy-cards'));
      expect(lotusShellCleanupScript, contains('.edit-bounty-cards'));
      expect(lotusShellCleanupScript, contains("type: 'open-native-game-modes'"));
      expect(lotusShellCleanupScript, contains("preferredMode: trackedClick.matches('.planechase-btn')"));
      expect(lotusShellCleanupScript, contains("intent: 'edit-cards'"));
    });

    test('routes active game mode overlay settings back through the owned shell', () {
      expect(
        lotusShellCleanupScript,
        contains(
          "trackedClick.closest(\n            '.planechase-overlay, .archenemy-overlay, .bounty-overlay'",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains('planechase_overlay_settings_pressed'),
      );
      expect(
        lotusShellCleanupScript,
        contains('archenemy_overlay_settings_pressed'),
      );
      expect(
        lotusShellCleanupScript,
        contains('bounty_overlay_settings_pressed'),
      );
      expect(
        lotusShellCleanupScript,
        contains("observeUiSurface('.planechase-overlay', 'planechase_overlay_opened');"),
      );
      expect(
        lotusShellCleanupScript,
        contains("observeUiSurface('.archenemy-overlay', 'archenemy_overlay_opened');"),
      );
      expect(
        lotusShellCleanupScript,
        contains("observeUiSurface('.bounty-overlay', 'bounty_overlay_opened');"),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(\n      '.edit-planechase-cards-overlay',\n      'planechase_card_pool_overlay_opened'",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(\n      '.edit-archenemy-cards-overlay',\n      'archenemy_card_pool_overlay_opened'",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains(
          "observeUiSurface(\n      '.edit-bounty-cards-overlay',\n      'bounty_card_pool_overlay_opened'",
        ),
      );
      expect(
        lotusShellCleanupScript,
        contains("observeUiSurface('.game-mode-info-overlay', 'game_mode_info_overlay_opened');"),
      );
      expect(
        lotusShellCleanupScript,
        contains("observeUiSurface('.max-game-modes-warning', 'max_game_modes_warning_opened');"),
      );
    });
  });
}
