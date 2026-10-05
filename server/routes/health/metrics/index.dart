import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../lib/catalog_read_guard.dart';
import '../../../lib/endpoint_cache.dart';
import '../../../lib/request_metrics_service.dart';
import '../../../lib/http_responses.dart';

/// GET /health/metrics (ops key ou admin): totais, janelas de 5 e 60 minutos,
/// o cache em memória desta réplica (tamanho, teto e saídas pelo teto) e as
/// chamadas a terceiro bloqueadas nas leituras do catálogo. É o que o
/// avaliador de SLO e alertas lê (BT-OBS-001, D-47; BT-CAT-03).
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final snapshot = RequestMetricsService.instance.snapshot();

  return Response.json(
    statusCode: HttpStatus.ok,
    body: {
      'status': 'ok',
      ...snapshot,
      'cache': {
        'endpoint_cache_entries': EndpointCache.instance.length,
        'endpoint_cache_max_entries': EndpointCache.instance.entryLimit,
        'endpoint_cache_evictions': EndpointCache.instance.evictions,
      },
      'catalog_read_guard': CatalogReadGuard.snapshot(),
    },
  );
}
