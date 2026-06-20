# Battle latest human replay renderer recheck 2026-06-19T21:14:52Z

## Escopo

- Validacao somente leitura do latest recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`.
- Sem alteracao de PostgreSQL.
- Sem swaps.
- Sem commit ou staging.
- Objetivo: revalidar se o `replay.txt` humano pode ser tratado como log
  completo de aprendizagem ou se ainda precisa ser cruzado com JSONL/gates.

## Latest real

- Run real:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `seeds_requested=16`, `seeds_completed=16`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.

## Tamanho do replay humano versus ledger

Totais agregados nas 16 seeds:

- `replay.txt`: `7608` linhas.
- `replay.events.jsonl`: `14457` eventos.
- `replay.decision_trace.jsonl`: `2221` traces de decisao.

Por seed:

| Seed | replay.txt linhas | events JSONL | decision traces |
| --- | ---: | ---: | ---: |
| `63202022` | 421 | 872 | 136 |
| `63202023` | 490 | 911 | 131 |
| `63202024` | 487 | 879 | 127 |
| `63202025` | 511 | 974 | 132 |
| `63202026` | 627 | 1158 | 190 |
| `63202027` | 345 | 563 | 90 |
| `63202028` | 520 | 994 | 143 |
| `63202029` | 422 | 829 | 133 |
| `63202030` | 483 | 958 | 143 |
| `63202031` | 488 | 865 | 143 |
| `63202032` | 416 | 804 | 118 |
| `63202033` | 412 | 792 | 124 |
| `63202034` | 433 | 812 | 128 |
| `63202035` | 597 | 1167 | 189 |
| `63202036` | 545 | 1035 | 163 |
| `63202037` | 411 | 844 | 131 |

## Placeholders no replay.txt

Busca por placeholders no texto humano:

- Total de placeholders encontrados: `100`.
- `CMC=?`: `97`.
- `life=?->`: `3`.
- `event=?`: `0`.
- `stack=?`: `0`.
- `target=?`: `0`.
- `phase=?`: `0`.
- `priority=?` / `priority_window=?`: `0`.

Exemplos de `life=?->`:

- `seed_63202035/replay.txt:513`: Ancient Tomb com `life=?->28 life_paid=2`.
- `seed_63202029/replay.txt:100`: Ancient Tomb com `life=?->38 life_paid=2`.
- `seed_63202029/replay.txt:141`: Ancient Tomb com `life=?->36 life_paid=2`.

## Lacunas no JSONL fonte

Contagem agregada em `replay.events.jsonl`:

- `utility_land_activated` com `life_paid` e sem `life_before/life_after`: `8`.
- `commander_cast` sem `cmc`: `25`.
- `miracle_cast` sem `cmc`: `51`.
- `end_step_instant` sem `cmc`: `21`.
- `spell_countered` sem `phase` e sem `priority_window`: `10/10`.
- `spell_resolved` sem `phase`: `0/310`.

Leitura: os `97` `CMC=?` no texto batem com os caminhos de cast sem `cmc` no
JSONL (`25 + 51 + 21 = 97`). Ja `life=?->` aparece apenas em parte dos eventos
com vida paga sem before/after, porque nem todo evento fonte e renderizado do
mesmo modo no texto humano.

## Contrato/testes atuais

O teste atual do renderer ainda aceita explicitamente placeholder de vida:

- `test_battle_replay_v10_3_renderer.py` contem assert para
  `life=?->38 life_paid=2`.

O auditor de decisao declara deliberadamente que o replay humano nao e avaliado
como completo:

- `human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.

## Leitura operacional

- `BV-063` permanece aberto.
- O latest e trusted para strategy learning pelos mandatory gates, mas
  `replay.txt` continua sendo uma projecao humana, nao o ledger completo.
- Houve melhora contra a evidencia antiga em alguns placeholders, mas ainda ha
  `100` placeholders textuais e a propria suite atual aceita `life=?->`.
- Para auditoria de regras, custos, curva, vida e prioridade, o `replay.txt`
  deve continuar sendo cruzado com `replay.events.jsonl`,
  `replay.decision_trace.jsonl`, action critic, replay decision auditor e
  forensic audit.

## Validacoes executadas

- `jq` no latest `summary.json` - PASS.
- `wc -l` em todos os `replay.txt`, `replay.events.jsonl` e
  `replay.decision_trace.jsonl` - PASS.
- `rg` dos placeholders no `replay.txt` - PASS.
- `jq` dos eventos sem `cmc`, `life_before/life_after`, phase/priority e
  `spell_resolved.phase` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS.

