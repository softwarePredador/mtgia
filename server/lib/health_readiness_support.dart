import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import 'ai/battle_engine_config.dart';
import 'openai_runtime_config.dart';

class AiRuntimeReadiness {
  const AiRuntimeReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

typedef BattleSidecarProbe =
    Future<Map<String, dynamic>?> Function(String engine, Uri healthUri);

class BattleRuntimeReadiness {
  const BattleRuntimeReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class DeckValidationSchemaReadiness {
  const DeckValidationSchemaReadiness({
    required this.healthy,
    required this.check,
  });

  final bool healthy;
  final Map<String, dynamic> check;
}

class AiJobSchemaReadiness {
  const AiJobSchemaReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class CollectionAvailabilitySchemaReadiness {
  const CollectionAvailabilitySchemaReadiness({
    required this.healthy,
    required this.check,
  });

  final bool healthy;
  final Map<String, dynamic> check;
}

const aiJobSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '048'
        AND name = 'close_ai_job_lifecycle'
    ) AS migration_048_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name IN ('ai_generate_jobs', 'ai_optimize_jobs')
        AND column_name IN (
          'request_key', 'request_fingerprint', 'cancelled_at'
        )
    ) = 6 AS lifecycle_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conname IN (
        'chk_ai_generate_jobs_status',
        'chk_ai_optimize_jobs_status'
      )
        AND convalidated
        AND pg_get_constraintdef(oid) LIKE '%cancelled%'
    ) = 2 AS status_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_index
      WHERE indexrelid IN (
        to_regclass('public.idx_ai_generate_jobs_user_request_key'),
        to_regclass('public.idx_ai_optimize_jobs_user_request_key')
      )
        AND indisvalid
        AND indisready
    ) = 2 AS idempotency_indexes_ready
''';

Future<AiJobSchemaReadiness> evaluateAiJobSchemaReadiness(Pool pool) async {
  try {
    final result = await pool
        .execute(aiJobSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 4 && row.take(4).every((value) => value == true);
    return AiJobSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['048'],
        if (!healthy) 'error_code': 'ai_job_schema_not_ready',
      },
    );
  } on Object {
    return const AiJobSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['048'],
        'error_code': 'ai_job_schema_check_failed',
      },
    );
  }
}

const collectionAvailabilitySchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '045'
        AND name = 'create_collection_availability_contract'
    ) AS migration_045_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '049'
        AND name = 'preserve_binder_physical_identity'
    ) AS migration_049_registered,
    (
      SELECT COUNT(*)
      FROM pg_class
      WHERE oid IN (
        to_regclass('public.collection_availability_snapshot'),
        to_regclass('public.binder_item_availability')
      )
        AND relkind = 'v'
    ) = 2 AS availability_views_ready,
    EXISTS (
      SELECT 1
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.user_binder_items')
        AND conname = 'chk_user_binder_items_language'
        AND convalidated
    ) AS language_constraint_ready,
    EXISTS (
      SELECT 1
      FROM pg_index
      WHERE indexrelid = to_regclass(
        'public.uq_user_binder_items_physical_identity'
      )
        AND indisunique
        AND indisvalid
        AND indisready
        AND pg_get_indexdef(indexrelid) LIKE '%language%'
    ) AS physical_identity_index_ready
''';

Future<CollectionAvailabilitySchemaReadiness>
evaluateCollectionAvailabilitySchemaReadiness(Pool pool) async {
  try {
    final result = await pool
        .execute(collectionAvailabilitySchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 5 && row.take(5).every((value) => value == true);
    return CollectionAvailabilitySchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['045', '049'],
        if (!healthy) 'error_code': 'collection_availability_schema_not_ready',
      },
    );
  } on Object {
    return const CollectionAvailabilitySchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['045', '049'],
        'error_code': 'collection_availability_schema_check_failed',
      },
    );
  }
}

const deckValidationSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '039'
        AND name = 'persist_deck_validation_review_state'
    ) AS migration_039_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '040'
        AND name = 'align_cards_reserved_runtime_schema'
    ) AS migration_040_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '047'
        AND name = 'close_deck_validation_state_transitions'
    ) AS migration_047_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'decks'
        AND column_name IN (
          'validation_state',
          'validation_reasons',
          'validation_updated_at'
        )
    ) = 3 AS columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.decks')
        AND conname IN (
          'chk_decks_validation_state',
          'chk_decks_validation_reasons_array',
          'chk_decks_validation_state_payload'
        )
        AND convalidated
    ) = 3 AS constraints_ready,
    EXISTS (
      SELECT 1
      FROM pg_index
      WHERE indexrelid = to_regclass(
        'public.idx_decks_user_validation_state'
      )
        AND indisvalid
        AND indisready
    ) AS index_ready,
    (
      SELECT COUNT(*)
      FROM pg_trigger
      WHERE tgname IN (
          'manaloom_deck_cards_require_review',
          'manaloom_deck_format_require_review'
        )
        AND tgenabled IN ('O', 'A')
        AND NOT tgisinternal
    ) = 2 AS triggers_ready,
    EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'cards'
        AND column_name = 'is_reserved'
        AND data_type = 'boolean'
        AND is_nullable = 'NO'
        AND lower(column_default) = 'false'
    ) AS cards_reserved_ready
''';

Future<DeckValidationSchemaReadiness> evaluateDeckValidationSchemaReadiness(
  Pool pool,
) async {
  try {
    final result = await pool
        .execute(deckValidationSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 8 && row.take(8).every((value) => value == true);
    return DeckValidationSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['039', '040', '047'],
        if (!healthy) 'error_code': 'deck_validation_schema_not_ready',
      },
    );
  } on Object {
    return const DeckValidationSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['039', '040', '047'],
        'error_code': 'deck_validation_schema_check_failed',
      },
    );
  }
}

/// Verifies the exact engine set required by [BattleEngineConfig].
///
/// The response deliberately omits sidecar URLs and exception messages so the
/// public readiness endpoint cannot disclose internal network coordinates.
Future<BattleRuntimeReadiness> evaluateBattleRuntimeReadiness(
  DotEnv env, {
  BattleSidecarProbe probe = probeBattleSidecarHealth,
}) async {
  late final BattleEngineConfig config;
  try {
    config = BattleEngineConfig.fromEnvironment({
      for (final key in const [
        'BATTLE_ENGINE',
        'XMAGE_SIDECAR_URL',
        'FORGE_SIDECAR_URL',
        'NATIVE_BATTLE_SIDECAR_URL',
        'XMAGE_EXPECTED_COMMIT',
        'FORGE_EXPECTED_COMMIT',
        'XMAGE_EXPECTED_VERSION',
        'FORGE_EXPECTED_VERSION',
        'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
      ])
        if (env[key] case final String value) key: value,
    });
  } on BattleEngineConfigurationException catch (error) {
    return BattleRuntimeReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'mode': (env['BATTLE_ENGINE'] ?? 'auto').trim().toLowerCase(),
        'error_code': error.code,
      },
    );
  }

  final requiredUrls = <String, String>{
    if (config.mode == 'auto' || config.mode == 'xmage')
      'xmage': config.xmageSidecarUrl,
    if (config.mode == 'auto' || config.mode == 'forge')
      'forge': config.forgeSidecarUrl,
    if (config.mode == 'auto' || config.mode == 'native')
      'native': config.nativeSidecarUrl,
  };

  final engineChecks = <String, Map<String, dynamic>>{};
  await Future.wait(
    requiredUrls.entries.map((entry) async {
      final stopwatch = Stopwatch()..start();
      var healthy = false;
      var errorCode = 'battle_sidecar_unavailable';
      final baseUri = Uri.tryParse(entry.value);
      if (baseUri == null ||
          !const {'http', 'https'}.contains(baseUri.scheme) ||
          baseUri.host.isEmpty) {
        errorCode = 'battle_sidecar_invalid_url';
      } else {
        try {
          final payload = await probe(entry.key, baseUri.resolve('/health'));
          if (payload == null) {
            healthy = false;
          } else if (entry.key == 'native') {
            healthy =
                payload['status'] == 'ok' &&
                payload['engine'] == 'manaloom_native_reviewed';
            if (!healthy) errorCode = 'battle_sidecar_identity_mismatch';
          } else {
            final expected =
                entry.key == 'xmage'
                    ? config.xmageIdentity
                    : config.forgeIdentity;
            final identityError = externalBattleIdentityValidationError(
              payload,
              expected: expected,
              allowLegacy: config.allowLegacySidecarIdentity,
            );
            healthy = payload['status'] == 'ok' && identityError == null;
            if (identityError != null) {
              errorCode = 'battle_sidecar_identity_mismatch';
            }
          }
        } catch (_) {
          healthy = false;
        }
      }
      stopwatch.stop();
      engineChecks[entry.key] = {
        'status': healthy ? 'healthy' : 'unhealthy',
        'latency_ms': stopwatch.elapsedMilliseconds,
        if (!healthy) 'error_code': errorCode,
      };
    }),
  );

  final healthy =
      engineChecks.length == requiredUrls.length &&
      engineChecks.values.every((check) => check['status'] == 'healthy');
  return BattleRuntimeReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'healthy' : 'unhealthy',
      'mode': config.mode,
      'engines': engineChecks,
      if (!healthy) 'error_code': 'battle_runtime_not_ready',
    },
  );
}

Future<Map<String, dynamic>?> probeBattleSidecarHealth(
  String engine,
  Uri healthUri,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client
        .getUrl(healthUri)
        .timeout(const Duration(seconds: 2));
    final response = await request.close().timeout(const Duration(seconds: 2));
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 2));
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }
    final payload = jsonDecode(body);
    if (payload is! Map) {
      return null;
    }
    return payload.cast<String, dynamic>();
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

AiRuntimeReadiness evaluateAiRuntimeReadiness(DotEnv env) {
  final config = OpenAiRuntimeConfig(env);
  final providerConfigured = (env['OPENAI_API_KEY'] ?? '').trim().isNotEmpty;
  final healthy =
      !config.isProductionLike ||
      (providerConfigured && !config.allowsMockFallbacks);

  return AiRuntimeReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'healthy' : 'unhealthy',
      'profile': config.profile,
      'provider_configured': providerConfigured,
      'mock_fallbacks_allowed': config.allowsMockFallbacks,
      'models': config.selectedModels,
      if (!healthy) 'error_code': 'ai_provider_not_ready',
    },
  );
}

Map<String, dynamic> buildReadinessResponseBody({
  required Map<String, dynamic> checks,
  required bool allHealthy,
  DateTime? now,
  String? environment,
  bool e2eIsolatedRuntime = false,
}) {
  return {
    'status': allHealthy ? 'ready' : 'not_ready',
    'service': 'mtgia-server',
    'timestamp': (now ?? DateTime.now()).toIso8601String(),
    'environment':
        environment ?? Platform.environment['ENVIRONMENT'] ?? 'development',
    'e2e_isolated_runtime': e2eIsolatedRuntime,
    'checks': checks,
  };
}

int readinessStatusCode(bool allHealthy) =>
    allHealthy ? HttpStatus.ok : HttpStatus.serviceUnavailable;
