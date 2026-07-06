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
      int.tryParse(context.request.uri.queryParameters['days'] ?? '30');

  try {
    final service = CommercialMetricsService(context.read<Pool>());
    final snapshot = await service.snapshot(days: days ?? 30);
    return Response.json(statusCode: HttpStatus.ok, body: snapshot);
  } catch (error) {
    return internalServerError(
      'Falha ao carregar metricas comerciais',
      details: error,
    );
  }
}
