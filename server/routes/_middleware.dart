import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:sentry/sentry.dart';

import '../lib/auth_service.dart';
import '../lib/cors_policy.dart';
import '../lib/database.dart';
import '../lib/logger.dart';
import '../lib/observability.dart';
import '../lib/request_metrics_service.dart';
import '../lib/request_trace.dart';
import '../lib/runtime_environment.dart';

final _db = Database();
var _connected = false;
const _socialSlowRequestThresholdMs = 1000;
final _runtimeEnvironment = loadRuntimeEnvironment();
final _corsPolicy = CorsPolicy.fromEnvironment({
  'ENVIRONMENT': _runtimeEnvironment['ENVIRONMENT'] ?? 'development',
  'MANALOOM_ALLOWED_ORIGINS':
      _runtimeEnvironment['MANALOOM_ALLOWED_ORIGINS'] ?? '',
  'MANALOOM_ALLOW_DEV_ORIGINS':
      _runtimeEnvironment['MANALOOM_ALLOW_DEV_ORIGINS'] ?? 'false',
});

const _securityHeaders = {
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
      'Content-Type, Authorization, X-Request-Id, X-ManaLoom-Ops-Key',
  'Access-Control-Max-Age': '86400',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'no-referrer',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  'Strict-Transport-Security': 'max-age=31536000',
  'Content-Security-Policy':
      "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
};

Handler middleware(Handler handler) {
  return (context) async {
    final startedAt = DateTime.now();
    final requestId = resolveRequestId(context.request.headers);
    final trace = RequestTrace(requestId: requestId);
    final endpoint =
        '${context.request.method.name.toUpperCase()} ${context.request.uri.path}';
    final origin = _header(context.request.headers, 'origin');
    final responseHeaders = <String, Object>{
      ..._securityHeaders,
      ..._corsPolicy.headersFor(origin),
    };
    final processLiveness = isDatabaseIndependentHealthPath(
      context.request.uri.path,
    );

    if (!_corsPolicy.isAllowed(origin)) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'cors_origin_denied'},
        headers: {...responseHeaders, 'x-request-id': requestId},
      );
    }

    if (context.request.method == HttpMethod.options) {
      final validPreflight =
          origin == null ||
          _corsPolicy.isValidPreflight(
            requestedMethod: _header(
              context.request.headers,
              'access-control-request-method',
            ),
            requestedHeaders: _header(
              context.request.headers,
              'access-control-request-headers',
            ),
          );
      if (!validPreflight) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'cors_preflight_rejected'},
          headers: {...responseHeaders, 'x-request-id': requestId},
        );
      }
      return Response(
        statusCode: HttpStatus.noContent,
        headers: {...responseHeaders, 'x-request-id': requestId},
      );
    }

    try {
      if (!processLiveness) {
        await ensureObservabilityInitialized();

        if (!_connected) {
          await _db.connect();
          if (!_db.isConnected) {
            return Response.json(
              statusCode: HttpStatus.serviceUnavailable,
              body: {'error': 'Serviço temporariamente indisponível (DB)'},
              headers: {...responseHeaders, 'x-request-id': requestId},
            );
          }
          _connected = true;
        }
      }

      var response =
          processLiveness
              ? await handler.use(provider<RequestTrace>((_) => trace))(context)
              : await handler
                  .use(provider<Pool>((_) => _db.connection))
                  .use(provider<RequestTrace>((_) => trace))(context);

      final contentLength = int.tryParse(
        response.headers['content-length'] ?? '',
      );
      if (response.statusCode == HttpStatus.methodNotAllowed &&
          (contentLength == null || contentLength == 0)) {
        response = Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'error': 'Method not allowed'},
          headers: response.headers,
        );
      }

      final mergedHeaders = <String, Object>{
        ...response.headers,
        ...responseHeaders,
        'x-request-id': requestId,
      };
      final finalResponse = response.copyWith(headers: mergedHeaders);

      final latencyMs = DateTime.now().difference(startedAt).inMilliseconds;
      RequestMetricsService.instance.record(
        endpoint: endpoint,
        statusCode: finalResponse.statusCode,
        latencyMs: latencyMs,
      );
      _recordHttpObservability(
        context: context,
        response: finalResponse,
        trace: trace,
        endpoint: endpoint,
        latencyMs: latencyMs,
      );

      return finalResponse;
    } catch (e, st) {
      await captureObservedException(
        e,
        stackTrace: st,
        request: context.request,
        trace: trace,
        tags: const {'source': 'root_middleware'},
        extras: {'endpoint': endpoint},
      );

      Log.e(
        '[root-middleware] unhandled request failure '
        'endpoint=$endpoint request_id=$requestId type=${e.runtimeType}',
      );

      final latencyMs = DateTime.now().difference(startedAt).inMilliseconds;
      RequestMetricsService.instance.record(
        endpoint: endpoint,
        statusCode: HttpStatus.internalServerError,
        latencyMs: latencyMs,
      );

      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Erro interno do servidor'},
        headers: {...responseHeaders, 'x-request-id': requestId},
      );
    }
  };
}

/// Process liveness must stay independent from PostgreSQL and telemetry.
/// Readiness remains dependency-aware at `/health/ready` and `/ready`.
bool isDatabaseIndependentHealthPath(String path) {
  return path == '/health' ||
      path == '/health/' ||
      path == '/health/live' ||
      path == '/health/live/';
}

String? _header(Map<String, String> headers, String name) {
  final normalized = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value;
  }
  return null;
}

void _recordHttpObservability({
  required RequestContext context,
  required Response response,
  required RequestTrace trace,
  required String endpoint,
  required int latencyMs,
}) {
  final path = context.request.uri.path;
  final isSocialEndpoint =
      path == '/trades' ||
      path.startsWith('/trades/') ||
      path == '/conversations' ||
      path.startsWith('/conversations/') ||
      path == '/users' ||
      path.startsWith('/users/') ||
      path == '/community' ||
      path.startsWith('/community/');
  final isSlow = isSocialEndpoint && latencyMs >= _socialSlowRequestThresholdMs;
  final isErrorStatus = isSocialEndpoint && response.statusCode >= 400;

  if (!isSlow && !isErrorStatus) {
    return;
  }

  final userId = _safeUserId(context);
  final classification =
      response.statusCode >= 500
          ? 'server_error'
          : response.statusCode >= 400
          ? 'client_error'
          : 'slow_request';
  final logMessage =
      '[http_observability] classification=$classification '
      'endpoint=$endpoint status=${response.statusCode} '
      'duration_ms=$latencyMs request_id=${trace.requestId} '
      'user_id=${userId ?? 'n/a'}';

  if (response.statusCode >= 500) {
    Log.e(logMessage);
  } else {
    Log.w(logMessage);
  }

  unawaited(
    captureObservedMessage(
      'HTTP $classification: $endpoint',
      request: context.request,
      trace: trace,
      userId: userId,
      level:
          response.statusCode >= 500 ? SentryLevel.error : SentryLevel.warning,
      tags: {
        'source': 'root_middleware',
        'classification': classification,
        'endpoint': endpoint,
      },
      extras: {
        'status_code': response.statusCode,
        'duration_ms': latencyMs,
        'request_id': trace.requestId,
        'path': path,
      },
    ).catchError((Object error, StackTrace stackTrace) {
      Log.e(
        '[http_observability] sentry_capture_failed endpoint=$endpoint '
        'request_id=${trace.requestId} error=$error',
      );
    }),
  );
}

String? _safeUserId(RequestContext context) {
  try {
    return context.read<String>();
  } catch (_) {
    try {
      final traceUserId = context.read<RequestTrace>().userId;
      if (traceUserId != null && traceUserId.isNotEmpty) {
        return traceUserId;
      }
    } catch (_) {
      // Fall through to the Authorization header.
    }
  }
  final authHeader = context.request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  final payload = AuthService().verifyToken(authHeader.substring(7));
  return payload?['userId'] as String?;
}
