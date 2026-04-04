import 'dart:convert';

import 'lotus_webview_contract.dart';

abstract final class LotusVisualSkinStyleIds {
  static const String primary = 'manaloom-lotus-visual-skin';
}

String get lotusInjectedVisualSkinScript {
  final css = '''
@import url("https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght,SOFT@9..144,600,0;9..144,700,0&family=Manrope:wght@500;600;700;800&display=swap");

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
})();
''';
}
