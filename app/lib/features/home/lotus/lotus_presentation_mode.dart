import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract interface class LotusWakeLockController {
  Future<void> setEnabled(bool enabled);
}

final class _WakelockPlusController implements LotusWakeLockController {
  const _WakelockPlusController();

  @override
  Future<void> setEnabled(bool enabled) {
    return WakelockPlus.toggle(enable: enabled);
  }
}

class LotusPresentationMode {
  LotusPresentationMode._(this._wakeLockController);

  @visibleForTesting
  LotusPresentationMode.forTesting({
    required LotusWakeLockController wakeLockController,
  }) : _wakeLockController = wakeLockController;

  static final LotusPresentationMode instance = LotusPresentationMode._(
    const _WakelockPlusController(),
  );

  final LotusWakeLockController _wakeLockController;
  int _activeClients = 0;
  Future<void> _operationQueue = Future<void>.value();

  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  Future<void> enter() {
    _activeClients += 1;
    return _enqueueDesiredState();
  }

  Future<void> exit() {
    if (_activeClients > 0) {
      _activeClients -= 1;
    }
    return _enqueueDesiredState();
  }

  Future<void> refresh() {
    return _enqueueDesiredState();
  }

  Future<void> _enqueueDesiredState() {
    _operationQueue = _operationQueue.then<void>(
      (_) => _applyDesiredState(),
      onError: (Object _, StackTrace _) => _applyDesiredState(),
    );
    return _operationQueue;
  }

  Future<void> _applyDesiredState() async {
    if (_activeClients == 0) {
      await _applyExit();
      return;
    }

    await _setWakeLockEnabled(true);
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

  Future<void> _applyExit() async {
    await _setWakeLockEnabled(false);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }

  Future<void> _setWakeLockEnabled(bool enabled) async {
    try {
      await _wakeLockController.setEnabled(enabled);
    } catch (error) {
      debugPrint(
        '[LotusPresentationMode] could not ${enabled ? 'enable' : 'disable'} '
        'screen wake lock: $error',
      );
    }
  }
}
