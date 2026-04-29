import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:sentry/sentry.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/logger.dart';
import '../lib/observability.dart';
import '../lib/request_metrics_service.dart';
import '../lib/request_trace.dart';

final _db = Database();
var _connected = false;
const _socialSlowRequestThresholdMs = 1000;

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Request-Id',
  'Access-Control-Max-Age': '86400',
};

Handler middleware(Handler handler) {
  return (context) async {
    final startedAt = DateTime.now();
    final requestId = resolveRequestId(context.request.headers);
    final trace = RequestTrace(requestId: requestId);
    final endpoint =
        '${context.request.method.name.toUpperCase()} ${context.request.uri.path}';

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: {
          ..._corsHeaders,
          'x-request-id': requestId,
        },
      );
    }

    try {
      await ensureObservabilityInitialized();

      if (!_connected) {
        await _db.connect();
        if (!_db.isConnected) {
          return Response.json(
            statusCode: HttpStatus.serviceUnavailable,
            body: {'error': 'Serviço temporariamente indisponível (DB)'},
            headers: {
              ..._corsHeaders,
              'x-request-id': requestId,
            },
          );
        }
        _connected = true;
      }

      var response = await handler
          .use(provider<Pool>((_) => _db.connection))
          .use(provider<RequestTrace>((_) => trace))(context);

      final contentLength =
          int.tryParse(response.headers['content-length'] ?? '');
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
        ..._corsHeaders,
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
        tags: const {
          'source': 'root_middleware',
        },
        extras: {
          'endpoint': endpoint,
        },
      );

      print('[ERROR] middleware: $e');
      print('[ERROR] stack: $st');

      final latencyMs = DateTime.now().difference(startedAt).inMilliseconds;
      RequestMetricsService.instance.record(
        endpoint: endpoint,
        statusCode: HttpStatus.internalServerError,
        latencyMs: latencyMs,
      );

      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Erro interno do servidor'},
        headers: {
          ..._corsHeaders,
          'x-request-id': requestId,
        },
      );
    }
  };
}

void _recordHttpObservability({
  required RequestContext context,
  required Response response,
  required RequestTrace trace,
  required String endpoint,
  required int latencyMs,
}) {
  final path = context.request.uri.path;
  final isSocialEndpoint = path == '/trades' ||
      path.startsWith('/trades/') ||
      path == '/conversations' ||
      path.startsWith('/conversations/');
  final isSlow = isSocialEndpoint && latencyMs >= _socialSlowRequestThresholdMs;
  final isErrorStatus = isSocialEndpoint && response.statusCode >= 400;

  if (!isSlow && !isErrorStatus) {
    return;
  }

  final userId = _safeUserId(context);
  final classification = response.statusCode >= 500
      ? 'server_error'
      : response.statusCode >= 400
          ? 'client_error'
          : 'slow_request';
  final logMessage = '[http_observability] classification=$classification '
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
