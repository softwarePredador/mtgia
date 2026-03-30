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

String get lotusShellCleanupScript {
  final blockedHosts = jsonEncode(lotusBlockedExternalHosts.toList()..sort());
  final suppressedSelectors = jsonEncode(lotusSuppressedShellSelectors);

  return '''
(() => {
  const BLOCKED_HOSTS = new Set($blockedHosts);
  const SUPPRESSED_SELECTORS = $suppressedSelectors;
  const STYLE_ID = 'manaloom-lotus-shell-policy';
  const SUPPRESSED_ATTR = 'data-manaloom-shell-suppressed';
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
    ensureStyle();
    suppressShell(document);
    protectBlockedLinks(document);
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
