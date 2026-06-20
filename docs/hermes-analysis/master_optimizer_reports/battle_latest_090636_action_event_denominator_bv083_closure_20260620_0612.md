# Battle latest 090636 action-event denominator BV-083 closure

Data local: 2026-06-20 06:12 -03:00.

Escopo: tratativa de `BV-083` no wrapper local do battle-strategy-audit. Sem
write em PostgreSQL, sem deck swap, sem promocao de regra battle e sem alteracao
de deck builder.

## Mudanca aplicada

O wrapper local
`/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
agora publica explicitamente os dois denominadores de tipos de evento:

- `action_event_types_total`: campo legado, mantido como soma por seed.
- `action_event_types_total_semantics=legacy_seed_sum_across_seed_action_critics`.
- `action_event_types_seed_sum`: soma dos tipos unicos por seed.
- `action_event_types_distinct_total`: denominador global distinto observado no
  run, copiado do auditor estatico de contrato de eventos.
- `action_event_type_class_seed_sum`: soma por classe dos tipos unicos por seed.
- `action_event_type_class_distinct_counts`: contagem global distinta por classe.

`summary.md` tambem passou a renderizar `seed-sum` e `distinct global` em linhas
separadas.

## Evidencia

- Sintaxe do wrapper: `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- Run recorrente limpo executado em clone temporario limpo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_090636/summary.json`.
- `summary.json`: `run_scope=recurring_full`, `run_profile=recurring_16_seed`,
  `seeds_requested=16`, `seeds_completed=16`,
  `test_results_total=16` e `test_results_status_counts={"pass":16}`.
- `summary.json`: `action_event_types_total=561`,
  `action_event_types_total_semantics=legacy_seed_sum_across_seed_action_critics`,
  `action_event_types_seed_sum=561` e
  `action_event_types_distinct_total=55`.
- `summary.json`: `action_event_type_class_seed_sum={"action_audited":328,"ignored_with_reason":39,"renderer_only":33,"strategy_signal":85,"technical":76}`.
- `summary.json`: `action_event_type_class_distinct_counts={"action_audited":24,"ignored_with_reason":4,"renderer_only":6,"strategy_signal":16,"technical":5}`.
- `summary.json`: `event_contract_static_observed_event_types_total=55` e
  `event_contract_static_observed_type_class_counts={"action_audited":24,"ignored_with_reason":4,"renderer_only":6,"strategy_signal":16,"technical":5}`.
- `summary.md` do mesmo run renderiza:
  `Action event types seed-sum: 561`,
  `Action event types distinct global: 55`,
  `Action event type class seed-sum` e
  `Action event type class distinct global`.

## Resultado

`BV-083` fica fechado como pendencia de nomenclatura/observabilidade: o summary
agora separa a soma por seed do denominador global distinto. O run
`20260620_090636` ficou `battle_replay_final_status=review_required` por
`mandatory_gate_divergences=["forensic_audit=review_required"]`; isso nao reabre
`BV-083`, mas mantem a leitura operacional de que este latest nao e trusted para
aprendizagem global.
