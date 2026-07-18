import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LotusPresentationMode {
  LotusPresentationMode._();

  static int _activeClients = 0;
  static Future<void> _operationQueue = Future<void>.value();

  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static Future<void> enter() {
    _activeClients += 1;
    return _enqueueDesiredState();
  }

  static Future<void> exit() {
    if (_activeClients > 0) {
      _activeClients -= 1;
    }
    return _enqueueDesiredState();
  }

  static Future<void> _enqueueDesiredState() {
    _operationQueue = _operationQueue.then<void>(
      (_) => _applyDesiredState(),
      onError: (Object _, StackTrace _) => _applyDesiredState(),
    );
    return _operationQueue;
  }

  static Future<void> _applyDesiredState() async {
    if (_activeClients == 0) {
      await _applyExit();
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [],
    );
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }

  static Future<void> _applyExit() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }
}
