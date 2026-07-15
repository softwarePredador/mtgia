import 'package:test/test.dart';

import '../lib/ai/battle_engine_config.dart';

void main() {
  test('defaults to auto and requires the primary XMage sidecar', () {
    expect(
      () => BattleEngineConfig.fromEnvironment(const {}),
      throwsA(
        isA<BattleEngineConfigurationException>().having(
          (error) => error.message,
          'message',
          contains('XMAGE_SIDECAR_URL'),
        ),
      ),
    );
  });

  test('auto requires Forge instead of silently skipping the secondary lane',
      () {
    expect(
      () => BattleEngineConfig.fromEnvironment(const {
        'XMAGE_SIDECAR_URL': 'http://xmage:8080',
      }),
      throwsA(
        isA<BattleEngineConfigurationException>().having(
          (error) => error.message,
          'message',
          contains('FORGE_SIDECAR_URL'),
        ),
      ),
    );
  });

  test('auto accepts both pinned sidecar endpoints', () {
    final config = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'auto',
      'XMAGE_SIDECAR_URL': 'http://xmage:8080',
      'FORGE_SIDECAR_URL': 'http://forge:8080',
      'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
    });

    expect(config.mode, 'auto');
    expect(config.xmageSidecarUrl, 'http://xmage:8080');
    expect(config.forgeSidecarUrl, 'http://forge:8080');
    expect(config.nativeSidecarUrl, 'http://native:8080');
  });

  test('native requires the reviewed native sidecar', () {
    expect(
      () => BattleEngineConfig.fromEnvironment(const {
        'BATTLE_ENGINE': 'native',
      }),
      throwsA(isA<BattleEngineConfigurationException>()),
    );
    final config = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'native',
      'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
    });

    expect(config.isNative, isTrue);
  });

  test('auto refuses the legacy in-process native fallback', () {
    expect(
      () => BattleEngineConfig.fromEnvironment(const {
        'BATTLE_ENGINE': 'auto',
        'XMAGE_SIDECAR_URL': 'http://xmage:8080',
        'FORGE_SIDECAR_URL': 'http://forge:8080',
      }),
      throwsA(
        isA<BattleEngineConfigurationException>().having(
          (error) => error.message,
          'message',
          contains('NATIVE_BATTLE_SIDECAR_URL'),
        ),
      ),
    );
  });

  test('strict modes require only their selected engine', () {
    final xmage = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'xmage',
      'XMAGE_SIDECAR_URL': 'http://xmage:8080',
    });
    final forge = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'forge',
      'FORGE_SIDECAR_URL': 'http://forge:8080',
    });

    expect(xmage.isStrictXmage, isTrue);
    expect(forge.isStrictForge, isTrue);
  });

  test('rejects an unknown engine mode', () {
    expect(
      () => BattleEngineConfig.fromEnvironment(const {
        'BATTLE_ENGINE': 'old-runner',
      }),
      throwsA(
        isA<BattleEngineConfigurationException>().having(
          (error) => error.code,
          'code',
          'battle_engine_invalid_configuration',
        ),
      ),
    );
  });
}
