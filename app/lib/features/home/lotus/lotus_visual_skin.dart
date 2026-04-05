import 'dart:convert';

import 'lotus_runtime_flags.dart';
import 'lotus_webview_contract.dart';

abstract final class LotusVisualSkinStyleIds {
  static const String primary = 'manaloom-lotus-visual-skin';
}

String get lotusInjectedVisualSkinScript {
  final css = '''
@font-face {
  font-family: "Manrope";
  src: url("fonts/Manrope.ttf") format("truetype");
  font-style: normal;
  font-weight: 200 800;
  font-display: swap;
}

@font-face {
  font-family: "Fraunces";
  src: url("fonts/Fraunces.ttf") format("truetype");
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
}

:root {
  --manaloom-ui-font: "Manrope", BlinkMacSystemFont, -apple-system, "Segoe UI",
    Roboto, Helvetica, Arial, sans-serif;
  --manaloom-display-font: "Fraunces", "Iowan Old Style", "Palatino Linotype",
    "Book Antiqua", Georgia, serif;
  --manaloom-shell-shadow:
    0 28px 48px rgba(1, 9, 24, 0.42),
    0 10px 24px rgba(3, 10, 24, 0.26);
  --manaloom-shell-border: rgba(255, 255, 255, 0.16);
  --manaloom-shell-panel: rgba(7, 13, 28, 0.78);
  --manaloom-shell-panel-strong: rgba(8, 16, 34, 0.9);
  --manaloom-shell-panel-soft: rgba(13, 23, 45, 0.56);
  --manaloom-shell-text: rgba(245, 247, 252, 0.96);
  --manaloom-shell-text-muted: rgba(207, 215, 233, 0.76);
  --manaloom-shell-accent: #78a8ff;
  --manaloom-shell-accent-strong: #9ac2ff;
  --manaloom-shell-accent-warm: #f3c46b;
  --manaloom-shell-radius: 22px;
  --manaloom-shell-pill-radius: 999px;
  --manaloom-shell-backdrop: saturate(1.12) blur(16px);
}

html,
body {
  font-family: var(--manaloom-ui-font) !important;
  color: var(--manaloom-shell-text);
}

body {
  background:
    radial-gradient(circle at top, rgba(120, 168, 255, 0.14), transparent 34%),
    linear-gradient(165deg, rgba(9, 15, 31, 0.94), rgba(4, 10, 24, 0.98));
  letter-spacing: 0.01em;
}

${LotusDomSelectors.playerCard} {
  filter: saturate(1.04) contrast(1.02);
}

${LotusDomSelectors.playerCard} .player-card-inner:not(.option-card):not(.color-card) {
  border-radius: calc(var(--borderRadius) * 1.15);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.18),
    inset 0 -24px 36px rgba(1, 6, 16, 0.18),
    var(--manaloom-shell-shadow);
}

${LotusDomSelectors.playerCard} .player-name,
${LotusDomSelectors.playerCard} .player-name-input,
${LotusDomSelectors.playerCard} .commander-damage-overlay .text,
${LotusDomSelectors.playerCard} .counters-on-card .counter,
${LotusDomSelectors.playerCard} .commander-damage-counters .counter {
  font-family: var(--manaloom-ui-font) !important;
}

${LotusDomSelectors.playerCard} .player-name,
${LotusDomSelectors.playerCard} .player-name-input {
  font-family: var(--manaloom-display-font) !important;
  font-weight: 650;
  letter-spacing: 0.015em;
  text-shadow: 0 2px 18px rgba(3, 8, 21, 0.35);
}

${LotusDomSelectors.playerCard} .player-life-count {
  filter: drop-shadow(0 14px 22px rgba(2, 7, 19, 0.28));
}

${LotusDomSelectors.playerCard} .player-life-count .font {
  text-shadow:
    0 2px 0 rgba(255, 255, 255, 0.08),
    0 10px 18px rgba(1, 7, 18, 0.22);
}

${LotusDomSelectors.playerCard} .counters-on-card .counter {
  background: linear-gradient(
    180deg,
    rgba(9, 16, 33, 0.8),
    rgba(5, 10, 23, 0.68)
  );
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.14),
    0 8px 18px rgba(0, 0, 0, 0.18);
}

${LotusDomSelectors.playerCard} .commander-damage-counters .counter.commander-damage-counter:before {
  box-shadow:
    0 0 0 2px rgba(255, 255, 255, 0.9),
    0 10px 18px rgba(0, 0, 0, 0.26);
}

${LotusDomSelectors.menuButton},
.day-night-switcher,
.planechase-btn,
.archenemy-btn,
.bounty-btn {
  border: 1px solid var(--manaloom-shell-border);
  box-shadow: var(--manaloom-shell-shadow);
  backdrop-filter: var(--manaloom-shell-backdrop);
}

${LotusDomSelectors.menuButton} {
  background:
    linear-gradient(180deg, rgba(20, 32, 61, 0.94), rgba(8, 14, 30, 0.88));
}

${LotusDomSelectors.optionCard} {
  font-family: var(--manaloom-ui-font) !important;
  background:
    linear-gradient(180deg, rgba(12, 21, 40, 0.96), rgba(6, 11, 24, 0.92));
  border: 1px solid var(--manaloom-shell-border);
  box-shadow: var(--manaloom-shell-shadow);
  backdrop-filter: var(--manaloom-shell-backdrop);
}

${LotusDomSelectors.optionCard} .label,
${LotusDomSelectors.optionCard} .title,
${LotusDomSelectors.optionCard} h1,
${LotusDomSelectors.optionCard} h2,
${LotusDomSelectors.optionCard} h3 {
  font-family: var(--manaloom-display-font) !important;
  letter-spacing: 0.01em;
}

.commander-damage-overlay,
.turn-tracker-hint-overlay,
.show-counters-hint-overlay,
.max-game-modes-warning,
.input-overlay {
  box-sizing: border-box;
  width: min(86vw, 340px);
  max-width: calc(100vw - 32px);
  padding: 18px 18px 16px;
  border-radius: 24px;
  border: 1px solid var(--manaloom-shell-border);
  box-shadow: var(--manaloom-shell-shadow);
  backdrop-filter: var(--manaloom-shell-backdrop);
  background:
    linear-gradient(180deg, rgba(12, 21, 40, 0.97), rgba(6, 11, 24, 0.94));
}

.commander-damage-overlay .font,
.commander-damage-overlay .text,
.turn-tracker-hint-overlay .font,
.show-counters-hint-overlay .font,
.max-game-modes-warning .text,
.input-overlay .overlay-text {
  font-family: var(--manaloom-ui-font) !important;
  display: block !important;
  width: 100%;
  white-space: normal !important;
  font-size: clamp(13px, 4vw, 19px) !important;
  line-height: 1.08;
  letter-spacing: -0.01em;
  text-wrap: balance;
  overflow-wrap: anywhere;
  word-break: break-word;
  text-align: center;
}

.commander-damage-overlay .font,
.turn-tracker-hint-overlay .font,
.show-counters-hint-overlay .font {
  font-size: clamp(16px, 5vw, 24px) !important;
  font-weight: 700 !important;
  line-height: 0.98;
}

.commander-damage-overlay .btn,
.turn-tracker-hint-overlay .btn,
.show-counters-hint-overlay .btn,
.max-game-modes-warning .close,
.input-overlay .btn {
  min-height: 42px;
  height: auto;
  padding: 10px 18px;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(14px, 4vw, 18px) !important;
  font-weight: 800;
  letter-spacing: 0.01em;
  white-space: normal;
}

.commander-damage-overlay .btn-wrapper,
.show-counters-hint-overlay .btn-wrapper,
.input-overlay .btn-wrapper {
  gap: 10px;
}

${LotusDomSelectors.mainGameTimer},
${LotusDomSelectors.currentTimeClock},
${LotusDomSelectors.turnTracker},
.toast,
.lotus,
.patreon,
.feedback-btn,
.patreon-btn {
  font-family: var(--manaloom-ui-font) !important;
}

${LotusDomSelectors.mainGameTimer},
${LotusDomSelectors.currentTimeClock},
${LotusDomSelectors.turnTracker} {
  background:
    linear-gradient(180deg, rgba(13, 22, 43, 0.94), rgba(7, 12, 24, 0.86));
  border: 1px solid var(--manaloom-shell-border);
  box-shadow: var(--manaloom-shell-shadow);
  backdrop-filter: var(--manaloom-shell-backdrop);
  color: var(--manaloom-shell-text);
  font-weight: 700;
  letter-spacing: 0.02em;
}

${LotusDomSelectors.mainGameTimer}:after,
${LotusDomSelectors.currentTimeClock}:after {
  font-family: var(--manaloom-ui-font) !important;
  font-weight: 800;
}

${LotusDomSelectors.turnTracker} .minutes-seconds:before {
  background: rgba(255, 255, 255, 0.24);
}

.toast {
  background:
    linear-gradient(135deg, rgba(49, 114, 214, 0.96), rgba(29, 72, 147, 0.92));
  border-radius: 18px 18px 0 0;
  border: 1px solid rgba(255, 255, 255, 0.12);
  box-shadow: var(--manaloom-shell-shadow);
  letter-spacing: 0.015em;
}

.toast.error {
  background:
    linear-gradient(135deg, rgba(188, 63, 84, 0.96), rgba(121, 28, 48, 0.92));
}

.lotus,
.patreon {
  background:
    linear-gradient(180deg, rgba(249, 251, 255, 0.97), rgba(234, 240, 252, 0.94));
  border: 1px solid rgba(9, 18, 36, 0.08);
  box-shadow: 0 20px 36px rgba(0, 0, 0, 0.18);
}

.lotus .name,
.patreon .text,
#Content h1,
#Content h2,
#Content h3 {
  font-family: var(--manaloom-display-font) !important;
}

#Content p,
#Content li,
#Content a,
#Content .buildversion {
  font-family: var(--manaloom-ui-font) !important;
}
''';

  final styleId = jsonEncode(LotusVisualSkinStyleIds.primary);
  final cssJson = jsonEncode(css);

  return '''
(() => {
  const styleId = $styleId;
  const css = $cssJson;
  const head = document.head || document.documentElement;
  if (!head) {
    return;
  }

  let style = document.getElementById(styleId);
  if (!(style instanceof HTMLStyleElement)) {
    style = document.createElement('style');
    style.id = styleId;
    head.appendChild(style);
  }

  style.textContent = css;

  const fontSet = document.fonts;
  if (fontSet && typeof fontSet.load === 'function') {
    fontSet.load('400 16px "Manrope"').catch(() => {});
    fontSet.load('650 16px "Fraunces"').catch(() => {});
  }
})();
''';
}

String? get lotusInjectedVisualProofScript {
  final proof = debugLotusVisualProof.trim();
  if (proof.isEmpty) {
    return null;
  }

  late final String overlayClass;
  late final String title;
  late final String text;
  late final List<String> buttons;

  switch (proof) {
    case 'commander_damage':
      overlayClass = 'commander-damage-overlay';
      title = "COMMANDER DAMAGE YOU'VE RECEIVED";
      text = 'SWIPE LEFT OR RIGHT TO TRACK COMMANDER DAMAGE';
      buttons = const ['RETURN TO GAME', 'GOT IT!'];
    case 'turn_tracker_hint':
      overlayClass = 'turn-tracker-hint-overlay';
      title = 'TURN TRACKER';
      text = 'TAP NEXT OR PREVIOUS TO FOLLOW THE ACTIVE TURN';
      buttons = const ['GOT IT!'];
    case 'show_counters_hint':
      overlayClass = 'show-counters-hint-overlay';
      title = 'PLAYER COUNTERS';
      text = 'TAP A COUNTER TO OPEN QUICK CONTROLS';
      buttons = const ['GOT IT!'];
    default:
      return null;
  }

  final buttonsHtml = buttons
      .map((label) => '<div class="btn">$label</div>')
      .join();
  final overlayClassJson = jsonEncode(overlayClass);
  final titleJson = jsonEncode(title);
  final textJson = jsonEncode(text);
  final buttonsHtmlJson = jsonEncode(buttonsHtml);
  final proofJson = jsonEncode(proof);

  return '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());

  const overlay = document.createElement('div');
  overlay.className = $overlayClassJson;
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML =
    '<div class="font">' + $titleJson + '</div>' +
    '<div class="text">' + $textJson + '</div>' +
    '<div class="btn-wrapper">' + $buttonsHtmlJson + '</div>';

  document.body.appendChild(overlay);
})();
''';
}
