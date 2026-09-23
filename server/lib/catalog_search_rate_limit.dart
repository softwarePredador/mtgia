import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';

import 'auth_runtime_policy.dart';
import 'distributed_rate_limiter.dart';
import 'logger.dart';
import 'rate_limit_middleware.dart'
    show RateLimiter, buildRateLimitHeaders, buildRateLimitResponseBody;
import 'runtime_environment.dart';

/// Limite por IP da leitura cara do catálogo (BT-CAT-03, decisão D-36).
///
/// Leitura cara é a busca textual sem filtro: `GET /cards` com `name` e sem
/// `set` nem `id`. Ela varre `cards` por trecho do nome; as demais leituras
/// do catálogo seguem sem limite próprio. Em produção o contador é o
/// distribuído (`rate_limit_events`); se ele cair, a busca cara é negada
/// (fail-closed), porque liberar sem contador é justamente o que o limite
/// existe para impedir. Fora de produção vale o contador em memória.
const catalogTextSearchRateLimitBucket = 'catalog_text_search';

/// Produção: 60 buscas textuais sem filtro por IP a cada minuto.
final _catalogTextSearchLimiter = RateLimiter(
  maxRequests: 60,
  windowSeconds: 60,
);

final _catalogTextSearchLimiterDev = RateLimiter(
  maxRequests: 600,
  windowSeconds: 60,
);

RateLimiter? _catalogTextSearchLimiterOverride;

@visibleForTesting
void overrideCatalogTextSearchRateLimiterForTesting(RateLimiter? limiter) {
  _catalogTextSearchLimiterOverride = limiter;
}

/// A busca textual sem filtro, a única leitura cara do catálogo (D-36).
bool isExpensiveCatalogSearch(Map<String, String> queryParameters) {
  String value(String key) => queryParameters[key]?.trim() ?? '';
  return value('name').isNotEmpty &&
      value('set').isEmpty &&
      value('id').isEmpty;
}

/// Devolve 429 quando o IP esgotou a busca cara, 503 quando o limite não pode
/// ser verificado, ou `null` para seguir.
Future<Response?> catalogTextSearchRateLimitResponse(RequestContext context) {
  final environment = _catalogRateLimitEnvironment();
  return catalogTextSearchRateLimitDecision(
    headers: context.request.headers,
    remoteAddress: _requestRemoteAddress(context),
    environment: environment,
    distributedAllowed:
        (clientId, limiter) => DistributedRateLimiter(
          pool: context.read<Pool>(),
          bucket: catalogTextSearchRateLimitBucket,
          maxRequests: limiter.maxRequests,
          windowSeconds: limiter.windowSeconds,
        ).isAllowed(clientId),
  );
}

@visibleForTesting
Future<Response?> catalogTextSearchRateLimitDecision({
  required Map<String, String> headers,
  required String? remoteAddress,
  required Map<String, String> environment,
  required Future<bool> Function(String clientId, RateLimiter limiter)
  distributedAllowed,
}) async {
  final production = _isProduction(environment);
  final limiter =
      _catalogTextSearchLimiterOverride ??
      (production ? _catalogTextSearchLimiter : _catalogTextSearchLimiterDev);

  final identity = resolveRateLimitClientIdentity(
    headers: headers,
    environment: environment,
    remoteAddress: remoteAddress,
  );
  if (!identity.isValid) {
    Log.w(
      '[rate-limit] identity_unavailable bucket=$catalogTextSearchRateLimitBucket '
      'code=${identity.failureCode ?? 'unknown'}',
    );
    return _failClosed(
      error: 'rate_limit_identity_unavailable',
      message:
          'Não foi possível validar a origem da requisição. Tente novamente '
          'mais tarde.',
    );
  }
  final clientId = identity.identifier!;

  if (production && _distributedEnabled(environment)) {
    final bool allowed;
    try {
      allowed = await distributedAllowed(clientId, limiter);
    } catch (error) {
      Log.w(
        '[rate-limit] backend_unavailable bucket=$catalogTextSearchRateLimitBucket '
        'error=${error.runtimeType}',
      );
      return _failClosed(
        error: 'rate_limit_unavailable',
        message:
            'A busca de cartas está indisponível por um instante. Tente de '
            'novo em seguida.',
      );
    }
    return allowed ? null : _tooManyRequests(limiter, backend: 'distributed');
  }

  final allowed = limiter.isAllowed(
    '$catalogTextSearchRateLimitBucket|$clientId',
  );
  return allowed ? null : _tooManyRequests(limiter, backend: 'in_memory');
}

Response _tooManyRequests(RateLimiter limiter, {required String backend}) {
  return Response.json(
    statusCode: HttpStatus.tooManyRequests,
    body: buildRateLimitResponseBody(
      error: 'catalog_search_rate_limited',
      message:
          'Você fez muitas buscas de cartas em sequência. Aguarde um minuto e '
          'tente de novo.',
      retryAfterSeconds: limiter.windowSeconds,
      bucket: catalogTextSearchRateLimitBucket,
      backend: backend,
    ),
    headers: buildRateLimitHeaders(
      maxRequests: limiter.maxRequests,
      windowSeconds: limiter.windowSeconds,
      retryAfterSeconds: limiter.windowSeconds,
    ),
  );
}

Response _failClosed({required String error, required String message}) {
  return Response.json(
    statusCode: HttpStatus.serviceUnavailable,
    body: {
      'error': error,
      'message': message,
      'rate_limit_bucket': catalogTextSearchRateLimitBucket,
      'rate_limit_backend': 'fail_closed',
    },
    headers: const {'Retry-After': '30'},
  );
}

bool _isProduction(Map<String, String> environment) =>
    (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
    'production';

bool _distributedEnabled(Map<String, String> environment) {
  final raw =
      (environment['RATE_LIMIT_DISTRIBUTED'] ?? 'true').toLowerCase().trim();
  return raw == '1' || raw == 'true' || raw == 'yes';
}

Map<String, String> _catalogRateLimitEnvironment() {
  final env = loadRuntimeEnvironment();
  return {
    'ENVIRONMENT': env['ENVIRONMENT'] ?? 'development',
    if (env['RATE_LIMIT_DISTRIBUTED'] case final String value)
      'RATE_LIMIT_DISTRIBUTED': value,
    if (env[trustedProxyHopsEnvironmentKey] case final String value)
      trustedProxyHopsEnvironmentKey: value,
    if (env[trustedProxyPeersEnvironmentKey] case final String value)
      trustedProxyPeersEnvironmentKey: value,
  };
}

String? _requestRemoteAddress(RequestContext context) {
  try {
    return context.request.connectionInfo.remoteAddress.address;
  } on Object {
    return null;
  }
}
