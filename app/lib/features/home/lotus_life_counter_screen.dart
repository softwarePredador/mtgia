import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lotus/lotus_host_controller.dart';
import 'lotus/lotus_host_overlays.dart';
import 'lotus/lotus_runtime_flags.dart';

class LotusLifeCounterScreen extends StatefulWidget {
  const LotusLifeCounterScreen({super.key});

  @override
  State<LotusLifeCounterScreen> createState() => _LotusLifeCounterScreenState();
}

class _LotusLifeCounterScreenState extends State<LotusLifeCounterScreen> {
  late final LotusHostController _hostController;
  DateTime? _lastShellMessageAt;
  OverlayEntry? _loadingOverlayEntry;
  OverlayEntry? _errorOverlayEntry;

  @override
  void initState() {
    super.initState();
    _hostController = LotusHostController(
      onAppReviewRequested: _handleAppReviewRequested,
      onShellMessageRequested: _handleShellMessageRequested,
    );
    _hostController.isLoading.addListener(_syncLoadingOverlay);
    _hostController.errorMessage.addListener(_syncErrorOverlay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _syncLoadingOverlay();
      _syncErrorOverlay();
      unawaited(_hostController.loadBundle());
    });
  }

  @override
  void dispose() {
    _hostController.isLoading.removeListener(_syncLoadingOverlay);
    _hostController.errorMessage.removeListener(_syncErrorOverlay);
    _removeLoadingOverlay();
    _removeErrorOverlay();
    _hostController.dispose();
    super.dispose();
  }

  void _syncLoadingOverlay() {
    if (!mounted) {
      return;
    }

    if (_hostController.isLoading.value) {
      _ensureLoadingOverlay();
      return;
    }

    _removeLoadingOverlay();
  }

  void _syncErrorOverlay() {
    if (!mounted) {
      return;
    }

    final errorMessage = _hostController.errorMessage.value;
    if (errorMessage == null) {
      _removeErrorOverlay();
      return;
    }

    _ensureErrorOverlay();
    _errorOverlayEntry?.markNeedsBuild();
  }

  void _ensureLoadingOverlay() {
    if (_loadingOverlayEntry != null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => const LotusLoadingOverlay(),
    );
    overlay.insert(_loadingOverlayEntry!);
  }

  void _removeLoadingOverlay() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
  }

  void _ensureErrorOverlay() {
    if (_errorOverlayEntry != null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _errorOverlayEntry = OverlayEntry(
      builder:
          (context) => LotusErrorOverlay(
            message: _hostController.errorMessage.value ?? '',
            onRetry: () {
              _removeErrorOverlay();
              unawaited(_hostController.loadBundle());
            },
          ),
    );
    overlay.insert(_errorOverlayEntry!);
  }

  void _removeErrorOverlay() {
    _errorOverlayEntry?.remove();
    _errorOverlayEntry = null;
  }

  void _handleAppReviewRequested(String message) {
    debugPrint('$lotusLogPrefix AppReview requested: $message');
  }

  void _handleShellMessageRequested(String message) {
    if (!mounted) {
      return;
    }

    final now = DateTime.now();
    if (_lastShellMessageAt != null &&
        now.difference(_lastShellMessageAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastShellMessageAt = now;

    String displayMessage = 'Lotus external shortcut hidden in ManaLoom.';
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'];
        if (type == 'blocked-window-open' || type == 'blocked-link') {
          displayMessage =
              'This Lotus shortcut is disabled while ManaLoom owns the shell.';
        }
      } else if (message.startsWith('Lotus external link blocked:')) {
        displayMessage =
            'This Lotus shortcut is disabled while ManaLoom owns the shell.';
      }
    } catch (_) {
      if (message.startsWith('Lotus external link blocked:')) {
        displayMessage =
            'This Lotus shortcut is disabled while ManaLoom owns the shell.';
      }
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // A plain body avoids the zero-sized viewport issue we hit when wrapping
      // this PlatformView in a Stack on Android.
      body: WebViewWidget(controller: _hostController.webViewController),
    );
  }
}
