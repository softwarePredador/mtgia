import 'package:flutter/foundation.dart';

const bool debugLotusBridgeProbe = bool.fromEnvironment(
  'DEBUG_LOTUS_BRIDGE_PROBE',
  defaultValue: false,
);

const bool debugLotusDisableShellCleanup = bool.fromEnvironment(
  'DEBUG_LOTUS_DISABLE_SHELL_CLEANUP',
  defaultValue: false,
);

const Duration lotusLoadingOverlayTimeout = Duration(seconds: 6);
const int lotusLoadingOverlayDismissProgress = 80;
const String lotusAndroidEntryUrl = 'file:///android_asset/lotus/index.html';
const String lotusFlutterAssetEntry = 'assets/lotus/index.html';
const String lotusLogPrefix = '[LotusLifeCounter]';

bool get lotusShouldLoadFromAndroidAssets =>
    defaultTargetPlatform == TargetPlatform.android;

bool get lotusShouldRunBridgeProbe => kDebugMode && debugLotusBridgeProbe;

bool get lotusShouldEnforceShellCleanup => !debugLotusDisableShellCleanup;
