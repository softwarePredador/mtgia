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
      expect(
        lotusShellCleanupScript,
        contains('.menu-button, .dice-btn, .life-history-btn'),
      );
    });
  });
}
