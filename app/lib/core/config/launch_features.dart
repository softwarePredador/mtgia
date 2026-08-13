class LaunchFeatures {
  LaunchFeatures._();

  /// Technical support compiled into this artifact.
  ///
  /// This flag is never an authorization decision. Runtime access also
  /// requires the server capability `scanner.allowed == true`.
  static const bool scannerSupported = bool.fromEnvironment(
    'ENABLE_SCANNER_RELEASE',
    defaultValue: false,
  );

  /// Compatibility alias for scanner widgets that have not yet migrated to
  /// the server-authoritative capability provider.
  static const bool scannerEnabled = scannerSupported;

  /// Async Battle jobs and the live spectator stay fail-closed until the
  /// backend polling contract is homologated in the target environment. This
  /// is build support only; `battle_live.allowed` remains authoritative.
  static const bool battleLiveSpectatorSupported = bool.fromEnvironment(
    'ENABLE_BATTLE_LIVE_SPECTATOR',
    defaultValue: false,
  );

  static const bool battleLiveSpectatorEnabled = battleLiveSpectatorSupported;

  /// Human-in-the-loop battle sessions require a dedicated interactive rules
  /// runtime and PostgreSQL session store. Keep the surface fail-closed until
  /// both runtimes are explicitly enabled in the target environment. This is
  /// build support only; `battle_coach.allowed` remains authoritative.
  static const bool interactiveBattleSupported = bool.fromEnvironment(
    'ENABLE_INTERACTIVE_BATTLE',
    defaultValue: false,
  );

  static const bool interactiveBattleEnabled = interactiveBattleSupported;
}
