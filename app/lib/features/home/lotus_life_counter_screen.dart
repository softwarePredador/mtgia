import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lotus/lotus_host_controller.dart';
import 'lotus/lotus_runtime_flags.dart';

class LotusLifeCounterScreen extends StatefulWidget {
  const LotusLifeCounterScreen({super.key});

  @override
  State<LotusLifeCounterScreen> createState() => _LotusLifeCounterScreenState();
}

class _LotusLifeCounterScreenState extends State<LotusLifeCounterScreen> {
  late final LotusHostController _hostController;
  DateTime? _lastShellMessageAt;

  @override
  void initState() {
    super.initState();
    _hostController = LotusHostController(
      onAppReviewRequested: _handleAppReviewRequested,
      onShellMessageRequested: _handleShellMessageRequested,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_hostController.loadBundle());
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
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
