import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'lotus_js_bridges.dart';
import 'lotus_webview_contract.dart';

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
  const SHELL_CHANNEL = '${LotusJavaScriptBridges.shellChannelName}';
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
      type: '${LotusShellMessageTypes.blockedLink}',
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
        type: '${LotusShellMessageTypes.blockedWindowOpen}',
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
    observeUiSurface('.menu-button-overlay', 'menu_overlay_opened');
    observeUiSurface('.settings-overlay', 'settings_overlay_opened');
    observeUiSurface('.life-history-overlay', 'history_overlay_opened');
    observeUiSurface('.card-search-overlay', 'card_search_overlay_opened');
    observeUiSurface('.planechase-overlay', 'planechase_overlay_opened');
    observeUiSurface('.archenemy-overlay', 'archenemy_overlay_opened');
    observeUiSurface('.bounty-overlay', 'bounty_overlay_opened');
    observeUiSurface(
      '.edit-planechase-cards-overlay',
      'planechase_card_pool_overlay_opened'
    );
    observeUiSurface(
      '.edit-archenemy-cards-overlay',
      'archenemy_card_pool_overlay_opened'
    );
    observeUiSurface(
      '.edit-bounty-cards-overlay',
      'bounty_card_pool_overlay_opened'
    );
    observeUiSurface('.game-mode-info-overlay', 'game_mode_info_overlay_opened');
    observeUiSurface('.max-game-modes-warning', 'max_game_modes_warning_opened');
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
