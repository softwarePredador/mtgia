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
  });
  final shortcuts = jsonEncode(<Map<String, Object>>[
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
  const VERSION = '2026-07-17';
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

  const closeTableMenu = () => {
    window.setTimeout(() => {
      const menuButton = document.querySelector(SELECTORS.menuButton);
      if (menuButton instanceof HTMLElement &&
          menuButton.classList.contains('active')) {
        menuButton.click();
      }
    }, 0);
  };

  const dispatchSurfaceReset = (card, surface) => {
    if (!(card instanceof HTMLElement)) {
      return;
    }
    const base = Array.from(card.children).find((candidate) => {
      return candidate instanceof HTMLElement &&
        candidate.matches(
          '.player-card-inner:not(.option-card):not(.color-card):not(.info-card)'
        );
    });
    if (base instanceof HTMLElement) {
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
      }
    }

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
        surface.getAttribute(TAKEOVER_ATTR) === 'true') {
      return false;
    }
    const card = resolvePlayerCard(surface);
    const targetPlayerIndex = resolvePlayerIndex(surface);
    if (!(card instanceof HTMLElement) || targetPlayerIndex === null) {
      return false;
    }

    const isPlayerOptions = surface.matches(SELECTORS.optionCard);
    const payload = isPlayerOptions
      ? {
          type: 'open-native-player-state',
          source: 'player_option_card_presented',
          targetPlayerIndex,
        }
      : {
          type: 'open-native-commander-damage',
          source: 'commander_damage_info_card_presented',
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

  const handleClick = (event) => {
    const target = event.target instanceof Element ? event.target : null;
    if (!target) {
      return;
    }

    const commanderCounter = target.closest(
      SELECTORS.commanderDamageCounters
    );
    if (commanderCounter && emitPlayerAction(event, commanderCounter, {
      type: 'open-native-commander-damage',
      source: 'commander_damage_counter_pressed',
    })) {
      return;
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
      if (shortcut.preferredMode) {
        payload.preferredMode = shortcut.preferredMode;
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

  const sync = (root = document) => {
    ensureStyle();
    queryWithin(root, SELECTORS.optionCard).forEach(takeOverSurface);
    queryWithin(root, SELECTORS.infoCard).forEach(takeOverSurface);
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
    snapshot: () => ({
      optionCards: document.querySelectorAll(SELECTORS.optionCard).length,
      infoCards: document.querySelectorAll(SELECTORS.infoCard).length,
      regularCounters: document.querySelectorAll(
        SELECTORS.regularCounters
      ).length,
      commanderDamageCounters: document.querySelectorAll(
        SELECTORS.commanderDamageCounters
      ).length,
      nativeActions: document.querySelectorAll(
        '[' + ACTION_ATTR + ']'
      ).length,
    }),
    dispose: () => {
      observer.disconnect();
      document.removeEventListener('click', handleClick, true);
    },
  });
  sync(document);
})();
''';
}
