import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/commercial_metrics_service.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final days =
      int.tryParse(context.request.uri.queryParameters['days'] ?? '30') ?? 30;
  final bucket = context.request.uri.queryParameters['bucket'] ?? 'day';

  try {
    final service = CommercialMetricsService(context.read<Pool>());
    final history = await service.aiPerformanceHistory(
      days: days,
      bucket: bucket,
    );
    return Response.json(statusCode: HttpStatus.ok, body: history);
  } catch (error) {
    return internalServerError(
      'Falha ao carregar historico de metricas de IA',
      details: error,
    );
  }
}
