import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

const Set<String> lotusBlockedExternalHosts = {
  'apps.apple.com',
  'play.google.com',
  'edh.wiki',
  'edh-combos.com',
  'combo-finder.com',
  'watchedh.com',
  'packsim.app',
  'forms.gle',
  'patreon.com',
  'www.patreon.com',
};

const List<String> lotusSuppressedShellSelectors = <String>[
  '#Content',
  '.lotus',
  '.patreon',
  '.feedback-btn-wrapper',
  '.feedback-btn',
  '.patreon-btn-wrapper',
  '.patreon-btn',
  '.turn-tracker-hint-overlay',
  '.show-counters-hint-overlay',
];

bool lotusShouldPreventNavigation(NavigationRequest request) {
  if (!request.isMainFrame) {
    return false;
  }

  final uri = Uri.tryParse(request.url);
  if (uri == null) {
    return true;
  }

  if (_isAllowedLocalUri(uri)) {
    return false;
  }

  if (_isBlockedMarketingUri(uri)) {
    return true;
  }

  return true;
}

Object? lotusDecodeShellPayload(String payload) => jsonDecode(payload);

String get lotusShellCleanupScript {
  final blockedHosts = jsonEncode(lotusBlockedExternalHosts.toList()..sort());
  final suppressedSelectors = jsonEncode(lotusSuppressedShellSelectors);

  return '''
(() => {
  const BLOCKED_HOSTS = new Set($blockedHosts);
  const SUPPRESSED_SELECTORS = $suppressedSelectors;
  const TURN_TRACKER_HINT_KEY = 'turnTrackerHintOverlay_v1';
  const COUNTERS_HINT_KEY = 'countersOnPlayerCardHintOverlay_v1';
  const STYLE_ID = 'manaloom-lotus-shell-policy';
  const SUPPRESSED_ATTR = 'data-manaloom-shell-suppressed';
  const TELEMETRY_ATTR = 'data-manaloom-telemetry-seen';
  const PLAYER_STATE_ATTR = 'data-manaloom-player-state-seen';
  const PLAYER_APPEARANCE_ATTR = 'data-manaloom-player-appearance-seen';
  const SHELL_CHANNEL = 'FlutterManaLoomShellBridge';
  document.title = 'ManaLoom Life Counter';
  const postShellMessage = (payload) => {
    try {
      if (
        window[SHELL_CHANNEL] &&
        typeof window[SHELL_CHANNEL].postMessage === 'function'
      ) {
        window[SHELL_CHANNEL].postMessage(JSON.stringify(payload));
      }
    } catch (_) {}
  };
  const postAnalytics = (name, category, data = {}) => {
    postShellMessage({
      type: 'analytics',
      name,
      category,
      data,
    });
  };
  const resolvePlayerCards = () =>
    Array.from(document.querySelectorAll('.player-card')).filter(
      (node) => !node.classList.contains('empty-player-card')
    );
  const resolveTargetPlayerIndex = (node) => {
    if (!(node instanceof Element)) {
      return null;
    }

    const playerCard = node.closest('.player-card');
    if (!(playerCard instanceof Element)) {
      return null;
    }

    const playerCards = resolvePlayerCards();
    const targetPlayerIndex = playerCards.indexOf(playerCard);
    return targetPlayerIndex >= 0 ? targetPlayerIndex : null;
  };
  const openNativePlayerState = (node, source) => {
    if (!(node instanceof Element)) {
      return false;
    }

    const targetPlayerIndex = resolveTargetPlayerIndex(node);
    if (targetPlayerIndex == null) {
      return false;
    }

    postAnalytics('player_state_surface_pressed', 'life_counter.shell', {
      selector: node.className || node.tagName,
      source,
      target_player_index: targetPlayerIndex,
    });
    postShellMessage({
      type: 'open-native-player-state',
      source,
      targetPlayerIndex,
    });
    return true;
  };
  const openNativePlayerAppearance = (node, source) => {
    if (!(node instanceof Element)) {
      return false;
    }

    const targetPlayerIndex = resolveTargetPlayerIndex(node);
    if (targetPlayerIndex == null) {
      return false;
    }

    postAnalytics('player_background_surface_pressed', 'life_counter.shell', {
      selector: node.className || node.tagName,
      source,
      target_player_index: targetPlayerIndex,
    });
    postShellMessage({
      type: 'open-native-player-appearance',
      source,
      targetPlayerIndex,
    });
    return true;
  };
  const openNativeSetLife = (node, source) => {
    if (!(node instanceof Element)) {
      return false;
    }

    const targetPlayerIndex = resolveTargetPlayerIndex(node);
    if (targetPlayerIndex == null) {
      return false;
    }

    postAnalytics('set_life_surface_pressed', 'life_counter.shell', {
      selector: node.className || node.tagName,
      source,
      target_player_index: targetPlayerIndex,
    });
    postShellMessage({
      type: 'open-native-set-life',
      source,
      targetPlayerIndex,
    });
    return true;
  };
  const observePlayerStateSurface = (root = document) => {
    root.querySelectorAll('.player-card-inner.option-card').forEach((node) => {
      if (!(node instanceof Element)) {
        return;
      }

      if (node.getAttribute(PLAYER_STATE_ATTR) === 'true') {
        return;
      }

      node.setAttribute(PLAYER_STATE_ATTR, 'true');
      openNativePlayerState(node, 'player_option_card_presented');
    });
  };
  const observePlayerAppearanceSurface = (root = document) => {
    root.querySelectorAll('.player-card-inner.color-card').forEach((node) => {
      if (!(node instanceof Element)) {
        return;
      }

      if (node.getAttribute(PLAYER_APPEARANCE_ATTR) === 'true') {
        return;
      }

      node.setAttribute(PLAYER_APPEARANCE_ATTR, 'true');
      openNativePlayerAppearance(node, 'player_background_color_card_presented');
    });
  };
  const resolvePlayerCounterKey = (node) => {
    if (!(node instanceof Element)) {
      return null;
    }

    const ignoredClasses = new Set([
      'counter',
      'clicked',
      'commander-damage-counter',
    ]);
    const candidate = Array.from(node.classList).find(
      (className) => !ignoredClasses.has(className)
    );
    return candidate || null;
  };

  const isBlockedUrl = (rawUrl) => {
    if (!rawUrl) {
      return false;
    }

    try {
      const url = new URL(rawUrl, window.location.href);
      if (url.searchParams.get('force') === 'true') {
        return true;
      }

      return BLOCKED_HOSTS.has(url.host.toLowerCase());
    } catch (_) {
      return false;
    }
  };

  const ensureStyle = () => {
    if (document.getElementById(STYLE_ID)) {
      return;
    }

    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = SUPPRESSED_SELECTORS.join(',') + ` {
      display: none !important;
      visibility: hidden !important;
      pointer-events: none !important;
    }`;
    document.head.appendChild(style);
  };

  const suppressNode = (node) => {
    if (!(node instanceof Element)) {
      return;
    }

    if (node.getAttribute(SUPPRESSED_ATTR) === 'true') {
      return;
    }

    node.setAttribute(SUPPRESSED_ATTR, 'true');
    node.setAttribute('aria-hidden', 'true');
    node.style.setProperty('display', 'none', 'important');
    node.style.setProperty('visibility', 'hidden', 'important');
    node.style.setProperty('pointer-events', 'none', 'important');
  };

  const suppressShell = (root = document) => {
    SUPPRESSED_SELECTORS.forEach((selector) => {
      root.querySelectorAll(selector).forEach(suppressNode);
    });
  };

  const protectBlockedLinks = (root = document) => {
    root.querySelectorAll('a[href]').forEach((link) => {
      const href = link.getAttribute('href') || link.href;
      if (!isBlockedUrl(href)) {
        return;
      }

      link.setAttribute('data-manaloom-blocked-link', 'true');
      link.setAttribute('rel', 'noopener noreferrer');
    });
  };

  const clickGuard = (event) => {
    if (!(event.target instanceof Element)) {
      return;
    }

    const trackedClick = event.target.closest(
      '.menu-button, .dice-btn, .life-history-btn, .card-search-btn, .settings, .overlay-settings-btn, .turn-time-tracker, .game-timer:not(.current-time-clock), .current-time-clock, .commander-damage-counter, .counters-on-card .counter, .monarch-btn, .initiative-btn, .day-night-switcher'
    );
    const playerLifeClick = event.target.closest('.player-life-count');
    const playerStateClick = event.target.closest(
      '.player-card-inner.option-card, .player-card-inner .killed-overlay'
    );
    const playerAppearanceClick = event.target.closest(
      '.option-entry.background, .background.option-entry'
    );
    if (trackedClick) {
      let name = null;
      const playerCounterKey = resolvePlayerCounterKey(trackedClick);
      if (trackedClick.matches('.menu-button')) {
        name = 'menu_button_pressed';
      } else if (trackedClick.matches('.dice-btn')) {
        name = 'dice_shortcut_pressed';
      } else if (trackedClick.matches('.life-history-btn')) {
        name = 'history_shortcut_pressed';
      } else if (trackedClick.matches('.card-search-btn')) {
        name = 'card_search_shortcut_pressed';
      } else if (
        trackedClick.matches('.settings') ||
        trackedClick.matches('.overlay-settings-btn')
      ) {
        name = 'settings_shortcut_pressed';
      } else if (trackedClick.matches('.turn-time-tracker')) {
        name = 'turn_tracker_surface_pressed';
      } else if (
        trackedClick.matches('.current-time-clock:not(.with-game-timer)')
      ) {
        name = 'clock_surface_pressed';
      } else if (
        trackedClick.matches('.game-timer:not(.current-time-clock)') ||
        trackedClick.matches('.current-time-clock.with-game-timer')
      ) {
        name = 'game_timer_surface_pressed';
      } else if (trackedClick.matches('.monarch-btn')) {
        name = 'monarch_surface_pressed';
      } else if (trackedClick.matches('.initiative-btn')) {
        name = 'initiative_surface_pressed';
      } else if (trackedClick.matches('.day-night-switcher')) {
        name = 'day_night_surface_pressed';
      } else if (trackedClick.matches('.commander-damage-counter')) {
        name = 'commander_damage_surface_pressed';
      } else if (
        trackedClick.matches('.counters-on-card .counter') &&
        !trackedClick.matches('.commander-damage-counter')
      ) {
        name = 'player_counter_surface_pressed';
      }

      if (name) {
        postAnalytics(name, 'life_counter.shell', {
          selector: trackedClick.className || trackedClick.tagName,
          ...(playerCounterKey ? { counter_key: playerCounterKey } : {}),
        });
      }

      if (trackedClick.matches('.menu-button')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-quick-actions',
          source: name || 'menu_button_pressed',
        });
        return;
      }

      if (trackedClick.matches('.dice-btn')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-dice',
          source: name || 'dice_shortcut_pressed',
        });
        return;
      }

      if (trackedClick.matches('.life-history-btn')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-history',
          source: name || 'history_shortcut_pressed',
        });
        return;
      }

      if (trackedClick.matches('.card-search-btn')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-card-search',
          source: name || 'card_search_shortcut_pressed',
        });
        return;
      }

      if (
        trackedClick.matches('.settings') ||
        trackedClick.matches('.overlay-settings-btn')
      ) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-settings',
          source: name || 'settings_shortcut_pressed',
        });
        return;
      }

      if (trackedClick.matches('.turn-time-tracker')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-turn-tracker',
          source: name || 'turn_tracker_surface_pressed',
        });
        return;
      }

      if (
        trackedClick.matches('.game-timer:not(.current-time-clock)') ||
        trackedClick.matches('.current-time-clock')
      ) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-game-timer',
          source:
            name ||
            (trackedClick.matches('.current-time-clock:not(.with-game-timer)')
              ? 'clock_surface_pressed'
              : 'game_timer_surface_pressed'),
        });
        return;
      }

      if (
        trackedClick.matches('.monarch-btn') ||
        trackedClick.matches('.initiative-btn')
      ) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-table-state',
          source:
            name ||
            (trackedClick.matches('.monarch-btn')
              ? 'monarch_surface_pressed'
              : 'initiative_surface_pressed'),
        });
        return;
      }

      if (trackedClick.matches('.day-night-switcher')) {
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-day-night',
          source: name || 'day_night_surface_pressed',
        });
        return;
      }

      if (trackedClick.matches('.commander-damage-counter')) {
        event.preventDefault();
        event.stopPropagation();
        const playerCards = Array.from(
          document.querySelectorAll('.player-card')
        ).filter((node) => !node.classList.contains('empty-player-card'));
        const playerCard = trackedClick.closest('.player-card');
        const targetPlayerIndex =
          playerCard == null ? null : playerCards.indexOf(playerCard);
        postShellMessage({
          type: 'open-native-commander-damage',
          source: name || 'commander_damage_surface_pressed',
          targetPlayerIndex:
            targetPlayerIndex != null && targetPlayerIndex >= 0
              ? targetPlayerIndex
              : null,
        });
        return;
      }

      if (
        trackedClick.matches('.counters-on-card .counter') &&
        !trackedClick.matches('.commander-damage-counter')
      ) {
        const playerCards = Array.from(
          document.querySelectorAll('.player-card')
        ).filter((node) => !node.classList.contains('empty-player-card'));
        const playerCard = trackedClick.closest('.player-card');
        const targetPlayerIndex =
          playerCard == null ? null : playerCards.indexOf(playerCard);
        event.preventDefault();
        event.stopPropagation();
        postShellMessage({
          type: 'open-native-player-counter',
          source: name || 'player_counter_surface_pressed',
          targetPlayerIndex:
            targetPlayerIndex != null && targetPlayerIndex >= 0
              ? targetPlayerIndex
              : null,
          counterKey: playerCounterKey,
        });
        return;
      }
    }

    if (
      playerLifeClick &&
      document.body &&
      document.body.classList.contains('set-life-by-tap-enabled')
    ) {
      event.preventDefault();
      event.stopPropagation();
      if (
        openNativeSetLife(
          playerLifeClick,
          'player_life_total_surface_pressed'
        )
      ) {
        return;
      }
    }

    if (playerStateClick) {
      event.preventDefault();
      event.stopPropagation();
      openNativePlayerState(
        playerStateClick,
        playerStateClick.matches('.player-card-inner.option-card')
          ? 'player_state_surface_pressed'
          : 'killed_overlay_pressed'
      );
      return;
    }

    if (playerAppearanceClick) {
      event.preventDefault();
      event.stopPropagation();
      openNativePlayerAppearance(
        playerAppearanceClick,
        'player_background_surface_pressed'
      );
      return;
    }

    const link = event.target.closest('a[href]');
    if (!link) {
      return;
    }

    const href = link.getAttribute('href') || link.href;
    if (!isBlockedUrl(href)) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    console.log('[ManaLoomShell] Blocked branded link:', href);
    postShellMessage({
      type: 'blocked-link',
      href,
    });
  };

  const originalOpen = typeof window.open === 'function'
    ? window.open.bind(window)
    : null;

  window.open = function(url, target, features) {
    if (isBlockedUrl(url)) {
      console.log('[ManaLoomShell] Blocked branded window.open:', url);
      postShellMessage({
        type: 'blocked-window-open',
        href: url,
      });
      return null;
    }

    if (!originalOpen) {
      return null;
    }

    return originalOpen(url, target, features);
  };

  const applyPolicy = () => {
    try {
      localStorage.setItem(TURN_TRACKER_HINT_KEY, 'true');
      localStorage.setItem(COUNTERS_HINT_KEY, 'true');
    } catch (_) {}

    ensureStyle();
    suppressShell(document);
    protectBlockedLinks(document);
    observePlayerStateSurface(document);
    observePlayerAppearanceSurface(document);
    observeUiSurface('.menu-button-overlay', 'menu_overlay_opened');
    observeUiSurface('.settings-overlay', 'settings_overlay_opened');
    observeUiSurface('.life-history-overlay', 'history_overlay_opened');
    observeUiSurface('.search-overlay', 'card_search_overlay_opened');
    const dayNightMode = localStorage.getItem('__manaloom_day_night_mode');
    const switcher = document.querySelector('.day-night-switcher');
    if (
      switcher &&
      (dayNightMode === 'day' || dayNightMode === 'night')
    ) {
      switcher.classList.toggle('night', dayNightMode === 'night');
    }
  };

  const observeUiSurface = (selector, eventName) => {
    document.querySelectorAll(selector).forEach((node) => {
      if (!(node instanceof Element)) {
        return;
      }

      if (node.getAttribute(TELEMETRY_ATTR) === 'true') {
        return;
      }

      node.setAttribute(TELEMETRY_ATTR, 'true');
      postAnalytics(eventName, 'life_counter.shell', {
        selector,
      });
    });
  };

  let applyQueued = false;
  const queueApplyPolicy = () => {
    if (applyQueued) {
      return;
    }

    applyQueued = true;
    const schedule =
      window.requestAnimationFrame ||
      function(callback) {
        return window.setTimeout(callback, 16);
      };
    schedule(() => {
      applyQueued = false;
      applyPolicy();
    });
  };

  document.addEventListener('click', clickGuard, true);

  const observer = new MutationObserver((records) => {
    if (
      records.some((record) =>
        record.type === 'childList' && record.addedNodes.length > 0
      )
    ) {
      queueApplyPolicy();
    }
  });

  if (document.documentElement) {
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  applyPolicy();
})();
''';
}

bool _isAllowedLocalUri(Uri uri) {
  if (uri.scheme == 'file') {
    return true;
  }

  return const <String>{
    'about',
    'data',
    'javascript',
    'blob',
    'content',
  }.contains(uri.scheme);
}

bool _isBlockedMarketingUri(Uri uri) {
  if (uri.queryParameters['force'] == 'true') {
    return true;
  }

  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return false;
  }

  return lotusBlockedExternalHosts.contains(host);
}
