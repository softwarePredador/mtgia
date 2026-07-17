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
    Future<bool> Function(String engine, Uri healthUri);

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
          'chk_decks_validation_reasons_array'
        )
        AND convalidated
    ) = 2 AS constraints_ready,
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
        row.length >= 7 && row.take(7).every((value) => value == true);
    return DeckValidationSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['039', '040'],
        if (!healthy) 'error_code': 'deck_validation_schema_not_ready',
      },
    );
  } on Object {
    return const DeckValidationSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['039', '040'],
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
          healthy = await probe(entry.key, baseUri.resolve('/health'));
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

Future<bool> probeBattleSidecarHealth(String engine, Uri healthUri) async {
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
      return false;
    }
    final payload = jsonDecode(body);
    if (payload is! Map) {
      return false;
    }
    final expectedEngine =
        engine == 'native' ? 'manaloom_native_reviewed' : engine;
    return payload['status'] == 'ok' && payload['engine'] == expectedEngine;
  } on Object {
    return false;
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
