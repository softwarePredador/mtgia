# Battle documentation current router recheck 2026-06-19T21:10:33Z

## Escopo

- Validacao somente leitura da documentacao battle atual contra o latest
  recorrente.
- Sem alteracao de PostgreSQL.
- Sem swaps.
- Sem commit ou staging.
- Objetivo: verificar se os `.md` marcados como current ainda representam o
  estado operacional do battle.

## Latest real usado como fonte primaria

- Latest real:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `seeds_requested=16`, `seeds_completed=16`.
- `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`.
- `strategy_low_confidence_seeds=["63202025","63202031"]`.
- `effect_coverage_effect_totals_unknown=41`.
- `focused_template_ready_unknown_effect_count=28`.
- `test_results=null`.

## Docs verificados

### BATTLE_SYSTEM_LOGIC.md

O topo do documento avisa que ele e arquitetura/logica e manda cruzar com
register, latest e gate matrix, mas ainda embute snapshot antigo:

- `2026-06-19T16:42:53Z`.
- `battle_replay_final_status=review_required`.

Leitura: a advertencia de "nao usar como prova de pronto" e correta, mas o
status pontual antigo ainda pode induzir leitor ou agente a citar
`review_required` como estado atual, apesar do latest real estar
`trusted_for_strategy_learning`.

### BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md

O indice declara que o register prevalece quando houver divergencia, mas a tabela
de current sources ainda diz:

- `BATTLE_REPLAY_GATE_MATRIX.md` atualizado para latest `20260619_184721`.
- `master_optimizer_reports/battle_forensic_audit_20260619_163318.md` como
  auditoria forensic/linhagem current.
- O indice nao lista os reports tardios que hoje explicam gaps abertos como
  `BV-068`, `BV-073`, `BV-074` e `BV-075`.

Leitura: como roteador, o index esta defasado e incompleto. Ele ainda aponta o
leitor para snapshots anteriores ao latest trusted atual e aos rechecks tardios.

### BATTLE_REPLAY_GATE_MATRIX.md

O documento esta em melhor estado que o status index, mas nao e o latest real:

- Status declarado: `current as of 2026-06-19T20:38Z`.
- Current Gate Reading aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/summary.json`.
- Latest real atual: `20260619_204826`.

Differences relevantes:

- Gate matrix menciona `event_contract_static` com `53` event types observed e
  `44` static-only event types com waiver.
- Latest real tem `event_contract_static_observed_event_types_total=52`,
  `event_contract_static_static_event_types_total=100` e
  `event_contract_static_fixture_accepted_waiver_total=48`.
- Gate matrix nao menciona gaps tardios do latest como
  `effect_coverage_effect_totals_unknown=41`,
  `focused_template_ready_unknown_effect_count=28`, `test_results=null` e
  provenance de oponentes learned.

Leitura: a regra operacional da matriz continua correta, mas o bloco
`Current Gate Reading` nao deve ser usado como estado mais atual sem cruzar com
`summary.json`.

### BATTLE_DECISION_TRACE_TAXONOMY.md

O documento ainda representa o run:

- `20260619_171605`.
- `decision_trace_rows=152`.
- `decision_trace_kinds_total=15`.
- `decision_trace_kinds_observed=10`.
- `decision_trace_kinds_uncovered=5`.

Latest real atual:

- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`.
- `decision_trace_taxonomy_rows=2221`.
- `decision_trace_kinds_total=15`.
- `decision_trace_kinds_observed=12`.
- `decision_trace_kinds_uncovered=3`.
- `decision_trace_static_uncovered_types=["activated_sacrifice_damage","attack_trigger_artifact_tutor","worldfire_reset"]`.
- `decision_trace_accepted_waivers=["activated_sacrifice_damage","attack_trigger_artifact_tutor","lorehold_upkeep_rummage","saga_chapter_resolution","utility_artifact_activation","utility_land_activation"]`.

Leitura: o contrato conceitual ainda e util, mas o documento nao e mais current
para contagens de corpus, observed counts ou uncovered types. Isto revalida
`BV-060`.

## Conclusao

- `BV-058` permanece aberto: o roteamento/status da documentacao current ainda
  esta defasado contra latest `20260619_204826`.
- `BV-060` permanece aberto: a taxonomia markdown ainda esta em snapshot
  `20260619_171605`, com contagens inferiores ao latest atual.
- Nenhum novo BV foi aberto nesta etapa; os problemas ja estavam representados
  por `BV-058` e `BV-060`.

## Validacoes executadas

- `jq` no latest `summary.json` - PASS.
- `jq` em `decision_trace_taxonomy.json` do latest - PASS.
- Leitura de `BATTLE_SYSTEM_LOGIC.md` - PASS.
- Leitura de `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` - PASS.
- Leitura de `BATTLE_REPLAY_GATE_MATRIX.md` - PASS.
- Leitura de `BATTLE_DECISION_TRACE_TAXONOMY.md` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py` - PASS, `3 tests passed`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS, `5 tests passed`.

