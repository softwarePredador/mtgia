import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/operational_alerts.dart';
import '../lib/request_metrics_service.dart';
import '../routes/health/metrics/index.dart' as metrics_route;

/// BT-OBS-001 (D-47): as janelas de 5 e 60 minutos alimentam o SLO e os
/// alertas; a chave de métrica é o template da rota, sem ID.
void main() {
  late DateTime now;
  late RequestMetricsService metrics;

  setUp(() {
    now = DateTime.utc(2026, 9, 24, 12);
    metrics = RequestMetricsService.forTesting(clock: () => now);
  });

  Map<String, dynamic> window(String name) =>
      (metrics.snapshot()['windows'] as Map)[name] as Map<String, dynamic>;

  group('routeTemplate', () {
    test('troca UUID, número, hash e token de caminho por :id', () {
      expect(
        routeTemplate(
          'GET /decks/0f8fad5b-d9cb-469f-a165-70867728950e/cards/42',
        ),
        'GET /decks/:id/cards/:id',
      );
      expect(
        routeTemplate('GET /reports/9f86d081884c7d659a2feaa0c55ad015'),
        'GET /reports/:id',
      );
      expect(
        routeTemplate('POST /auth/verify-email/abcDEF123_-abcDEF123_-xyz'),
        'POST /auth/verify-email/:id',
      );
      expect(routeTemplate('GET /cards?name=sol+ring&page=2'), 'GET /cards');
      expect(routeTemplate('GET /users/me'), 'GET /users/me');
      expect(routeTemplate('GET /sets/latest'), 'GET /sets/latest');
    });

    test('mantém nome de rota longo e chave que não é caminho', () {
      expect(
        routeTemplate('GET /ai/commander-reference-deck-corpus-builder'),
        'GET /ai/commander-reference-deck-corpus-builder',
      );
      expect(
        routeTemplate(
          'RELEASE_CAPABILITY_DENIAL capability_route_unclassified',
        ),
        'RELEASE_CAPABILITY_DENIAL capability_route_unclassified',
      );
    });
  });

  test('a chave da métrica e o JSON não levam ID de recurso', () {
    const user = '0f8fad5b-d9cb-469f-a165-70867728950e';
    metrics.record(
      endpoint: 'GET /users/$user/decks/77',
      statusCode: 200,
      latencyMs: 12,
    );
    final snapshot = metrics.snapshot();
    expect(
      (snapshot['endpoints'] as Map).keys,
      contains('GET /users/:id/decks/:id'),
    );
    expect(jsonEncode(snapshot), isNot(contains(user)));
  });

  test('as janelas contam só os últimos 5 e 60 minutos', () {
    metrics.record(endpoint: 'GET /cards', statusCode: 200, latencyMs: 10);
    now = now.add(const Duration(minutes: 30));
    metrics.record(endpoint: 'GET /cards', statusCode: 500, latencyMs: 20);
    now = now.add(const Duration(minutes: 3));
    metrics.record(endpoint: 'POST /decks', statusCode: 201, latencyMs: 900);

    expect(window('5m'), {
      'minutes': 5,
      'request_count': 2,
      'error_count': 1,
      'error_rate': 0.5,
      'read_count': 1,
      'read_p95_ms': 20,
    });
    expect(window('60m')['request_count'], 3);
    expect(window('60m')['read_count'], 2);

    now = now.add(const Duration(minutes: 61));
    expect(window('60m')['request_count'], 0);
    expect(metrics.snapshot()['totals'], containsPair('request_count', 3));
  });

  test('sondagens de saúde ficam fora das janelas do SLO', () {
    for (final endpoint in [
      'GET /health',
      'GET /health/live',
      'GET /health/ready',
      'GET /health/metrics',
      'GET /ready',
      'GET /capabilities',
    ]) {
      metrics.record(endpoint: endpoint, statusCode: 503, latencyMs: 5);
    }
    expect(window('5m')['request_count'], 0);
    expect(metrics.snapshot()['totals'], containsPair('error_count', 6));
  });

  test('o p95 de leitura só olha GET e HEAD', () {
    for (var index = 1; index <= 20; index++) {
      metrics.record(
        endpoint: 'GET /cards',
        statusCode: 200,
        latencyMs: index * 10,
      );
      metrics.record(endpoint: 'POST /decks', statusCode: 200, latencyMs: 9000);
    }
    expect(window('5m')['read_count'], 20);
    expect(window('5m')['read_p95_ms'], 190);
  });

  test('apagão depois de muito tempo no ar dispara pela janela', () {
    for (var index = 0; index < 100000; index++) {
      metrics.record(endpoint: 'GET /cards', statusCode: 200, latencyMs: 5);
    }
    now = now.add(const Duration(hours: 6));
    for (var index = 0; index < 60; index++) {
      metrics.record(endpoint: 'GET /cards', statusCode: 503, latencyMs: 5);
    }
    final snapshot = metrics.snapshot();
    final lifetime = (snapshot['totals'] as Map)['error_rate'] as double;
    expect(lifetime, lessThan(0.001));

    final alerts = evaluateOperationalAlerts(
      requestMetrics: snapshot,
      aiJobs: const {'status': 'not_initialized'},
      aiCost: const {'status': 'not_initialized'},
    );
    final codes = (alerts['alerts'] as List).cast<Map<String, Object>>().map(
      (alert) => alert['code'],
    );
    expect(codes, contains('http_5xx_rate_critical'));
  });

  test('a memória fica limitada: rotas demais somam em OTHER', () {
    for (
      var index = 0;
      index < RequestMetricsService.maxEndpoints + 50;
      index++
    ) {
      metrics.record(
        endpoint: 'GET /rota-$index',
        statusCode: 200,
        latencyMs: 1,
      );
    }
    final endpoints = metrics.snapshot()['endpoints'] as Map;
    expect(endpoints.length, RequestMetricsService.maxEndpoints + 1);
    expect(
      (endpoints[RequestMetricsService.overflowEndpoint]
          as Map)['request_count'],
      50,
    );

    for (var index = 0; index < 2000; index++) {
      metrics.record(endpoint: 'GET /cards', statusCode: 200, latencyMs: 1);
    }
    expect(
      window('5m')['read_count'],
      RequestMetricsService.maxEndpoints + 50 + 2000,
    );
  });

  test('GET /health/metrics devolve janelas e o cache, sem ID', () async {
    const deck = '5b6f3c2e-1d4a-4c8b-9e7f-0a1b2c3d4e5f';
    RequestMetricsService.instance.record(
      endpoint: 'GET /decks/$deck',
      statusCode: 200,
      latencyMs: 3,
    );
    final response = metrics_route.onRequest(
      _MetricsRequestContext(
        Request('GET', Uri.parse('http://localhost/health/metrics')),
      ),
    );
    final text = await response.body();
    final body = jsonDecode(text) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok);
    expect((body['windows'] as Map).keys, containsAll(['5m', '60m']));
    expect(body['cache'], contains('endpoint_cache_entries'));
    expect(text, isNot(contains(deck)));
  });
}

class _MetricsRequestContext implements RequestContext {
  _MetricsRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('A rota de métricas não lê providers.');
}
