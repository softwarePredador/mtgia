import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'auth_runtime_policy.dart';
import 'distributed_rate_limiter.dart';
import 'internal_ai_request_token.dart';
import 'logger.dart';
import 'runtime_environment.dart';

/// Rate Limiter Middleware para prevenir abuso de endpoints
///
/// **Uso:**
/// ```dart
/// // Em routes/auth/_middleware.dart (aplicar apenas nas rotas de auth)
/// Handler middleware(Handler handler) {
///   return handler
///     .use(rateLimitMiddleware(maxRequests: 5, windowSeconds: 60));
/// }
/// ```
///
/// **Estratégia:**
/// - Limita o número de requisições por IP em uma janela de tempo
/// - Retorna 429 (Too Many Requests) se exceder o limite
/// - Usa memória local (em produção, recomenda-se Redis)
///
/// **Parâmetros:**
/// - `maxRequests`: Número máximo de requisições permitidas na janela
/// - `windowSeconds`: Duração da janela em segundos
/// - `identifier`: Função para identificar o cliente (default: IP address)
///
/// **Exemplo de Limites Sugeridos:**
/// - Login/Register: 5 requisições por minuto
/// - Endpoints gerais autenticados: 100 requisições por minuto
/// - Endpoints de IA: 10 requisições por minuto (custosos)
class RateLimiter {
  final int maxRequests;
  final int windowSeconds;
  final String Function(RequestContext) identifier;

  // Mapa: identifier -> List<timestamp dos requests>
  final Map<String, List<DateTime>> _requestLog = {};

  RateLimiter({
    required this.maxRequests,
    required this.windowSeconds,
    String Function(RequestContext)? identifier,
  }) : identifier = identifier ?? _defaultIdentifier;

  static String _defaultIdentifier(RequestContext context) {
    return resolveRateLimitClientIdentity(
      headers: context.request.headers,
      environment: const {'ENVIRONMENT': 'development'},
      remoteAddress: _requestRemoteAddress(context),
    ).identifier!;
  }

  static String buildClientIdentifierFromHeaders(Map<String, String> headers) {
    return resolveRateLimitClientIdentity(
      headers: headers,
      environment: const {'ENVIRONMENT': 'development'},
    ).identifier!;
  }

  bool isAllowed(String clientId) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: windowSeconds));

    // Limpar requisições antigas da janela
    if (_requestLog.containsKey(clientId)) {
      _requestLog[clientId]!.removeWhere(
        (timestamp) => timestamp.isBefore(windowStart),
      );
    } else {
      _requestLog[clientId] = [];
    }

    // Verificar limite
    if (_requestLog[clientId]!.length >= maxRequests) {
      return false; // Limite excedido
    }

    // Registrar nova requisição
    _requestLog[clientId]!.add(now);
    return true;
  }

  void cleanup() {
    final cutoff = DateTime.now().subtract(
      Duration(seconds: windowSeconds * 2),
    );
    _requestLog.removeWhere((_, timestamps) {
      timestamps.removeWhere((t) => t.isBefore(cutoff));
      return timestamps.isEmpty;
    });
  }

  void clear() {
    _requestLog.clear();
  }
}

Map<String, dynamic> buildRateLimitResponseBody({
  required String error,
  required String message,
  required int retryAfterSeconds,
  required String bucket,
  String scope = 'client',
  String? backend,
}) {
  return {
    'error': error,
    'message': message,
    'retry_after': retryAfterSeconds,
    'retry_after_seconds': retryAfterSeconds,
    'retry_after_ms': retryAfterSeconds * 1000,
    'rate_limit_bucket': bucket,
    'rate_limit_scope': scope,
    if (backend != null) 'rate_limit_backend': backend,
  };
}

String buildAiRateLimitIdentifier({
  required String? userId,
  required Map<String, String> headers,
}) {
  final normalizedUserId = userId?.trim();
  if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
    return 'user:$normalizedUserId';
  }
  return RateLimiter.buildClientIdentifierFromHeaders(headers);
}

Map<String, String> buildRateLimitHeaders({
  required int maxRequests,
  required int windowSeconds,
  required int retryAfterSeconds,
  int remaining = 0,
}) {
  return {
    'Retry-After': retryAfterSeconds.toString(),
    'X-RateLimit-Limit': maxRequests.toString(),
    'X-RateLimit-Remaining': remaining.toString(),
    'X-RateLimit-Window': windowSeconds.toString(),
    'X-RateLimit-Reset': retryAfterSeconds.toString(),
  };
}

/// Instâncias globais de rate limiters por tipo de endpoint
final _authRateLimiter = RateLimiter(
  maxRequests: 5,
  windowSeconds: 60, // 5 requisições por minuto
);

final _authRateLimiterDev = RateLimiter(
  maxRequests: 200,
  windowSeconds: 60, // Mais permissivo em dev/test
);

final _aiRateLimiter = RateLimiter(
  maxRequests: 10,
  windowSeconds: 60, // 10 requisições por minuto (IA é custosa)
);

final _aiRateLimiterDev = RateLimiter(maxRequests: 60, windowSeconds: 60);

final _aiPollingRateLimiter = RateLimiter(maxRequests: 120, windowSeconds: 60);

final _aiPollingRateLimiterDev = RateLimiter(
  maxRequests: 600,
  windowSeconds: 60,
);

bool _isProduction() {
  return _isProductionEnvironment(_rateLimitRuntimeEnvironment());
}

bool _isProductionEnvironment(Map<String, String> environment) =>
    (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
    'production';

Map<String, String> _rateLimitRuntimeEnvironment() {
  final env = loadRuntimeEnvironment();
  return {
    'ENVIRONMENT': env['ENVIRONMENT'] ?? 'development',
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

String classifyRateLimitTransportPeer(String? remoteAddress) {
  final parsed = InternetAddress.tryParse(remoteAddress?.trim() ?? '');
  if (parsed == null) {
    return remoteAddress == null || remoteAddress.trim().isEmpty
        ? 'missing'
        : 'invalid';
  }
  final bytes = parsed.rawAddress;
  if (bytes.length == 16 &&
      bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff) {
    return 'ipv4_mapped_ipv6';
  }
  return bytes.length == 4 ? 'ipv4' : 'ipv6';
}

bool _hasForwardedFor(Map<String, String> headers) => headers.entries.any(
  (entry) =>
      entry.key.toLowerCase() == 'x-forwarded-for' &&
      entry.value.trim().isNotEmpty,
);

void _logIdentityFailure({
  required String bucket,
  required ClientIdentityResolution identity,
  required Map<String, String> headers,
  required String? remoteAddress,
}) {
  Log.w(
    '[rate-limit] identity_unavailable bucket=$bucket '
    'code=${identity.failureCode ?? 'unknown'} '
    'peer_kind=${classifyRateLimitTransportPeer(remoteAddress)} '
    'forwarded_for_present=${_hasForwardedFor(headers)}',
  );
}

bool _useDistributedRateLimitInProd() {
  final env = loadRuntimeEnvironment();
  final raw = (env['RATE_LIMIT_DISTRIBUTED'] ?? 'true').toLowerCase().trim();
  return raw == '1' || raw == 'true' || raw == 'yes';
}

Future<bool?> _isAllowedDistributedIfAvailable(
  RequestContext context, {
  required String bucket,
  required String clientId,
  required int maxRequests,
  required int windowSeconds,
}) async {
  if (!_isProduction() || !_useDistributedRateLimitInProd()) {
    return null;
  }

  try {
    final pool = context.read<Pool>();
    final limiter = DistributedRateLimiter(
      pool: pool,
      bucket: bucket,
      maxRequests: maxRequests,
      windowSeconds: windowSeconds,
    );
    return limiter.isAllowed(clientId);
  } catch (_) {
    return null;
  }
}

Response _rateLimitIdentityUnavailable() {
  return Response.json(
    statusCode: HttpStatus.serviceUnavailable,
    body: {
      'error': 'rate_limit_identity_unavailable',
      'message':
          'Não foi possível validar a origem da requisição. Tente novamente mais tarde.',
      'rate_limit_backend': 'fail_closed',
    },
    headers: const {'Retry-After': '60'},
  );
}

/// Middleware factory para diferentes níveis de rate limiting
Middleware rateLimitMiddleware({
  int maxRequests = 100,
  int windowSeconds = 60,
  String Function(RequestContext)? identifier,
}) {
  final limiter = RateLimiter(
    maxRequests: maxRequests,
    windowSeconds: windowSeconds,
    identifier: identifier,
  );

  return (handler) {
    return (context) async {
      final clientId = limiter.identifier(context);

      if (!limiter.isAllowed(clientId)) {
        return Response.json(
          statusCode: HttpStatus.tooManyRequests, // 429
          body: buildRateLimitResponseBody(
            error: 'Too Many Requests',
            message:
                'Você excedeu o limite de $maxRequests requisições em $windowSeconds segundos.',
            retryAfterSeconds: windowSeconds,
            bucket: 'generic',
          ),
          headers: buildRateLimitHeaders(
            maxRequests: maxRequests,
            windowSeconds: windowSeconds,
            retryAfterSeconds: windowSeconds,
          ),
        );
      }

      // Adicionar headers informativos na resposta bem-sucedida
      final response = await handler(context);

      // Contar quantas requisições restam (estimativa)
      final remaining =
          maxRequests - (limiter._requestLog[clientId]?.length ?? 0);

      return response.copyWith(
        headers: {
          ...response.headers,
          'X-RateLimit-Limit': maxRequests.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Window': windowSeconds.toString(),
        },
      );
    };
  };
}

/// Returns whether the request submits credentials and therefore belongs to
/// the authentication brute-force bucket.
///
/// Token validation (`GET /auth/me`) is deliberately excluded: it is a
/// high-frequency session bootstrap/read operation, not a credential attempt.
bool isAuthCredentialAttempt(Request request) {
  if (request.method != HttpMethod.post) return false;

  final path = request.uri.path;
  final normalizedPath =
      path.length > 1 && path.endsWith('/')
          ? path.substring(0, path.length - 1)
          : path;
  return const {
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/change-password',
    '/auth/revoke-sessions',
    '/auth/verify-email',
    '/auth/resend-verification',
  }.contains(normalizedPath);
}

/// Middleware específico para tentativas de autenticação (mais restritivo).
///
/// Only credential submissions (`POST /auth/login` and
/// `POST /auth/register`) consume this bucket. Other routes under `/auth`, in
/// particular `GET /auth/me`, pass through without consuming or being blocked
/// by the brute-force limiter.
Middleware authRateLimit({RateLimiter? limiterOverrideForTesting}) {
  return (handler) {
    return (context) async {
      if (!isAuthCredentialAttempt(context.request)) {
        return handler(context);
      }

      final environment = _rateLimitRuntimeEnvironment();
      final isProd = _isProductionEnvironment(environment);
      final limiter =
          limiterOverrideForTesting ??
          (isProd ? _authRateLimiter : _authRateLimiterDev);
      final remoteAddress = _requestRemoteAddress(context);
      final identity = resolveRateLimitClientIdentity(
        headers: context.request.headers,
        environment: environment,
        remoteAddress: remoteAddress,
      );
      if (!identity.isValid) {
        _logIdentityFailure(
          bucket: 'auth',
          identity: identity,
          headers: context.request.headers,
          remoteAddress: remoteAddress,
        );
        return _rateLimitIdentityUnavailable();
      }
      final clientId = identity.identifier!;

      if (!isProd && clientId == 'anonymous') {
        return handler(context);
      }

      final distributedAllowed = await _isAllowedDistributedIfAvailable(
        context,
        bucket: 'auth',
        clientId: clientId,
        maxRequests: limiter.maxRequests,
        windowSeconds: limiter.windowSeconds,
      );

      if (distributedAllowed == false) {
        return Response.json(
          statusCode: HttpStatus.tooManyRequests,
          body: buildRateLimitResponseBody(
            error: 'Too Many Login Attempts',
            message: 'Você fez muitas tentativas de login. Aguarde 1 minuto.',
            retryAfterSeconds: 60,
            bucket: 'auth',
            backend: 'distributed',
          ),
          headers: buildRateLimitHeaders(
            maxRequests: limiter.maxRequests,
            windowSeconds: limiter.windowSeconds,
            retryAfterSeconds: 60,
          ),
        );
      }

      if (distributedAllowed == true) {
        return handler(context);
      }

      if (!limiter.isAllowed(clientId)) {
        return Response.json(
          statusCode: HttpStatus.tooManyRequests,
          body: buildRateLimitResponseBody(
            error: 'Too Many Login Attempts',
            message: 'Você fez muitas tentativas de login. Aguarde 1 minuto.',
            retryAfterSeconds: 60,
            bucket: 'auth',
            backend: 'in_memory_fallback',
          ),
          headers: buildRateLimitHeaders(
            maxRequests: limiter.maxRequests,
            windowSeconds: limiter.windowSeconds,
            retryAfterSeconds: 60,
          ),
        );
      }

      return handler(context);
    };
  };
}

/// Middleware específico para rotas de IA (controla custos)
Middleware aiRateLimit() => _aiRateLimit(
  productionLimiter: _aiRateLimiter,
  developmentLimiter: _aiRateLimiterDev,
  bucket: 'ai',
  message: 'Você atingiu o limite de requisições de IA. Aguarde 1 minuto.',
);

/// Polling is frequent by design, but remains bounded per authenticated user.
Middleware aiPollingRateLimit() => _aiRateLimit(
  productionLimiter: _aiPollingRateLimiter,
  developmentLimiter: _aiPollingRateLimiterDev,
  bucket: 'ai-poll',
  message: 'Muitas atualizações em sequência. Aguarde alguns segundos.',
);

Middleware _aiRateLimit({
  required RateLimiter productionLimiter,
  required RateLimiter developmentLimiter,
  required String bucket,
  required String message,
}) {
  return (handler) {
    return (context) async {
      if (InternalAiRequestToken.matches(context.request.headers)) {
        return handler(context);
      }

      final environment = _rateLimitRuntimeEnvironment();
      final limiter =
          _isProductionEnvironment(environment)
              ? productionLimiter
              : developmentLimiter;
      String? userId;
      try {
        userId = context.read<String>();
      } catch (_) {
        userId = null;
      }
      final normalizedUserId = userId?.trim();
      late final String clientId;
      if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
        clientId = 'user:$normalizedUserId';
      } else {
        final remoteAddress = _requestRemoteAddress(context);
        final identity = resolveRateLimitClientIdentity(
          headers: context.request.headers,
          environment: environment,
          remoteAddress: remoteAddress,
        );
        if (!identity.isValid) {
          _logIdentityFailure(
            bucket: bucket,
            identity: identity,
            headers: context.request.headers,
            remoteAddress: remoteAddress,
          );
          return _rateLimitIdentityUnavailable();
        }
        clientId = identity.identifier!;
      }
      final rateLimitScope = clientId.startsWith('user:') ? 'user' : 'client';

      final distributedAllowed = await _isAllowedDistributedIfAvailable(
        context,
        bucket: bucket,
        clientId: clientId,
        maxRequests: limiter.maxRequests,
        windowSeconds: limiter.windowSeconds,
      );

      if (distributedAllowed == false) {
        return Response.json(
          statusCode: HttpStatus.tooManyRequests,
          body: buildRateLimitResponseBody(
            error: 'Too Many AI Requests',
            message: message,
            retryAfterSeconds: 60,
            bucket: bucket,
            scope: rateLimitScope,
            backend: 'distributed',
          ),
          headers: buildRateLimitHeaders(
            maxRequests: limiter.maxRequests,
            windowSeconds: limiter.windowSeconds,
            retryAfterSeconds: 60,
          ),
        );
      }

      if (distributedAllowed == true) {
        return handler(context);
      }

      if (!limiter.isAllowed(clientId)) {
        return Response.json(
          statusCode: HttpStatus.tooManyRequests,
          body: buildRateLimitResponseBody(
            error: 'Too Many AI Requests',
            message: message,
            retryAfterSeconds: 60,
            bucket: bucket,
            scope: rateLimitScope,
            backend: 'in_memory_fallback',
          ),
          headers: buildRateLimitHeaders(
            maxRequests: limiter.maxRequests,
            windowSeconds: limiter.windowSeconds,
            retryAfterSeconds: 60,
          ),
        );
      }

      return handler(context);
    };
  };
}
