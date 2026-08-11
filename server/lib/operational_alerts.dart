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

const int operationalAlertThresholdsVersion = 2;
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
const int _warningOldestBattleJobSeconds = 180;
const int _criticalOldestBattleJobSeconds = 360;
const int _warningBattleQueueSeconds = 120;
const int _criticalBattleQueueSeconds = 300;
const int _minimumBattleTerminalSample = 5;
const double _warningBattleFailureRate = 0.20;
const double _criticalBattleFailureRate = 0.50;
const int _criticalCoachTerminalCount = 3;

Map<String, Object> evaluateOperationalAlerts({
  required Map<String, dynamic> requestMetrics,
  required Map<String, dynamic> aiJobs,
  required Map<String, dynamic> aiCost,
  Map<String, dynamic> battleJobs = const {},
  Map<String, dynamic> interactiveBattle = const {},
}) {
  final alerts = <OperationalAlert>[
    ..._requestAlerts(requestMetrics),
    ..._aiJobAlerts(aiJobs),
    ..._aiProviderAlerts(aiCost),
    ..._battleJobAlerts(battleJobs),
    ..._interactiveBattleAlerts(interactiveBattle),
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

Iterable<OperationalAlert> _battleJobAlerts(
  Map<String, dynamic> battleJobs,
) sync* {
  if (battleJobs['status'] != 'ok') return;

  final jobs = _map(battleJobs['jobs']);
  final active = _integer(jobs['active']);
  final oldestActiveSeconds = _integer(jobs['oldest_active_seconds']);
  if (active > 0 && oldestActiveSeconds >= _warningOldestBattleJobSeconds) {
    final critical = oldestActiveSeconds >= _criticalOldestBattleJobSeconds;
    yield OperationalAlert(
      code:
          critical
              ? 'battle_job_stalled_critical'
              : 'battle_job_stalled_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'Existe Battle job ativo além do orçamento operacional.',
      observed: oldestActiveSeconds,
      threshold:
          critical
              ? _criticalOldestBattleJobSeconds
              : _warningOldestBattleJobSeconds,
      action: 'Inspecionar lease, heartbeat, worker e sidecar do Battle job.',
    );
  }

  final queue = _map(battleJobs['queue']);
  final queueDepth = _integer(queue['depth']);
  final oldestQueueSeconds = _integer(queue['oldest_wait_seconds']);
  if (queueDepth > 0 && oldestQueueSeconds >= _warningBattleQueueSeconds) {
    final critical = oldestQueueSeconds >= _criticalBattleQueueSeconds;
    yield OperationalAlert(
      code:
          critical
              ? 'battle_job_queue_stalled_critical'
              : 'battle_job_queue_stalled_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'A fila de Battle jobs não está drenando dentro do orçamento.',
      observed: oldestQueueSeconds,
      threshold:
          critical ? _criticalBattleQueueSeconds : _warningBattleQueueSeconds,
      action: 'Verificar capacidade do worker, claims e saúde dos sidecars.',
    );
  }

  final persistence = _map(battleJobs['persistence']);
  final persistenceFailures = _integer(persistence['failures']);
  if (persistenceFailures > 0) {
    yield OperationalAlert(
      code: 'battle_job_persistence_error_critical',
      severity: 'critical',
      summary: 'Battle registrou falha de persistência na janela operacional.',
      observed: persistenceFailures,
      threshold: 0,
      action:
          'Inspecionar PostgreSQL e impedir resultado terminal não gravado.',
    );
  }

  final completed = _integer(jobs['completed']);
  final censored = _integer(jobs['censored']);
  final timeout = _integer(jobs['timeout']);
  final coverageError = _integer(jobs['coverage_error']);
  final engineError = _integer(jobs['engine_error']);
  final persistenceError = _integer(jobs['persistence_error']);
  final successful = completed + censored;
  final failed = timeout + coverageError + engineError + persistenceError;
  final total = successful + failed;
  final failureRate = total == 0 ? 0.0 : failed / total;
  if (total >= _minimumBattleTerminalSample &&
      failureRate >= _warningBattleFailureRate) {
    final critical = failureRate >= _criticalBattleFailureRate;
    yield OperationalAlert(
      code:
          critical
              ? 'battle_job_failure_rate_critical'
              : 'battle_job_failure_rate_warning',
      severity: critical ? 'critical' : 'warning',
      summary: 'Taxa operacional de falha dos Battle jobs está elevada.',
      observed: failureRate,
      threshold:
          critical ? _criticalBattleFailureRate : _warningBattleFailureRate,
      action:
          'Separar timeout, coverage_error, engine_error e '
          'persistence_error por runtime.',
    );
  }
}

Iterable<OperationalAlert> _interactiveBattleAlerts(
  Map<String, dynamic> interactiveBattle,
) sync* {
  if (interactiveBattle['status'] != 'ok') return;

  final active = _map(interactiveBattle['active']);
  final waitingPastDeadline = _integer(active['waiting_past_prompt_deadline']);
  if (waitingPastDeadline > 0) {
    yield OperationalAlert(
      code: 'battle_coach_prompt_overdue_critical',
      severity: 'critical',
      summary: 'Battle Coach mantém prompt aberto depois do prazo.',
      observed: waitingPastDeadline,
      threshold: 0,
      action: 'Correlacionar timeout do runtime e terminalizar a sessão.',
    );
  }

  final expiredNonTerminal = _integer(active['ttl_expired_non_terminal']);
  if (expiredNonTerminal > 0) {
    yield OperationalAlert(
      code: 'battle_coach_ttl_expired_active_critical',
      severity: 'critical',
      summary: 'Battle Coach possui sessão não terminal após o TTL.',
      observed: expiredNonTerminal,
      threshold: 0,
      action: 'Reconciliar runtime, attempt e estado terminal no PostgreSQL.',
    );
  }

  final terminals = _map(interactiveBattle['terminals_24h']);
  yield* _coachTerminalCountAlert(
    count: _integer(terminals['process_lost']),
    code: 'battle_coach_process_lost',
    summary: 'Battle Coach perdeu o processo interativo nas últimas 24h.',
    action: 'Verificar restart, digest e isolamento do sidecar interativo.',
  );
  yield* _coachTerminalCountAlert(
    count: _integer(terminals['timeout']),
    code: 'battle_coach_timeout',
    summary: 'Battle Coach atingiu timeout nas últimas 24h.',
    action: 'Inspecionar deadline do prompt, rede e capacidade interativa.',
  );

  final persistenceErrors = _integer(terminals['persistence_error']);
  if (persistenceErrors > 0) {
    yield OperationalAlert(
      code: 'battle_coach_persistence_error_critical',
      severity: 'critical',
      summary: 'Battle Coach falhou ao persistir estado terminal ou replay.',
      observed: persistenceErrors,
      threshold: 0,
      action: 'Bloquear expansão do Coach e inspecionar PostgreSQL/replay.',
    );
  }
}

Iterable<OperationalAlert> _coachTerminalCountAlert({
  required int count,
  required String code,
  required String summary,
  required String action,
}) sync* {
  if (count <= 0) return;
  final critical = count >= _criticalCoachTerminalCount;
  yield OperationalAlert(
    code: '${code}_${critical ? 'critical' : 'warning'}',
    severity: critical ? 'critical' : 'warning',
    summary: summary,
    observed: count,
    threshold: critical ? _criticalCoachTerminalCount : 1,
    action: action,
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
