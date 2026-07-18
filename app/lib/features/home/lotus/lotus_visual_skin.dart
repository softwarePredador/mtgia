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
  letter-spacing: 0;
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

${LotusDomSelectors.playerCard} .player-card-inner:not(.option-card):not(.color-card):not(.background-image) {
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
  letter-spacing: 0;
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

.switch-to-own-damage {
  background-color: rgba(5, 10, 23, 0.94) !important;
  border: 1px solid rgba(224, 165, 51, 0.82) !important;
  box-shadow:
    inset 0 0 0 1px rgba(255, 255, 255, 0.08),
    0 10px 24px rgba(0, 0, 0, 0.34) !important;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0;
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
  font-size: 10.5px !important;
  line-height: 1.12 !important;
  font-weight: 700 !important;
  letter-spacing: 0 !important;
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
  letter-spacing: 0 !important;
  color: rgb(247, 241, 226) !important;
  text-align: left !important;
}

.settings-overlay::before {
  content: "Configurações" !important;
}

.card-search-overlay::before {
  content: "Busca de cartas" !important;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0 !important;
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
  width: 44px !important;
  height: 44px !important;
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
.card-search-overlay label > div,
.card-search-overlay .view-all-prints-btn {
  min-height: 44px !important;
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

.life-history-overlay .all-games-btn {
  top: calc(env(safe-area-inset-top, 0px) + 18px) !important;
  right: 82px !important;
  max-width: calc(100% - 100px) !important;
  min-width: 0 !important;
  padding-inline: 14px !important;
  box-sizing: border-box !important;
  white-space: nowrap !important;
  overflow: hidden !important;
  text-overflow: ellipsis !important;
}

.life-history-overlay .history-meta-header {
  padding-top: calc(env(safe-area-inset-top, 0px) + 78px) !important;
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
  min-height: 44px !important;
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
  height: 44px !important;
  border-radius: 12px !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.12) !important;
}

.first-time-user-overlay .options-card .option-entry-text {
  font-family: var(--manaloom-ui-font) !important;
  font-size: 10px !important;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0;
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
  min-height: 44px;
  height: auto;
  padding: 10px 18px;
  font-family: var(--manaloom-ui-font) !important;
  font-size: clamp(14px, 4vw, 18px) !important;
  font-weight: 800;
  letter-spacing: 0;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0 !important;
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
  letter-spacing: 0;
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
  letter-spacing: 0;
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

/* ManaLoom tabletop restraint and accessibility pass. */
body {
  background: #02050b !important;
}

/*
 * Lotus encodes rotation in the selected layout, but ManaLoom runs the table
 * in landscape and must face each card toward its physical seat. Normalize
 * the stock transform first; the seat synchronizer below then assigns a
 * direction from the card's rendered row and column.
 */
${LotusDomSelectors.playerCard}.rotate-left .player-card-inner,
${LotusDomSelectors.playerCard}.rotate-right .player-card-inner {
  --sizeWidth: var(--width) !important;
  --sizeHeight: var(--height) !important;
  width: var(--width) !important;
  height: var(--height) !important;
  transform: none;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="opposite"] .player-card-inner,
${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="near"] .player-card-inner {
  --sizeWidth: var(--width) !important;
  --sizeHeight: var(--height) !important;
  width: var(--width) !important;
  height: var(--height) !important;
  transform: none;
  transform-origin: center !important;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="opposite"] .player-card-inner {
  rotate: 180deg !important;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="near"] .player-card-inner {
  rotate: 0deg !important;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="left"] .player-card-inner,
${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="right"] .player-card-inner {
  --sizeWidth: var(--height) !important;
  --sizeHeight: var(--width) !important;
  width: var(--height) !important;
  height: var(--width) !important;
  transform: none;
  transform-origin: center !important;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="left"] .player-card-inner {
  rotate: 90deg !important;
}

${LotusDomSelectors.playerCard}[data-manaloom-seat-facing="right"] .player-card-inner {
  rotate: -90deg !important;
}

${LotusDomSelectors.playerCard} .player-life-count,
${LotusDomSelectors.playerCard} .increase-button.life,
${LotusDomSelectors.playerCard} .decrease-button.life,
${LotusDomSelectors.playerCard} .counters-on-card .counter,
${LotusDomSelectors.playerCard} .counter-controls {
  writing-mode: horizontal-tb !important;
  text-orientation: mixed !important;
}

${LotusDomSelectors.playerCard} {
  filter: saturate(0.72) brightness(0.86) contrast(1.06);
  box-shadow:
    inset 0 0 0 1px var(--manaloom-player-accent-soft),
    0 4px 14px rgba(0, 0, 0, 0.24);
}

${LotusDomSelectors.playerCard} .player-card-inner:not(.option-card):not(.color-card):not(.background-image) {
  background:
    linear-gradient(145deg, rgba(2, 6, 15, 0.38), rgba(2, 6, 15, 0.7)),
    var(--bg, rgb(16, 23, 38)) !important;
  background-blend-mode: multiply, normal !important;
  box-shadow:
    inset 0 0 0 1px var(--manaloom-player-accent-soft),
    inset 0 -22px 34px rgba(1, 5, 13, 0.28) !important;
}

${LotusDomSelectors.playerCard} .increase-button.life,
${LotusDomSelectors.playerCard} .decrease-button.life {
  background: transparent !important;
  box-shadow: none !important;
  touch-action: manipulation;
  transition: background-color 100ms ease-out !important;
}

${LotusDomSelectors.playerCard} .player-card-inner.background-image .increase-button.life,
${LotusDomSelectors.playerCard} .player-card-inner.background-image .decrease-button.life {
  background:
    linear-gradient(180deg, rgba(1, 4, 10, 0.58), rgba(1, 4, 10, 0.66))
    !important;
}

${LotusDomSelectors.playerCard} .increase-button.life:after,
${LotusDomSelectors.playerCard} .decrease-button.life:after {
  font-size: clamp(28px, 10vw, 56px);
  color: rgba(247, 241, 226, 0.38);
  text-shadow: 0 3px 12px rgba(0, 0, 0, 0.4);
}

${LotusDomSelectors.playerCard} .increase-button.life,
${LotusDomSelectors.playerCard} .decrease-button.life,
${LotusDomSelectors.playerCard} .increase-button.life .font,
${LotusDomSelectors.playerCard} .decrease-button.life .font,
${LotusDomSelectors.playerCard} .increase-button.life .char-plus,
${LotusDomSelectors.playerCard} .decrease-button.life .char-minus {
  --fontColor: rgba(247, 241, 226, 0.78) !important;
  color: rgba(247, 241, 226, 0.78) !important;
  fill: rgba(247, 241, 226, 0.78) !important;
  stroke: rgba(247, 241, 226, 0.78) !important;
  -webkit-text-fill-color: rgba(247, 241, 226, 0.78) !important;
  filter: none !important;
}

${LotusDomSelectors.playerCard} .increase-button.life:active,
${LotusDomSelectors.playerCard} .decrease-button.life:active {
  background: rgba(255, 255, 255, 0.075) !important;
}

${LotusDomSelectors.playerCard} .player-life-count,
${LotusDomSelectors.playerCard} .player-life-count .font {
  filter: none !important;
  text-shadow: 0 6px 16px rgba(0, 0, 0, 0.46) !important;
}

.list::before,
.list::after {
  display: none !important;
}

.list > * .btn,
.list > *.players .btn,
.list > *.restart .btn,
.list > *.settings .btn,
.list > *.more .btn,
.list > *.high-roll .btn {
  border-color: rgba(255, 255, 255, 0.14) !important;
  background: rgb(8, 14, 27) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 5px 12px rgba(0, 0, 0, 0.26) !important;
  backdrop-filter: none !important;
  transition:
    transform 120ms ease-out,
    background-color 120ms ease-out !important;
}

.list > * .btn:active {
  transform: scale(0.94) !important;
  background: rgb(14, 23, 41) !important;
}

.manaloom-life-counter-exit {
  position: fixed !important;
  top: calc(env(safe-area-inset-top, 0px) + 12px) !important;
  left: calc(env(safe-area-inset-left, 0px) + 12px) !important;
  z-index: 121 !important;
  width: 48px !important;
  height: 48px !important;
  display: none !important;
  align-items: center !important;
  justify-content: center !important;
  padding: 0 !important;
  border: 1px solid rgba(255, 255, 255, 0.14) !important;
  border-radius: 12px !important;
  background: rgba(5, 10, 21, 0.96) !important;
  color: rgba(247, 241, 226, 0.94) !important;
  font-family: var(--manaloom-ui-font) !important;
  font-size: 24px !important;
  line-height: 1 !important;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.26) !important;
  touch-action: manipulation !important;
  appearance: none !important;
  -webkit-appearance: none !important;
}

.manaloom-life-counter-exit.is-visible {
  display: flex !important;
}

/* Keep table management separate from the game-state shortcut deck. */
.menu-button.active .list {
  position: fixed !important;
  inset: auto !important;
  left: -80px !important;
  top: -168px !important;
  width: 320px !important;
  height: 58px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  gap: 8px !important;
  transform: none !important;
  z-index: 122 !important;
}

.menu-button.active .list > * {
  position: relative !important;
  inset: auto !important;
  width: 56px !important;
  height: 56px !important;
  transform: none !important;
  animation: none !important;
}

.menu-button.active .list > * .btn {
  width: 56px !important;
  height: 56px !important;
  min-width: 56px !important;
  min-height: 56px !important;
  transform: none !important;
  border-radius: 10px !important;
  background-color: rgb(9, 16, 30) !important;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.12) !important;
}

.menu-button-overlay .game-states-wrapper {
  width: min(390px, calc(100vw - 20px)) !important;
  gap: 6px !important;
  padding:
    9px 10px calc(env(safe-area-inset-bottom, 0px) + 9px) !important;
  background: rgba(4, 9, 19, 0.97) !important;
  border-color: rgba(255, 255, 255, 0.1) !important;
  border-radius: 14px !important;
  box-shadow: 0 -8px 18px rgba(0, 0, 0, 0.28) !important;
  backdrop-filter: none !important;
}

.menu-button-overlay .game-states-wrapper > * {
  width: 66px !important;
  min-width: 66px !important;
  height: 64px !important;
  min-height: 64px !important;
  max-height: 64px !important;
  flex-basis: 66px !important;
  padding: 8px 5px !important;
  box-sizing: border-box !important;
  overflow: hidden !important;
  font-size: 11px !important;
  line-height: 1.15 !important;
  background: rgb(9, 16, 30) !important;
  border-color: rgba(255, 255, 255, 0.1) !important;
  border-radius: 10px !important;
  box-shadow: none !important;
}

.menu-button-overlay .game-states-wrapper > *.active {
  color: rgb(255, 239, 199) !important;
  background: rgb(29, 23, 18) !important;
  border-color: rgb(224, 165, 51) !important;
  box-shadow: inset 0 0 0 2px rgba(224, 165, 51, 0.32) !important;
}

@media (min-width: 600px) and (orientation: landscape) {
  .menu-button-overlay .game-states-wrapper {
    width: min(620px, calc(100vw - 32px)) !important;
    display: grid !important;
    grid-template-columns: repeat(5, minmax(0, 1fr)) !important;
    grid-auto-rows: 64px !important;
  }

  .menu-button-overlay .game-states-wrapper > * {
    width: auto !important;
    min-width: 0 !important;
    max-width: none !important;
    height: 64px !important;
    min-height: 64px !important;
    max-height: 64px !important;
    overflow-wrap: normal !important;
    word-break: normal !important;
    hyphens: none !important;
  }
}

@media (max-width: 480px) {
  .menu-button-overlay .game-states-wrapper {
    width: min(330px, calc(100vw - 16px)) !important;
  }

  .life-history-overlay .all-games-btn {
    font-size: 15px !important;
  }

  .menu-button-overlay .game-states-wrapper > * {
    width: calc((100% - 12px) / 3) !important;
    min-width: 0 !important;
    flex: 0 0 calc((100% - 12px) / 3) !important;
    font-size: 10.5px !important;
    word-break: normal !important;
    overflow-wrap: normal !important;
    hyphens: manual !important;
  }
}

.settings-overlay,
.life-history-overlay,
.card-search-overlay {
  background: rgb(3, 8, 18) !important;
}

.settings-overlay::before {
  content: "Configurações" !important;
}

.settings-overlay .settings-headline::after {
  content: "Preferências da mesa" !important;
}

.card-search-overlay::before {
  content: "Busca de cartas" !important;
  top: max(
    calc(env(safe-area-inset-top, 0px) + 24px),
    72px
  ) !important;
}

.settings-overlay .settings-overlay-list {
  gap: 0 !important;
}

.settings-overlay .settings-list-item {
  padding: 14px 0 !important;
  border: 0 !important;
  border-top: 1px solid rgba(255, 255, 255, 0.09) !important;
  border-radius: 0 !important;
  background: transparent !important;
  box-shadow: none !important;
}

.settings-overlay .settings-select {
  min-height: 48px !important;
  border-radius: 10px !important;
  background: rgb(9, 16, 30) !important;
  box-shadow: none !important;
}

.life-history-overlay .life-history-header,
.life-history-overlay .history-meta-header,
.life-history-overlay .life-history-timeline,
.life-history-overlay .life-history-row,
.life-history-overlay .empty-timeline-overlay {
  background: rgb(7, 13, 26) !important;
  border-color: rgba(255, 255, 255, 0.09) !important;
  box-shadow: none !important;
}

.settings-overlay .close-settings-overlay-btn,
.life-history-overlay .close-life-history-overlay-btn,
.card-search-overlay .close-card-search-overlay {
  width: 48px !important;
  height: 48px !important;
  border-radius: 12px !important;
  background: rgb(9, 16, 30) !important;
  box-shadow: none !important;
}

.settings-overlay .btn,
.settings-overlay button,
.settings-overlay .set-value-btn,
.life-history-overlay .all-games-btn,
.life-history-overlay .set-value-btn,
.card-search-overlay label > div,
.card-search-overlay .view-all-prints-btn {
  min-height: 48px !important;
  border-radius: 12px !important;
  background: rgb(224, 165, 51) !important;
  box-shadow: none !important;
}

.first-time-user-overlay .options-card .option-entry-text {
  font-size: 11px !important;
  line-height: 1.18 !important;
}

.first-time-user-overlay > .btn,
.first-time-user-overlay .commander-card .button,
.commander-damage-overlay .btn,
.own-commander-damage-hint-overlay .btn,
.turn-tracker-hint-overlay .btn,
.manaloom-turn-tracker-proof .btn,
.show-counters-hint-overlay .btn,
.manaloom-show-counters-proof .btn,
.max-game-modes-warning .close,
.input-overlay .btn {
  min-height: 48px !important;
}

.commander-damage-overlay,
.own-commander-damage-hint-overlay,
.turn-tracker-hint-overlay,
.manaloom-turn-tracker-proof,
.show-counters-hint-overlay,
.manaloom-show-counters-proof,
.max-game-modes-warning,
.input-overlay {
  border-radius: 16px !important;
  background: rgb(7, 13, 26) !important;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.32) !important;
}

${LotusDomSelectors.mainGameTimer},
${LotusDomSelectors.currentTimeClock},
${LotusDomSelectors.turnTracker} {
  background: rgba(5, 10, 21, 0.94) !important;
  border-color: rgba(255, 255, 255, 0.12) !important;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.24) !important;
  backdrop-filter: none !important;
}

.dice-overlay .rng-list .roller.custom .roll-btn {
  width: 84px !important;
  min-width: 84px !important;
  font-size: 18px !important;
  line-height: 1 !important;
  white-space: nowrap !important;
}

.dice-overlay .rng-list .roller.custom .roll-btn::after {
  width: 94px !important;
}

[role="button"]:focus-visible,
button:focus-visible,
input:focus-visible,
select:focus-visible,
textarea:focus-visible {
  outline: 3px solid var(--manaloom-shell-accent-warm-strong) !important;
  outline-offset: 3px !important;
}

@media (orientation: landscape) and (min-width: 640px) {
  .settings-overlay .settings-overlay-list {
    display: grid !important;
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    column-gap: 22px !important;
  }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
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

  const existingAccessibility = window.__ManaLoomLifeCounterAccessibility;
  if (existingAccessibility && typeof existingAccessibility.sync === 'function') {
    existingAccessibility.sync();
    return;
  }

  const setAttributeIfChanged = (node, name, value) => {
    if (!(node instanceof HTMLElement) || node.getAttribute(name) === value) {
      return;
    }
    node.setAttribute(name, value);
  };

  const readableText = (node) => {
    if (!(node instanceof HTMLElement)) {
      return '';
    }
    const inputValue = node instanceof HTMLInputElement ? node.value : '';
    return String(inputValue || node.textContent || '').replace(/\\s+/g, ' ').trim();
  };

  const ptBrText = new Map([
    ['Settings', 'Configurações'],
    ['Restart Game', 'Reiniciar partida'],
    ['Restart', 'Reiniciar'],
    ['History', 'Histórico'],
    ['Current Game', 'Partida atual'],
    ['All Games', 'Todas as partidas'],
    ['Previous Games', 'Partidas anteriores'],
    ['Winner', 'Vencedor'],
    ['No Winner', 'Sem vencedor'],
    ['Select Winner', 'Selecionar vencedor'],
    ['Set Winner', 'Definir vencedor'],
    ['Victory', 'Vitória'],
    ['Defeated', 'Eliminado'],
    ['Save', 'Salvar'],
    ['Saved', 'Salvo'],
    ['Cancel', 'Cancelar'],
    ['Confirm', 'Confirmar'],
    ['Done', 'Concluir'],
    ['Back', 'Voltar'],
    ['Return to Game', 'Voltar à partida'],
    ['Delete', 'Excluir'],
    ['Delete Game', 'Excluir partida'],
    ['Delete this game from history?', 'Excluir esta partida do histórico?'],
    ['Edit', 'Editar'],
    ['Share', 'Compartilhar'],
    ['Restore', 'Restaurar'],
    ['Yes', 'Sim'],
    ['Players', 'Jogadores'],
    ['Player', 'Jogador'],
    ['Player Card', 'Painel do jogador'],
    ['Player Card Layout', 'Layout dos jogadores'],
    ['Player Card Direction', 'Orientação dos jogadores'],
    ['Starting Life', 'Vida inicial'],
    ['Two-player starting life', 'Vida inicial para dois jogadores'],
    ['Multi-player starting life', 'Vida inicial para vários jogadores'],
    ['Set Life', 'Definir vida'],
    ['Set Life Manually', 'Definir vida manualmente'],
    ['Set Custom Starting Life', 'Definir vida inicial personalizada'],
    ['Commander damage', 'Dano de comandante'],
    ['Partner', 'Parceiro'],
    ['Partners', 'Parceiros'],
    ['Background', 'Aparência'],
    ['Customize', 'Personalizar'],
    ['Reset Player Background Colors', 'Restaurar cores dos jogadores'],
    ['Card Search', 'Busca de cartas'],
    ['Search for a card', 'Buscar uma carta'],
    ['Search for a gif', 'Buscar um GIF'],
    ['Cards', 'Cartas'],
    ['View all prints', 'Ver todas as edições'],
    ['View card', 'Ver carta'],
    ['Upload Image', 'Enviar imagem'],
    ['Change Background Image', 'Alterar imagem de fundo'],
    ['Set Background Image', 'Definir imagem de fundo'],
    ['Set Partner Background Image', 'Definir fundo do parceiro'],
    ['Load Profile', 'Carregar perfil'],
    ['Save Profile', 'Salvar perfil'],
    ['Delete Profile', 'Excluir perfil'],
    ['Share Profile', 'Compartilhar perfil'],
    ['Profiles', 'Perfis'],
    ['Edit Profiles', 'Editar perfis'],
    ['Import', 'Importar'],
    ['Export All', 'Exportar tudo'],
    ['Export All Profiles', 'Exportar todos os perfis'],
    ['Import Profile', 'Importar perfil'],
    ['Profile code', 'Código do perfil'],
    ['Paste profile code', 'Cole o código do perfil'],
    ['How it works', 'Como funciona'],
    ['Help', 'Ajuda'],
    ['Game Modes', 'Modos de jogo'],
    ['Game Duration', 'Duração da partida'],
    ['Game Timeline', 'Linha do tempo'],
    ['Turns', 'Turnos'],
    ['Dice', 'Dados'],
    ['Roll', 'Rolar'],
    ['High Roll', 'Maior rolagem'],
    ['Heads', 'Cara'],
    ['Tails', 'Coroa'],
    ['Day/Night', 'Dia/Noite'],
    ['Monarch', 'Monarca'],
    ['Initiative', 'Iniciativa'],
    ['Archenemy', 'Arqui-inimigo'],
    ['Bounty', 'Recompensa'],
    ['Claim', 'Reivindicar'],
    ['Flip', 'Virar'],
    ['Previous', 'Anterior'],
    ['Next', 'Próximo'],
    ['Format', 'Formato'],
    ['Set Format', 'Definir formato'],
    ['View all formats', 'Ver todos os formatos'],
    ['Gameplay', 'Partida'],
    ['Support', 'Suporte'],
    ['Review', 'Avaliar'],
    ['Leave a Review', 'Deixar uma avaliação'],
    ['Got Feedback?', 'Quer enviar feedback?'],
    ['Enjoying Lotus?', 'Gostando do contador?'],
    ['Okay, got it', 'Entendi'],
    ['Got it!', 'Entendi!'],
    ['Good to know!', 'Bom saber!'],
    ['Alright!', 'Certo!'],
    ['Pinch to zoom • Drag to reposition', 'Aperte para ampliar • arraste para ajustar'],
    ['Are you sure you want to restart the game?', 'Deseja reiniciar a partida?'],
    ['Do you want to revive the killed player?', 'Deseja trazer o jogador eliminado de volta?'],
    ['Revive', 'Trazer de volta'],
    ['Kill', 'Eliminar'],
    ['Unkill', 'Restaurar jogador'],
    ['No life total changes in this game.', 'Nenhuma mudança de vida nesta partida.'],
    ['No life total changes so far.', 'Nenhuma mudança de vida até agora.'],
    ['Maximum 2 game modes can be active at once. Please disable one first.', 'No máximo dois modos podem ficar ativos. Desative um antes de continuar.'],
  ]);

  const settingNamesPtBr = new Map([
    ['Auto-Kill', 'Nocaute automático'],
    ['Clean Look', 'Visual limpo'],
    ['Clickable Commander Damage Counters', 'Dano de comandante interativo'],
    ['Clock on Main Screen', 'Relógio na mesa'],
    ['Custom Long Tap', 'Toque longo personalizado'],
    ['Cycle Salty Defeat Messages', 'Alternar mensagens de eliminação'],
    ['Game Timer', 'Cronômetro da partida'],
    ['Game Timer on Main Screen', 'Cronômetro na mesa'],
    ['Keep Zero Counters on Player Card', 'Manter marcadores zerados'],
    ['Low Health Warning', 'Aviso de vida baixa'],
    ['Preserve Background Images On Shuffle', 'Preservar fundos ao embaralhar'],
    ['Random Player Colors', 'Cores aleatórias dos jogadores'],
    ['Salty Defeat Messages', 'Mensagens de eliminação'],
    ['Set Life By Tapping Number', 'Definir vida tocando no número'],
    ['Show Commander Damage Counters on Player Card', 'Mostrar dano de comandante no painel'],
    ['Show Counters on Player Card', 'Mostrar marcadores no painel'],
    ['Show Regular Counters on Player Card', 'Mostrar marcadores comuns no painel'],
    ['Turn Timer', 'Cronômetro do turno'],
    ['Turn Tracker', 'Controle de turnos'],
    ['Vertical Tap Areas', 'Áreas de toque verticais'],
  ]);

  const translateKnownText = (value) => {
    const normalized = String(value || '').replace(/\\s+/g, ' ').trim();
    if (!normalized) {
      return normalized;
    }
    const direct = ptBrText.get(normalized);
    if (direct) {
      return direct;
    }
    const playerMatch = normalized.match(/^Player\\s+(\\d+)\$/i);
    if (playerMatch) {
      return 'Jogador ' + playerMatch[1];
    }
    const previousGamesMatch = normalized.match(/^Previous Games\\s*(\\d*)\$/i);
    if (previousGamesMatch) {
      return 'Partidas anteriores' + (previousGamesMatch[1] ? ' ' + previousGamesMatch[1] : '');
    }
    const toggleMatch = normalized.match(/^(.+):\\s*(Enable|Disable)\$/);
    if (toggleMatch) {
      const settingName = settingNamesPtBr.get(toggleMatch[1]) || ptBrText.get(toggleMatch[1]);
      if (settingName) {
        return settingName + ': ' + (toggleMatch[2] === 'Enable' ? 'ativar' : 'desativar');
      }
    }
    const startingLifeMatch = normalized.match(/^Set Starting Life:\\s*(.+)\$/);
    if (startingLifeMatch) {
      return 'Definir vida inicial: ' + startingLifeMatch[1];
    }
    return normalized;
  };

  const syncPtBrCopy = () => {
    document.documentElement.lang = 'pt-BR';
    document.title = 'ManaLoom • Contador de vida';
    const roots = document.querySelectorAll([
      '.menu-button-overlay',
      '.settings-overlay',
      '.life-history-overlay',
      '.card-search-overlay',
      '.commander-damage-overlay',
      '.first-time-user-overlay',
      '.custom-life-overlay',
      '.input-overlay',
      '.confirm-overlay',
      '.load-profile-overlay',
      '.game-modes-overlay',
      '.dice-overlay',
      '.winner-overlay',
      '.killed-overlay',
    ].join(','));
    roots.forEach((root) => {
      const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
      let textNode = walker.nextNode();
      while (textNode) {
        const raw = textNode.nodeValue || '';
        const trimmed = raw.trim();
        let translated = translateKnownText(trimmed);
        const parent = textNode.parentElement;
        if (
          translated === trimmed &&
          parent instanceof HTMLElement &&
          parent.classList.contains('text') &&
          parent.closest('.winner-overlay, .killed-overlay')
        ) {
          translated = parent.closest('.winner-overlay') ? 'Vitória!' : 'Jogador eliminado';
        }
        if (trimmed && translated !== trimmed) {
          textNode.nodeValue = raw.replace(trimmed, translated);
        }
        textNode = walker.nextNode();
      }
      root.querySelectorAll('input[placeholder], textarea[placeholder]').forEach((input) => {
        const translated = translateKnownText(input.getAttribute('placeholder'));
        if (translated) {
          input.setAttribute('placeholder', translated);
        }
      });
      root.querySelectorAll('[title]').forEach((node) => {
        const translated = translateKnownText(node.getAttribute('title'));
        if (translated) {
          node.setAttribute('title', translated);
        }
      });
    });
    document.querySelectorAll('.player-name, .player-name-input').forEach((node) => {
      if (node instanceof HTMLInputElement) {
        const translated = translateKnownText(node.value);
        if (translated !== node.value) node.value = translated;
      } else {
        const translated = translateKnownText(node.textContent);
        if (translated && translated !== node.textContent) node.textContent = translated;
      }
    });
  };

  const decodeVisualNumber = (node) => {
    if (!(node instanceof HTMLElement)) {
      return '';
    }
    return Array.from(node.querySelectorAll('.font')).map((digit) => {
      const charClass = Array.from(digit.classList).find((className) => {
        return className.startsWith('char-');
      });
      if (!charClass) {
        return '';
      }
      const charName = charClass.substring('char-'.length);
      if (charName === 'plus') {
        return '+';
      }
      if (charName === 'minus') {
        return '-';
      }
      return charName;
    }).join('');
  };

  const dispatchAccessibleTap = (node) => {
    if (!(node instanceof HTMLElement)) {
      return;
    }
    const bounds = node.getBoundingClientRect();
    const eventInit = {
      bubbles: true,
      cancelable: true,
      pointerId: 1,
      pointerType: 'touch',
      isPrimary: true,
      button: 0,
      buttons: 1,
      clientX: bounds.left + bounds.width / 2,
      clientY: bounds.top + bounds.height / 2,
    };
    const downEvent =
      typeof PointerEvent === 'function'
        ? new PointerEvent('pointerdown', eventInit)
        : new MouseEvent('mousedown', eventInit);
    const upEvent =
      typeof PointerEvent === 'function'
        ? new PointerEvent('pointerup', { ...eventInit, buttons: 0 })
        : new MouseEvent('mouseup', { ...eventInit, buttons: 0 });
    node.dispatchEvent(downEvent);
    node.dispatchEvent(upEvent);
  };

  const bindKeyboardAction = (node, action) => {
    if (!(node instanceof HTMLElement) || node.dataset.manaloomKeyboardBound === 'true') {
      return;
    }
    node.dataset.manaloomKeyboardBound = 'true';
    node.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter' && event.key !== ' ') {
        return;
      }
      event.preventDefault();
      action();
    });
  };

  let activeDialog = null;
  let restoreFocusNode = null;
  let playerLayoutObserver = null;
  const tabletopSeatFacing = Object.freeze({
    opposite: 'opposite',
    near: 'near',
    left: 'left',
    right: 'right',
  });
  const tabletopPlayerCountMin = 2;
  const tabletopPlayerCountMax = 6;
  const dialogFocusableSelector = [
    'button:not([disabled])',
    'input:not([disabled])',
    'select:not([disabled])',
    'textarea:not([disabled])',
    '[role="button"][tabindex="0"]',
    '[tabindex]:not([tabindex="-1"])',
  ].join(',');

  const bindDialogKeyboard = (dialog) => {
    if (!(dialog instanceof HTMLElement) || dialog.dataset.manaloomDialogBound === 'true') {
      return;
    }
    dialog.dataset.manaloomDialogBound = 'true';
    dialog.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        const isMenuDialog = dialog.matches('.menu-button-overlay');
        let closeButton = dialog.querySelector(
          '.overlay-close-btn, [class*="close-"], .cancel, .btn.cancel',
        );
        if (
          !(closeButton instanceof HTMLElement) &&
          isMenuDialog
        ) {
          closeButton = document.querySelector(
            ${jsonEncode(LotusDomSelectors.menuButton)},
          );
        }
        if (closeButton instanceof HTMLElement) {
          event.preventDefault();
          event.stopPropagation();
          closeButton.click();
          if (isMenuDialog) {
            const menuTrigger = document.querySelector(
              ${jsonEncode(LotusDomSelectors.menuButton)},
            );
            if (menuTrigger instanceof HTMLElement) {
              menuTrigger.focus({ preventScroll: true });
              requestAnimationFrame(() => {
                if (menuTrigger.isConnected) {
                  menuTrigger.focus({ preventScroll: true });
                }
              });
            }
          }
        }
        return;
      }
      if (event.key !== 'Tab') {
        return;
      }
      const focusable = Array.from(dialog.querySelectorAll(dialogFocusableSelector)).filter(
        (node) => node instanceof HTMLElement && getComputedStyle(node).display !== 'none',
      );
      if (focusable.length === 0) {
        event.preventDefault();
        dialog.focus({ preventScroll: true });
        return;
      }
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });
  };

  const syncDialogFocus = (dialogs) => {
    const visibleDialogs = dialogs.filter((dialog) => {
      return (
        dialog instanceof HTMLElement &&
        !dialog.classList.contains('hidden') &&
        getComputedStyle(dialog).display !== 'none' &&
        getComputedStyle(dialog).visibility !== 'hidden'
      );
    });
    const nextDialog = visibleDialogs.length === 0
      ? null
      : visibleDialogs[visibleDialogs.length - 1];
    if (nextDialog === activeDialog) {
      return;
    }

    if (nextDialog instanceof HTMLElement) {
      if (!(activeDialog instanceof HTMLElement)) {
        const menuTrigger = nextDialog.matches('.menu-button-overlay')
          ? document.querySelector(${jsonEncode(LotusDomSelectors.menuButton)})
          : null;
        if (menuTrigger instanceof HTMLElement) {
          restoreFocusNode = menuTrigger;
        } else if (document.activeElement instanceof HTMLElement) {
          restoreFocusNode = document.activeElement;
        }
      }
      activeDialog = nextDialog;
      requestAnimationFrame(() => {
        if (!(activeDialog instanceof HTMLElement) || activeDialog !== nextDialog) {
          return;
        }
        if (nextDialog.contains(document.activeElement)) {
          return;
        }
        const firstFocusable = nextDialog.querySelector(dialogFocusableSelector);
        (firstFocusable instanceof HTMLElement ? firstFocusable : nextDialog).focus({
          preventScroll: true,
        });
      });
      return;
    }

    const closedDialog = activeDialog;
    activeDialog = null;
    let focusTarget =
      restoreFocusNode instanceof HTMLElement && restoreFocusNode.isConnected
        ? restoreFocusNode
        : null;
    if (
      !(focusTarget instanceof HTMLElement) &&
      closedDialog instanceof HTMLElement &&
      closedDialog.matches('.menu-button-overlay')
    ) {
      focusTarget = document.querySelector(
        ${jsonEncode(LotusDomSelectors.menuButton)},
      );
    }
    restoreFocusNode = null;
    if (focusTarget instanceof HTMLElement) {
      requestAnimationFrame(() => {
        if (activeDialog === null && focusTarget.isConnected) {
          focusTarget.focus({ preventScroll: true });
        }
      });
    }
  };

  const clearTabletopSeat = (card) => {
    if (!(card instanceof HTMLElement)) {
      return;
    }
    delete card.dataset.manaloomSeatFacing;
    delete card.dataset.manaloomSeatRow;
    delete card.dataset.manaloomSeatPosition;
  };

  const findTabletopPlayerCards = (playerCards) => {
    const groups = new Map();
    playerCards.forEach((card) => {
      if (
        !(card instanceof HTMLElement) ||
        !(card.parentElement instanceof HTMLElement) ||
        card.closest('[class*="overlay"], [data-manaloom-visual-proof="true"]') !== null
      ) {
        return;
      }
      const siblings = groups.get(card.parentElement) || [];
      siblings.push(card);
      groups.set(card.parentElement, siblings);
    });

    return Array.from(groups.values())
      .filter((cards) => {
        return cards.length >= tabletopPlayerCountMin &&
          cards.length <= tabletopPlayerCountMax;
      })
      .map((cards) => ({
        cards,
        visibleArea: cards.reduce((area, card) => {
          const bounds = card.getBoundingClientRect();
          return area + Math.max(0, bounds.width) * Math.max(0, bounds.height);
        }, 0),
      }))
      .filter((group) => group.visibleArea > 0)
      .sort((left, right) => right.visibleArea - left.visibleArea)[0]?.cards || [];
  };

  const groupTabletopRows = (cards) => {
    const measuredCards = cards
      .map((card) => ({ card, bounds: card.getBoundingClientRect() }))
      .filter(({ bounds }) => bounds.width > 0 && bounds.height > 0)
      .sort((left, right) => {
        const verticalDelta = left.bounds.top - right.bounds.top;
        return Math.abs(verticalDelta) > 2
          ? verticalDelta
          : left.bounds.left - right.bounds.left;
      });
    if (measuredCards.length !== cards.length) {
      return [];
    }

    const rowTolerance = Math.max(
      2,
      Math.min(...measuredCards.map(({ bounds }) => bounds.height)) * 0.12,
    );
    const rows = [];
    measuredCards.forEach((entry) => {
      const currentRow = rows[rows.length - 1];
      if (!currentRow || Math.abs(currentRow.top - entry.bounds.top) > rowTolerance) {
        rows.push({ top: entry.bounds.top, entries: [entry] });
        return;
      }
      currentRow.entries.push(entry);
      currentRow.top = currentRow.entries.reduce(
        (sum, item) => sum + item.bounds.top,
        0,
      ) / currentRow.entries.length;
    });
    rows.forEach((row) => {
      row.entries.sort((left, right) => left.bounds.left - right.bounds.left);
    });
    return rows;
  };

  const setTabletopSeat = (entry, facing, rowIndex, positionIndex) => {
    entry.card.dataset.manaloomSeatFacing = facing;
    entry.card.dataset.manaloomSeatRow = String(rowIndex + 1);
    entry.card.dataset.manaloomSeatPosition = String(positionIndex + 1);
  };

  const syncTabletopSeatLayout = (playerCards = Array.from(
    document.querySelectorAll(${jsonEncode(LotusDomSelectors.playerCard)}),
  )) => {
    const tableCards = findTabletopPlayerCards(playerCards);
    const tableCardSet = new Set(tableCards);
    playerCards.forEach((card) => {
      if (!tableCardSet.has(card)) {
        clearTabletopSeat(card);
      }
    });
    const rows = groupTabletopRows(tableCards);
    if (rows.length === 0) {
      tableCards.forEach(clearTabletopSeat);
      return [];
    }

    const tableBounds = tableCards.reduce(
      (bounds, card) => {
        const cardBounds = card.getBoundingClientRect();
        return {
          left: Math.min(bounds.left, cardBounds.left),
          right: Math.max(bounds.right, cardBounds.right),
        };
      },
      { left: Number.POSITIVE_INFINITY, right: Number.NEGATIVE_INFINITY },
    );
    const tableCenterX = (tableBounds.left + tableBounds.right) / 2;

    rows.forEach((row, rowIndex) => {
      row.entries.forEach((entry, positionIndex) => {
        let facing;
        if (rows.length === 1) {
          const cardCenterX = entry.bounds.left + entry.bounds.width / 2;
          facing = cardCenterX <= tableCenterX
            ? tabletopSeatFacing.left
            : tabletopSeatFacing.right;
        } else if (rowIndex === 0) {
          facing = tabletopSeatFacing.opposite;
        } else if (rowIndex === rows.length - 1) {
          facing = tabletopSeatFacing.near;
        } else {
          const cardCenterX = entry.bounds.left + entry.bounds.width / 2;
          facing = cardCenterX <= tableCenterX
            ? tabletopSeatFacing.left
            : tabletopSeatFacing.right;
        }
        setTabletopSeat(entry, facing, rowIndex, positionIndex);
      });
    });

    return tableCards.map((card) => {
      const panel = card.querySelector('.player-card-inner');
      const cardBounds = card.getBoundingClientRect();
      const panelBounds = panel instanceof HTMLElement
        ? panel.getBoundingClientRect()
        : null;
      const panelStyle = panel instanceof HTMLElement
        ? getComputedStyle(panel)
        : null;
      return {
        facing: card.dataset.manaloomSeatFacing || null,
        row: Number.parseInt(card.dataset.manaloomSeatRow || '0', 10),
        position: Number.parseInt(card.dataset.manaloomSeatPosition || '0', 10),
        rotation: panelStyle?.rotate || null,
        cardWidth: cardBounds.width,
        cardHeight: cardBounds.height,
        panelWidth: panelBounds?.width || 0,
        panelHeight: panelBounds?.height || 0,
        panelFits: panelBounds !== null &&
          panelBounds.left >= cardBounds.left - 2 &&
          panelBounds.right <= cardBounds.right + 2 &&
          panelBounds.top >= cardBounds.top - 2 &&
          panelBounds.bottom <= cardBounds.bottom + 2,
      };
    });
  };

  const syncAccessibility = () => {
    syncPtBrCopy();

    const playerCards = Array.from(document.querySelectorAll(
      ${jsonEncode(LotusDomSelectors.playerCard)},
    ));
    syncTabletopSeatLayout(playerCards);
    playerCards.forEach((card, index) => {
      if (!(card instanceof HTMLElement)) {
        return;
      }
      playerLayoutObserver?.observe(card);
      const panel = card.querySelector('.player-card-inner');
      if (panel instanceof HTMLElement) {
        playerLayoutObserver?.observe(panel);
      }
      const panelWidth = panel instanceof HTMLElement ? panel.clientWidth : 0;
      const panelHeight = panel instanceof HTMLElement ? panel.clientHeight : 0;
      if (panelWidth > 0 && panelHeight > 0) {
        const panelAspectRatio = String(panelWidth / panelHeight);
        if (
          card.style.getPropertyValue('--aspect-ratio-card') !== panelAspectRatio ||
          card.style.getPropertyPriority('--aspect-ratio-card') !== 'important'
        ) {
          // Lotus stores the reciprocal ratio for 90-degree cards because its
          // stock inner panel is rotated. ManaLoom keeps that panel horizontal,
          // so previews must use the visible panel ratio as a unitless number.
          // Avoid typed CSS division here to retain WKWebView/iOS 15.5 support.
          card.style.setProperty(
            '--aspect-ratio-card',
            panelAspectRatio,
            'important',
          );
        }
      }
      const fallbackName = 'Jogador ' + String(index + 1);
      const nameNode = card.querySelector('.player-name, .player-name-input');
      const playerName = readableText(nameNode) || fallbackName;
      setAttributeIfChanged(card, 'role', 'group');
      setAttributeIfChanged(card, 'aria-label', 'Controles de ' + playerName);

      const lifeNode = card.querySelector('.player-life-count');
      if (lifeNode instanceof HTMLElement) {
        const lifeValue =
          decodeVisualNumber(lifeNode) || readableText(lifeNode) || 'desconhecida';
        const numericLife = Number.parseInt(lifeValue, 10);
        setAttributeIfChanged(lifeNode, 'role', 'spinbutton');
        setAttributeIfChanged(lifeNode, 'tabindex', '0');
        setAttributeIfChanged(lifeNode, 'aria-live', 'polite');
        setAttributeIfChanged(lifeNode, 'aria-atomic', 'true');
        if (Number.isFinite(numericLife)) {
          setAttributeIfChanged(lifeNode, 'aria-valuenow', String(numericLife));
        }
        setAttributeIfChanged(lifeNode, 'aria-valuemin', '-999');
        setAttributeIfChanged(lifeNode, 'aria-valuemax', '999');
        setAttributeIfChanged(
          lifeNode,
          'aria-label',
          playerName + ', vida: ' + lifeValue,
        );
        const increaseButton = card.querySelector('.increase-button.life');
        const decreaseButton = card.querySelector('.decrease-button.life');
        if (increaseButton instanceof HTMLElement) {
          setAttributeIfChanged(increaseButton, 'role', 'button');
          setAttributeIfChanged(increaseButton, 'tabindex', '0');
          setAttributeIfChanged(
            increaseButton,
            'aria-label',
            'Aumentar a vida de ' + playerName,
          );
          bindKeyboardAction(increaseButton, () => dispatchAccessibleTap(increaseButton));
        }
        if (decreaseButton instanceof HTMLElement) {
          setAttributeIfChanged(decreaseButton, 'role', 'button');
          setAttributeIfChanged(decreaseButton, 'tabindex', '0');
          setAttributeIfChanged(
            decreaseButton,
            'aria-label',
            'Diminuir a vida de ' + playerName,
          );
          bindKeyboardAction(decreaseButton, () => dispatchAccessibleTap(decreaseButton));
        }
        if (lifeNode.dataset.manaloomSpinbuttonBound !== 'true') {
          lifeNode.dataset.manaloomSpinbuttonBound = 'true';
          lifeNode.addEventListener('keydown', (event) => {
            if (event.key === 'ArrowUp' && increaseButton instanceof HTMLElement) {
              event.preventDefault();
              dispatchAccessibleTap(increaseButton);
            } else if (event.key === 'ArrowDown' && decreaseButton instanceof HTMLElement) {
              event.preventDefault();
              dispatchAccessibleTap(decreaseButton);
            } else if (event.key === 'Enter' || event.key === ' ') {
              event.preventDefault();
              dispatchAccessibleTap(lifeNode);
            }
          });
        }
      }

    });

    const menuButton = document.querySelector(
      ${jsonEncode(LotusDomSelectors.menuButton)},
    );
    if (menuButton instanceof HTMLElement) {
      const isOpen = menuButton.classList.contains('active');
      setAttributeIfChanged(menuButton, 'role', 'button');
      setAttributeIfChanged(menuButton, 'tabindex', '0');
      setAttributeIfChanged(
        menuButton,
        'aria-label',
        isOpen ? 'Fechar controles da mesa' : 'Abrir controles da mesa',
      );
      setAttributeIfChanged(menuButton, 'aria-expanded', String(isOpen));
      bindKeyboardAction(menuButton, () => menuButton.click());
    }

    const tableManagementTools = [
      ['.list > .high-roll .btn', 'Desempate por dados'],
      ['.list > .settings .btn', 'Configurações'],
      ['.list > .more .btn', 'Ajuda'],
      ['.list > .players .btn', 'Jogadores'],
      ['.list > .restart .btn', 'Reiniciar partida'],
    ];
    tableManagementTools.forEach((entry) => {
      document.querySelectorAll(entry[0]).forEach((node) => {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        setAttributeIfChanged(node, 'role', 'button');
        setAttributeIfChanged(
          node,
          'tabindex',
          menuButton instanceof HTMLElement && menuButton.classList.contains('active')
            ? '0'
            : '-1',
        );
        setAttributeIfChanged(node, 'aria-label', entry[1]);
        setAttributeIfChanged(node, 'title', entry[1]);
        bindKeyboardAction(node, () => node.click());
      });
    });

    document.querySelectorAll('.menu-button-overlay .game-states-wrapper > *').forEach((node) => {
      if (!(node instanceof HTMLElement)) {
        return;
      }
      setAttributeIfChanged(node, 'role', 'button');
      setAttributeIfChanged(
        node,
        'tabindex',
        menuButton instanceof HTMLElement && menuButton.classList.contains('active') ? '0' : '-1',
      );
      const label = readableText(node);
      if (label) {
        setAttributeIfChanged(node, 'aria-label', label);
      }
      bindKeyboardAction(node, () => node.click());
    });

    const diceButtonLabels = [
      ['.dice-overlay .roller.d4', 'Rolar dado de 4 lados'],
      ['.dice-overlay .roller.d6', 'Rolar dado de 6 lados'],
      ['.dice-overlay .roller.d8', 'Rolar dado de 8 lados'],
      ['.dice-overlay .roller.d10', 'Rolar dado de 10 lados'],
      ['.dice-overlay .roller.d12', 'Rolar dado de 12 lados'],
      ['.dice-overlay .roller.d20', 'Rolar dado de 20 lados'],
      ['.dice-overlay .roller.coin', 'Lançar moeda'],
      ['.dice-overlay .roll-btn', 'Rolar dado personalizado'],
      ['.dice-overlay .close-dice-overlay-btn', 'Fechar dados'],
    ];
    diceButtonLabels.forEach((entry) => {
      document.querySelectorAll(entry[0]).forEach((node) => {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        setAttributeIfChanged(node, 'role', 'button');
        setAttributeIfChanged(node, 'tabindex', '0');
        setAttributeIfChanged(node, 'aria-label', entry[1]);
        bindKeyboardAction(node, () => node.click());
      });
    });
    document.querySelectorAll('.dice-overlay .roller.custom input').forEach((input) => {
      if (!(input instanceof HTMLElement)) {
        return;
      }
      setAttributeIfChanged(
        input,
        'aria-label',
        'Número de lados do dado personalizado',
      );
      setAttributeIfChanged(input, 'inputmode', 'numeric');
      setAttributeIfChanged(input, 'min', '2');
      setAttributeIfChanged(input, 'max', '999');
      setAttributeIfChanged(input, 'step', '1');

      const normalizeCustomDiceSides = () => {
        const parsed = Number.parseInt(input.value, 10);
        const normalized = Number.isFinite(parsed)
          ? Math.min(999, Math.max(2, parsed))
          : 100;
        const normalizedValue = String(normalized);
        if (input.value !== normalizedValue) {
          input.value = normalizedValue;
          input.dispatchEvent(new Event('input', { bubbles: true }));
        }
      };
      if (input.dataset.manaloomCustomDiceBound !== 'true') {
        input.dataset.manaloomCustomDiceBound = 'true';
        input.addEventListener('change', normalizeCustomDiceSides);
        input.addEventListener('blur', normalizeCustomDiceSides);
        const rollButton = input
          .closest('.roller.custom')
          ?.querySelector('.roll-btn');
        if (rollButton instanceof HTMLElement) {
          rollButton.addEventListener('click', normalizeCustomDiceSides, true);
        }
      }
      normalizeCustomDiceSides();
    });

    let exitButton = document.querySelector('.manaloom-life-counter-exit');
    if (!(exitButton instanceof HTMLElement) && document.body) {
      exitButton = document.createElement('button');
      exitButton.type = 'button';
      exitButton.className = 'manaloom-life-counter-exit';
      exitButton.textContent = '←';
      exitButton.setAttribute('aria-label', 'Sair do contador de vida');
      document.body.appendChild(exitButton);
    }
    if (exitButton instanceof HTMLElement) {
      const menuIsOpen =
        menuButton instanceof HTMLElement && menuButton.classList.contains('active');
      const menuOverlay = document.querySelector('.menu-button-overlay');
      if (
        menuIsOpen &&
        menuOverlay instanceof HTMLElement &&
        exitButton.parentElement !== menuOverlay
      ) {
        menuOverlay.appendChild(exitButton);
      }
      exitButton.classList.toggle('is-visible', menuIsOpen);
      if (exitButton.dataset.manaloomExitBound !== 'true') {
        exitButton.dataset.manaloomExitBound = 'true';
        exitButton.addEventListener('click', () => {
          const bridge = window.FlutterManaLoomShellBridge;
          if (bridge && typeof bridge.postMessage === 'function') {
            bridge.postMessage(JSON.stringify({
              type: '${LotusShellMessageTypes.closeLifeCounter}',
              source: 'table_menu_exit',
            }));
          }
        });
      }
    }

    const dialogs = [
      ['.menu-button-overlay', 'Controles da mesa'],
      ['.settings-overlay', 'Configurações do contador de vida'],
      ['.life-history-overlay', 'Histórico da partida'],
      ['.card-search-overlay', 'Busca de cartas'],
      ['.commander-damage-overlay', 'Dano de comandante'],
      ['.first-time-user-overlay', 'Tutorial do contador de vida'],
      ['.custom-life-overlay', 'Definir vida'],
      ['.dice-overlay', 'Dados'],
      ['.input-overlay', 'Informar um valor'],
      ['.confirm-overlay', 'Confirmar ação'],
    ];
    const dialogNodes = [];
    dialogs.forEach((entry) => {
      document.querySelectorAll(entry[0]).forEach((node) => {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        setAttributeIfChanged(node, 'role', 'dialog');
        setAttributeIfChanged(node, 'aria-modal', 'true');
        setAttributeIfChanged(node, 'aria-label', entry[1]);
        setAttributeIfChanged(node, 'tabindex', '-1');
        bindDialogKeyboard(node);
        dialogNodes.push(node);
      });
    });
    syncDialogFocus(dialogNodes);
  };

  let accessibilitySyncQueued = false;
  const queueAccessibilitySync = () => {
    if (accessibilitySyncQueued) {
      return;
    }
    accessibilitySyncQueued = true;
    requestAnimationFrame(() => {
      accessibilitySyncQueued = false;
      syncAccessibility();
    });
  };

  const accessibilityObserver = new MutationObserver(queueAccessibilitySync);
  if (typeof ResizeObserver === 'function') {
    playerLayoutObserver = new ResizeObserver(queueAccessibilitySync);
  }
  window.addEventListener('resize', queueAccessibilitySync);
  if (document.body) {
    accessibilityObserver.observe(document.body, {
      childList: true,
      characterData: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
  }
  window.__ManaLoomLifeCounterAccessibility = {
    observer: accessibilityObserver,
    sync: syncAccessibility,
  };
  window.__ManaLoomTabletopSeatLayout = Object.freeze({
    sync: syncTabletopSeatLayout,
    snapshot: () => syncTabletopSeatLayout(),
  });
  syncAccessibility();
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
        title: 'DANO DE COMANDANTE RECEBIDO',
        text: 'DESLIZE PARA A ESQUERDA OU DIREITA PARA REGISTRAR O DANO',
        buttons: const ['VOLTAR À PARTIDA', 'ENTENDI!'],
      );
    case 'turn_tracker_hint':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'CONTROLE DE TURNOS',
        text: 'TOQUE EM AVANÇAR OU VOLTAR PARA ACOMPANHAR O TURNO ATIVO',
        buttons: const ['ENTENDI!'],
      );
    case 'turn_tracker_hint_step1':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'CONTROLE DE TURNOS',
        text: 'MANTENHA O CONTROLE PRESSIONADO PARA VOLTAR AO JOGADOR ANTERIOR',
        buttons: const ['PRÓXIMO'],
      );
    case 'turn_tracker_hint_step2':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'manaloom-turn-tracker-proof',
        title: 'CONTROLE DE TURNOS',
        text:
            'NO TURNO 1 DO JOGADOR INICIAL, MANTENHA PRESSIONADO PARA TROCAR QUEM COMEÇA',
        buttons: const ['ENTENDI!'],
      );
    case 'show_counters_hint':
      return _buildShowCountersVisualProofScript(proofKey: proof);
    case 'menu_overlay':
      return _buildMenuOverlayVisualProofScript(proofKey: proof);
    case 'first_time_commander_damage':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Dano de comandante',
        text:
            'Deslize para a <b>esquerda</b> ou <b>direita</b> para registrar o dano',
        buttonLabel: 'Entendi!',
        coverCardClassName: 'cover-card swipe-left',
        commanderCardClassName: 'commander-card',
      );
    case 'first_time_player_options':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Personalize seu jogador',
        text: 'Deslize para <b>cima</b> ou <b>baixo</b> para ver as opções',
        buttonLabel: 'Certo!',
        coverCardClassName: 'cover-card swipe-up',
        commanderCardClassName: 'commander-card hide',
      );
    case 'first_time_fullscreen_mode':
      return _buildFirstTimeUserVisualProofScript(
        proofKey: proof,
        headline: 'Modo tela cheia',
        text: 'Adicione o site à <b>tela inicial</b> para usar a tela cheia',
        buttonLabel: 'Entendi!',
        coverCardClassName: 'cover-card swipe-up',
        commanderCardClassName: 'commander-card hide',
      );
    case 'own_commander_damage_hint':
      return _buildSimpleVisualProofScript(
        proofKey: proof,
        overlayClass: 'own-commander-damage-hint-overlay',
        title: 'DANO DO PRÓPRIO COMANDANTE',
        text:
            'FOI TRAÍDO?<br><span>TOQUE NA ADAGA PARA REGISTRAR O DANO DO SEU PRÓPRIO COMANDANTE.</span>',
        buttons: const ['ENTENDI!'],
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
      <div class="label"><b>Commander</b>Dano recebido</div>
      <div class="button">Voltar à partida</div>
    </div>
    <div class="options-card">
      <div class="inner">
        <div class="option-entry background">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Fundo</div>
        </div>
        <div class="option-entry kill">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Nocautear</div>
        </div>
        <div class="option-entry partner">
          <div class="option-entry-icon"></div>
          <div class="option-entry-text">Parceiro</div>
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
  <div class="dice-btn">Dados</div>
  <div class="life-history-btn">Histórico</div>
  <div class="initiative-btn">Iniciativa</div>
  <div class="monarch-btn">Monarca</div>
  <div class="card-search-btn">Busca de cartas</div>
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
<div class="manaloom-proof-title">EXIBIR MARCADORES NOS PAINÉIS? <br><span>(VOCÊ PODE ALTERAR ISSO NAS CONFIGURAÇÕES)</span></div>
<div class="manaloom-proof-actions">
  <div class="btn disable">NÃO</div>
  <div class="btn confirm">SIM</div>
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
