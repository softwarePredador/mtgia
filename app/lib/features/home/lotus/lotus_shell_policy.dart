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
  '.first-time-user-overlay',
  '.own-commander-damage-hint-overlay',
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
  const TUTORIAL_OVERLAY_KEY = 'tutorialOverlay_v1';
  const OWN_COMMANDER_DAMAGE_HINT_KEY = 'ownCommanderDamageHintOverlay_v1';
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

  const ensureLocalFlag = (key) => {
    try {
      if (localStorage.getItem(key) === 'true') {
        return;
      }
      localStorage.setItem(key, 'true');
    } catch (_) {}
  };

  const queryWithin = (root, selector) => {
    if (!(root instanceof Element) && root !== document) {
      return [];
    }

    const matches = [];
    if (root instanceof Element && root.matches(selector)) {
      matches.push(root);
    }
    matches.push(...root.querySelectorAll(selector));
    return matches;
  };

  const ensureStyle = () => {
    if (document.getElementById(STYLE_ID)) {
      return;
    }

    const style = document.createElement('style');
    style.id = STYLE_ID;
    const EXTRA_CSS = `
.close-controls-backdrop {
  background: rgba(2, 6, 16, 0.58) !important;
  backdrop-filter: blur(14px) saturate(1.08) !important;
  pointer-events: auto !important;
}

.life-history-overlay,
.settings-overlay,
.card-search-overlay,
.planechase-overlay,
.archenemy-overlay,
.bounty-overlay,
.edit-planechase-cards-overlay,
.edit-archenemy-cards-overlay,
.edit-bounty-cards-overlay,
.game-mode-info-overlay {
  font-family: var(--manaloom-ui-font, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif) !important;
  color: rgba(245, 247, 252, 0.96) !important;
  background: rgba(4, 8, 18, 0.68) !important;
}

.life-history-overlay button,
.settings-overlay button,
.card-search-overlay button,
.planechase-overlay button,
.archenemy-overlay button,
.bounty-overlay button,
.edit-planechase-cards-overlay button,
.edit-archenemy-cards-overlay button,
.edit-bounty-cards-overlay button,
.game-mode-info-overlay button {
  font-family: var(--manaloom-ui-font, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif) !important;
  border-radius: 16px !important;
  border: 1px solid rgba(255, 255, 255, 0.14) !important;
  background: linear-gradient(180deg, rgba(18, 26, 46, 0.98), rgba(8, 13, 27, 0.96)) !important;
  color: rgba(245, 247, 252, 0.96) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    0 10px 20px rgba(0, 0, 0, 0.22) !important;
}

.life-history-overlay input,
.settings-overlay input,
.card-search-overlay input,
.life-history-overlay select,
.settings-overlay select,
.card-search-overlay select,
.life-history-overlay textarea,
.settings-overlay textarea,
.card-search-overlay textarea {
  font-family: var(--manaloom-ui-font, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif) !important;
  border-radius: 14px !important;
  border: 1px solid rgba(255, 255, 255, 0.12) !important;
  background: rgba(7, 13, 28, 0.72) !important;
  color: rgba(245, 247, 252, 0.96) !important;
}

.list > * .btn {
  width: 62px !important;
  height: 62px !important;
  min-width: 62px !important;
  min-height: 62px !important;
}
`;

    style.textContent =
      SUPPRESSED_SELECTORS.join(',') + ` {
        display: none !important;
        visibility: hidden !important;
        pointer-events: none !important;
      }` + EXTRA_CSS;
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
      queryWithin(root, selector).forEach(suppressNode);
    });
  };

  const protectBlockedLinks = (root = document) => {
    queryWithin(root, 'a[href]').forEach((link) => {
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

  const applyPolicy = (root = document) => {
    ensureLocalFlag(TUTORIAL_OVERLAY_KEY);
    ensureLocalFlag(OWN_COMMANDER_DAMAGE_HINT_KEY);
    ensureLocalFlag(TURN_TRACKER_HINT_KEY);
    ensureLocalFlag(COUNTERS_HINT_KEY);
    ensureStyle();
    suppressShell(root);
    protectBlockedLinks(root);
    observeUiSurface(root, '.menu-button-overlay', 'menu_overlay_opened');
    observeUiSurface(root, '.settings-overlay', 'settings_overlay_opened');
    observeUiSurface(root, '.life-history-overlay', 'history_overlay_opened');
    observeUiSurface(root, '.card-search-overlay', 'card_search_overlay_opened');
    observeUiSurface(root, '.planechase-overlay', 'planechase_overlay_opened');
    observeUiSurface(root, '.archenemy-overlay', 'archenemy_overlay_opened');
    observeUiSurface(root, '.bounty-overlay', 'bounty_overlay_opened');
    observeUiSurface(
      root,
      '.edit-planechase-cards-overlay',
      'planechase_card_pool_overlay_opened'
    );
    observeUiSurface(
      root,
      '.edit-archenemy-cards-overlay',
      'archenemy_card_pool_overlay_opened'
    );
    observeUiSurface(
      root,
      '.edit-bounty-cards-overlay',
      'bounty_card_pool_overlay_opened'
    );
    observeUiSurface(
      root,
      '.game-mode-info-overlay',
      'game_mode_info_overlay_opened'
    );
    observeUiSurface(
      root,
      '.max-game-modes-warning',
      'max_game_modes_warning_opened'
    );
    const dayNightMode = localStorage.getItem('__manaloom_day_night_mode');
    const switcher =
      queryWithin(root, '.day-night-switcher')[0] ??
      document.querySelector('.day-night-switcher');
    if (
      switcher &&
      (dayNightMode === 'day' || dayNightMode === 'night')
    ) {
      switcher.classList.toggle('night', dayNightMode === 'night');
    }
  };

  const observeUiSurface = (root, selector, eventName) => {
    queryWithin(root, selector).forEach((node) => {
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
  let pendingRoots = new Set();
  const queueApplyPolicy = (root = document) => {
    if (root instanceof Element || root === document) {
      pendingRoots.add(root);
    } else {
      pendingRoots.add(document);
    }
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
      const roots = pendingRoots.size > 0 ? Array.from(pendingRoots) : [document];
      pendingRoots = new Set();
      roots.forEach((root) => applyPolicy(root));
    });
  };

  document.addEventListener('click', clickGuard, true);

  const observer = new MutationObserver((records) => {
    let shouldApply = false;
    records.forEach((record) => {
      if (record.type === 'attributes' && record.target instanceof Element) {
        shouldApply = true;
        queueApplyPolicy(record.target);
        return;
      }

      if (record.type !== 'childList' || record.addedNodes.length == 0) {
        return;
      }

      shouldApply = true;
      record.addedNodes.forEach((node) => {
        if (node instanceof Element) {
          queueApplyPolicy(node);
        }
      });
    });

    if (shouldApply) {
      return;
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
