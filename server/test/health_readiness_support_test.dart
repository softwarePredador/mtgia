import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/ai/battle_engine_config.dart';
import '../lib/health_readiness_support.dart';

void main() {
  group('health_readiness_support', () {
    test('builds ready response body', () {
      final body = buildReadinessResponseBody(
        checks: const {
          'database': {'status': 'healthy'},
        },
        allHealthy: true,
        now: DateTime.parse('2026-03-24T00:00:00.000Z'),
        environment: 'staging',
        e2eIsolatedRuntime: true,
      );

      expect(body['status'], equals('ready'));
      expect(body['service'], equals('mtgia-server'));
      expect(body['environment'], equals('staging'));
      expect(body['e2e_isolated_runtime'], isTrue);
      expect(body['checks'], isA<Map<String, dynamic>>());
    });

    test('maps unhealthy readiness to 503', () {
      expect(readinessStatusCode(false), equals(503));
      expect(readinessStatusCode(true), equals(200));
    });

    test(
      'Deckbuilder schema readiness requires the closed state migrations',
      () {
        expect(deckValidationSchemaReadinessSql, contains("version = '039'"));
        expect(deckValidationSchemaReadinessSql, contains("version = '040'"));
        expect(deckValidationSchemaReadinessSql, contains("version = '047'"));
        expect(
          deckValidationSchemaReadinessSql,
          contains("column_name = 'is_reserved'"),
        );
        expect(
          deckValidationSchemaReadinessSql,
          contains('manaloom_deck_cards_require_review'),
        );
        expect(
          deckValidationSchemaReadinessSql,
          contains('chk_decks_validation_state_payload'),
        );
      },
    );

    test('AI job readiness requires cancellable idempotent lifecycle', () {
      expect(aiJobSchemaReadinessSql, contains("version = '048'"));
      expect(aiJobSchemaReadinessSql, contains("'request_key'"));
      expect(aiJobSchemaReadinessSql, contains("'request_fingerprint'"));
      expect(aiJobSchemaReadinessSql, contains("'cancelled_at'"));
      expect(
        aiJobSchemaReadinessSql,
        contains('idx_ai_generate_jobs_user_request_key'),
      );
      expect(
        aiJobSchemaReadinessSql,
        contains('idx_ai_optimize_jobs_user_request_key'),
      );
      expect(aiJobSchemaReadinessSql, contains("LIKE '%cancelled%'"));
    });

    test(
      'collection readiness requires playable and physical identity contracts',
      () {
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains("version = '045'"),
        );
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains("version = '049'"),
        );
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains('collection_availability_snapshot'),
        );
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains('binder_item_availability'),
        );
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains('uq_user_binder_items_physical_identity'),
        );
        expect(
          collectionAvailabilitySchemaReadinessSql,
          contains('chk_user_binder_items_language'),
        );
      },
    );

    test('production AI readiness requires a configured provider', () {
      final missingProvider = evaluateAiRuntimeReadiness(
        DotEnv()..addAll({'ENVIRONMENT': 'production'}),
      );
      final configuredProvider = evaluateAiRuntimeReadiness(
        DotEnv()..addAll({
          'ENVIRONMENT': 'production',
          'OPENAI_PROFILE': 'dev',
          'OPENAI_API_KEY': 'configured-but-never-exposed',
        }),
      );

      expect(missingProvider.healthy, isFalse);
      expect(missingProvider.check['provider_configured'], isFalse);
      expect(missingProvider.check, isNot(contains('OPENAI_API_KEY')));
      expect(configuredProvider.healthy, isTrue);
      expect(configuredProvider.check['profile'], 'prod');
      expect(configuredProvider.check['mock_fallbacks_allowed'], isFalse);
      expect(
        (configuredProvider.check['models'] as Map)['optimize'],
        'gpt-5.4-mini',
      );
    });

    test(
      'auto Battle readiness requires all three configured engines',
      () async {
        final probed = <String>[];
        final readiness = await evaluateBattleRuntimeReadiness(
          DotEnv()..addAll({
            'BATTLE_ENGINE': 'auto',
            'XMAGE_SIDECAR_URL': 'http://xmage:8080',
            'FORGE_SIDECAR_URL': 'http://forge:8080',
            'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
          }),
          probe: (engine, uri) async {
            probed.add('$engine:${uri.path}');
            return _battleHealth(engine);
          },
        );

        expect(readiness.healthy, isTrue);
        expect(readiness.check['mode'], 'auto');
        expect(
          probed,
          containsAll(<String>[
            'xmage:/health',
            'forge:/health',
            'native:/health',
          ]),
        );
      },
    );

    test('Battle readiness fails closed on an unavailable engine', () async {
      final readiness = await evaluateBattleRuntimeReadiness(
        DotEnv()..addAll({
          'BATTLE_ENGINE': 'auto',
          'XMAGE_SIDECAR_URL': 'http://xmage:8080',
          'FORGE_SIDECAR_URL': 'http://forge:8080',
          'NATIVE_BATTLE_SIDECAR_URL': 'http://native:8080',
        }),
        probe:
            (engine, uri) async =>
                engine == 'forge' ? null : _battleHealth(engine),
      );

      expect(readiness.healthy, isFalse);
      expect(readiness.check['error_code'], 'battle_runtime_not_ready');
      expect(
        (readiness.check['engines'] as Map)['forge'],
        containsPair('status', 'unhealthy'),
      );
    });

    test(
      'Battle readiness rejects a stronger XMage determinism claim',
      () async {
        final readiness = await evaluateBattleRuntimeReadiness(
          DotEnv()..addAll({
            'BATTLE_ENGINE': 'xmage',
            'XMAGE_SIDECAR_URL': 'http://xmage:8080',
          }),
          probe: (engine, uri) async {
            return _battleHealth(engine)..['deterministic'] = true;
          },
        );

        expect(readiness.healthy, isFalse);
        expect(
          (readiness.check['engines'] as Map)['xmage'],
          containsPair('error_code', 'battle_sidecar_identity_mismatch'),
        );
      },
    );

    test(
      'Battle readiness does not leak invalid configuration details',
      () async {
        final readiness = await evaluateBattleRuntimeReadiness(DotEnv());

        expect(readiness.healthy, isFalse);
        expect(readiness.check['error_code'], 'auto_not_configured');
        expect(readiness.check, isNot(contains('XMAGE_SIDECAR_URL')));
      },
    );
  });

  group('ready route contract', () {
    test('/ready delegates to /health/ready handler', () {
      final route = File('routes/ready/index.dart').readAsStringSync();
      final contract =
          File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();

      expect(route, contains("import '../health/ready/index.dart'"));
      expect(route, contains('health_ready.onRequest(context)'));
      expect(
        contract,
        contains('| `GET /ready` | internal/stable ops alias |'),
      );
      expect(
        contract,
        isNot(contains('| `GET /ready` | internal/deprecated |')),
      );
    });

    test('readiness reports latency without leaking dependency exceptions', () {
      final route = File('routes/health/ready/index.dart').readAsStringSync();

      expect(route, contains('databaseStopwatch.elapsedMilliseconds'));
      expect(route, contains('cardsStopwatch.elapsedMilliseconds'));
      expect(route, contains("'error_code': 'database_check_failed'"));
      expect(route, contains("'error_code': 'cards_data_check_failed'"));
      expect(route, isNot(contains("'error': e.toString()")));
      expect(route, isNot(contains("'latency_ms': null")));
      expect(route, contains('isManaloomE2eIsolatedRuntime()'));
      expect(route, contains("checks['ai_runtime'] = aiRuntime.check"));
      expect(route, contains("checks['battle_runtime'] = battleRuntime.check"));
      expect(
        route,
        contains(
          "checks['deck_validation_schema'] = deckValidationSchema.check",
        ),
      );
      expect(route, contains("checks['collection_availability_schema'] ="));
    });
  });
}

Map<String, dynamic> _battleHealth(String engine) {
  if (engine == 'native') {
    return const {'status': 'ok', 'engine': 'manaloom_native_reviewed'};
  }
  final isXmage = engine == 'xmage';
  final commit = isXmage ? pinnedXmageCommit : pinnedForgeCommit;
  return {
    'schema_version': externalBattleExecutionSchema,
    'status': 'ok',
    'engine': engine,
    'engine_version': isXmage ? pinnedXmageVersion : pinnedForgeVersion,
    'engine_commit': commit,
    'sidecar_protocol_version': externalBattleSidecarProtocol,
    'sidecar_build_identity': '$engine-sidecar-v2@$commit',
    'sidecar_process_id': '$engine-process',
    'sidecar_started_at': '2026-07-22T12:00:00Z',
    'ai_profile': isXmage ? 'computer_mad' : 'forge_default_ai',
    isXmage ? 'normalizer_version' : 'parser_version':
        isXmage ? 'xmage_replay_normalizer_v2' : 'forge_log_parser_v2',
    'seed_semantics':
        isXmage
            ? 'request_correlation_only_server_rng_uncontrolled'
            : 'engine_rng_seeded_not_replay_guarantee',
    'deterministic': false,
  };
}
