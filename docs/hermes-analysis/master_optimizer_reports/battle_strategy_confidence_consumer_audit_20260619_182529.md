# Battle Strategy Confidence Consumer Audit - 2026-06-19T18:25Z

## Escopo

Auditoria read-only para verificar o que ainda falta apos o fechamento de
`BV-056`: o latest recorrente e o research review ja separam
high-confidence e low-confidence, mas os consumidores de WR/optimizer precisam
ser avaliados como superficie separada.

Fontes verificadas:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_outside_recurring_audit_20260619_175415.md`

Nenhuma consulta ou alteracao PostgreSQL foi feita. Nenhum swap foi aplicado.
Nenhum codigo de produto foi alterado. Nenhum commit foi feito.

## Latest usado

- Latest: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_182219`
- `timestamp_utc=2026-06-19T18:22:19Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["focused_template_dispatch=review_required","strategy_audit=review_required"]`
- `focused_template_evidence_ready=5`
- `focused_template_evidence_not_ready_unwaived=24`
- `strategy_findings=3`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":3}`
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`
- `strategy_high_confidence_learning_seeds=["63201734","63201735","63201736","63201737","63201738","63201742","63201743","63201744","63201745","63201746","63201747","63201748","63201749"]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

Nao ha alerta atual pelo criterio do usuario: nenhum high/critical em action
findings e nenhum strategy blocker. Ainda assim, o status final permanece
`review_required`.

## O que foi fechado

O fechamento de `BV-056` esta correto para a superficie recorrente:

- `battle_decision_strategy_auditor.py` marca forced keep apos mulligan cap como
  `low_confidence_replay`.
- Cada seed low-confidence fica com
  `high_confidence_learning_eligible=false` e
  `high_confidence_learning_weight=0.0`.
- O wrapper recorrente publica `strategy_learning_confidence_counts`,
  `strategy_low_confidence_seeds` e
  `strategy_high_confidence_learning_seeds`.
- O `research_review.json` recorrente tambem publica os mesmos denominadores.
- As seeds `63201739`, `63201740` e `63201741` nao entram em
  `strategy_high_confidence_learning_seeds`.

## Lacuna restante

Nao encontrei prova de que os scripts de optimizer/WR consultem
automaticamente o gate agregado antes de apresentar WR, baseline, delta ou
handoff como evidencia:

- `master_optimizer_baseline.py` grava baseline a partir de `run_battle(...)` e
  `result.win_rate`.
- `slot_optimizer.py` e `master_optimizer_confirmation.py` calculam delta por
  `result.win_rate - baseline_wr`.
- `master_optimizer_quality_gate.py` e `master_optimizer_handoff.py` revisam
  baselines/benchmarks via SQLite local, hashes e quality reviews.
- `master_optimizer_common.py` faz parse de `OVERALL vN: WR=...`, sem campo de
  confidence/gate vindo do audit recorrente.

Isso nao prova que os `3` seeds low-confidence contaminam o optimizer. A prova
atual e outra: o optimizer/scorecard e uma superficie fora do recorrente, e os
relatorios de WR podem ser lidos como aprovados se a task nao cruzar
manualmente com `battle_replay_final_status`.

## Risco

Se uma task futura usar WR, baseline, confirmation ou handoff como evidencia
final sem cruzar o latest audit, ela pode ignorar:

- `battle_replay_final_status=review_required`;
- `mandatory_gate_divergences`;
- `strategy_audit=review_required`;
- `focused_template_dispatch=review_required`;
- `13` samples high-confidence versus `3` low-confidence.

O WR pode continuar sendo util para o corpus que o gerou, mas nao deve ser
apresentado como evidencia final de aprendizado battle sem gate agregado ou
waiver explicito de corpus.

## Ajuste necessario

Antes de qualquer scorecard, baseline, confirmation ou handoff usar WR como
evidencia final, o fluxo deve registrar uma destas condicoes:

1. `battle_replay_final_status=trusted_for_strategy_learning`, sem
   `mandatory_gate_divergences`;
2. ou waiver explicito informando que aquele WR vem de outro corpus/gate e nao
   representa aprendizado high-confidence do latest recorrente;
3. ou denominador separado e visivel com high-confidence, low-confidence e peso
   usado.

Relatorios de optimizer/WR deveriam carregar campos ou secao equivalente a:

- `strategy_confidence_source`
- `battle_replay_final_status`
- `mandatory_gate_divergences`
- `high_confidence_learning_samples`
- `low_confidence_learning_samples`
- `low_confidence_learning_weight`

## Classificacao

- `BV-056`: permanece fechado pela evidencia atual do summary e do research
  review recorrente.
- `BV-057`: novo achado para a lacuna de guardrail entre optimizer/WR e o gate
  agregado do recurring battle audit.

## Validacoes executadas

- `rg` direcionado sobre `docs/hermes-analysis/manaloom-knowledge/scripts`,
  `server/bin`, `server/routes` e
  `/Users/desenvolvimentomobile/.manaloom-agents/bin` para
  `strategy_learning_confidence`, `battle_replay_final_status`,
  `trusted_for_strategy_learning`, `win_rate`, `WR` e termos relacionados.
- Leitura manual dos scripts listados no escopo.
- Leitura do latest `summary.json`.
- Leitura do latest `research_review.json`.
