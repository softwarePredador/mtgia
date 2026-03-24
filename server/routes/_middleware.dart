import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/observability.dart';
import '../lib/request_metrics_service.dart';
import '../lib/request_trace.dart';

final _db = Database();
var _connected = false;

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
