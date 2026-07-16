import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lotus_runtime_flags.dart';

typedef LotusAppReviewCallback = void Function(String message);
typedef LotusShellMessageCallback = void Function(String message);
typedef LotusStorageMessageCallback = Future<void> Function(String message);
typedef LotusStorageMessageErrorCallback =
    void Function(Object error, StackTrace stackTrace);

class LotusStorageMessageQueue {
  LotusStorageMessageQueue(
    this._onMessage, {
    LotusStorageMessageErrorCallback? onError,
  }) : _onError = onError ?? _logError;

  final LotusStorageMessageCallback _onMessage;
  final LotusStorageMessageErrorCallback _onError;

  Future<void> _tail = Future<void>.value();
  bool _isClosed = false;

  void enqueue(String message) {
    if (_isClosed) {
      return;
    }

    _tail = _tail.then((_) => _dispatch(message));
  }

  Future<T> enqueueTask<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    if (_isClosed) {
      completer.completeError(
        StateError('Lotus storage message queue is closed'),
      );
      return completer.future;
    }

    _tail = _tail.then((_) async {
      try {
        completer.complete(await task());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> get idle => _tail;

  void close() {
    _isClosed = true;
  }

  Future<void> _dispatch(String message) async {
    try {
      await _onMessage(message);
    } catch (error, stackTrace) {
      try {
        _onError(error, stackTrace);
      } catch (_) {}
    }
  }

  static void _logError(Object error, StackTrace _) {
    debugPrint('$lotusLogPrefix storage bridge callback error: $error');
  }
}

class LotusJavaScriptBridges {
  LotusJavaScriptBridges._();

  static const String clipboardChannelName = 'FlutterClipboardBridge';
  static const String appReviewChannelName = 'FlutterAppReviewBridge';
  static const String shellChannelName = 'FlutterManaLoomShellBridge';
  static const String storageChannelName = 'FlutterManaLoomStorageBridge';

  static LotusStorageMessageQueue register(
    WebViewController controller, {
    required LotusAppReviewCallback onAppReviewRequested,
    required LotusShellMessageCallback onShellMessageRequested,
    required LotusStorageMessageCallback onStorageMessageRequested,
  }) {
    final storageMessageQueue = LotusStorageMessageQueue(
      onStorageMessageRequested,
    );

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
      )
      ..addJavaScriptChannel(
        storageChannelName,
        onMessageReceived: (message) {
          storageMessageQueue.enqueue(message.message);
        },
      );

    return storageMessageQueue;
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
