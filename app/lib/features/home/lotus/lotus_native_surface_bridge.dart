import 'dart:convert';

import 'lotus_js_bridges.dart';
import 'lotus_webview_contract.dart';

abstract final class LotusNativeSurfaceBridgeStyleIds {
  static const String takeover = 'manaloom-lotus-native-surface-bridge';
}

String get lotusInjectedNativeSurfaceBridgeScript {
  final styleId = LotusNativeSurfaceBridgeStyleIds.takeover;
  final shellChannel = LotusJavaScriptBridges.shellChannelName;
  final selectors = jsonEncode(<String, String>{
    'playerCard': LotusDomSelectors.playerCard,
    'optionCard': LotusDomSelectors.optionCard,
    'infoCard': LotusDomSelectors.infoCard,
    'regularCounters': LotusDomSelectors.regularCounters,
    'commanderDamageCounters': LotusDomSelectors.commanderDamageCounters,
    'lifeTotal': LotusDomSelectors.lifeTotal,
    'turnTracker': LotusDomSelectors.turnTracker,
    'gameTimer': LotusDomSelectors.mainGameTimer,
    'menuButton': LotusDomSelectors.menuButton,
    'menuUtilityBar': LotusDomSelectors.menuUtilityBar,
    'playerToolsShortcut': LotusDomSelectors.playerToolsShortcut,
    'commanderDamageShortcut': LotusDomSelectors.commanderDamageShortcut,
  });
  final shortcuts = jsonEncode(<Map<String, Object>>[
    <String, Object>{
      'selector': LotusDomSelectors.playerToolsShortcut,
      'type': 'open-native-player-state',
      'source': 'table_player_tools_shortcut_pressed',
      'targetPlayerIndex': 0,
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.commanderDamageShortcut,
      'type': 'open-lotus-commander-damage',
      'source': 'table_commander_damage_shortcut_pressed',
      'targetPlayerIndex': 0,
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.settingsShortcut,
      'type': 'open-native-settings',
      'source': 'settings_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.highRollShortcut,
      'type': 'open-native-dice',
      'source': 'high_roll_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.diceShortcut,
      'type': 'open-native-dice',
      'source': 'dice_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.historyShortcut,
      'type': 'open-native-history',
      'source': 'history_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.cardSearchShortcut,
      'type': 'open-native-card-search',
      'source': 'card_search_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.monarchShortcut,
      'type': 'open-native-table-state',
      'source': 'monarch_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.initiativeShortcut,
      'type': 'open-native-table-state',
      'source': 'initiative_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.dayNightShortcut,
      'type': 'open-native-day-night',
      'source': 'day_night_shortcut_pressed',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.dayNightSurface,
      'type': 'open-native-day-night',
      'source': 'day_night_surface_pressed',
      'closeMenu': false,
    },
    <String, Object>{
      'selector': LotusDomSelectors.planechaseShortcut,
      'type': 'open-native-game-modes',
      'source': 'planechase_shortcut_pressed',
      'preferredMode': 'planechase',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.planechaseSurface,
      'type': 'open-native-game-modes',
      'source': 'planechase_surface_pressed',
      'preferredMode': 'planechase',
      'closeMenu': false,
    },
    <String, Object>{
      'selector': LotusDomSelectors.archenemyShortcut,
      'type': 'open-native-game-modes',
      'source': 'archenemy_shortcut_pressed',
      'preferredMode': 'archenemy',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.archenemySurface,
      'type': 'open-native-game-modes',
      'source': 'archenemy_surface_pressed',
      'preferredMode': 'archenemy',
      'closeMenu': false,
    },
    <String, Object>{
      'selector': LotusDomSelectors.bountyShortcut,
      'type': 'open-native-game-modes',
      'source': 'bounty_shortcut_pressed',
      'preferredMode': 'bounty',
      'closeMenu': true,
    },
    <String, Object>{
      'selector': LotusDomSelectors.bountySurface,
      'type': 'open-native-game-modes',
      'source': 'bounty_surface_pressed',
      'preferredMode': 'bounty',
      'closeMenu': false,
    },
  ]);

  return '''
(() => {
  const VERSION = '2026-07-30-lotus-commander';
  const STYLE_ID = '$styleId';
  const SHELL_CHANNEL = '$shellChannel';
  const TAKEOVER_ATTR = 'data-manaloom-native-takeover';
  const ACTION_ATTR = 'data-manaloom-native-action';
  const SELECTORS = Object.freeze($selectors);
  const SHORTCUTS = Object.freeze($shortcuts);
  const existing = window.__ManaLoomNativeSurfaceBridge;
  if (existing && existing.version === VERSION) {
    if (typeof existing.sync === 'function') {
      existing.sync();
    }
    return;
  }
  if (existing && typeof existing.dispose === 'function') {
    existing.dispose();
  }

  const ensureStyle = () => {
    if (document.getElementById(STYLE_ID)) {
      return;
    }
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent =
      '[' + TAKEOVER_ATTR + '="true"] {' +
        'visibility: hidden !important;' +
        'opacity: 0 !important;' +
        'pointer-events: none !important;' +
      '}' +
      '[' + ACTION_ATTR + '] {' +
        'touch-action: manipulation !important;' +
      '}' +
      SELECTORS.playerToolsShortcut + ', ' +
      SELECTORS.commanderDamageShortcut + ' {' +
        'height: 44px;' +
        'border: 0;' +
        'border-radius: 999px;' +
        'background: #000;' +
        'color: #fff;' +
        'display: inline-flex;' +
        'align-items: center;' +
        'flex: 0 0 auto;' +
        'gap: 4px;' +
        'padding: 0 16px 0 4px;' +
        'font: inherit;' +
        'font-size: 22px;' +
        'font-weight: 700;' +
        'white-space: nowrap;' +
        'cursor: pointer;' +
        'animation: barChipsSlideIn .5s ease-out forwards;' +
        'transform: translateY(100%) scaleX(.7) rotate(60deg);' +
      '}' +
      SELECTORS.playerToolsShortcut + '::before, ' +
      SELECTORS.commanderDamageShortcut + '::before {' +
        'content: "";' +
        'display: block;' +
        'width: 44px;' +
        'height: 44px;' +
        'flex: 0 0 44px;' +
        'background-position: center;' +
        'background-repeat: no-repeat;' +
        'background-size: 28px;' +
      '}' +
      SELECTORS.playerToolsShortcut + '::before {' +
        'background-image: url("images/poison.svg");' +
      '}' +
      SELECTORS.commanderDamageShortcut + '::before {' +
        'background-image: url("images/commander-v2.svg");' +
      '}' +
      SELECTORS.playerToolsShortcut + ':focus-visible, ' +
      SELECTORS.commanderDamageShortcut + ':focus-visible {' +
        'outline: 3px solid #fff;' +
        'outline-offset: 2px;' +
      '}' +
      '[data-manaloom-player-drag="horizontal"] {' +
        'translate: var(--manaloom-player-drag-x, 0px) 0 !important;' +
        'filter: brightness(1.08) saturate(1.08);' +
        'transition: translate 40ms linear, filter 80ms ease-out;' +
        'z-index: 4;' +
      '}' +
      '[data-manaloom-player-drag="settling"] {' +
        'translate: 0 0 !important;' +
        'filter: none;' +
        'transition: translate 180ms cubic-bezier(.2,.8,.2,1), ' +
          'filter 140ms ease-out;' +
        'z-index: 4;' +
      '}';
    (document.head || document.documentElement).appendChild(style);
  };

  const postShellMessage = (payload) => {
    try {
      const channel = window[SHELL_CHANNEL];
      if (!channel || typeof channel.postMessage !== 'function') {
        return false;
      }
      channel.postMessage(JSON.stringify(payload));
      return true;
    } catch (_) {
      return false;
    }
  };

  const queryWithin = (root, selector) => {
    const matches = [];
    if (root instanceof Element && root.matches(selector)) {
      matches.push(root);
    }
    if (root && typeof root.querySelectorAll === 'function') {
      matches.push(...root.querySelectorAll(selector));
    }
    return matches;
  };

  const isRuntimePlayerCard = (card) => {
    return card instanceof HTMLElement &&
      card.matches(SELECTORS.playerCard) &&
      card.closest(
        '[class*="overlay"], [data-manaloom-visual-proof="true"]'
      ) === null;
  };

  const resolvePlayerCard = (node) => {
    if (!(node instanceof Element)) {
      return null;
    }
    const card = node.closest(SELECTORS.playerCard);
    return isRuntimePlayerCard(card) ? card : null;
  };

  const resolvePlayerIndex = (node) => {
    const card = resolvePlayerCard(node);
    if (!(card instanceof HTMLElement) ||
        !(card.parentElement instanceof HTMLElement)) {
      return null;
    }
    const siblings = Array.from(card.parentElement.children)
      .filter((candidate) => isRuntimePlayerCard(candidate));
    const index = siblings.indexOf(card);
    return index >= 0 ? index : null;
  };

  const consumeEvent = (event) => {
    event.preventDefault();
    event.stopPropagation();
    if (typeof event.stopImmediatePropagation === 'function') {
      event.stopImmediatePropagation();
    }
  };

  let internalLegacyCommanderSwipe = false;
  let restorePlayerSwipeGuard = null;
  const ensurePlayerSwipeGuard = () => {
    if (restorePlayerSwipeGuard) {
      return;
    }
    const managerPrototype = window.Hammer?.Manager?.prototype;
    const originalEmit = managerPrototype?.emit;
    if (!managerPrototype || typeof originalEmit !== 'function') {
      return;
    }
    const blockedEvents = new Set([
      'swipe',
      'swipeup',
      'swipedown',
      'swipeleft',
      'swiperight',
    ]);
    const guardedEmit = function(eventName, eventData) {
      if (!internalLegacyCommanderSwipe &&
          blockedEvents.has(eventName) &&
          this?.element?.matches?.(SELECTORS.playerCard)) {
        return;
      }
      return originalEmit.call(this, eventName, eventData);
    };
    managerPrototype.emit = guardedEmit;
    restorePlayerSwipeGuard = () => {
      if (managerPrototype.emit === guardedEmit) {
        managerPrototype.emit = originalEmit;
      }
      restorePlayerSwipeGuard = null;
    };
  };

  const closeTableMenu = () => {
    window.setTimeout(() => {
      const menuButton = document.querySelector(SELECTORS.menuButton);
      if (menuButton instanceof HTMLElement &&
          menuButton.classList.contains('active')) {
        menuButton.click();
      }
    }, 0);
  };

  const ensureTableMenuAction = ({
    className,
    label,
    accessibilityLabel,
  }) => {
    const utilityBar = document.querySelector(SELECTORS.menuUtilityBar);
    if (!(utilityBar instanceof HTMLElement) ||
        utilityBar.querySelector('.' + className)) {
      return;
    }

    const button = document.createElement('button');
    button.type = 'button';
    button.className = className;
    button.textContent = label;
    button.setAttribute('aria-label', accessibilityLabel);
    button.setAttribute('title', accessibilityLabel);
    utilityBar.insertBefore(button, utilityBar.firstChild);
  };

  const ensureTableMenuActions = () => {
    ensureTableMenuAction({
      className: 'manaloom-player-tools-btn',
      label: 'Marcadores',
      accessibilityLabel: 'Abrir marcadores e ações dos jogadores',
    });
    ensureTableMenuAction({
      className: 'manaloom-commander-damage-btn',
      label: 'Dano comandante',
      accessibilityLabel: 'Registrar dano de comandante',
    });
  };

  let internalSurfaceReset = false;

  const resolvePlayerBase = (card) => Array.from(card.children).find(
    (candidate) => candidate instanceof HTMLElement &&
      candidate.matches(
        '.player-card-inner:not(.option-card):not(.color-card):not(.info-card)'
      )
  );

  const resetPlayerSwipe = (card) => {
    if (!(card instanceof HTMLElement)) {
      return;
    }
    const base = resolvePlayerBase(card);
    if (base instanceof HTMLElement) {
      internalSurfaceReset = true;
      try {
        base.dispatchEvent(new PointerEvent('pointerdown', {
          bubbles: true,
          cancelable: true,
          pointerId: 1,
          pointerType: 'touch',
          isPrimary: true,
          button: 0,
        }));
      } catch (_) {
        base.dispatchEvent(new MouseEvent('mousedown', {
          bubbles: true,
          cancelable: true,
          button: 0,
        }));
      } finally {
        internalSurfaceReset = false;
      }
    }
  };

  const schedulePlayerSwipeReset = (card) => {
    window.setTimeout(() => resetPlayerSwipe(card), 0);
    window.setTimeout(() => resetPlayerSwipe(card), 120);
  };

  const dispatchSurfaceReset = (card, surface) => {
    if (!(card instanceof HTMLElement)) {
      return;
    }
    const base = resolvePlayerBase(card);
    resetPlayerSwipe(card);

    window.setTimeout(() => {
      if (surface instanceof HTMLElement && surface.isConnected) {
        surface.remove();
      }
      if (base instanceof HTMLElement) {
        base.classList.remove('hide');
      }
    }, 80);
  };

  const takeOverSurface = (surface) => {
    if (!(surface instanceof HTMLElement) ||
        !surface.matches(SELECTORS.optionCard) ||
        surface.getAttribute(TAKEOVER_ATTR) === 'true') {
      return false;
    }
    const card = resolvePlayerCard(surface);
    const targetPlayerIndex = resolvePlayerIndex(surface);
    if (!(card instanceof HTMLElement) || targetPlayerIndex === null) {
      return false;
    }

    const payload = {
      type: 'open-native-player-state',
      source: 'player_option_card_presented',
      targetPlayerIndex,
    };
    if (!postShellMessage(payload)) {
      return false;
    }

    surface.setAttribute(TAKEOVER_ATTR, 'true');
    dispatchSurfaceReset(card, surface);
    return true;
  };

  const extractCounterKey = (counter) => {
    const ignored = new Set([
      'counter',
      'clicked',
      'commander-damage-counter',
      'has-background-image',
      'own-damage',
      'partner-commander',
      'tax',
    ]);
    const candidates = Array.from(counter.classList)
      .filter((className) => !ignored.has(className));
    return candidates.find((className) => className.startsWith('tax-')) ||
      candidates[0] ||
      (counter.classList.contains('tax') ? 'tax-1' : null);
  };

  const emitPlayerAction = (event, node, payload) => {
    const targetPlayerIndex = resolvePlayerIndex(node);
    if (targetPlayerIndex === null) {
      return false;
    }
    if (!postShellMessage({ ...payload, targetPlayerIndex })) {
      return false;
    }
    node.setAttribute(ACTION_ATTR, payload.type);
    consumeEvent(event);
    return true;
  };

  let suppressedPlayerClick = null;

  const handleClick = (event) => {
    const target = event.target instanceof Element ? event.target : null;
    if (!target) {
      return;
    }

    if (suppressedPlayerClick &&
        Date.now() <= suppressedPlayerClick.until &&
        resolvePlayerIndex(target) === suppressedPlayerClick.playerIndex) {
      suppressedPlayerClick = null;
      consumeEvent(event);
      return;
    }
    suppressedPlayerClick = null;

    const commanderCounter = target.closest(
      SELECTORS.commanderDamageCounters
    );
    if (commanderCounter) {
      const card = resolvePlayerCard(commanderCounter);
      if (openLegacyCommanderDamage(card, 1)) {
        consumeEvent(event);
        return;
      }
    }

    const regularCounter = target.closest(SELECTORS.regularCounters);
    if (regularCounter) {
      const counterKey = extractCounterKey(regularCounter);
      if (counterKey && emitPlayerAction(event, regularCounter, {
        type: 'open-native-player-counter',
        source: 'player_counter_surface_pressed',
        counterKey,
      })) {
        return;
      }
    }

    const lifeTotal = target.closest(SELECTORS.lifeTotal);
    if (lifeTotal && emitPlayerAction(event, lifeTotal, {
      type: 'open-native-set-life',
      source: 'player_life_total_surface_pressed',
    })) {
      return;
    }

    const turnTracker = target.closest(SELECTORS.turnTracker);
    if (turnTracker && postShellMessage({
      type: 'open-native-turn-tracker',
      source: 'turn_tracker_surface_pressed',
    })) {
      turnTracker.setAttribute(ACTION_ATTR, 'open-native-turn-tracker');
      consumeEvent(event);
      return;
    }

    const gameTimer = target.closest(SELECTORS.gameTimer);
    if (gameTimer && postShellMessage({
      type: 'open-native-game-timer',
      source: 'game_timer_surface_pressed',
    })) {
      gameTimer.setAttribute(ACTION_ATTR, 'open-native-game-timer');
      consumeEvent(event);
      return;
    }

    for (const shortcut of SHORTCUTS) {
      const shortcutNode = target.closest(shortcut.selector);
      if (!(shortcutNode instanceof HTMLElement)) {
        continue;
      }
      const payload = {
        type: shortcut.type,
        source: shortcut.source,
      };
      if (shortcut.type === 'open-lotus-commander-damage') {
        const targetIndex = Number.isInteger(shortcut.targetPlayerIndex)
          ? shortcut.targetPlayerIndex
          : 0;
        if (shortcut.closeMenu) {
          closeTableMenu();
        }
        window.setTimeout(
          () => openLegacyCommanderDamageForPlayer(targetIndex),
          80
        );
        consumeEvent(event);
        return;
      }
      if (shortcut.preferredMode) {
        payload.preferredMode = shortcut.preferredMode;
      }
      if (Number.isInteger(shortcut.targetPlayerIndex)) {
        payload.targetPlayerIndex = shortcut.targetPlayerIndex;
      }
      if (!postShellMessage(payload)) {
        return;
      }
      shortcutNode.setAttribute(ACTION_ATTR, shortcut.type);
      consumeEvent(event);
      if (shortcut.closeMenu) {
        closeTableMenu();
      }
      return;
    }
  };

  let activePlayerDrag = null;
  let activeMouseDrag = null;
  const playerDragThreshold = 42;

  const shouldIgnorePlayerDragTarget = (target) => {
    if (!(target instanceof Element)) {
      return true;
    }
    if (target.closest(
      'button, a, input, select, textarea, .menu-button-overlay'
    )) {
      return true;
    }
    return target.closest(SELECTORS.turnTracker) !== null ||
      target.closest(SELECTORS.gameTimer) !== null;
  };

  const buildPlayerDrag = (event, inputId) => {
    const target = event.target instanceof Element ? event.target : null;
    if (shouldIgnorePlayerDragTarget(target)) {
      return null;
    }
    const targetPlayerIndex = resolvePlayerIndex(target);
    if (targetPlayerIndex === null) {
      return null;
    }
    return {
      inputId,
      startX: event.clientX,
      startY: event.clientY,
      targetPlayerIndex,
      playerCard: resolvePlayerCard(target),
      claimed: false,
    };
  };

  const playerDragDistance = (event, drag) => Math.hypot(
    event.clientX - drag.startX,
    event.clientY - drag.startY
  );

  const updatePlayerDragFeedback = (event, drag) => {
    const card = drag?.playerCard;
    if (!(card instanceof HTMLElement)) {
      return;
    }
    const deltaX = event.clientX - drag.startX;
    const deltaY = event.clientY - drag.startY;
    if (Math.abs(deltaX) < Math.abs(deltaY)) {
      return;
    }
    const visualDelta = Math.max(-38, Math.min(38, deltaX * .32));
    card.setAttribute('data-manaloom-player-drag', 'horizontal');
    card.style.setProperty(
      '--manaloom-player-drag-x',
      visualDelta + 'px'
    );
  };

  const resetPlayerDragFeedback = (card) => {
    if (!(card instanceof HTMLElement) ||
        !card.hasAttribute('data-manaloom-player-drag')) {
      return;
    }
    card.setAttribute('data-manaloom-player-drag', 'settling');
    card.style.setProperty('--manaloom-player-drag-x', '0px');
    window.setTimeout(() => {
      if (card.getAttribute('data-manaloom-player-drag') === 'settling') {
        card.removeAttribute('data-manaloom-player-drag');
        card.style.removeProperty('--manaloom-player-drag-x');
      }
    }, 190);
  };

  const cancelLegacyPlayerGesture = (event) => {
    try {
      window.dispatchEvent(new PointerEvent('pointercancel', {
        bubbles: false,
        cancelable: true,
        pointerId: event.pointerId ?? 1,
        pointerType: event.pointerType || 'mouse',
        isPrimary: event.isPrimary ?? true,
        button: 0,
        clientX: event.clientX,
        clientY: event.clientY,
      }));
    } catch (_) {
      // Mouse cancellation below remains available on older WebViews.
    }
    window.dispatchEvent(new MouseEvent('mouseup', {
      bubbles: false,
      cancelable: true,
      button: 0,
      clientX: event.clientX,
      clientY: event.clientY,
    }));
  };

  const openLegacyCommanderDamage = (card, horizontalDirection) => {
    if (!(card instanceof HTMLElement)) {
      return false;
    }
    const direction = horizontalDirection < 0 ? -1 : 1;
    const legacyDirection = direction < 0 ? 'left' : 'right';
    const legacySurfaceSelector = '.info-card, .commander-damage-card';
    const triggerLegacySwipe = card.__manaloomTriggerSwipe;

    if (typeof triggerLegacySwipe === 'function') {
      internalLegacyCommanderSwipe = true;
      try {
        triggerLegacySwipe.call(card, legacyDirection);
      } finally {
        internalLegacyCommanderSwipe = false;
      }
      return card.querySelector(legacySurfaceSelector) !== null;
    }

    const bounds = card.getBoundingClientRect();
    const travel = Math.max(96, Math.min(180, bounds.width * .32));
    const startX = bounds.left + bounds.width / 2;
    const startY = bounds.top + bounds.height / 2;
    const endX = startX + direction * travel;

    internalLegacyCommanderSwipe = true;
    try {
      try {
        const pointerId = 91;
        card.dispatchEvent(new PointerEvent('pointerdown', {
          bubbles: true,
          cancelable: true,
          pointerId,
          pointerType: 'mouse',
          isPrimary: true,
          button: 0,
          buttons: 1,
          clientX: startX,
          clientY: startY,
        }));
        window.dispatchEvent(new PointerEvent('pointermove', {
          bubbles: false,
          cancelable: true,
          pointerId,
          pointerType: 'mouse',
          isPrimary: true,
          button: 0,
          buttons: 1,
          clientX: endX,
          clientY: startY,
        }));
        window.dispatchEvent(new PointerEvent('pointerup', {
          bubbles: false,
          cancelable: true,
          pointerId,
          pointerType: 'mouse',
          isPrimary: true,
          button: 0,
          buttons: 0,
          clientX: endX,
          clientY: startY,
        }));
      } catch (_) {
        // The mouse fallback below covers WebViews without PointerEvent.
      }

      if (!card.querySelector(legacySurfaceSelector)) {
        card.dispatchEvent(new MouseEvent('mousedown', {
          bubbles: true,
          cancelable: true,
          button: 0,
          buttons: 1,
          clientX: startX,
          clientY: startY,
        }));
        window.dispatchEvent(new MouseEvent('mousemove', {
          bubbles: false,
          cancelable: true,
          button: 0,
          buttons: 1,
          clientX: endX,
          clientY: startY,
        }));
        window.dispatchEvent(new MouseEvent('mouseup', {
          bubbles: false,
          cancelable: true,
          button: 0,
          buttons: 0,
          clientX: endX,
          clientY: startY,
        }));
      }
    } finally {
      internalLegacyCommanderSwipe = false;
    }

    return card.querySelector(legacySurfaceSelector) !== null;
  };

  const openLegacyCommanderDamageForPlayer = (
    targetPlayerIndex,
    horizontalDirection = 1
  ) => {
    const cards = Array.from(document.querySelectorAll(
      SELECTORS.playerCard
    )).filter((card) => isRuntimePlayerCard(card));
    const normalizedIndex = Number.isInteger(targetPlayerIndex)
      ? Math.max(0, Math.min(cards.length - 1, targetPlayerIndex))
      : 0;
    return openLegacyCommanderDamage(
      cards[normalizedIndex] ?? cards[0] ?? null,
      horizontalDirection
    );
  };

  const handlePlayerDragStart = (event) => {
    if (internalSurfaceReset || internalLegacyCommanderSwipe ||
        (event.pointerType === 'mouse' && event.button !== 0)) {
      return;
    }
    activePlayerDrag = buildPlayerDrag(event, event.pointerId);
  };

  const handlePlayerDragMove = (event) => {
    const drag = activePlayerDrag;
    if (!drag || drag.inputId !== event.pointerId) {
      return;
    }
    updatePlayerDragFeedback(event, drag);
    if (!drag.claimed &&
        playerDragDistance(event, drag) >= playerDragThreshold) {
      drag.claimed = true;
      if (activeMouseDrag) {
        activeMouseDrag.claimed = true;
      }
      cancelLegacyPlayerGesture(event);
    }
    if (drag.claimed) {
      consumeEvent(event);
    }
  };

  const handleMouseDragStart = (event) => {
    if (internalSurfaceReset ||
        internalLegacyCommanderSwipe ||
        event.button !== 0) {
      return;
    }
    activeMouseDrag = buildPlayerDrag(event, 'mouse');
  };

  const handleMouseDragMove = (event) => {
    const drag = activeMouseDrag;
    if (!drag) {
      return;
    }
    updatePlayerDragFeedback(event, drag);
    if (!drag.claimed &&
        playerDragDistance(event, drag) >= playerDragThreshold) {
      drag.claimed = true;
      cancelLegacyPlayerGesture(event);
    }
    if (drag.claimed) {
      consumeEvent(event);
    }
  };

  const clearPlayerDrag = () => {
    resetPlayerDragFeedback(activePlayerDrag?.playerCard);
    resetPlayerDragFeedback(activeMouseDrag?.playerCard);
    activePlayerDrag = null;
    activeMouseDrag = null;
  };

  const completePlayerDrag = (event, drag) => {
    if (!drag) {
      return false;
    }

    const deltaX = event.clientX - drag.startX;
    const deltaY = event.clientY - drag.startY;
    if (!drag.claimed &&
        playerDragDistance(event, drag) < playerDragThreshold) {
      return false;
    }

    const isHorizontal = Math.abs(deltaX) >= Math.abs(deltaY);
    if (isHorizontal) {
      if (!openLegacyCommanderDamage(
        drag.playerCard,
        deltaX < 0 ? -1 : 1
      )) {
        return false;
      }
    } else {
      const payload = {
        type: 'open-native-player-state',
        source: 'player_vertical_drag',
        targetPlayerIndex: drag.targetPlayerIndex,
      };
      if (!postShellMessage(payload)) {
        return false;
      }
      schedulePlayerSwipeReset(drag.playerCard);
    }
    suppressedPlayerClick = {
      playerIndex: drag.targetPlayerIndex,
      until: Date.now() + 750,
    };
    return true;
  };

  const handlePlayerDragEnd = (event) => {
    const drag = activePlayerDrag;
    activePlayerDrag = null;
    resetPlayerDragFeedback(drag?.playerCard);
    if (!drag || drag.inputId !== event.pointerId) {
      return;
    }
    if (completePlayerDrag(event, drag)) {
      if (activeMouseDrag) {
        activeMouseDrag.handledByPointer = true;
      }
      consumeEvent(event);
    }
  };

  const handleMouseDragEnd = (event) => {
    const drag = activeMouseDrag;
    activeMouseDrag = null;
    resetPlayerDragFeedback(drag?.playerCard);
    if (drag?.handledByPointer) {
      consumeEvent(event);
      return;
    }
    if (completePlayerDrag(event, drag)) {
      consumeEvent(event);
    }
  };

  const sync = (root = document) => {
    ensureStyle();
    ensurePlayerSwipeGuard();
    ensureTableMenuActions();
    queryWithin(root, SELECTORS.optionCard).forEach(takeOverSurface);
    [
      SELECTORS.regularCounters,
      SELECTORS.commanderDamageCounters,
      SELECTORS.lifeTotal,
      SELECTORS.turnTracker,
      SELECTORS.gameTimer,
      ...SHORTCUTS.map((shortcut) => shortcut.selector),
    ].forEach((selector) => {
      queryWithin(root, selector).forEach((node) => {
        if (node instanceof HTMLElement) {
          node.setAttribute(
            ACTION_ATTR,
            node.getAttribute(ACTION_ATTR) || 'ready'
          );
          node.setAttribute('aria-haspopup', 'dialog');
        }
      });
    });
  };

  const observer = new MutationObserver((records) => {
    records.forEach((record) => {
      record.addedNodes.forEach((node) => {
        if (node instanceof Element) {
          sync(node);
        }
      });
    });
  });
  if (document.documentElement) {
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
  document.addEventListener('click', handleClick, true);

  window.__ManaLoomNativeSurfaceBridge = Object.freeze({
    version: VERSION,
    sync: () => sync(document),
    openCommanderDamage: (targetPlayerIndex = 0) => (
      openLegacyCommanderDamageForPlayer(targetPlayerIndex)
    ),
    snapshot: () => ({
      optionCards: document.querySelectorAll(SELECTORS.optionCard).length,
      infoCards: document.querySelectorAll(SELECTORS.infoCard).length,
      regularCounters: document.querySelectorAll(
        SELECTORS.regularCounters
      ).length,
      commanderDamageCounters: document.querySelectorAll(
        SELECTORS.commanderDamageCounters
      ).length,
      playerToolsShortcuts: document.querySelectorAll(
        SELECTORS.playerToolsShortcut
      ).length,
      commanderDamageShortcuts: document.querySelectorAll(
        SELECTORS.commanderDamageShortcut
      ).length,
      playerDragThreshold,
      mouseDragFallback: true,
      nativeActions: document.querySelectorAll(
        '[' + ACTION_ATTR + ']'
      ).length,
    }),
    dispose: () => {
      observer.disconnect();
      restorePlayerSwipeGuard?.();
      document.removeEventListener('click', handleClick, true);
      document.removeEventListener(
        'pointerdown',
        handlePlayerDragStart,
        true
      );
      document.removeEventListener('pointermove', handlePlayerDragMove, true);
      document.removeEventListener('pointerup', handlePlayerDragEnd, true);
      document.removeEventListener('pointercancel', clearPlayerDrag, true);
      document.removeEventListener('mousedown', handleMouseDragStart, true);
      document.removeEventListener('mousemove', handleMouseDragMove, true);
      document.removeEventListener('mouseup', handleMouseDragEnd, true);
    },
  });
  document.addEventListener('pointerdown', handlePlayerDragStart, true);
  document.addEventListener('pointermove', handlePlayerDragMove, true);
  document.addEventListener('pointerup', handlePlayerDragEnd, true);
  document.addEventListener('pointercancel', clearPlayerDrag, true);
  document.addEventListener('mousedown', handleMouseDragStart, true);
  document.addEventListener('mousemove', handleMouseDragMove, true);
  document.addEventListener('mouseup', handleMouseDragEnd, true);
  sync(document);
})();
''';
}
