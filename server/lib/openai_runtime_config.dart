import 'dart:io' show InternetAddress;

import 'package:dotenv/dotenv.dart';

class OpenAiRuntimeConfig {
  final DotEnv env;

  OpenAiRuntimeConfig(this.env);

  String get _profile {
    final environment = env['ENVIRONMENT']?.trim().toLowerCase();
    // Production is fail-closed: an accidentally persisted development
    // profile must never re-enable mock/provider fallbacks in a live runtime.
    if (environment == 'production' || environment == 'prod') {
      return 'prod';
    }

    final explicit = env['OPENAI_PROFILE']?.trim().toLowerCase();
    if (explicit == 'dev' || explicit == 'staging' || explicit == 'prod') {
      return explicit!;
    }

    if (environment == 'staging' || environment == 'stage') {
      return 'staging';
    }
    return 'dev';
  }

  String get profile => _profile;

  bool get isProductionLike => _profile == 'prod';

  bool get allowsMockFallbacks => !isProductionLike;

  /// Base fixa do provedor de chat. É a única cópia da URL no servidor
  /// (`lib` e `routes`); toda chamada usa [chatCompletionsUri].
  static const defaultBaseUrl = 'https://api.openai.com/v1';

  /// Variável que troca a base fora da produção (D-83, `BT-AI-029`).
  static const baseUrlEnvironment = 'OPENAI_BASE_URL';

  /// Endpoint de chat completions de toda chamada ao provedor.
  ///
  /// Na produção (perfil `prod`) é sempre [defaultBaseUrl]: nenhuma variável
  /// de ambiente desvia o tráfego nem a chave. Fora dela, `OPENAI_BASE_URL`
  /// pode apontar para um provedor falso local, mas só em loopback
  /// (127.0.0.0/8, `::1` ou `localhost`), por http ou https, sem usuário,
  /// consulta ou fragmento. Qualquer outro valor é ignorado, e a chamada vai
  /// para a URL fixa, como antes.
  Uri get chatCompletionsUri =>
      Uri.parse('${providerBaseUrl}/chat/completions');

  /// A base efetivamente usada: a de `OPENAI_BASE_URL` quando ela é aceita,
  /// senão [defaultBaseUrl].
  String get providerBaseUrl => acceptedBaseUrlOverride ?? defaultBaseUrl;

  /// `OPENAI_BASE_URL` aceita, sem a barra final, ou `null` quando ela está
  /// vazia, na produção ou fora do loopback.
  String? get acceptedBaseUrlOverride {
    if (isProductionLike) return null;
    final raw = env[baseUrlEnvironment]?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return null;
    }
    if (!isLoopbackHost(uri.host)) return null;
    var base = uri.toString();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  /// `OPENAI_BASE_URL` veio preenchida e foi recusada (produção ou host fora
  /// do loopback). Serve para diagnóstico; a chamada segue na URL fixa.
  bool get ignoresBaseUrlOverride {
    final raw = env[baseUrlEnvironment]?.trim();
    return raw != null && raw.isNotEmpty && acceptedBaseUrlOverride == null;
  }

  /// Loopback de verdade: um literal IP de loopback ou o nome `localhost`.
  static bool isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized == 'localhost') return true;
    final address = InternetAddress.tryParse(normalized);
    return address != null && address.isLoopback;
  }

  String get generateModel => modelFor(
    key: 'OPENAI_MODEL_GENERATE',
    fallback: 'gpt-4o-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-4o-mini',
  );

  String get archetypesModel => modelFor(
    key: 'OPENAI_MODEL_ARCHETYPES',
    fallback: 'gpt-4o-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-4o-mini',
  );

  String get explainModel => modelFor(
    key: 'OPENAI_MODEL_EXPLAIN',
    fallback: 'gpt-4o-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-4o-mini',
  );

  String get analysisModel => modelFor(
    key: 'OPENAI_MODEL_AI_ANALYSIS',
    fallback: 'gpt-4o-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-4o-mini',
  );

  String get optimizeModel => modelFor(
    key: 'OPENAI_MODEL_OPTIMIZE',
    fallback: 'gpt-5.4-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-5.4-mini',
  );

  String get completeModel => modelFor(
    key: 'OPENAI_MODEL_COMPLETE',
    fallback: 'gpt-5.4-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-5.4-mini',
  );

  String get optimizationCriticModel => modelFor(
    key: 'OPENAI_MODEL_OPTIMIZATION_CRITIC',
    fallback: 'gpt-4o-mini',
    devFallback: 'gpt-4o-mini',
    stagingFallback: 'gpt-4o-mini',
    prodFallback: 'gpt-4o-mini',
  );

  Map<String, String> get selectedModels => {
    'generate': generateModel,
    'archetypes': archetypesModel,
    'explain': explainModel,
    'analysis': analysisModel,
    'optimize': optimizeModel,
    'complete': completeModel,
    'optimization_critic': optimizationCriticModel,
  };

  bool shouldUseFallbackForInvalidApiKey({
    required int statusCode,
    required String responseBody,
  }) {
    if (isProductionLike || statusCode != 401) return false;

    final body = responseBody.toLowerCase();
    return body.contains('invalid_api_key') ||
        body.contains('incorrect api key') ||
        body.contains('openai api error');
  }

  String modelFor({
    required String key,
    required String fallback,
    String? devFallback,
    String? stagingFallback,
    String? prodFallback,
  }) {
    final value = env[key]?.trim();
    if (value == null || value.isEmpty) {
      switch (_profile) {
        case 'dev':
          return devFallback ?? fallback;
        case 'staging':
          return stagingFallback ?? fallback;
        case 'prod':
          return prodFallback ?? fallback;
        default:
          return fallback;
      }
    }
    return value;
  }

  double temperatureFor({
    required String key,
    required double fallback,
    double? devFallback,
    double? stagingFallback,
    double? prodFallback,
  }) {
    final raw = env[key]?.trim();
    if (raw == null || raw.isEmpty) {
      switch (_profile) {
        case 'dev':
          return _clampTemp(devFallback ?? fallback);
        case 'staging':
          return _clampTemp(stagingFallback ?? fallback);
        case 'prod':
          return _clampTemp(prodFallback ?? fallback);
        default:
          return _clampTemp(fallback);
      }
    }

    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return _clampTemp(fallback);
    }

    return _clampTemp(parsed);
  }

  Duration timeoutFor({
    required String key,
    required Duration fallback,
    Duration? devFallback,
    Duration? stagingFallback,
    Duration? prodFallback,
    Duration min = const Duration(seconds: 1),
    Duration max = const Duration(seconds: 120),
  }) {
    final raw = env[key]?.trim();
    final selectedFallback = switch (_profile) {
      'dev' => devFallback ?? fallback,
      'staging' => stagingFallback ?? fallback,
      'prod' => prodFallback ?? fallback,
      _ => fallback,
    };

    final parsedSeconds =
        raw == null || raw.isEmpty ? null : num.tryParse(raw)?.round();
    final duration =
        parsedSeconds == null
            ? selectedFallback
            : Duration(seconds: parsedSeconds);

    if (duration < min) return min;
    if (duration > max) return max;
    return duration;
  }

  int intFor({
    required String key,
    required int fallback,
    int? devFallback,
    int? stagingFallback,
    int? prodFallback,
    int? min,
    int? max,
  }) {
    final raw = env[key]?.trim();
    final selectedFallback = switch (_profile) {
      'dev' => devFallback ?? fallback,
      'staging' => stagingFallback ?? fallback,
      'prod' => prodFallback ?? fallback,
      _ => fallback,
    };

    final parsed = raw == null || raw.isEmpty ? null : int.tryParse(raw);
    var value = parsed ?? selectedFallback;
    if (min != null && value < min) value = min;
    if (max != null && value > max) value = max;
    return value;
  }

  double _clampTemp(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
