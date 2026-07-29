class LaunchFeatures {
  LaunchFeatures._();

  static const bool scannerEnabled = bool.fromEnvironment(
    'ENABLE_SCANNER_RELEASE',
    defaultValue: false,
  );

  /// Async Battle jobs and the live spectator stay fail-closed until the
  /// backend polling contract is homologated in the target environment.
  static const bool battleLiveSpectatorEnabled = bool.fromEnvironment(
    'ENABLE_BATTLE_LIVE_SPECTATOR',
    defaultValue: false,
  );

  /// Human-in-the-loop battle sessions require a dedicated interactive rules
  /// runtime and PostgreSQL session store. Keep the surface fail-closed until
  /// both runtimes are explicitly enabled in the target environment.
  static const bool interactiveBattleEnabled = bool.fromEnvironment(
    'ENABLE_INTERACTIVE_BATTLE',
    defaultValue: false,
  );
}
