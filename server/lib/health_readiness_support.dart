import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'openai_runtime_config.dart';

class AiRuntimeReadiness {
  const AiRuntimeReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
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
