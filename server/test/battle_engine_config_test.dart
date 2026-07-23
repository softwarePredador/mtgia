import 'dart:io';

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

  test(
    'auto requires Forge instead of silently skipping the secondary lane',
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
    },
  );

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
      () =>
          BattleEngineConfig.fromEnvironment(const {'BATTLE_ENGINE': 'native'}),
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

  test('pins expected identities and keeps legacy identity opt-in', () {
    final config = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'auto',
      'XMAGE_SIDECAR_URL': 'http://xmage:8080',
      'FORGE_SIDECAR_URL': 'http://forge:8080',
      'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
    });

    expect(config.allowLegacySidecarIdentity, isFalse);
    expect(config.xmageIdentity.commit, pinnedXmageCommit);
    expect(config.xmageIdentity.deterministic, isFalse);
    expect(
      config.xmageIdentity.seedSemantics,
      'request_correlation_only_server_rng_uncontrolled',
    );
    expect(
      File('../services/xmage-sidecar/XMAGE_COMMIT').readAsStringSync().trim(),
      pinnedXmageCommit,
    );
    expect(
      File('../services/forge-sidecar/FORGE_COMMIT').readAsStringSync().trim(),
      pinnedForgeCommit,
    );
  });

  test('canonical deck hashing is order independent and engine-bound', () {
    final config = BattleEngineConfig.fromEnvironment(const {
      'BATTLE_ENGINE': 'auto',
      'XMAGE_SIDECAR_URL': 'http://xmage:8080',
      'FORGE_SIDECAR_URL': 'http://forge:8080',
      'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
    });
    final cards = <Map<String, dynamic>>[
      {'name': 'Commander', 'quantity': 1, 'is_commander': true},
      {'name': 'Plains', 'quantity': 99, 'is_commander': false},
    ];
    final base = <String, dynamic>{
      'request_id': 'request-42',
      'seed': 42,
      'timeout_ms': 40000,
      'max_turns': 30,
      'focus_cards': const ['Sol Ring'],
      'force_focus_access_mode': 'none',
      'same_lane': true,
      'natural_sample': true,
      'deck_a': {'id': 'deck-a', 'cards': cards},
      'deck_b': {'id': 'deck-b', 'cards': cards.reversed.toList()},
    };

    final xmage = buildExternalBattleRequestEnvelope(
      request: base,
      identity: config.xmageIdentity,
    );
    final forge = buildExternalBattleRequestEnvelope(
      request: base,
      identity: config.forgeIdentity,
    );

    expect(
      (xmage['deck_hashes'] as Map)['deck_a'],
      (xmage['deck_hashes'] as Map)['deck_b'],
    );
    expect(
      (xmage['deck_hashes'] as Map)['deck_a'],
      '100fc3b88a03428527c22c037f7b62905e272a8ecec100eb0b385b3cc7d09e7c',
    );
    expect(
      xmage['request_hash'],
      'ad93b5dd41231adc7c9c1a25772aca16a4cc0e418081d6897962edf1153539b6',
    );
    expect(
      forge['request_hash'],
      '4f9ee996b548e718547b58d0dfcf8765e7751c143fd273cc50821a4cb4d17469',
    );
  });

  test('route permits fallback only on structured coverage exceptions', () {
    final route = File('routes/ai/simulate/index.dart').readAsStringSync();

    expect(route, contains('on XmageCoverageIncomplete catch'));
    expect(route, contains('on ForgeCoverageIncomplete catch'));
    expect(route, contains('on XmageServiceException catch'));
    expect(route, contains('on ForgeServiceException catch'));
    expect(route, contains("'operational_timeout_not_eligible'"));
    expect(route, contains("'fallback_allowed': false"));
    expect(route, contains("result['fallback_reason'] = 'none'"));
    expect(route, contains("result['engine_selection_reason']"));
    expect(route, contains("'fallback_eligibility_reason':"));
    expect(
      route,
      isNot(contains("'fallback_reason': 'strict_mode_coverage_incomplete'")),
    );
    expect(
      route,
      isNot(contains("'fallback_reason': 'operational_timeout_not_eligible'")),
    );
    expect(
      route,
      isNot(contains("'fallback_reason': 'operational_failure_not_eligible'")),
    );
    expect(
      route,
      isNot(contains("result['fallback_reason'] = 'xmage_mode_configured'")),
    );
    expect(
      route,
      isNot(contains("result['fallback_reason'] = 'forge_mode_configured'")),
    );
    expect(
      route,
      isNot(contains("result['fallback_reason'] = 'native_mode_configured'")),
    );
    expect(
      route.indexOf('_forgeOrNativeFallback('),
      lessThan(route.lastIndexOf('on XmageServiceException catch')),
    );
  });
}
