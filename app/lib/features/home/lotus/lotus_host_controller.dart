import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lotus_js_bridges.dart';
import 'lotus_runtime_flags.dart';
import 'lotus_shell_policy.dart';

class LotusHostController {
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
      onShellMessageRequested: onShellMessageRequested,
    );
  }

  final WebViewController webViewController;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<String?> errorMessage;
  final LotusShellMessageCallback _onShellMessageRequested;

  bool _didRunBridgeProbe = false;
  bool _isDisposed = false;
  bool _didInjectDebugBundleFailure = false;
  Timer? _loadingOverlayFallbackTimer;

  Future<void> loadBundle() async {
    errorMessage.value = null;
    isLoading.value = true;

    try {
      await webViewController.loadFlutterAsset(_resolveBundleEntry());
    } catch (error) {
      debugPrint('$lotusLogPrefix load bundle error: $error');
      errorMessage.value = _bundleLoadErrorMessage;
      dismissLoadingOverlay();
    }
  }

  void dispose() {
    _isDisposed = true;
    _loadingOverlayFallbackTimer?.cancel();
    isLoading.dispose();
    errorMessage.dispose();
  }

  void _configure({
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
  }) {
    LotusJavaScriptBridges.register(
      webViewController,
      onAppReviewRequested: onAppReviewRequested,
      onShellMessageRequested: onShellMessageRequested,
    );

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setOnConsoleMessage((message) {
        debugPrint(
          '$lotusLogPrefix console '
          '${message.level.name}: ${message.message}',
        );
      })
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
