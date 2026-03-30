import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lotus_runtime_flags.dart';

typedef LotusAppReviewCallback = void Function(String message);
typedef LotusShellMessageCallback = void Function(String message);

class LotusJavaScriptBridges {
  LotusJavaScriptBridges._();

  static const String clipboardChannelName = 'FlutterClipboardBridge';
  static const String appReviewChannelName = 'FlutterAppReviewBridge';
  static const String shellChannelName = 'FlutterLotusShellBridge';

  static void register(
    WebViewController controller, {
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
  }) {
    controller
      ..addJavaScriptChannel(
        clipboardChannelName,
        onMessageReceived: _handleClipboardMessage,
      )
      ..addJavaScriptChannel(
        appReviewChannelName,
        onMessageReceived: (message) {
          onAppReviewRequested(message.message);
        },
      )
      ..addJavaScriptChannel(
        shellChannelName,
        onMessageReceived: (message) {
          onShellMessageRequested(message.message);
        },
      );
  }

  static Future<void> _handleClipboardMessage(JavaScriptMessage message) async {
    try {
      await Clipboard.setData(ClipboardData(text: message.message));
      debugPrint(
        '$lotusLogPrefix copied ${message.message.length} chars to clipboard',
      );
    } catch (error) {
      debugPrint('$lotusLogPrefix clipboard error: $error');
    }
  }
}
