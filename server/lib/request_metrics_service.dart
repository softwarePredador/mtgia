import 'dart:math';

class EndpointMetricSnapshot {
  final int requestCount;
  final int errorCount;
  final double avgLatencyMs;
  final int p95LatencyMs;
  final DateTime lastRequestAt;

  const EndpointMetricSnapshot({
    required this.requestCount,
    required this.errorCount,
    required this.avgLatencyMs,
    required this.p95LatencyMs,
    required this.lastRequestAt,
  });

  Map<String, dynamic> toJson() => {
    'request_count': requestCount,
    'error_count': errorCount,
    'error_rate': requestCount == 0 ? 0.0 : errorCount / requestCount,
    'avg_latency_ms': avgLatencyMs,
    'p95_latency_ms': p95LatencyMs,
    'last_request_at': lastRequestAt.toIso8601String(),
  };
}

class _EndpointMetricBucket {
  int requestCount = 0;
  int errorCount = 0;
  int latencyTotalMs = 0;
  DateTime lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  final List<int> recentLatencies = <int>[];

  void add({
    required int latencyMs,
    required bool isError,
    required DateTime at,
  }) {
    requestCount += 1;
    if (isError) errorCount += 1;
    latencyTotalMs += latencyMs;
    lastRequestAt = at;

    recentLatencies.add(latencyMs);
    if (recentLatencies.length > 200) {
      recentLatencies.removeAt(0);
    }
  }

  EndpointMetricSnapshot snapshot() {
    return EndpointMetricSnapshot(
      requestCount: requestCount,
      errorCount: errorCount,
      avgLatencyMs: requestCount == 0 ? 0 : latencyTotalMs / requestCount,
      p95LatencyMs: _p95(recentLatencies),
      lastRequestAt: lastRequestAt,
    );
  }
}

/// Um minuto de tráfego de produto (sem as sondagens de saúde).
class _MinuteBucket {
  int requestCount = 0;
  int errorCount = 0;
  int readCount = 0;
  final List<int> readLatencies = <int>[];
}

/// Métricas de requisição por réplica, em memória.
///
/// BT-OBS-001 (D-47): além dos totais desde o início do processo, guarda um
/// anel de minutos das últimas [windowMinutes]. As janelas de 5 e 60 minutos
/// (taxa de 5xx e p95 de leitura) são o que os alertas e o SLO leem: um
/// contador vitalício dilui um apagão depois de dias no ar.
///
/// A chave é o template da rota ([routeTemplate]): nenhum UUID ou número de
/// caminho entra em chave de métrica ou em código de alerta. Acima de
/// [maxEndpoints] rotas, as novas somam em [overflowEndpoint], então a
/// memória fica limitada.
class RequestMetricsService {
  RequestMetricsService._({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Instância isolada, com relógio controlado, para testes.
  factory RequestMetricsService.forTesting({
    required DateTime Function() clock,
  }) => RequestMetricsService._(clock: clock);

  static final RequestMetricsService instance = RequestMetricsService._();

  static const maxEndpoints = 256;
  static const overflowEndpoint = 'OTHER';
  static const windowMinutes = 60;
  static const maxReadSamplesPerMinute = 512;

  final DateTime Function() _clock;
  final Map<String, _EndpointMetricBucket> _metrics =
      <String, _EndpointMetricBucket>{};
  final Map<int, _MinuteBucket> _minutes = <int, _MinuteBucket>{};

  void record({
    required String endpoint,
    required int statusCode,
    required int latencyMs,
  }) {
    final now = _clock().toUtc();
    final template = routeTemplate(endpoint);
    final key =
        _metrics.containsKey(template) || _metrics.length < maxEndpoints
            ? template
            : overflowEndpoint;
    final isError = statusCode >= 500;
    _metrics
        .putIfAbsent(key, () => _EndpointMetricBucket())
        .add(latencyMs: latencyMs, isError: isError, at: now);

    if (!_countsForSlo(template)) return;
    final minute = _minuteOf(now);
    _prune(minute);
    final bucket = _minutes.putIfAbsent(minute, () => _MinuteBucket());
    bucket.requestCount += 1;
    if (isError) bucket.errorCount += 1;
    if (_isRead(template)) {
      bucket.readCount += 1;
      if (bucket.readLatencies.length < maxReadSamplesPerMinute) {
        bucket.readLatencies.add(latencyMs);
      }
    }
  }

  Map<String, dynamic> snapshot() {
    final now = _clock().toUtc();
    final entries =
        _metrics.entries.toList()..sort(
          (a, b) => b.value.requestCount.compareTo(a.value.requestCount),
        );

    var totalRequests = 0;
    var totalErrors = 0;

    final endpointMetrics = <String, dynamic>{};
    for (final entry in entries) {
      final snap = entry.value.snapshot();
      totalRequests += snap.requestCount;
      totalErrors += snap.errorCount;
      endpointMetrics[entry.key] = snap.toJson();
    }

    final minute = _minuteOf(now);
    _prune(minute);
    return {
      'generated_at': now.toIso8601String(),
      'totals': {
        'request_count': totalRequests,
        'error_count': totalErrors,
        'error_rate': totalRequests == 0 ? 0.0 : totalErrors / totalRequests,
      },
      'windows': {'5m': _window(minute, 5), '60m': _window(minute, 60)},
      'endpoints': endpointMetrics,
    };
  }

  Map<String, Object> _window(int currentMinute, int minutes) {
    var requests = 0;
    var errors = 0;
    var reads = 0;
    final latencies = <int>[];
    for (final MapEntry(key: minute, value: bucket) in _minutes.entries) {
      if (minute <= currentMinute - minutes) continue;
      requests += bucket.requestCount;
      errors += bucket.errorCount;
      reads += bucket.readCount;
      latencies.addAll(bucket.readLatencies);
    }
    return {
      'minutes': minutes,
      'request_count': requests,
      'error_count': errors,
      'error_rate': requests == 0 ? 0.0 : errors / requests,
      'read_count': reads,
      'read_p95_ms': _p95(latencies),
    };
  }

  void _prune(int currentMinute) {
    _minutes.removeWhere(
      (minute, _) => minute <= currentMinute - windowMinutes,
    );
  }

  static int _minuteOf(DateTime at) =>
      at.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;
}

/// UUID, número, ou hash e token: 16 ou mais caracteres com ao menos um
/// dígito. Nome de rota (`commander-reference`) não tem dígito e fica.
final _pathIdentifier = RegExp(
  r'^(?:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}|\d+|(?=[A-Za-z_-]*\d)[A-Za-z0-9_-]{16,})$',
);

/// `METHOD /caminho` com cada segmento que identifica um recurso (UUID,
/// número, hash ou token longo) trocado por `:id`. Sem query string. A chave
/// da negação de capability (`RELEASE_CAPABILITY_DENIAL <motivo>`) não tem
/// dígito e fica como está.
String routeTemplate(String endpoint) {
  final space = endpoint.indexOf(' ');
  if (space < 0) return endpoint;
  final method = endpoint.substring(0, space);
  var path = endpoint.substring(space + 1);
  final query = path.indexOf('?');
  if (query >= 0) path = path.substring(0, query);
  final segments = path
      .split('/')
      .map((segment) => _pathIdentifier.hasMatch(segment) ? ':id' : segment);
  return '$method ${segments.join('/')}';
}

/// Sondagens de saúde e o manifesto de capabilities não são tráfego de
/// produto: ficam fora das janelas do SLO.
bool _countsForSlo(String template) {
  final space = template.indexOf(' ');
  if (space < 0) return false;
  final path = template.substring(space + 1);
  return !(path == '/health' ||
      path.startsWith('/health/') ||
      path == '/ready' ||
      path == '/capabilities' ||
      path == '/capabilities/');
}

bool _isRead(String template) =>
    template.startsWith('GET ') || template.startsWith('HEAD ');

int _p95(List<int> latencies) {
  if (latencies.isEmpty) return 0;
  final sorted = [...latencies]..sort();
  return sorted[max(0, (sorted.length * 0.95).ceil() - 1)];
}
