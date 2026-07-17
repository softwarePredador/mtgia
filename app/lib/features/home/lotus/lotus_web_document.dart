import 'dart:convert';

const String lotusWebStorageKey = 'manaloom_lotus_web_storage_v1';
const String lotusWebStoragePendingFingerprintKey =
    'manaloom_lotus_web_storage_pending_fingerprint_v1';

bool isLotusWebStoragePendingFingerprintCurrent({
  required String? pendingFingerprint,
  required String currentStorageFingerprint,
}) {
  return pendingFingerprint != null &&
      pendingFingerprint == currentStorageFingerprint;
}

bool shouldClearLotusWebStoragePendingFingerprint({
  required String? pendingFingerprint,
  required String completedFingerprint,
  required String currentStorageFingerprint,
}) {
  return completedFingerprint == currentStorageFingerprint &&
      isLotusWebStoragePendingFingerprintCurrent(
        pendingFingerprint: pendingFingerprint,
        currentStorageFingerprint: currentStorageFingerprint,
      );
}

String buildLotusWebDocument({
  required String sourceHtml,
  required String assetBaseUrl,
  required String bridgeToken,
  required Map<String, String> initialStorage,
  required List<String> injectedScripts,
}) {
  final headMatch = RegExp(
    r'<head(?:\s[^>]*)?>',
    caseSensitive: false,
  ).firstMatch(sourceHtml);
  final bodyCloseMatch = RegExp(
    r'</body\s*>',
    caseSensitive: false,
  ).firstMatch(sourceHtml);
  if (headMatch == null || bodyCloseMatch == null) {
    throw const FormatException('Lotus web document requires head and body.');
  }

  final escapedBaseUrl = const HtmlEscape(
    HtmlEscapeMode.attribute,
  ).convert(assetBaseUrl);
  final bridgeScript = _buildBridgeScript(
    bridgeToken: bridgeToken,
    initialStorage: initialStorage,
  );
  final headInjection = '''
<base href="$escapedBaseUrl">
<script>${_safeInlineScript(bridgeScript)}</script>
''';
  final withBridge = sourceHtml.replaceRange(
    headMatch.end,
    headMatch.end,
    headInjection,
  );

  final refreshedBodyCloseMatch =
      RegExp(r'</body\s*>', caseSensitive: false).firstMatch(withBridge)!;
  final runtimeInjection = <String>[
    ...injectedScripts,
    _buildReadyScript(bridgeToken),
  ].map((script) => '<script>${_safeInlineScript(script)}</script>').join('\n');

  return withBridge.replaceRange(
    refreshedBodyCloseMatch.start,
    refreshedBodyCloseMatch.start,
    '$runtimeInjection\n',
  );
}

String _buildBridgeScript({
  required String bridgeToken,
  required Map<String, String> initialStorage,
}) {
  final encodedToken = jsonEncode(bridgeToken);
  final encodedStorage = jsonEncode(initialStorage);
  return '''
(() => {
  'use strict';
  const TOKEN = $encodedToken;
  let values = Object.assign(Object.create(null), $encodedStorage);

  const postToHost = (kind, payload = {}) => {
    window.parent.postMessage({
      manaloomLotusWeb: true,
      token: TOKEN,
      kind,
      ...payload,
    }, '*');
  };

  const persist = () => {
    postToHost('storage', { values: { ...values } });
  };
  const scopedStorage = {
    key(index) {
      const keys = Object.keys(values);
      return index >= 0 && index < keys.length ? keys[index] : null;
    },
    getItem(key) {
      const normalizedKey = String(key);
      return Object.prototype.hasOwnProperty.call(values, normalizedKey)
        ? values[normalizedKey]
        : null;
    },
    setItem(key, value) {
      values[String(key)] = String(value);
      persist();
    },
    removeItem(key) {
      delete values[String(key)];
      persist();
    },
    clear() {
      values = Object.create(null);
      persist();
    },
  };
  Object.defineProperty(scopedStorage, 'length', {
    enumerable: true,
    get: () => Object.keys(values).length,
  });

  try {
    Object.defineProperty(window, 'localStorage', {
      configurable: false,
      enumerable: true,
      value: scopedStorage,
    });
  } catch (error) {
    postToHost('fatal', {
      message: 'Could not isolate the Lotus browser storage.',
      detail: String(error),
    });
    return;
  }

  window.FlutterManaLoomStorageBridge = {
    postMessage(rawMessage) {
      let message = rawMessage;
      try {
        if (typeof rawMessage === 'string') {
          message = JSON.parse(rawMessage);
        }
      } catch (_) {
        message = null;
      }
      if (!message || typeof message !== 'object') {
        return;
      }

      if (message.type === 'request_bootstrap') {
        setTimeout(() => {
          const bridge = window.__ManaloomLotusStorageBridge;
          if (!bridge || typeof bridge.receiveBootstrap !== 'function') {
            return;
          }
          bridge.receiveBootstrap({
            sessionId: message.sessionId,
            requestId: message.requestId,
            revision: 0,
            values: { ...values },
          });
        }, 0);
        return;
      }

      if (message.type === 'persist_snapshot' && message.values) {
        values = Object.assign(Object.create(null), message.values);
        persist();
      }
      if (message.type === 'bootstrap_failed') {
        postToHost('fatal', {
          message: 'Lotus could not restore its browser session.',
          detail: String(message.reason || 'bootstrap_failed'),
        });
      }
    },
  };
  window.FlutterManaLoomShellBridge = {
    postMessage(message) {
      postToHost('shell', { message: String(message || '') });
    },
  };
  window.FlutterClipboardBridge = {
    postMessage(message) {
      postToHost('clipboard', { message: String(message || '') });
    },
  };
  window.FlutterAppReviewBridge = {
    postMessage(message) {
      postToHost('app-review', { message: String(message || '') });
    },
  };

  window.addEventListener('message', (event) => {
    const message = event.data;
    if (
      event.source !== window.parent ||
      !message ||
      message.manaloomLotusWeb !== true ||
      message.token !== TOKEN ||
      message.kind !== 'eval'
    ) {
      return;
    }

    Promise.resolve().then(() => (0, eval)(String(message.script || '')))
      .then((result) => {
        try {
          postToHost('eval-result', { id: message.id, result });
        } catch (_) {
          postToHost('eval-result', {
            id: message.id,
            result: result == null ? null : String(result),
          });
        }
      })
      .catch((error) => {
        postToHost('eval-result', {
          id: message.id,
          error: error && error.message ? String(error.message) : String(error),
        });
      });
  });
})();
''';
}

String _buildReadyScript(String bridgeToken) {
  final encodedToken = jsonEncode(bridgeToken);
  return '''
(() => {
  const TOKEN = $encodedToken;
  let attempts = 0;
  const reportReady = () => {
    attempts += 1;
    const runtimeReady = !!(
      document.querySelector('.player-card') ||
      document.querySelector('.first-time-user-overlay') ||
      document.querySelector('.menu-button')
    );
    if (!runtimeReady && attempts < 120) {
      setTimeout(reportReady, 50);
      return;
    }
    window.parent.postMessage({
      manaloomLotusWeb: true,
      token: TOKEN,
      kind: 'ready',
      runtimeReady,
    }, '*');
  };
  reportReady();
})();
''';
}

String _safeInlineScript(String value) {
  return value.replaceAll(
    RegExp(r'</script', caseSensitive: false),
    r'<\/script',
  );
}
