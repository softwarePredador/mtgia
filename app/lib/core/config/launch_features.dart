class LaunchFeatures {
  LaunchFeatures._();

  static const bool scannerEnabled = bool.fromEnvironment(
    'ENABLE_SCANNER_RELEASE',
    defaultValue: false,
  );
}
