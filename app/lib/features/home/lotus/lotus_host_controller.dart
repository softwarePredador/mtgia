import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/observability/app_observability.dart';
import 'lotus_host.dart';
import 'lotus_js_bridges.dart';
import 'lotus_runtime_flags.dart';
import 'lotus_shell_policy.dart';

class LotusHostController implements LotusHost {
  static const String _bundleLoadErrorMessage =
      'ManaLoom could not open the embedded life counter. '
      'Check the local bundle and try again.';

  LotusHostController({
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
  }) : webViewController = WebViewController(),
       isLoading = ValueNotifier<bool>(true),
       errorMessage = ValueNotifier<String?>(null),
       _onShellMessageRequested = onShellMessageRequested {
    _configure(
      onAppReviewRequested: onAppReviewRequested,
    );
  }

  final WebViewController webViewController;
  @override
  final ValueNotifier<bool> isLoading;
  @override
  final ValueNotifier<String?> errorMessage;
  final LotusShellMessageCallback _onShellMessageRequested;

  bool _didRunBridgeProbe = false;
  bool _isDisposed = false;
  bool _didInjectDebugBundleFailure = false;
  Timer? _loadingOverlayFallbackTimer;

  @override
  Widget buildView(BuildContext context) {
    return WebViewWidget(controller: webViewController);
  }

  @override
  Future<void> loadBundle() async {
    final isRetry = errorMessage.value != null;
    final bundleEntry = _resolveBundleEntry();
    errorMessage.value = null;
    isLoading.value = true;
    unawaited(
      AppObservability.instance.recordEvent(
        isRetry ? 'bundle_retry_requested' : 'bundle_load_started',
        category: 'life_counter.host',
        data: {
          'entry': bundleEntry,
          'is_retry': isRetry,
        },
      ),
    );

    try {
      await webViewController.loadFlutterAsset(bundleEntry);
    } catch (error, stackTrace) {
      debugPrint('$lotusLogPrefix load bundle error: $error');
      errorMessage.value = _bundleLoadErrorMessage;
      dismissLoadingOverlay();
      unawaited(
        AppObservability.instance.recordEvent(
          'bundle_load_failed',
          category: 'life_counter.host',
          level: SentryLevel.error,
          data: {
            'error': error.toString(),
          },
        ),
      );
      unawaited(
        AppObservability.instance.captureException(
          error,
          stackTrace: stackTrace,
          tags: const {
            'source': 'life_counter_host',
            'stage': 'bundle_load',
          },
          extras: {
            'entry': bundleEntry,
            'is_retry': isRetry,
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadingOverlayFallbackTimer?.cancel();
    isLoading.dispose();
    errorMessage.dispose();
  }

  void _configure({
    required LotusAppReviewCallback onAppReviewRequested,
  }) {
    LotusJavaScriptBridges.register(
      webViewController,
      onAppReviewRequested: onAppReviewRequested,
      onShellMessageRequested: _handleShellMessage,
    );

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setOnConsoleMessage(_handleConsoleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _handleProgress,
          onPageFinished: _handlePageFinished,
          onNavigationRequest: _handleNavigationRequest,
          onWebResourceError: _handleWebResourceError,
        ),
      );

    _loadingOverlayFallbackTimer = Timer(
      lotusLoadingOverlayTimeout,
      dismissLoadingOverlay,
    );
  }

  void dismissLoadingOverlay() {
    if (_isDisposed || !isLoading.value) {
      return;
    }

    isLoading.value = false;
  }

  void _handleProgress(int progress) {
    if (progress >= lotusLoadingOverlayDismissProgress) {
      dismissLoadingOverlay();
    }
  }

  void _handlePageFinished(String _) {
    unawaited(
      AppObservability.instance.recordEvent(
        'bundle_load_succeeded',
        category: 'life_counter.host',
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 300),
      dismissLoadingOverlay,
    );
    unawaited(_applyShellCleanupIfNeeded());
    unawaited(_runBridgeProbeIfNeeded());
    unawaited(_runDomProbeIfNeeded());
  }

  void _handleWebResourceError(WebResourceError error) {
    debugPrint(
      '$lotusLogPrefix WebView error: '
      '${error.errorCode} ${error.description}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'web_resource_error',
        category: 'life_counter.host',
        level: SentryLevel.error,
        data: {
          'code': error.errorCode,
          'description': error.description,
          'is_main_frame': error.isForMainFrame ?? true,
        },
      ),
    );

    if (error.isForMainFrame ?? true) {
      errorMessage.value = _bundleLoadErrorMessage;
    }

    dismissLoadingOverlay();
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    if (!lotusShouldEnforceShellCleanup) {
      return NavigationDecision.navigate;
    }

    if (!lotusShouldPreventNavigation(request)) {
      return NavigationDecision.navigate;
    }

    debugPrint(
      '$lotusLogPrefix blocked top-level navigation to ${request.url}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'blocked_top_level_navigation',
        category: 'life_counter.shell',
        data: {
          'url': request.url,
        },
      ),
    );
    _notifyBlockedNavigation(request.url);
    return NavigationDecision.prevent;
  }

  Future<void> _applyShellCleanupIfNeeded() async {
    if (!lotusShouldEnforceShellCleanup || _isDisposed) {
      return;
    }

    try {
      await webViewController.runJavaScript(lotusShellCleanupScript);
    } catch (error) {
      debugPrint('$lotusLogPrefix shell cleanup error: $error');
    }
  }

  Future<void> _runBridgeProbeIfNeeded() async {
    if (!lotusShouldRunBridgeProbe || _didRunBridgeProbe || _isDisposed) {
      return;
    }

    _didRunBridgeProbe = true;

    try {
      final bridgeState = await webViewController.runJavaScriptReturningResult(
        '''
        JSON.stringify({
          cordova: !!window.cordova,
          appReview: !!(
            window.cordova &&
            window.cordova.plugins &&
            window.cordova.plugins.AppReview &&
            window.cordova.plugins.AppReview.requestReview
          ),
          insomnia: !!(
            window.plugins &&
            window.plugins.insomnia &&
            window.plugins.insomnia.keepAwake
          ),
          clipboard: !!(
            navigator.clipboard &&
            navigator.clipboard.writeText
          )
        })
        ''',
      );
      debugPrint('$lotusLogPrefix bridge probe: $bridgeState');

      await webViewController.runJavaScript(
        "navigator.clipboard.writeText('__lotus_clipboard_probe__');",
      );
      await webViewController.runJavaScript(
        "window.cordova.plugins.AppReview.requestReview();",
      );
    } catch (error) {
      debugPrint('$lotusLogPrefix bridge probe error: $error');
    }
  }

  Future<void> _runDomProbeIfNeeded() async {
    if (!lotusShouldRunDomProbe || _isDisposed) {
      return;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (_isDisposed) {
        return;
      }

      final snapshot = await webViewController.runJavaScriptReturningResult('''
        (() => {
          const describeNode = (node) => {
            const style = window.getComputedStyle(node);
            const rect = node.getBoundingClientRect();
            return {
              tag: node.tagName,
              className: node.className,
              id: node.id,
              text: (node.innerText || '').trim().slice(0, 80),
              display: style.display,
              visibility: style.visibility,
              opacity: style.opacity,
              background: style.background,
              color: style.color,
              width: rect.width,
              height: rect.height,
              top: rect.top,
              left: rect.left,
            };
          };

          const firstPlayerCard = document.querySelector('.player-card');
          const firstOverlay = document.querySelector('[class*="overlay"]');

          return JSON.stringify({
            readyState: document.readyState,
            title: document.title,
            bodyChildCount: document.body ? document.body.children.length : -1,
            bodyTextLength: document.body ? (document.body.innerText || '').length : -1,
            bodyClassName: document.body ? document.body.className : null,
            bodyBackground: document.body ? window.getComputedStyle(document.body).background : null,
            bodyColor: document.body ? window.getComputedStyle(document.body).color : null,
            htmlClassName: document.documentElement ? document.documentElement.className : null,
            innerWidth: window.innerWidth,
            innerHeight: window.innerHeight,
            screenWidth: window.screen ? window.screen.width : null,
            screenHeight: window.screen ? window.screen.height : null,
            styleSheetCount: document.styleSheets ? document.styleSheets.length : -1,
            hasContentGlobal: typeof Content !== 'undefined',
            contentIsConnected: typeof Content !== 'undefined' ? Content.isConnected : null,
            contentInnerHtmlLength: typeof Content !== 'undefined' ? Content.innerHTML.length : -1,
            playerCardCount: document.querySelectorAll('.player-card').length,
            emptyPlayerCardCount: document.querySelectorAll('.empty-player-card').length,
            overlayCount: document.querySelectorAll('[class*="overlay"]').length,
            firstPlayerCard: firstPlayerCard ? describeNode(firstPlayerCard) : null,
            firstOverlay: firstOverlay ? describeNode(firstOverlay) : null,
            firstBodyChildren: document.body
              ? Array.from(document.body.children).slice(0, 12).map(describeNode)
              : [],
          });
        })()
        ''');
      debugPrint('$lotusLogPrefix DOM probe: $snapshot');
    } catch (error) {
      debugPrint('$lotusLogPrefix DOM probe error: $error');
    }
  }

  void _notifyBlockedNavigation(String url) {
    _onShellMessageRequested('ManaLoom blocked an external link: $url');
  }

  void _handleConsoleMessage(JavaScriptConsoleMessage message) {
    debugPrint(
      '$lotusLogPrefix console ${message.level.name}: ${message.message}',
    );
    _recordConsoleEvent(message.message);
  }

  void _recordConsoleEvent(String message) {
    final normalizedMessage = message.trim();
    final markers = <String, ({String category, String name})>{
      'Start Cordova Plugins': (
        category: 'life_counter.host',
        name: 'cordova_plugins_started',
      ),
      'Turn and Time Tracker added': (
        category: 'life_counter.gameplay',
        name: 'turn_tracker_enabled',
      ),
      'Planechase: Open Settings': (
        category: 'life_counter.settings',
        name: 'planechase_settings_opened',
      ),
      'Archenemy: Open Settings': (
        category: 'life_counter.settings',
        name: 'archenemy_settings_opened',
      ),
      'Bounty: Click Settings': (
        category: 'life_counter.settings',
        name: 'bounty_settings_opened',
      ),
      'Life History Overlay': (
        category: 'life_counter.history',
        name: 'history_overlay_opened',
      ),
      'Card Search Overlay': (
        category: 'life_counter.search',
        name: 'card_search_overlay_opened',
      ),
    };

    for (final entry in markers.entries) {
      if (!normalizedMessage.contains(entry.key)) {
        continue;
      }

      unawaited(
        AppObservability.instance.recordEvent(
          entry.value.name,
          category: entry.value.category,
          data: {
            'console_message': normalizedMessage,
          },
        ),
      );
      return;
    }
  }

  void _handleShellMessage(String message) {
    final payload = _tryDecodeShellPayload(message);
    if (payload == null) {
      _onShellMessageRequested(message);
      return;
    }

    final type = payload['type'];
    if (type == 'analytics') {
      final name = payload['name'];
      final category = payload['category'];
      if (name is String && category is String) {
        final data = <String, Object?>{};
        final rawData = payload['data'];
        if (rawData is Map) {
          for (final entry in rawData.entries) {
            final key = entry.key;
            if (key is String) {
              data[key] = entry.value;
            }
          }
        }

        unawaited(
          AppObservability.instance.recordEvent(
            name,
            category: category,
            data: data,
          ),
        );
      }
      return;
    }

    if (type == 'blocked-link' || type == 'blocked-window-open') {
      final href = payload['href'];
      unawaited(
        AppObservability.instance.recordEvent(
          'blocked_external_link',
          category: 'life_counter.shell',
          data: {
            'type': type,
            'href': href,
          },
        ),
      );
    }

    _onShellMessageRequested(message);
  }

  Map<String, dynamic>? _tryDecodeShellPayload(String message) {
    try {
      final decoded = lotusDecodeShellPayload(message);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _resolveBundleEntry() {
    if (debugLotusForceBundleFailure) {
      return lotusMissingFlutterAssetEntry;
    }

    if (debugLotusFailFirstBundleLoad && !_didInjectDebugBundleFailure) {
      _didInjectDebugBundleFailure = true;
      return lotusMissingFlutterAssetEntry;
    }

    return lotusFlutterAssetEntry;
  }
}
