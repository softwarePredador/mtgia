import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/observability/app_observability.dart';
import 'life_counter_route.dart';
import 'lotus/lotus_host.dart';
import 'lotus/lotus_host_controller.dart';
import 'lotus/lotus_host_overlays.dart';
import 'lotus/lotus_runtime_flags.dart';

class LotusLifeCounterScreen extends StatefulWidget {
  const LotusLifeCounterScreen({super.key, this.hostFactory});

  final LotusHostFactory? hostFactory;

  @override
  State<LotusLifeCounterScreen> createState() => _LotusLifeCounterScreenState();
}

class _LotusLifeCounterScreenState extends State<LotusLifeCounterScreen> {
  late final LotusHost _hostController;
  DateTime? _lastShellMessageAt;
  OverlayEntry? _loadingOverlayEntry;
  OverlayEntry? _errorOverlayEntry;

  @override
  void initState() {
    super.initState();
    _hostController =
        (widget.hostFactory ?? LotusHostController.new)(
      onAppReviewRequested: _handleAppReviewRequested,
      onShellMessageRequested: _handleShellMessageRequested,
    );
    unawaited(
      AppObservability.instance.recordEvent(
        'opened',
        category: 'life_counter.screen',
        data: {
          'route': lifeCounterRoutePath,
          'implementation': 'embedded_lotus',
        },
      ),
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
    unawaited(
      AppObservability.instance.recordEvent(
        'closed',
        category: 'life_counter.screen',
        data: {
          'route': lifeCounterRoutePath,
          'implementation': 'embedded_lotus',
        },
      ),
    );
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
    unawaited(
      AppObservability.instance.recordEvent(
        'app_review_requested',
        category: 'life_counter.shell',
        data: {
          'message': message,
        },
      ),
    );
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

    var displayMessage =
        'External shortcut disabled while ManaLoom owns the life counter shell.';
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'];
        if (type == 'blocked-window-open' || type == 'blocked-link') {
          displayMessage =
              'External shortcut disabled while ManaLoom owns the life counter shell.';
        }
      } else if (message.startsWith('ManaLoom blocked an external link:')) {
        displayMessage =
            'External shortcut disabled while ManaLoom owns the life counter shell.';
      }
    } catch (_) {
      if (message.startsWith('ManaLoom blocked an external link:')) {
        displayMessage =
            'External shortcut disabled while ManaLoom owns the life counter shell.';
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
      body: _hostController.buildView(context),
    );
  }
}
