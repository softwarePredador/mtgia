class OperationalAlert {
  const OperationalAlert({
    required this.code,
    required this.severity,
    required this.summary,
    required this.observed,
    required this.threshold,
    required this.action,
  });

  final String code;
  final String severity;
  final String summary;
  final Object observed;
  final Object threshold;
  final String action;

  Map<String, Object> toJson() => {
    'code': code,
    'severity': severity,
    'summary': summary,
    'observed': observed,
    'threshold': threshold,
    'action': action,
  };
}

const int operationalAlertThresholdsVersion = 1;
const int _minimumRequestSample = 20;
const int _minimumEndpointSample = 10;
const int _minimumAiSample = 5;
const double _warningErrorRate = 0.05;
const double _criticalErrorRate = 0.15;
const int _warningEndpointP95Ms = 3000;
const int _criticalEndpointP95Ms = 10000;
const int _warningOldestAiJobSeconds = 180;
const int _criticalOldestAiJobSeconds = 360;
const double _warningAiFailureRate = 0.20;
const double _criticalAiFailureRate = 0.50;

Map<String, Object> evaluateOperationalAlerts({
  required Map<String, dynamic> requestMetrics,
  required Map<String, dynamic> aiJobs,
  required Map<String, dynamic> aiCost,
}) {
  final alerts = <OperationalAlert>[
    ..._requestAlerts(requestMetrics),
    ..._aiJobAlerts(aiJobs),
    ..._aiProviderAlerts(aiCost),
  ]..sort((left, right) {
    final severityOrder = {'critical': 0, 'warning': 1};
    final severityComparison = (severityOrder[left.severity] ?? 2).compareTo(
      severityOrder[right.severity] ?? 2,
    );
    return severityComparison != 0
        ? severityComparison
        : left.code.compareTo(right.code);
  });

  final status =
      alerts.any((alert) => alert.severity == 'critical')
          ? 'critical'
          : alerts.isNotEmpty
          ? 'warning'
          : 'ok';

  return {
    'status': status,
    'thresholds_version': operationalAlertThresholdsVersion,
    'alert_count': alerts.length,
    'alerts': alerts.map((alert) => alert.toJson()).toList(growable: false),
  };
}

Iterable<OperationalAlert> _requestAlerts(
  Map<String, dynamic> requestMetrics,
) sync* {
  final totals = _map(requestMetrics['totals']);
  final requestCount = _integer(totals['request_count']);
  final errorRate = _decimal(totals['error_rate']);
  if (requestCount >= _minimumRequestSample && errorRate >= _warningErrorRate) {
    final critical = errorRate >= _criticalErrorRate;
    yield OperationalAlert(
      code: critical ? 'http_5xx_rate_critical' : 'http_5xx_rate_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'Taxa agregada de respostas 5xx acima do orçamento.',
      observed: errorRate,
      threshold: critical ? _criticalErrorRate : _warningErrorRate,
      action:
          'Inspecionar Sentry por request_id e os endpoints com maior erro.',
    );
  }

  final endpoints = _map(requestMetrics['endpoints']);
  for (final entry in endpoints.entries) {
    final metrics = _map(entry.value);
    final endpointRequestCount = _integer(metrics['request_count']);
    final p95LatencyMs = _integer(metrics['p95_latency_ms']);
    if (endpointRequestCount < _minimumEndpointSample ||
        p95LatencyMs < _warningEndpointP95Ms) {
      continue;
    }
    final critical = p95LatencyMs >= _criticalEndpointP95Ms;
    yield OperationalAlert(
      code: 'endpoint_p95_${critical ? 'critical' : 'warning'}:${entry.key}',
      severity: critical ? 'critical' : 'warning',
      summary: 'Latência p95 do endpoint acima do orçamento.',
      observed: p95LatencyMs,
      threshold: critical ? _criticalEndpointP95Ms : _warningEndpointP95Ms,
      action: 'Correlacionar traces e reduzir a etapa dominante do endpoint.',
    );
  }
}

Iterable<OperationalAlert> _aiJobAlerts(Map<String, dynamic> aiJobs) sync* {
  if (aiJobs['status'] != 'ok') {
    return;
  }
  final activeTotal = _integer(aiJobs['active_total']);
  final oldestActiveSeconds = _integer(aiJobs['oldest_active_seconds']);
  if (activeTotal > 0 && oldestActiveSeconds >= _warningOldestAiJobSeconds) {
    final critical = oldestActiveSeconds >= _criticalOldestAiJobSeconds;
    yield OperationalAlert(
      code: critical ? 'ai_job_stalled_critical' : 'ai_job_stalled_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'Existe job de IA ativo próximo ou além do timeout total.',
      observed: oldestActiveSeconds,
      threshold:
          critical ? _criticalOldestAiJobSeconds : _warningOldestAiJobSeconds,
      action: 'Consultar heartbeat/deadline e cancelar ou repetir pelo job id.',
    );
  }

  final completed = _integer(aiJobs['completed_24h']);
  final failed = _integer(aiJobs['failed_24h']);
  final total = completed + failed;
  final failureRate = total == 0 ? 0.0 : failed / total;
  if (total >= _minimumAiSample && failureRate >= _warningAiFailureRate) {
    final critical = failureRate >= _criticalAiFailureRate;
    yield OperationalAlert(
      code:
          critical
              ? 'ai_job_failure_rate_critical'
              : 'ai_job_failure_rate_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'Taxa de falha dos jobs de IA nas últimas 24h está elevada.',
      observed: failureRate,
      threshold: critical ? _criticalAiFailureRate : _warningAiFailureRate,
      action: 'Separar falhas de provider, timeout e contrato antes de retry.',
    );
  }
}

Iterable<OperationalAlert> _aiProviderAlerts(
  Map<String, dynamic> aiCost,
) sync* {
  if (aiCost['status'] != 'ok') {
    return;
  }
  final calls = _integer(aiCost['total_calls']);
  final errors = _integer(aiCost['errors']);
  final errorRate = calls == 0 ? 0.0 : errors / calls;
  if (calls < _minimumAiSample || errorRate < _warningAiFailureRate) {
    return;
  }
  final critical = errorRate >= _criticalAiFailureRate;
  yield OperationalAlert(
    code:
        critical
            ? 'ai_provider_error_rate_critical'
            : 'ai_provider_error_rate_warning',
    severity: critical ? 'critical' : 'warning',
    summary: 'Taxa de erro do provider de IA nas últimas 24h está elevada.',
    observed: errorRate,
    threshold: critical ? _criticalAiFailureRate : _warningAiFailureRate,
    action: 'Verificar credencial, quota e disponibilidade sem habilitar mock.',
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

int _integer(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _decimal(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
