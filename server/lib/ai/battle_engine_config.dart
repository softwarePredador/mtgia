final class BattleEngineConfigurationException implements Exception {
  const BattleEngineConfigurationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

final class BattleEngineConfig {
  const BattleEngineConfig({
    required this.mode,
    required this.xmageSidecarUrl,
    required this.forgeSidecarUrl,
    required this.nativeSidecarUrl,
  });

  factory BattleEngineConfig.fromEnvironment(Map<String, String> environment) {
    final mode = (environment['BATTLE_ENGINE'] ?? 'auto').trim().toLowerCase();
    if (!const {'auto', 'xmage', 'forge', 'native'}.contains(mode)) {
      throw const BattleEngineConfigurationException(
        'battle_engine_invalid_configuration',
        'BATTLE_ENGINE must be auto, xmage, forge, or native',
      );
    }

    final xmageSidecarUrl = (environment['XMAGE_SIDECAR_URL'] ?? '').trim();
    final forgeSidecarUrl = (environment['FORGE_SIDECAR_URL'] ?? '').trim();
    final nativeSidecarUrl =
        (environment['NATIVE_BATTLE_SIDECAR_URL'] ?? '').trim();

    if ((mode == 'auto' || mode == 'xmage') && xmageSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_not_configured',
        'XMAGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }
    if ((mode == 'auto' || mode == 'forge') && forgeSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_not_configured',
        'FORGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }
    if ((mode == 'auto' || mode == 'native') && nativeSidecarUrl.isEmpty) {
      throw BattleEngineConfigurationException(
        '${mode}_native_not_configured',
        'NATIVE_BATTLE_SIDECAR_URL is required for BATTLE_ENGINE=$mode',
      );
    }

    return BattleEngineConfig(
      mode: mode,
      xmageSidecarUrl: xmageSidecarUrl,
      forgeSidecarUrl: forgeSidecarUrl,
      nativeSidecarUrl: nativeSidecarUrl,
    );
  }

  final String mode;
  final String xmageSidecarUrl;
  final String forgeSidecarUrl;
  final String nativeSidecarUrl;

  bool get isNative => mode == 'native';
  bool get isStrictXmage => mode == 'xmage';
  bool get isStrictForge => mode == 'forge';
}
