import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_visual_skin.dart';
import 'package:manaloom/features/home/lotus/lotus_webview_contract.dart';

void main() {
  group('lotus visual skin', () {
    test('injects a dedicated ManaLoom style tag', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusVisualSkinStyleIds.primary),
      );
      expect(lotusInjectedVisualSkinScript, contains("createElement('style')"));
      expect(
        lotusInjectedVisualSkinScript,
        contains('style.textContent = css;'),
      );
    });

    test('targets the safe Phase 1 surfaces', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.playerCard),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.menuButton),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.mainGameTimer),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.turnTracker),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.optionCard),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.commander-damage-overlay'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.turn-tracker-hint-overlay'),
      );
    });

    test('uses ManaLoom typography and visual tokens', () {
      expect(lotusInjectedVisualSkinScript, contains('Manrope'));
      expect(lotusInjectedVisualSkinScript, contains('Fraunces'));
      expect(lotusInjectedVisualSkinScript, contains('@font-face'));
      expect(lotusInjectedVisualSkinScript, contains('fonts/Manrope.ttf'));
      expect(lotusInjectedVisualSkinScript, contains('fonts/Fraunces.ttf'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('fontSet.load(\'400 16px "Manrope"\')'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('fontSet.load(\'650 16px "Fraunces"\')'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        isNot(contains('fonts.googleapis.com')),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('--manaloom-shell-shadow'),
      );
      expect(lotusInjectedVisualSkinScript, contains('--manaloom-shell-panel'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('clamp(13px, 4vw, 19px)'),
      );
      expect(lotusInjectedVisualSkinScript, contains('white-space: normal'));
      expect(lotusInjectedVisualSkinScript, contains('word-break: break-word'));
    });
  });
}
