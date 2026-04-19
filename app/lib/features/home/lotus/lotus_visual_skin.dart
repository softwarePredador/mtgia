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
    radial-gradient(circle at top, rgba(92, 124, 189, 0.08), transparent 38%),
    linear-gradient(180deg, rgba(7, 12, 23, 0.95), rgba(2, 6, 16, 0.99));
  letter-spacing: 0.01em;
}

${LotusDomSelectors.playerCard} {
  filter: saturate(0.84) brightness(0.96) contrast(0.99);
}

${LotusDomSelectors.playerCard} .player-card-inner:not(.option-card):not(.color-card) {
  border-radius: calc(var(--borderRadius) * 1.15);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    inset 0 -20px 28px rgba(1, 6, 16, 0.18),
    0 12px 24px rgba(1, 8, 22, 0.16);
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
  transform: translate(-50%, 47%) scale(0.92);
  background: transparent !important;
  border-color: transparent !important;
  box-shadow: none !important;
  backdrop-filter: none !important;
}

${LotusDomSelectors.menuButton} .menu-button-shape,
${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner,
${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner:before,
${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner:after {
  -webkit-mask-image: none !important;
  mask-image: none !important;
  border-radius: 22px !important;
}

${LotusDomSelectors.menuButton} .menu-button-shape {
  width: 68px !important;
  height: 68px !important;
  background: transparent !important;
  z-index: 1 !important;
}

${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner {
  width: 60px !important;
  height: 60px !important;
}

${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner:before {
  width: 100% !important;
  height: 100% !important;
  background:
    linear-gradient(180deg, rgba(22, 31, 53, 0.98), rgba(8, 13, 27, 0.96)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 8px 16px rgba(2, 8, 22, 0.16) !important;
}

${LotusDomSelectors.menuButton} .menu-button-shape .menu-button-shape-inner:after {
  width: 52px !important;
  height: 52px !important;
  background:
    linear-gradient(180deg, rgba(6, 11, 23, 0.98), rgba(3, 7, 16, 0.96)) !important;
  border: 1px solid rgba(188, 211, 255, 0.2) !important;
  z-index: 2 !important;
}

${LotusDomSelectors.menuButton} .menu-button-stroke {
  width: 22px !important;
  height: 3px !important;
  background: rgba(255, 255, 255, 0.95) !important;
  border-radius: 2px !important;
  z-index: 3 !important;
}

${LotusDomSelectors.menuButton} .menu-button-stroke:after,
${LotusDomSelectors.menuButton} .menu-button-stroke:before {
  width: 22px !important;
  height: 3px !important;
  background: rgba(255, 255, 255, 0.95) !important;
  border-radius: 2px !important;
}

${LotusDomSelectors.menuButton} .menu-button-stroke:after {
  transform: translateY(-7px) !important;
}

${LotusDomSelectors.menuButton} .menu-button-stroke:before {
  transform: translateY(7px) !important;
}

.list {
  position: fixed !important;
  inset: 0 !important;
  width: 100% !important;
  height: 100% !important;
  z-index: 18 !important;
  pointer-events: none !important;
}

.list::before {
  content: "" !important;
  position: absolute !important;
  left: 50% !important;
  top: 50% !important;
  width: 182px !important;
  height: 182px !important;
  transform: translate(-50%, -50%) !important;
  border-radius: 50% !important;
  border: 1px solid rgba(160, 182, 226, 0.08) !important;
  box-shadow:
    inset 0 0 0 1px rgba(255, 255, 255, 0.02),
    0 0 0 1px rgba(7, 13, 26, 0.18) !important;
  opacity: 0.9 !important;
}

.list::after {
  content: "" !important;
  position: absolute !important;
  left: 50% !important;
  top: 50% !important;
  width: 124px !important;
  height: 124px !important;
  transform: translate(-50%, -50%) !important;
  border-radius: 50% !important;
  background: radial-gradient(
    circle,
    rgba(120, 168, 255, 0.08),
    rgba(120, 168, 255, 0.02) 54%,
    transparent 72%
  ) !important;
  filter: blur(6px) !important;
  opacity: 0.92 !important;
}

.list > * {
  --manaloom-menu-x: 0px;
  --manaloom-menu-y: 0px;
  position: absolute !important;
  left: 50% !important;
  top: 50% !important;
  width: auto !important;
  height: auto !important;
  pointer-events: none !important;
  transform:
    translate(
      calc(-50% + var(--manaloom-menu-x)),
      calc(-50% + var(--manaloom-menu-y))
    ) !important;
  rotate: 0deg !important;
}

.list > *.restart {
  --manaloom-menu-y: -84px;
}

.list > *.players {
  --manaloom-menu-x: -80px;
  --manaloom-menu-y: -26px;
}

.list > *.settings {
  --manaloom-menu-x: 49px;
  --manaloom-menu-y: 68px;
}

.list > *.more {
  --manaloom-menu-x: -49px;
  --manaloom-menu-y: 68px;
}

.list > *.high-roll {
  --manaloom-menu-x: 80px;
  --manaloom-menu-y: -26px;
}

.list > * .btn {
  width: 54px !important;
  height: 54px !important;
  min-width: 54px !important;
  min-height: 54px !important;
  padding: 0 !important;
  position: relative !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  border-radius: 16px !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  background:
    linear-gradient(180deg, rgba(16, 24, 44, 0.98), rgba(8, 13, 27, 0.96)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.09),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
  font-size: 0 !important;
  color: transparent !important;
  pointer-events: auto !important;
  backdrop-filter: var(--manaloom-shell-backdrop) !important;
  animation: none !important;
  transform: none !important;
}

.list > * .btn::before {
  content: "" !important;
  width: 22px !important;
  height: 22px !important;
  display: block !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  background-size: contain !important;
  opacity: 0.96 !important;
}

.list > *.players .btn {
  box-shadow:
    inset 0 0 0 1px rgba(74, 212, 145, 0.36),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
}

.list > *.players .btn::before {
  background-image: url("images/player-avatar-white.svg") !important;
  transform: translate(-1px, 1px) !important;
}

.list > *.restart .btn {
  box-shadow:
    inset 0 0 0 1px rgba(237, 187, 70, 0.4),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
}

.list > *.restart .btn::before {
  background-image: url("images/flip.svg") !important;
  transform: translateY(-1px) !important;
}

.list > *.settings .btn {
  box-shadow:
    inset 0 0 0 1px rgba(126, 112, 232, 0.42),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
}

.list > *.settings .btn::before {
  width: 22px !important;
  height: 22px !important;
  background-image: url("images/planechase-settings.svg") !important;
  transform: translate(0.5px, 0.5px) !important;
}

.list > *.more .btn {
  box-shadow:
    inset 0 0 0 1px rgba(231, 60, 122, 0.4),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
}

.list > *.more .btn::before {
  content: "?" !important;
  width: auto !important;
  height: auto !important;
  background-image: none !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 23px !important;
  line-height: 1 !important;
  font-weight: 800 !important;
  letter-spacing: -0.02em !important;
  color: rgba(255, 255, 255, 0.96) !important;
  opacity: 1 !important;
  transform: translateY(-1px) !important;
}

.list > *.high-roll .btn {
  width: 54px !important;
  height: 54px !important;
  min-width: 54px !important;
  min-height: 54px !important;
  border-radius: 16px !important;
  box-shadow:
    inset 0 0 0 1px rgba(68, 168, 244, 0.42),
    0 7px 14px rgba(1, 9, 24, 0.22) !important;
}

.list > *.high-roll .btn::before {
  background-image: url("images/dice.svg") !important;
  transform: translate(0.5px, 0.5px) !important;
}

${LotusDomSelectors.menuButton}.active {
  transform: translate(-50%, 47%) scale(0.78) !important;
  z-index: 19 !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-shape {
  transform: none !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-shape .menu-button-shape-inner:before {
  background:
    linear-gradient(180deg, rgba(26, 36, 58, 0.98), rgba(10, 16, 30, 0.94)) !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-shape .menu-button-shape-inner:after {
  background:
    linear-gradient(180deg, rgba(10, 16, 29, 0.98), rgba(5, 9, 19, 0.96)) !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-stroke {
  background: transparent !important;
  transform: rotate(-90deg) !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-stroke:after,
${LotusDomSelectors.menuButton}.active .menu-button-stroke:before {
  background: rgba(255, 255, 255, 0.94) !important;
  height: 4px !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-stroke:after {
  transform: translateY(0) rotate(45deg) !important;
}

${LotusDomSelectors.menuButton}.active .menu-button-stroke:before {
  transform: translateY(0) rotate(-45deg) !important;
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

.menu-button-overlay .game-states-wrapper {
  box-sizing: border-box;
  width: min(320px, calc(100vw - 20px)) !important;
  max-width: calc(100vw - 28px) !important;
  left: 0 !important;
  right: 0 !important;
  margin-inline: auto !important;
  transform: none !important;
  display: flex !important;
  flex-wrap: wrap !important;
  justify-content: center !important;
  align-items: center !important;
  gap: 9px !important;
  padding:
    10px 12px calc(env(safe-area-inset-bottom, 0px) + 9px) !important;
  background:
    linear-gradient(180deg, rgba(9, 14, 27, 0.92), rgba(5, 9, 20, 0.9)) !important;
  box-shadow: 0 -14px 24px rgba(2, 9, 22, 0.28) !important;
  backdrop-filter: blur(14px) saturate(1.15) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
  border-radius: 20px !important;
}

.menu-button-overlay .game-states-wrapper > * {
  width: 62px !important;
  min-width: 62px !important;
  min-height: 56px !important;
  flex: 0 0 62px !important;
  padding: 8px 5px 7px !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 9px !important;
  line-height: 1.12 !important;
  font-weight: 700 !important;
  letter-spacing: 0.02em !important;
  text-transform: uppercase !important;
  text-align: center !important;
  white-space: normal !important;
  word-break: break-word !important;
  color: rgba(240, 244, 252, 0.92) !important;
  background: rgba(9, 14, 27, 0.92) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 8px 16px rgba(0, 0, 0, 0.16) !important;
  border-radius: 16px !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: flex-end !important;
  gap: 5px !important;
  position: relative !important;
}

.menu-button-overlay .game-states-wrapper > *:before,
.menu-button-overlay .game-states-wrapper > *:after {
  width: 16px !important;
  height: 16px !important;
  background-size: 16px !important;
}

.menu-button-overlay .game-states-wrapper > *:before {
  position: absolute !important;
  top: 9px !important;
  left: 50% !important;
  transform: translateX(-50%) !important;
}

.menu-button-overlay .game-states-wrapper > *:after {
  display: none !important;
}

.first-time-user-overlay {
  position: fixed !important;
  inset: 0 !important;
  z-index: 120 !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: flex-end !important;
  gap: 16px !important;
  padding:
    18px 16px calc(env(safe-area-inset-bottom, 0px) + 24px) !important;
  box-sizing: border-box !important;
  background:
    linear-gradient(
      180deg,
      rgba(3, 7, 18, 0.08),
      rgba(3, 7, 18, 0.52) 40%,
      rgba(2, 6, 16, 0.76)
    ) !important;
}

.first-time-user-overlay .text-wrapper {
  width: min(100%, 340px) !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  gap: 14px !important;
  padding: 18px 16px 20px !important;
  border-radius: 28px !important;
  background:
    linear-gradient(180deg, rgba(9, 14, 27, 0.95), rgba(5, 9, 20, 0.95)) !important;
  box-shadow: 0 22px 34px rgba(1, 9, 24, 0.28) !important;
}

.first-time-user-overlay .image {
  position: relative !important;
  width: min(82vw, 290px) !important;
  min-height: 180px !important;
  display: flex !important;
  align-items: flex-end !important;
  justify-content: center !important;
  overflow: visible !important;
}

.first-time-user-overlay .cover-card {
  width: min(72vw, 238px) !important;
  height: min(42vw, 150px) !important;
  border-radius: 26px !important;
  overflow: hidden !important;
  box-shadow: 0 18px 30px rgba(1, 9, 24, 0.28) !important;
  transform: translateY(-10px) scale(0.76) !important;
  opacity: 0.44 !important;
  filter: saturate(0.9) brightness(0.92) !important;
}

.first-time-user-overlay .cover-card .life-count {
  font-size: clamp(92px, 26vw, 120px) !important;
}

.first-time-user-overlay .commander-card {
  width: min(72vw, 236px) !important;
  min-height: 92px !important;
  margin-top: -12px !important;
  padding: 14px 14px 12px !important;
  border-radius: 20px !important;
  background:
    linear-gradient(180deg, rgba(30, 34, 47, 0.98), rgba(17, 21, 31, 0.96)) !important;
  box-shadow: 0 16px 28px rgba(1, 9, 24, 0.34) !important;
}

.first-time-user-overlay .commander-card .label {
  font-family: var(--manaloom-ui-font) !important;
  font-size: 13px !important;
  line-height: 1 !important;
  letter-spacing: 0 !important;
  text-align: center !important;
}

.first-time-user-overlay .commander-card .label b {
  display: block !important;
  margin-bottom: 2px !important;
  font-size: clamp(28px, 8vw, 34px) !important;
  line-height: 0.92 !important;
}

.first-time-user-overlay .commander-card .button {
  height: auto !important;
  min-height: 38px !important;
  margin-top: 10px !important;
  padding: 10px 14px !important;
  border-radius: 999px !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 14px !important;
  font-weight: 800 !important;
}

.first-time-user-overlay .options-card {
  width: min(76vw, 252px) !important;
  min-height: 120px !important;
  margin-top: -12px !important;
  padding: 16px 14px 14px !important;
  border-radius: 20px !important;
  background:
    linear-gradient(180deg, rgba(32, 35, 48, 0.98), rgba(19, 22, 31, 0.96)) !important;
  box-shadow: 0 16px 28px rgba(1, 9, 24, 0.34) !important;
}

.first-time-user-overlay .options-card .inner {
  display: grid !important;
  grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
  gap: 12px !important;
  align-items: start !important;
}

.first-time-user-overlay .options-card .option-entry {
  min-width: 0 !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: flex-start !important;
  gap: 8px !important;
}

.first-time-user-overlay .options-card .option-entry-icon {
  width: 50px !important;
  height: 42px !important;
  border-radius: 12px !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.12) !important;
}

.first-time-user-overlay .options-card .option-entry-text {
  font-family: var(--manaloom-ui-font) !important;
  font-size: 8.5px !important;
  font-weight: 700 !important;
  line-height: 1.05 !important;
  text-align: center !important;
  white-space: normal !important;
  overflow-wrap: anywhere !important;
  word-break: break-word !important;
}

.first-time-user-overlay .headline {
  max-width: 320px !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(18px, 6vw, 26px) !important;
  font-weight: 800 !important;
  line-height: 0.96 !important;
  letter-spacing: 0 !important;
  text-align: center !important;
}

.first-time-user-overlay .text {
  max-width: 320px !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(14px, 4.8vw, 21px) !important;
  font-weight: 700 !important;
  line-height: 0.98 !important;
  letter-spacing: -0.01em !important;
  text-align: center !important;
  text-wrap: balance !important;
}

.first-time-user-overlay .text b {
  color: var(--manaloom-shell-accent-warm) !important;
}

.first-time-user-overlay > .btn {
  min-width: 160px !important;
  min-height: 50px !important;
  padding: 12px 24px !important;
  border-radius: 999px !important;
  background: linear-gradient(180deg, #ff2f86, #f31269) !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 16px !important;
  font-weight: 800 !important;
  letter-spacing: 0.01em !important;
  color: #fff !important;
}

.first-time-user-overlay .commander-card.hide {
  display: none !important;
}

.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_commander_damage"] .cover-card,
.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_player_options"] .cover-card {
  display: none !important;
}

.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_commander_damage"] .image,
.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_player_options"] .image {
  min-height: 116px !important;
}

.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_fullscreen_mode"] .image {
  display: none !important;
}

.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_commander_damage"] .commander-card,
.first-time-user-overlay[data-manaloom-visual-proof-key="first_time_player_options"] .options-card {
  margin-top: 0 !important;
}

.commander-damage-overlay,
.own-commander-damage-hint-overlay,
.turn-tracker-hint-overlay,
.manaloom-turn-tracker-proof,
.show-counters-hint-overlay,
.manaloom-show-counters-proof,
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
.own-commander-damage-hint-overlay .font,
.own-commander-damage-hint-overlay .text,
.turn-tracker-hint-overlay .font,
.turn-tracker-hint-overlay .text,
.manaloom-turn-tracker-proof .font,
.manaloom-turn-tracker-proof .text,
.show-counters-hint-overlay .font,
.show-counters-hint-overlay .text,
.manaloom-show-counters-proof .font,
.manaloom-show-counters-proof .text,
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
.own-commander-damage-hint-overlay .font,
.turn-tracker-hint-overlay .font,
.manaloom-turn-tracker-proof .font,
.show-counters-hint-overlay .font,
.manaloom-show-counters-proof .font {
  font-size: clamp(16px, 5vw, 24px) !important;
  font-weight: 700 !important;
  line-height: 0.98;
}

.commander-damage-overlay .btn,
.own-commander-damage-hint-overlay .btn,
.turn-tracker-hint-overlay .btn,
.manaloom-turn-tracker-proof .btn,
.show-counters-hint-overlay .btn,
.manaloom-show-counters-proof .btn,
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
.own-commander-damage-hint-overlay .btn-wrapper,
.manaloom-turn-tracker-proof .btn-wrapper,
.show-counters-hint-overlay .btn-wrapper,
.manaloom-show-counters-proof .btn-wrapper,
.input-overlay .btn-wrapper {
  gap: 10px;
}

.manaloom-proof-title {
  width: 100% !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(16px, 4.8vw, 22px) !important;
  font-weight: 800 !important;
  line-height: 1 !important;
  letter-spacing: 0 !important;
  text-align: center !important;
  color: var(--manaloom-shell-text) !important;
}

.manaloom-proof-body {
  width: 100% !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(13px, 4vw, 18px) !important;
  font-weight: 700 !important;
  line-height: 1.08 !important;
  letter-spacing: -0.01em !important;
  text-align: center !important;
  color: var(--manaloom-shell-text) !important;
  text-wrap: balance !important;
}

.manaloom-proof-actions {
  width: 100% !important;
  display: flex !important;
  align-items: stretch !important;
  justify-content: center !important;
  gap: 10px !important;
  flex-wrap: wrap !important;
}

.commander-damage-overlay,
.own-commander-damage-hint-overlay,
.turn-tracker-hint-overlay,
.manaloom-turn-tracker-proof,
.show-counters-hint-overlay,
.manaloom-show-counters-proof {
  position: fixed !important;
  inset: auto 16px calc(env(safe-area-inset-bottom, 0px) + 22px) 16px !important;
  z-index: 120 !important;
  width: auto !important;
  max-width: none !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: flex-start !important;
  gap: 14px !important;
  overflow: hidden !important;
  backdrop-filter: none !important;
  background:
    linear-gradient(180deg, rgb(10, 16, 30), rgb(5, 9, 20)) !important;
}

.commander-damage-overlay .btn-wrapper,
.own-commander-damage-hint-overlay .btn-wrapper,
.turn-tracker-hint-overlay .btn-wrapper,
.manaloom-turn-tracker-proof .btn-wrapper,
.show-counters-hint-overlay .btn-wrapper,
.manaloom-show-counters-proof .btn-wrapper {
  width: 100% !important;
  display: flex !important;
  align-items: stretch !important;
  justify-content: center !important;
  flex-wrap: wrap !important;
}

.commander-damage-overlay .btn,
.own-commander-damage-hint-overlay .btn,
.turn-tracker-hint-overlay .btn,
.manaloom-turn-tracker-proof .btn,
.show-counters-hint-overlay .btn,
.manaloom-show-counters-proof .btn {
  flex: 1 1 0 !important;
  max-width: 180px !important;
  border-radius: 999px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  background: linear-gradient(180deg, #ff2f86, #f31269) !important;
  color: #fff !important;
}

.own-commander-damage-hint-overlay .font,
.turn-tracker-hint-overlay .font,
.manaloom-turn-tracker-proof .font,
.show-counters-hint-overlay .font,
.manaloom-show-counters-proof .font {
  font-size: clamp(15px, 4.6vw, 21px) !important;
  line-height: 1 !important;
}

.own-commander-damage-hint-overlay .text,
.turn-tracker-hint-overlay .text,
.manaloom-turn-tracker-proof .text,
.show-counters-hint-overlay .text,
.manaloom-show-counters-proof .text {
  font-size: clamp(13px, 4vw, 17px) !important;
  line-height: 1.08 !important;
}

.manaloom-show-counters-proof .player-card {
  position: relative !important;
  width: min(54vw, 168px) !important;
  height: min(24vh, 156px) !important;
  margin: 8px auto 0 !important;
  overflow: hidden !important;
  border-radius: 18px !important;
}

.manaloom-show-counters-proof .player-card .player-card-inner {
  border-radius: 18px !important;
}

.manaloom-show-counters-proof .player-card .player-life-count {
  opacity: 0.18 !important;
  transform: scale(0.44) !important;
  transform-origin: center !important;
}

.manaloom-show-counters-proof .player-card .counters-on-card {
  transform: scale(0.82) !important;
  transform-origin: bottom center !important;
}

.manaloom-show-counters-proof .player-card {
  display: none !important;
}

.manaloom-show-counters-proof::before {
  content: "" !important;
  display: block !important;
  width: 142px !important;
  height: 92px !important;
  border-radius: 22px !important;
  background:
    radial-gradient(circle at 76% 24%, rgba(255, 255, 255, 0.08), transparent 24%),
    linear-gradient(180deg, rgba(58, 64, 92, 0.92), rgba(27, 31, 46, 0.96)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    0 12px 22px rgba(0, 0, 0, 0.16) !important;
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

  switch (proof) {
    case 'commander_damage':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'commander-damage-overlay',
        title: "COMMANDER DAMAGE YOU'VE RECEIVED",
        text: 'SWIPE LEFT OR RIGHT TO TRACK COMMANDER DAMAGE',
        buttons: const ['RETURN TO GAME', 'GOT IT!'],
      );
    case 'turn_tracker_hint':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'TURN TRACKER',
        text: 'TAP NEXT OR PREVIOUS TO FOLLOW THE ACTIVE TURN',
        buttons: const ['GOT IT!'],
      );
    case 'turn_tracker_hint_step1':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'TURN TRACKER',
        text:
            'LONG PRESS THE TURN TRACKER TO MOVE IT BACK TO THE PREVIOUS PLAYER IF YOU MISSCLICKED',
        buttons: const ['NEXT'],
      );
    case 'turn_tracker_hint_step2':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'TURN TRACKER',
        text:
            'WHEN AT TURN 1 ON THE STARTING PLAYER, LONG PRESS TO CHANGE WHO STARTS FIRST',
        buttons: const ['GOT IT!'],
      );
    case 'show_counters_hint':
      return _buildShowCountersVisualProofScript(proofKey: proof);
    case 'menu_overlay':
      return _buildMenuOverlayVisualProofScript(proofKey: proof);
    case 'first_time_commander_damage':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Commander damage',
        text: 'Swipe <b>left</b> or <b>right</b> to track Commander damage',
        buttonLabel: 'Got it!',
        coverCardClassName: 'cover-card swipe-left',
        commanderCardClassName: 'commander-card',
      );
    case 'first_time_player_options':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Make it yours',
        text: 'Swipe <b>up</b> or <b>down</b> to show player options',
        buttonLabel: 'Alright!',
        coverCardClassName: 'cover-card swipe-up',
        commanderCardClassName: 'commander-card hide',
      );
    case 'first_time_fullscreen_mode':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Fullscreen mode',
        text: 'Add website to <b>home screen</b> for fullscreen mode',
        buttonLabel: 'Good to know!',
        coverCardClassName: 'cover-card swipe-up',
        commanderCardClassName: 'commander-card hide',
      );
    case 'own_commander_damage_hint':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'own-commander-damage-hint-overlay',
        title: 'OWN COMMANDER DAMAGE',
        text:
            'GOT BETRAYED?<br><span>TAP THE DAGGER TO TRACK DAMAGE TAKEN FROM YOUR OWN COMMANDER.</span>',
        buttons: const ['GOT IT!'],
      );
    default:
      return null;
  }
}

String get _visualProofChromeCleanupScript => '''
  [
    ${jsonEncode(LotusDomSelectors.menuButton)},
    ${jsonEncode(LotusDomSelectors.turnTracker)},
    ${jsonEncode(LotusDomSelectors.mainGameTimer)},
    ${jsonEncode(LotusDomSelectors.currentTimeClock)},
    '.other-buttons-wrapper',
    '.feedback-btn-wrapper',
    '.patreon-btn-wrapper',
    '.lotus',
    '.patreon',
    '.toast'
  ].forEach((selector) => {
    document.querySelectorAll(selector).forEach((node) => {
      if (!(node instanceof HTMLElement)) {
        return;
      }
      node.style.setProperty('display', 'none', 'important');
      node.style.setProperty('opacity', '0', 'important');
      node.style.setProperty('pointer-events', 'none', 'important');
    });
  });
''';

String get _visualProofIsolatedCanvasScript => '''
  Array.from(document.body.children).forEach((node) => {
    if (!(node instanceof HTMLElement)) {
      return;
    }
    node.style.setProperty('visibility', 'hidden', 'important');
    node.style.setProperty('pointer-events', 'none', 'important');
  });
  document.body.style.setProperty(
    'background',
    'linear-gradient(180deg, rgb(6, 11, 23), rgb(3, 7, 17))',
    'important',
  );
''';

String _buildSimpleVisualProofScript({
  required String proofKey,
  required String overlayClass,
  required String title,
  required String text,
  required List<String> buttons,
}) {
  final buttonsHtml =
      buttons.map((label) => '<div class="btn">$label</div>').join();
  final overlayClassJson = jsonEncode(overlayClass);
  final titleJson = jsonEncode(title);
  final textJson = jsonEncode(text);
  final buttonsHtmlJson = jsonEncode(buttonsHtml);
  final proofJson = jsonEncode(proofKey);

  return '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());
$_visualProofIsolatedCanvasScript

  const overlay = document.createElement('div');
  overlay.className = $overlayClassJson;
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML =
    '<div class="manaloom-proof-title">' + $titleJson + '</div>' +
    '<div class="manaloom-proof-body">' + $textJson + '</div>' +
    '<div class="manaloom-proof-actions">' + $buttonsHtmlJson + '</div>';

  document.body.appendChild(overlay);
})();
''';
}

String _buildFirstTimeUserVisualProofScript({
  required String proofKey,
  required String headline,
  required String text,
  required String buttonLabel,
  required String coverCardClassName,
  required String commanderCardClassName,
}) {
  final overlayHtml = jsonEncode('''
<div class="text-wrapper">
  <div class="image">
    <div class="$coverCardClassName">
      <div class="life-count">40</div>
      <div class="side minus">-</div>
      <div class="side plus">+</div>
    </div>
    <div class="$commanderCardClassName">
      <div class="label"><b>Commander</b>Damage you've received</div>
      <div class="button">Return to Game</div>
    </div>
    <div class="options-card">
      <div class="inner">
        <div class="option-entry background">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Background</div>
        </div>
        <div class="option-entry kill">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Kill</div>
        </div>
        <div class="option-entry partner">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Partner</div>
        </div>
      </div>
    </div>
  </div>
  <div class="headline">$headline</div>
  <div class="text">$text</div>
</div>
<div class="btn">$buttonLabel</div>
''');
  final proofJson = jsonEncode(proofKey);

  return '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());
$_visualProofChromeCleanupScript

  const overlay = document.createElement('div');
  overlay.className = 'first-time-user-overlay';
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML = $overlayHtml;

  document.body.appendChild(overlay);
})();
''';
}

String _buildMenuOverlayVisualProofScript({required String proofKey}) {
  final overlayHtml = jsonEncode('''
<div class="game-states-wrapper">
  <div class="dice-btn">Dice</div>
  <div class="life-history-btn">History</div>
  <div class="initiative-btn">Initiative</div>
  <div class="monarch-btn">Monarch</div>
  <div class="card-search-btn">Card Search</div>
</div>
''');
  final proofJson = jsonEncode(proofKey);

  return '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());
$_visualProofChromeCleanupScript

  const overlay = document.createElement('div');
  overlay.className = 'menu-button-overlay';
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML = $overlayHtml;

  document.body.appendChild(overlay);
})();
''';
}

String _buildShowCountersVisualProofScript({required String proofKey}) {
  final overlayHtml = jsonEncode('''
<div class="player-card">
  <div class="player-card-inner">
    <div class="player-life-count">40</div>
    <div class="counters-on-card">
      <div class="counter poison">4</div>
      <div class="counter energy">2</div>
    </div>
  </div>
</div>
<div class="manaloom-proof-title">DISPLAY COUNTERS ON PLAYER CARDS? <br><span>(YOU CAN TOGGLE THIS IN THE SETTINGS)</span></div>
<div class="manaloom-proof-actions">
  <div class="btn disable">NO</div>
  <div class="btn confirm">YES</div>
</div>
''');
  final proofJson = jsonEncode(proofKey);

  return '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());
$_visualProofIsolatedCanvasScript

  const overlay = document.createElement('div');
  overlay.className = 'manaloom-show-counters-proof';
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML = $overlayHtml;

  document.body.appendChild(overlay);
})();
''';
}
