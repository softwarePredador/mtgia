import 'dart:convert';

import 'lotus_runtime_flags.dart';
import 'lotus_webview_contract.dart';

abstract final class LotusVisualSkinStyleIds {
  static const String primary = 'manaloom-lotus-visual-skin';
}

String get lotusInjectedVisualSkinScript {
  final css = '''
@font-face {
  font-family: "Inter";
  src: url("fonts/Inter.ttf") format("truetype");
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
  --manaloom-ui-font: "Inter", BlinkMacSystemFont, -apple-system, "Segoe UI",
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
  --manaloom-shell-accent-warm: #d89a2f;
  --manaloom-shell-accent-warm-strong: #f2bc49;
  --manaloom-shell-border-warm: rgba(216, 154, 47, 0.42);
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
  --manaloom-player-accent: rgba(216, 154, 47, 0.78);
  --manaloom-player-accent-soft: rgba(216, 154, 47, 0.26);
  --manaloom-player-accent-faint: rgba(216, 154, 47, 0.1);
  --manaloom-player-glow: rgba(216, 154, 47, 0.2);
  filter: saturate(0.62) brightness(0.88) contrast(1.03);
  border-radius: calc(var(--borderRadius) * 1.15);
  box-shadow:
    inset 0 0 0 1px var(--manaloom-player-accent-soft),
    inset 0 0 34px var(--manaloom-player-accent-faint),
    0 18px 34px rgba(0, 0, 0, 0.26);
}

${LotusDomSelectors.playerCard}:nth-of-type(4n + 1) {
  --manaloom-player-accent: rgba(242, 188, 73, 0.82);
  --manaloom-player-accent-soft: rgba(242, 188, 73, 0.34);
  --manaloom-player-accent-faint: rgba(242, 188, 73, 0.14);
  --manaloom-player-glow: rgba(242, 188, 73, 0.24);
}

${LotusDomSelectors.playerCard}:nth-of-type(4n + 2) {
  --manaloom-player-accent: rgba(120, 168, 255, 0.82);
  --manaloom-player-accent-soft: rgba(120, 168, 255, 0.34);
  --manaloom-player-accent-faint: rgba(120, 168, 255, 0.14);
  --manaloom-player-glow: rgba(120, 168, 255, 0.24);
}

${LotusDomSelectors.playerCard}:nth-of-type(4n + 3) {
  --manaloom-player-accent: rgba(154, 124, 255, 0.82);
  --manaloom-player-accent-soft: rgba(154, 124, 255, 0.34);
  --manaloom-player-accent-faint: rgba(154, 124, 255, 0.14);
  --manaloom-player-glow: rgba(154, 124, 255, 0.24);
}

${LotusDomSelectors.playerCard}:nth-of-type(4n) {
  --manaloom-player-accent: rgba(78, 214, 145, 0.82);
  --manaloom-player-accent-soft: rgba(78, 214, 145, 0.34);
  --manaloom-player-accent-faint: rgba(78, 214, 145, 0.14);
  --manaloom-player-glow: rgba(78, 214, 145, 0.24);
}

${LotusDomSelectors.playerCard} .player-card-inner:not(.option-card):not(.color-card) {
  border-radius: calc(var(--borderRadius) * 1.15);
  background:
    radial-gradient(circle at 78% 18%, var(--manaloom-player-glow), transparent 35%),
    radial-gradient(circle at 42% 52%, var(--bg, rgba(21, 29, 45, 0.94)), transparent 50%),
    radial-gradient(circle at 20% 82%, var(--manaloom-player-accent-faint), transparent 40%),
    linear-gradient(145deg, rgba(4, 8, 18, 0.9), rgba(8, 14, 30, 0.96)) !important;
  background-blend-mode: screen, soft-light, screen, normal;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 0 0 1px var(--manaloom-player-accent-soft),
    inset 0 0 0 2px rgba(255, 255, 255, 0.025),
    inset 0 -28px 42px rgba(1, 6, 16, 0.36),
    inset 0 0 42px var(--manaloom-player-accent-faint),
    0 12px 24px rgba(1, 8, 22, 0.22);
}

${LotusDomSelectors.playerCard} .increase-button.life,
${LotusDomSelectors.playerCard} .decrease-button.life {
  position: absolute !important;
  background:
    radial-gradient(circle at center, var(--manaloom-player-accent-faint), transparent 48%),
    rgba(5, 9, 20, 0.08) !important;
  box-shadow:
    inset 0 0 90px rgba(2, 6, 16, 0.16),
    inset 0 0 0 1px rgba(255, 255, 255, 0.018);
}

${LotusDomSelectors.playerCard} .increase-button.life:after,
${LotusDomSelectors.playerCard} .decrease-button.life:after {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  font-family: var(--manaloom-ui-font);
  font-size: clamp(32px, 13vw, 68px);
  font-weight: 800;
  line-height: 1;
  color: rgba(247, 241, 226, 0.52);
  text-shadow:
    0 0 14px var(--manaloom-player-accent-soft),
    0 4px 14px rgba(1, 7, 18, 0.48);
}

${LotusDomSelectors.playerCard} .increase-button.life:after {
  content: "+";
}

${LotusDomSelectors.playerCard} .decrease-button.life:after {
  content: "−";
}

${LotusDomSelectors.playerCard} .increase-button.life:before,
${LotusDomSelectors.playerCard} .decrease-button.life:before {
  color: rgba(247, 241, 226, 0.68) !important;
  text-shadow:
    0 0 10px var(--manaloom-player-accent-soft),
    0 4px 12px rgba(1, 7, 18, 0.36) !important;
}

${LotusDomSelectors.playerCard} .increase-button.life,
${LotusDomSelectors.playerCard} .decrease-button.life,
${LotusDomSelectors.playerCard} .increase-button.life .font,
${LotusDomSelectors.playerCard} .decrease-button.life .font,
${LotusDomSelectors.playerCard} .increase-button.life .char-plus,
${LotusDomSelectors.playerCard} .decrease-button.life .char-minus {
  --fontColor: rgba(247, 241, 226, 0.68) !important;
  color: rgba(247, 241, 226, 0.68) !important;
  fill: rgba(247, 241, 226, 0.68) !important;
  stroke: rgba(247, 241, 226, 0.68) !important;
  -webkit-text-fill-color: rgba(247, 241, 226, 0.68) !important;
  opacity: 1 !important;
  filter: drop-shadow(0 0 8px var(--manaloom-player-accent-soft)) !important;
}

${LotusDomSelectors.playerCard} .increase-button.life:active,
${LotusDomSelectors.playerCard} .decrease-button.life:active {
  background:
    radial-gradient(circle at center, var(--manaloom-player-accent-soft), transparent 54%),
    rgba(5, 9, 20, 0.16) !important;
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
  color: rgba(247, 241, 226, 0.94) !important;
  -webkit-text-fill-color: rgba(247, 241, 226, 0.94) !important;
}

${LotusDomSelectors.playerCard} .player-life-count .font {
  --fontColor: var(--fontWhite) !important;
  color: rgba(247, 241, 226, 0.94) !important;
  -webkit-text-fill-color: rgba(247, 241, 226, 0.94) !important;
  text-shadow:
    0 1px 0 rgba(255, 255, 255, 0.08),
    0 12px 20px rgba(1, 7, 18, 0.5);
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

.settings-overlay,
.life-history-overlay,
.card-search-overlay {
  font-family: var(--manaloom-ui-font) !important;
  color: var(--manaloom-shell-text) !important;
  background:
    radial-gradient(circle at 50% 0%, rgba(216, 154, 47, 0.12), transparent 32%),
    radial-gradient(circle at 90% 12%, rgba(120, 168, 255, 0.08), transparent 30%),
    linear-gradient(180deg, rgb(5, 10, 22), rgb(2, 6, 16)) !important;
  text-transform: none !important;
}

.settings-overlay *,
.life-history-overlay *,
.card-search-overlay * {
  font-family: var(--manaloom-ui-font) !important;
  text-transform: none !important;
}

.settings-overlay {
  position: fixed !important;
  inset: 0 !important;
  left: 0 !important;
  top: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  width: 100vw !important;
  height: 100vh !important;
  min-width: 0 !important;
  max-width: 100vw !important;
  transform: none !important;
  display: block !important;
  align-items: flex-start !important;
  justify-content: flex-start !important;
  padding:
    calc(env(safe-area-inset-top, 0px) + 24px) 22px
    calc(env(safe-area-inset-bottom, 0px) + 28px) !important;
  box-sizing: border-box !important;
  overflow: auto !important;
}

.settings-overlay::before,
.card-search-overlay::before {
  display: block !important;
  width: 100% !important;
  margin: 0 0 18px !important;
  font-family: var(--manaloom-display-font) !important;
  font-size: 30px !important;
  line-height: 1 !important;
  font-weight: 700 !important;
  letter-spacing: -0.02em !important;
  color: rgb(247, 241, 226) !important;
  text-align: left !important;
}

.settings-overlay::before {
  content: "Configurações" !important;
}

.card-search-overlay::before {
  content: "Buscar carta" !important;
  position: absolute !important;
  left: 22px !important;
  top: calc(env(safe-area-inset-top, 0px) + 24px) !important;
  z-index: 2 !important;
}

.settings-overlay .settings-headline,
.settings-overlay h1,
.settings-overlay h2,
.settings-overlay h3,
.life-history-overlay .game-name,
.life-history-overlay .timeline-label,
.life-history-overlay .meta-label,
.card-search-overlay .results-wrapper .card-name {
  font-family: var(--manaloom-display-font) !important;
  color: rgb(247, 241, 226) !important;
  letter-spacing: -0.01em !important;
}

.settings-overlay .settings-headline {
  position: relative !important;
  left: 0 !important;
  top: 0 !important;
  transform: none !important;
  width: 100% !important;
  margin: 0 0 18px !important;
  font-size: 0 !important;
}

.settings-overlay .settings-headline::after {
  content: "Preferências da mesa" !important;
  display: block !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 15px !important;
  line-height: 1.3 !important;
  font-weight: 600 !important;
  letter-spacing: 0 !important;
  color: var(--manaloom-shell-text-muted) !important;
  text-align: left !important;
}

.settings-overlay .settings-overlay-list {
  position: relative !important;
  left: 0 !important;
  top: 0 !important;
  right: auto !important;
  bottom: auto !important;
  transform: none !important;
  width: 100% !important;
  max-width: calc(100vw - 44px) !important;
  margin: 0 !important;
  padding: 0 0 calc(env(safe-area-inset-bottom, 0px) + 88px) !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: stretch !important;
  justify-content: flex-start !important;
  gap: 12px !important;
  box-sizing: border-box !important;
  overflow: visible !important;
}

.settings-overlay .settings-list-item {
  width: 100% !important;
  max-width: 100% !important;
  min-width: 0 !important;
  box-sizing: border-box !important;
  margin: 0 !important;
  padding: 14px !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: stretch !important;
  justify-content: flex-start !important;
  gap: 10px !important;
  border-radius: 20px !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  background:
    linear-gradient(180deg, rgba(13, 22, 42, 0.8), rgba(6, 11, 24, 0.72)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.06),
    0 14px 26px rgba(1, 8, 22, 0.18) !important;
}

.settings-overlay .settings-label,
.settings-overlay .in-list-label {
  width: 100% !important;
  max-width: 100% !important;
  margin: 0 !important;
  padding: 0 !important;
  font-family: var(--manaloom-display-font) !important;
  font-size: 20px !important;
  line-height: 1.05 !important;
  font-weight: 700 !important;
  letter-spacing: -0.01em !important;
  text-align: left !important;
  color: rgb(247, 241, 226) !important;
}

.settings-overlay .settings-select {
  width: 100% !important;
  max-width: 100% !important;
  min-height: 46px !important;
  box-sizing: border-box !important;
  margin: 0 !important;
  padding: 11px 13px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: flex-start !important;
  gap: 12px !important;
  border-radius: 15px !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  background:
    linear-gradient(180deg, rgba(15, 25, 47, 0.76), rgba(8, 13, 27, 0.72)) !important;
  color: rgba(247, 241, 226, 0.94) !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 15px !important;
  line-height: 1.15 !important;
  font-weight: 750 !important;
  text-align: left !important;
  white-space: normal !important;
  overflow-wrap: anywhere !important;
  word-break: normal !important;
}

.settings-overlay .settings-select.subentry {
  width: calc(100% - 18px) !important;
  margin-left: 18px !important;
  opacity: 0.92 !important;
}

.settings-overlay .settings-select.subsubentry {
  width: calc(100% - 36px) !important;
  margin-left: 36px !important;
  opacity: 0.86 !important;
}

.settings-overlay .settings-select > div {
  min-width: 0 !important;
  max-width: 100% !important;
  display: flex !important;
  flex-direction: column !important;
  gap: 3px !important;
  white-space: normal !important;
  overflow-wrap: anywhere !important;
}

.settings-overlay .settings-select span {
  display: block !important;
  max-width: 100% !important;
  color: var(--manaloom-shell-text-muted) !important;
  font-size: 12px !important;
  line-height: 1.2 !important;
  font-weight: 600 !important;
  white-space: normal !important;
  overflow-wrap: anywhere !important;
}

.settings-overlay .settings-select::before,
.settings-overlay .settings-select::after {
  flex: 0 0 auto !important;
}

.settings-overlay .close-settings-overlay-btn,
.life-history-overlay .close-life-history-overlay-btn,
.card-search-overlay .close-card-search-overlay {
  position: absolute !important;
  top: calc(env(safe-area-inset-top, 0px) + 18px) !important;
  right: 18px !important;
  width: 42px !important;
  height: 42px !important;
  border-radius: 15px !important;
  background:
    linear-gradient(180deg, rgba(16, 24, 44, 0.96), rgba(7, 12, 25, 0.94)) !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 12px 22px rgba(1, 8, 22, 0.24) !important;
  color: rgba(247, 241, 226, 0.92) !important;
}

.settings-overlay .close-settings-overlay-btn::before,
.settings-overlay .close-settings-overlay-btn::after,
.life-history-overlay .close-life-history-overlay-btn::before,
.life-history-overlay .close-life-history-overlay-btn::after,
.card-search-overlay .close-card-search-overlay::before,
.card-search-overlay .close-card-search-overlay::after {
  background: rgba(247, 241, 226, 0.92) !important;
}

.settings-overlay input,
.settings-overlay textarea,
.settings-overlay select,
.settings-overlay .input,
.life-history-overlay input,
.card-search-overlay input.search-input {
  min-height: 44px !important;
  box-sizing: border-box !important;
  border-radius: 14px !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  background:
    linear-gradient(180deg, rgba(13, 22, 42, 0.92), rgba(6, 11, 24, 0.9)) !important;
  color: rgba(247, 241, 226, 0.96) !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.06) !important;
}

.settings-overlay input::placeholder,
.settings-overlay textarea::placeholder,
.card-search-overlay input.search-input::placeholder {
  color: rgba(207, 215, 233, 0.5) !important;
}

.settings-overlay .btn,
.settings-overlay button,
.settings-overlay .set-value-btn,
.life-history-overlay .all-games-btn,
.life-history-overlay .set-value-btn,
.card-search-overlay label,
.card-search-overlay .view-all-prints-btn {
  min-height: 38px !important;
  border-radius: 999px !important;
  border: 1px solid var(--manaloom-shell-border-warm) !important;
  background:
    linear-gradient(180deg, rgba(216, 154, 47, 0.96), rgba(186, 126, 28, 0.96)) !important;
  color: #170f04 !important;
  font-weight: 800 !important;
  box-shadow:
    0 12px 22px rgba(216, 154, 47, 0.18),
    inset 0 1px 0 rgba(255, 255, 255, 0.18) !important;
}

.settings-overlay .restart-btn {
  background:
    linear-gradient(180deg, rgba(161, 61, 74, 0.96), rgba(104, 28, 42, 0.96)) !important;
  color: rgba(247, 241, 226, 0.96) !important;
  box-shadow:
    0 12px 22px rgba(104, 28, 42, 0.24),
    inset 0 1px 0 rgba(255, 255, 255, 0.14) !important;
}

.settings-overlay .restart-btn.inactive,
.settings-overlay .btn.inactive {
  background:
    linear-gradient(180deg, rgba(18, 27, 47, 0.82), rgba(8, 13, 27, 0.82)) !important;
  border-color: rgba(255, 255, 255, 0.1) !important;
  color: rgba(207, 215, 233, 0.5) !important;
  box-shadow: none !important;
}

.settings-overlay .toggle,
.settings-overlay .checkbox,
.settings-overlay .radio,
.settings-overlay [class*="toggle"],
.settings-overlay [class*="checkbox"],
.settings-overlay [class*="radio"] {
  border-color: rgba(120, 168, 255, 0.4) !important;
  box-shadow:
    inset 0 0 0 1px rgba(255, 255, 255, 0.08),
    0 0 0 1px rgba(7, 13, 26, 0.18) !important;
}

.settings-overlay .active,
.settings-overlay .selected,
.life-history-overlay .active,
.card-search-overlay label.active {
  color: rgb(247, 241, 226) !important;
}

.life-history-overlay {
  overflow: auto !important;
  padding-bottom: calc(env(safe-area-inset-bottom, 0px) + 28px) !important;
}

.life-history-overlay .life-history-header,
.life-history-overlay .history-meta-header,
.life-history-overlay .life-history-timeline,
.life-history-overlay .life-history-row,
.life-history-overlay .empty-timeline-overlay {
  background:
    linear-gradient(180deg, rgba(13, 22, 42, 0.78), rgba(6, 11, 24, 0.7)) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.06),
    0 14px 26px rgba(1, 8, 22, 0.2) !important;
}

.life-history-overlay .life-history-header,
.life-history-overlay .history-meta-header {
  border-radius: 22px !important;
  margin: 10px 12px 14px !important;
}

.life-history-overlay .life-history-row,
.life-history-overlay .empty-timeline-overlay {
  border-radius: 16px !important;
  margin-inline: 12px !important;
}

.life-history-overlay .life-history-cell,
.life-history-overlay .meta-value,
.life-history-overlay .player-name,
.life-history-overlay .stat-value,
.card-search-overlay .card-meta,
.card-search-overlay .artist-label {
  color: var(--manaloom-shell-text-muted) !important;
}

.life-history-overlay .change-cell.active.positive {
  color: rgba(78, 214, 145, 0.96) !important;
}

.life-history-overlay .change-cell.active.negative {
  color: rgba(255, 104, 130, 0.96) !important;
}

.card-search-overlay {
  align-items: stretch !important;
  justify-content: flex-end !important;
  padding:
    calc(env(safe-area-inset-top, 0px) + 72px) 18px
    calc(env(safe-area-inset-bottom, 0px) + 24px) !important;
  box-sizing: border-box !important;
}

.card-search-overlay:after {
  background:
    linear-gradient(180deg, rgba(4, 8, 18, 0.96), rgba(2, 6, 16, 0.98)) !important;
}

.card-search-overlay .giphy-switch {
  top: calc(env(safe-area-inset-top, 0px) + 20px) !important;
  left: 18px !important;
  background:
    linear-gradient(180deg, rgba(16, 24, 44, 0.96), rgba(7, 12, 25, 0.94)) !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  color: rgba(247, 241, 226, 0.9) !important;
}

.card-search-overlay .results-wrapper {
  width: 100% !important;
  height: auto !important;
  max-height: calc(100vh - 210px) !important;
  padding: 0 0 18px !important;
  gap: 14px !important;
  z-index: 2 !important;
}

.card-search-overlay .results-wrapper .card-image,
.card-search-overlay.menu-card-search .card-image-wrapper {
  border-radius: 18px !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  box-shadow: 0 14px 24px rgba(1, 8, 22, 0.32) !important;
}

.card-search-overlay input.search-input {
  position: relative !important;
  z-index: 3 !important;
  width: 100% !important;
  min-height: 48px !important;
  padding: 0 18px !important;
  font-size: 16px !important;
  text-align: left !important;
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
  background:
    linear-gradient(
      180deg,
      var(--manaloom-shell-accent-warm-strong),
      var(--manaloom-shell-accent-warm)
    ) !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 16px !important;
  font-weight: 800 !important;
  letter-spacing: 0.01em !important;
  color: #170f04 !important;
  box-shadow:
    0 14px 24px rgba(216, 154, 47, 0.22),
    inset 0 1px 0 rgba(255, 255, 255, 0.22) !important;
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
    radial-gradient(circle at 82% 0%, rgba(216, 154, 47, 0.12), transparent 34%),
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
  position: relative !important;
  z-index: 2 !important;
  width: 100% !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(16px, 4.8vw, 22px) !important;
  font-weight: 800 !important;
  line-height: 1 !important;
  letter-spacing: 0 !important;
  text-align: center !important;
  color: var(--manaloom-shell-text) !important;
}

.manaloom-proof-step {
  position: relative !important;
  z-index: 2 !important;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
  min-height: 28px !important;
  padding: 7px 12px !important;
  border: 1px solid var(--manaloom-shell-border-warm) !important;
  border-radius: 999px !important;
  background: rgba(216, 154, 47, 0.12) !important;
  color: var(--manaloom-shell-accent-warm-strong) !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 12px !important;
  font-weight: 900 !important;
  line-height: 1 !important;
  letter-spacing: 0.08em !important;
  text-transform: uppercase !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08) !important;
}

.manaloom-proof-body {
  position: relative !important;
  z-index: 2 !important;
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
  position: relative !important;
  z-index: 2 !important;
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
  isolation: isolate !important;
  opacity: 1 !important;
  background:
    radial-gradient(circle at 78% 0%, rgba(216, 154, 47, 0.13), transparent 30%),
    linear-gradient(180deg, rgb(10, 16, 30), rgb(5, 9, 20)) !important;
}

[data-manaloom-visual-proof="true"].commander-damage-overlay .font,
[data-manaloom-visual-proof="true"].own-commander-damage-hint-overlay .font,
[data-manaloom-visual-proof="true"].turn-tracker-hint-overlay .font,
[data-manaloom-visual-proof="true"].manaloom-turn-tracker-proof .font,
[data-manaloom-visual-proof="true"].show-counters-hint-overlay .font,
[data-manaloom-visual-proof="true"].manaloom-show-counters-proof .font {
  display: none !important;
}

[data-manaloom-visual-proof-backdrop="true"] {
  position: fixed !important;
  inset: 0 !important;
  z-index: 2147483646 !important;
  display: block !important;
  visibility: visible !important;
  opacity: 1 !important;
  pointer-events: none !important;
  background:
    radial-gradient(circle at 50% 20%, rgba(216, 154, 47, 0.08), transparent 34%),
    linear-gradient(180deg, rgb(6, 11, 23), rgb(3, 7, 17)) !important;
}

[data-manaloom-visual-proof="true"].commander-damage-overlay,
[data-manaloom-visual-proof="true"].own-commander-damage-hint-overlay,
[data-manaloom-visual-proof="true"].turn-tracker-hint-overlay,
[data-manaloom-visual-proof="true"].manaloom-turn-tracker-proof,
[data-manaloom-visual-proof="true"].show-counters-hint-overlay,
[data-manaloom-visual-proof="true"].manaloom-show-counters-proof {
  z-index: 2147483647 !important;
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
  flex-wrap: nowrap !important;
  gap: 10px !important;
}

.commander-damage-overlay .btn,
.own-commander-damage-hint-overlay .btn,
.turn-tracker-hint-overlay .btn,
.manaloom-turn-tracker-proof .btn,
.show-counters-hint-overlay .btn,
.manaloom-show-counters-proof .btn {
  flex: 1 1 0 !important;
  min-width: 0 !important;
  max-width: none !important;
  min-height: 44px !important;
  padding: 10px 12px !important;
  border-radius: 999px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  text-align: center !important;
  white-space: nowrap !important;
  overflow: hidden !important;
  text-overflow: clip !important;
  font-size: clamp(10px, 3vw, 13px) !important;
  line-height: 1 !important;
  letter-spacing: 0 !important;
  background:
    linear-gradient(
      180deg,
      var(--manaloom-shell-accent-warm-strong),
      var(--manaloom-shell-accent-warm)
    ) !important;
  color: #170f04 !important;
  box-shadow:
    0 12px 22px rgba(216, 154, 47, 0.24),
    inset 0 1px 0 rgba(255, 255, 255, 0.24) !important;
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
    fontSet.load('400 16px "Inter"').catch(() => {});
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
  document.body.classList.add('manaloom-visual-proof-active');
  document.getElementById('manaloom-visual-proof-isolation-style')?.remove();
  const isolationStyle = document.createElement('style');
  isolationStyle.id = 'manaloom-visual-proof-isolation-style';
  isolationStyle.textContent = `
    body.manaloom-visual-proof-active {
      background: linear-gradient(180deg, rgb(6, 11, 23), rgb(3, 7, 17)) !important;
    }
    body.manaloom-visual-proof-active .player-card,
    body.manaloom-visual-proof-active .menu-button,
    body.manaloom-visual-proof-active .turn-time-tracker,
    body.manaloom-visual-proof-active .game-timer,
    body.manaloom-visual-proof-active .current-time-clock,
    body.manaloom-visual-proof-active .close-controls-backdrop {
      visibility: hidden !important;
      opacity: 0 !important;
      pointer-events: none !important;
    }
    body.manaloom-visual-proof-active [data-manaloom-visual-proof="true"],
    body.manaloom-visual-proof-active [data-manaloom-visual-proof="true"] * {
      visibility: visible !important;
      opacity: 1 !important;
      pointer-events: auto !important;
    }
  `;
  document.head.appendChild(isolationStyle);

  Array.from(document.body.querySelectorAll('*')).forEach((node) => {
    if (!(node instanceof HTMLElement)) {
      return;
    }
    if (node.closest('[data-manaloom-visual-proof="true"]')) {
      return;
    }
    node.style.setProperty('visibility', 'hidden', 'important');
    node.style.setProperty('opacity', '0', 'important');
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
  const backdrop = document.createElement('div');
  backdrop.setAttribute('data-manaloom-visual-proof', 'true');
  backdrop.setAttribute('data-manaloom-visual-proof-backdrop', 'true');

  overlay.className = $overlayClassJson;
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.setAttribute('data-manaloom-visual-proof-key', $proofJson);
  overlay.innerHTML =
    '<div class="manaloom-proof-step">Etapa 1</div>' +
    '<div class="manaloom-proof-title">' + $titleJson + '</div>' +
    '<div class="manaloom-proof-body">' + $textJson + '</div>' +
    '<div class="manaloom-proof-actions">' + $buttonsHtmlJson + '</div>';

  document.body.appendChild(backdrop);
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
