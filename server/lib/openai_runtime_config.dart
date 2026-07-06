import 'package:dotenv/dotenv.dart';

class OpenAiRuntimeConfig {
  final DotEnv env;

  OpenAiRuntimeConfig(this.env);

  String get _profile {
    final explicit = env['OPENAI_PROFILE']?.trim().toLowerCase();
    if (explicit == 'dev' || explicit == 'staging' || explicit == 'prod') {
      return explicit!;
    }

    final environment = env['ENVIRONMENT']?.trim().toLowerCase();
    if (environment == 'production' || environment == 'prod') {
      return 'prod';
    }
    if (environment == 'staging' || environment == 'stage') {
      return 'staging';
    }
    return 'dev';
  }

  String get profile => _profile;

  bool get isProductionLike => _profile == 'prod';

  bool get allowsMockFallbacks => !isProductionLike;

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
    final duration = parsedSeconds == null
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
