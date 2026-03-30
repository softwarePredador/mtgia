import 'package:flutter/foundation.dart';

const bool debugLotusBridgeProbe = bool.fromEnvironment(
  'DEBUG_LOTUS_BRIDGE_PROBE',
  defaultValue: false,
);

const bool debugLotusDomProbe = bool.fromEnvironment(
  'DEBUG_LOTUS_DOM_PROBE',
  defaultValue: false,
);

const bool debugLotusDisableShellCleanup = bool.fromEnvironment(
  'DEBUG_LOTUS_DISABLE_SHELL_CLEANUP',
  defaultValue: false,
);

const bool debugLotusForceBundleFailure = bool.fromEnvironment(
  'DEBUG_LOTUS_FORCE_BUNDLE_FAILURE',
  defaultValue: false,
);

const bool debugLotusFailFirstBundleLoad = bool.fromEnvironment(
  'DEBUG_LOTUS_FAIL_FIRST_BUNDLE_LOAD',
  defaultValue: false,
);

const Duration lotusLoadingOverlayTimeout = Duration(seconds: 6);
const int lotusLoadingOverlayDismissProgress = 80;
const String lotusFlutterAssetEntry = 'assets/lotus/index.html';
const String lotusMissingFlutterAssetEntry = 'assets/lotus/__missing__.html';
const String lotusLogPrefix = '[LotusLifeCounter]';

bool get lotusShouldRunBridgeProbe => kDebugMode && debugLotusBridgeProbe;
bool get lotusShouldRunDomProbe => kDebugMode && debugLotusDomProbe;

bool get lotusShouldEnforceShellCleanup => !debugLotusDisableShellCleanup;
