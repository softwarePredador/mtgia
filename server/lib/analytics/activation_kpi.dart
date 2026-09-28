import '../ai_telemetry_contract.dart';
import '../plan_service.dart';
import 'activation_event_catalog.dart';

/// BT-KPI-001, decisão D-47 do dono: as métricas de ativação contam usuários,
/// nunca eventos, e só leem números da base. Nenhum nome de deck, carta,
/// descrição, nota, prompt ou ID sai daqui: a resposta tem contagens, taxas,
/// semanas e os nomes fixos do catálogo.
///
/// - Coorte: a semana UTC do cadastro (segunda-feira), só com os cadastros da
///   janela pedida. Conta excluída sai das contagens e aparece só em
///   `deleted_accounts`, porque a exclusão apaga os dados dela.
/// - Ativação: o primeiro deck criado ou importado em até 24 h do cadastro,
///   lido da tabela `decks` (inclusive deck que foi depois para a lixeira; o
///   deck purgado some da conta). Só entra quem já completou as 24 h.
/// - Volta na segunda semana: pelo menos uma ação registrada no servidor
///   entre o 7º e o 14º dia depois do cadastro (fontes em
///   [activationKpiActivitySources]). Só entra quem já completou os 14 dias.
///   Uso só local, como o contador de vida sem nota de pós-jogo, não aparece.
/// - Loops de valor: usuários da coorte que montaram deck, anotaram partida,
///   ajustaram deck ou usaram IA.
const activationKpiDefinitionVersion = 'activation_kpi_v1';

const activationKpiActivationWindow = Duration(hours: 24);
const activationKpiWeek2Start = Duration(days: 7);
const activationKpiWeek2End = Duration(days: 14);

/// Uma ação do usuário registrada no servidor: a tabela e a coluna do momento,
/// com o filtro que separa ação de ruído.
final class ActivationKpiActivitySource {
  const ActivationKpiActivitySource(this.table, {this.filter});

  final String table;
  final String? filter;
}

/// Ações que contam como volta. Só colunas de criação: `updated_at` pode
/// mudar por processo do servidor, e a mudança de deck já está no ledger.
const activationKpiActivitySources = <ActivationKpiActivitySource>[
  ActivationKpiActivitySource('decks'),
  ActivationKpiActivitySource('deck_change_events'),
  ActivationKpiActivitySource('post_game_notes'),
  ActivationKpiActivitySource('user_binder_items'),
  ActivationKpiActivitySource('activation_funnel_events'),
  ActivationKpiActivitySource(
    'ai_logs',
    filter: "endpoint LIKE 'plan:%' AND success = TRUE",
  ),
  ActivationKpiActivitySource('ai_generate_requests'),
  ActivationKpiActivitySource('interactive_battle_sessions'),
  ActivationKpiActivitySource('shared_deck_reports'),
];

/// Tabelas que o cálculo lê além de `users` e `decks`; quem monta a consulta
/// passa as que existem no banco.
Set<String> activationKpiOptionalTables() =>
    {for (final source in activationKpiActivitySources) source.table}
      ..remove('decks');

/// Operações do ledger que contam como ajuste de deck: toda mudança do dono
/// menos ir para a lixeira e voltar dela.
const activationKpiDeckLifecycleOperations = <String>{
  'deck_delete',
  'deck_restore',
};

/// Taxa com 4 casas, ou nulo sem denominador (sem dado não é zero).
double? activationKpiRate(int numerator, int denominator) {
  if (denominator <= 0) return null;
  return double.parse((numerator / denominator).toStringAsFixed(4));
}

/// A consulta das coortes, com uma linha por semana de cadastro.
/// [existingTables] são as tabelas opcionais presentes no banco.
String activationKpiCohortSql(Set<String> existingTables) {
  String exists(String table, String condition) =>
      existingTables.contains(table)
          ? 'EXISTS (SELECT 1 FROM $table source_row '
              'WHERE source_row.user_id = c.user_id$condition)'
          : 'FALSE';

  final activity = <String>[
    for (final source in activationKpiActivitySources)
      if (source.table == 'decks' || existingTables.contains(source.table))
        'SELECT user_id, created_at AS at FROM ${source.table} '
            'WHERE user_id IN (SELECT user_id FROM cohort)'
            '${source.filter == null ? '' : ' AND ${source.filter}'}',
  ].join('\n      UNION ALL\n      ');
  final lifecycle = activationKpiDeckLifecycleOperations
      .map((operation) => "'$operation'")
      .join(', ');

  // O deck na lixeira conta como criado (D-47 mede a criação); a conta
  // excluída (users.deleted_at) sai das contagens.
  return '''
    WITH cohort AS (
      SELECT u.id AS user_id,
             u.created_at AS signup_at,
             (u.deleted_at IS NOT NULL) AS deleted,
             date_trunc('week', u.created_at AT TIME ZONE 'UTC')::date
               AS cohort_week
      FROM users u
      WHERE u.created_at IS NOT NULL
        AND u.created_at >= NOW() - (@days * INTERVAL '1 day')
    ),
    activity AS (
      $activity
    ),
    per_user AS (
      SELECT c.cohort_week,
             c.deleted,
             c.signup_at + INTERVAL '24 hours' <= NOW() AS activation_matured,
             EXISTS (
               SELECT 1 FROM decks d
               WHERE d.user_id = c.user_id
                 AND d.created_at < c.signup_at + INTERVAL '24 hours'
             ) AS activated_24h,
             c.signup_at + INTERVAL '14 days' <= NOW() AS week2_matured,
             EXISTS (
               SELECT 1 FROM activity a
               WHERE a.user_id = c.user_id
                 AND a.at >= c.signup_at + INTERVAL '7 days'
                 AND a.at < c.signup_at + INTERVAL '14 days'
             ) AS returned_week2,
             EXISTS (
               SELECT 1 FROM decks d WHERE d.user_id = c.user_id
             ) AS deck_built,
             ${exists('post_game_notes', '')} AS game_noted,
             ${exists('deck_change_events', ' AND source_row.operation NOT IN ($lifecycle)')} AS deck_improved,
             ${exists('ai_logs', " AND source_row.endpoint LIKE 'plan:%' AND source_row.success = TRUE")} AS ai_used
      FROM cohort c
    )
    SELECT cohort_week::text AS cohort_week,
           COUNT(*) FILTER (WHERE NOT deleted)::int AS signups,
           COUNT(*) FILTER (WHERE deleted)::int AS deleted_accounts,
           COUNT(*) FILTER (
             WHERE NOT deleted AND activation_matured
           )::int AS activation_matured,
           COUNT(*) FILTER (
             WHERE NOT deleted AND activation_matured AND activated_24h
           )::int AS activated_24h,
           COUNT(*) FILTER (
             WHERE NOT deleted AND week2_matured
           )::int AS week2_matured,
           COUNT(*) FILTER (
             WHERE NOT deleted AND week2_matured AND returned_week2
           )::int AS returned_week2,
           COUNT(*) FILTER (WHERE NOT deleted AND deck_built)::int
             AS deck_built,
           COUNT(*) FILTER (WHERE NOT deleted AND game_noted)::int
             AS game_noted,
           COUNT(*) FILTER (WHERE NOT deleted AND deck_improved)::int
             AS deck_improved,
           COUNT(*) FILTER (WHERE NOT deleted AND ai_used)::int AS ai_used
    FROM per_user
    GROUP BY cohort_week
    ORDER BY cohort_week
  ''';
}

/// O funil por coorte: usuários distintos (não eventos) de cada coorte que
/// emitiram cada evento do catálogo.
String activationKpiFunnelSql() {
  final names = activationEventCatalog.keys
      .map((name) {
        if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
          throw StateError('nome de evento fora do padrão: $name');
        }
        return "'$name'";
      })
      .join(', ');
  return '''
    WITH cohort AS (
      SELECT u.id AS user_id,
             date_trunc('week', u.created_at AT TIME ZONE 'UTC')::date
               AS cohort_week
      FROM users u
      WHERE u.created_at IS NOT NULL
        AND u.created_at >= NOW() - (@days * INTERVAL '1 day')
        AND u.deleted_at IS NULL
    )
    SELECT c.cohort_week::text AS cohort_week,
           e.event_name,
           COUNT(DISTINCT e.user_id)::int AS users
    FROM activation_funnel_events e
    JOIN cohort c ON c.user_id = e.user_id
    WHERE e.event_name IN ($names)
    GROUP BY c.cohort_week, e.event_name
  ''';
}

/// Uma linha de coorte (ou o total) na forma da resposta.
Map<String, Object?> activationKpiCohortJson({
  required String? cohortWeek,
  required Map<String, int> counts,
  required Map<String, int> funnelUsers,
}) {
  final signups = counts['signups'] ?? 0;
  Map<String, Object?> share(int users) => {
    'users': users,
    'share': activationKpiRate(users, signups),
  };
  return {
    if (cohortWeek != null) 'cohort_week': cohortWeek,
    'signups': signups,
    'deleted_accounts': counts['deleted_accounts'] ?? 0,
    'activation': {
      'matured': counts['activation_matured'] ?? 0,
      'activated_24h': counts['activated_24h'] ?? 0,
      'rate': activationKpiRate(
        counts['activated_24h'] ?? 0,
        counts['activation_matured'] ?? 0,
      ),
    },
    'week2_return': {
      'matured': counts['week2_matured'] ?? 0,
      'returned': counts['returned_week2'] ?? 0,
      'rate': activationKpiRate(
        counts['returned_week2'] ?? 0,
        counts['week2_matured'] ?? 0,
      ),
    },
    'loops': {
      for (final loop in activationKpiLoops) loop: share(counts[loop] ?? 0),
    },
    'funnel': [
      for (final event in activationEventCatalog.keys)
        {'event_name': event, ...share(funnelUsers[event] ?? 0)},
    ],
  };
}

const activationKpiLoops = <String>[
  'deck_built',
  'game_noted',
  'deck_improved',
  'ai_used',
];

/// As contagens de uma linha da consulta de coortes.
const activationKpiCohortCounters = <String>[
  'signups',
  'deleted_accounts',
  'activation_matured',
  'activated_24h',
  'week2_matured',
  'returned_week2',
  ...activationKpiLoops,
];

/// A definição que vai junto dos números, para a resposta se explicar.
Map<String, Object> activationKpiDefinition(Set<String> existingTables) => {
  'version': activationKpiDefinitionVersion,
  'decision': 'D-47',
  'unit': 'usuarios_distintos',
  'cohort': 'semana_utc_do_cadastro',
  'activation': 'primeiro_deck_criado_ou_importado_em_24h_do_cadastro',
  'week2_return': 'acao_registrada_no_servidor_do_dia_7_ao_14_do_cadastro',
  'deleted_accounts': 'fora_das_contagens',
  'event_catalog_version': activationEventCatalogVersion,
  'activity_sources': [
    for (final source in activationKpiActivitySources)
      if (source.table == 'decks' || existingTables.contains(source.table))
        source.table,
  ],
};

/// Versão dos limites abaixo. Mudar um número muda a versão.
const activationKpiGuardrailsVersion = 1;

/// Guardrails da D-47 (custo de IA e taxa de erro). As taxas de erro usam os
/// mesmos limites do alerta operacional de provedor de IA
/// (`lib/operational_alerts.dart`, versão 2); o custo é medido contra o teto
/// da beta gratuita (120 ações de IA por mês e usuário).
const activationKpiErrorRateWarning = 0.20;
const activationKpiErrorRateCritical = 0.50;
const activationKpiErrorRateMinimumSample = 5;
const activationKpiAiActionsWarningShareOfCap = 0.5;
const activationKpiAiActionsCriticalShareOfCap = 0.8;

const activationKpiGuardrailStatuses = <String>[
  'ok',
  'warning',
  'critical',
  'insufficient_data',
];

/// Uma medida contra os limites: abaixo do mínimo de amostra não há veredito.
Map<String, Object?> evaluateActivationKpiGuardrail({
  required String id,
  required double? observed,
  required int sample,
  required int minimumSample,
  required double warningAt,
  required double criticalAt,
  Map<String, Object?> extra = const {},
}) {
  final String status;
  if (observed == null || sample < minimumSample) {
    status = 'insufficient_data';
  } else if (observed >= criticalAt) {
    status = 'critical';
  } else if (observed >= warningAt) {
    status = 'warning';
  } else {
    status = 'ok';
  }
  return {
    'id': id,
    'status': status,
    'observed': observed,
    'sample': sample,
    'minimum_sample': minimumSample,
    'warning_at': warningAt,
    'critical_at': criticalAt,
    ...extra,
  };
}

/// O pior estado entre os guardrails com veredito; sem nenhum, falta dado.
String activationKpiGuardrailsStatus(List<Map<String, Object?>> items) {
  final statuses = items.map((item) => item['status']).toSet();
  if (statuses.contains('critical')) return 'critical';
  if (statuses.contains('warning')) return 'warning';
  if (statuses.contains('ok')) return 'ok';
  return 'insufficient_data';
}

/// Ações de IA por usuário que usou IA, levadas a 30 dias.
double? activationKpiAiActionsPer30Days({
  required int actions,
  required int users,
  required int windowDays,
}) {
  if (users <= 0 || windowDays <= 0) return null;
  return double.parse((actions / users * 30 / windowDays).toStringAsFixed(2));
}

const activationKpiAiErrorSql = '''
  SELECT COUNT(*)::int AS calls,
         COUNT(*) FILTER (WHERE success = FALSE)::int AS errors
  FROM ai_logs
  WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
    AND $aiProviderTelemetrySqlPredicate
''';

const activationKpiAiActionsSql = '''
  SELECT COUNT(*)::int AS actions,
         COUNT(DISTINCT user_id)::int AS users
  FROM ai_logs
  WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
    AND endpoint LIKE 'plan:%'
    AND success = TRUE
    AND user_id IS NOT NULL
''';

const activationKpiGenerateFailureSql = '''
  SELECT COUNT(*) FILTER (WHERE status IN ('completed', 'failed'))::int
           AS finished,
         COUNT(*) FILTER (WHERE status = 'failed')::int AS failed
  FROM ai_generate_requests
  WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
''';

/// Os limites de custo, em ações por usuário em 30 dias.
double activationKpiAiActionsWarningAt() =>
    PlanService.freeBetaAiMonthlyOperationalLimit *
    activationKpiAiActionsWarningShareOfCap;

double activationKpiAiActionsCriticalAt() =>
    PlanService.freeBetaAiMonthlyOperationalLimit *
    activationKpiAiActionsCriticalShareOfCap;
