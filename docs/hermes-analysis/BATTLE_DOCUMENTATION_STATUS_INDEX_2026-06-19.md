# Battle Documentation Status Index - 2026-06-19

## Status

Este indice define como ler a documentacao battle/Hermes depois das auditorias
de 2026-06-19. Ele nao substitui o registro vivo de validacao. Quando houver
divergencia, omissao ou artefato novo ainda nao listado aqui, o register
prevalece. A tabela de fontes atuais e um roteador de leitura, nao uma lista
exaustiva de todos os artefatos citados no register.

Fonte viva para achados abertos e fechados:

- [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md)

Regra operacional:

- `current`: pode ser usado como contexto atual, ainda cruzando com o register.
- `historical`: conserva contexto util, mas nao prova prontidao atual.
- `superseded`: foi ultrapassado por artefato, auditoria ou gate mais novo.
- `background`: explica arquitetura/historico, nao deve ser gate de pronto.

## Current Sources

| Documento | Status | Uso seguro |
| --- | --- | --- |
| `BATTLE_VALIDATION_REGISTER_2026-06-19.md` | current | Fonte viva de pendencias, tratativas fechadas e evidencia principal. |
| `BATTLE_SYSTEM_LOGIC.md` | current | Arquitetura/logica atual; cruzar qualquer conclusao de pronto com o register. |
| `BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md` | current | Matriz de trabalho atualizada em 2026-06-19; usar como backlog/priorizacao. |
| `ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md` | current | Fila atual de candidatos/templates/review. |
| `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` | current | Fonte atual sobre coerencia do deck aprendido Lorehold e metadata resolvida. |
| `master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md` | current | Snapshot read-only atual de coerencia do corpus learned-deck: `60` decks ativos, `high=173`, `medium=21`, e plano off-color sem mutacao. Usar com o register porque `BV-082` mostra que este report ainda nao junta 1:1 com os learned opponents do battle latest por chave estavel; no cruzamento atual, `0/12` `source_url` do latest `20260620_025107` apareceram como `row_id` neste report, e os `5/12` matches por `source_ref` tinham commander divergente. |
| `master_optimizer_reports/battle_flow_inventory_audit_20260619_154320.md` | current | Inventario atual de fluxo/gates battle. |
| `master_optimizer_reports/battle_template_gap_audit_20260619_155005.md` | current | Inventario atual de template gaps contra unknowns. |
| `master_optimizer_reports/battle_event_contract_audit_20260619_155726.md` | current | Inventario atual de superficie de eventos/consumidores. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_153722_runtime_safe.md` | current | Snapshot atual de runtime-safe/review-only/unknown coverage. |
| `master_optimizer_reports/battle_documentation_runtime_inventory_audit_20260619_1608.md` | current | Inventario que motivou este indice. |
| `master_optimizer_reports/battle_runtime_logic_map_audit_20260619_161623.md` | current | Mapa atual da superficie runtime/decision/effect/test, ainda report-only. |
| `BATTLE_DECISION_TRACE_TAXONOMY.md` | current | Taxonomia atual de tipos de decision trace, campos obrigatorios e dono/auditor por tipo; atualizada para o latest `20260620_031128`, com `2241` rows e `164` linhas field-contract-only (`BV-085`). |
| `BATTLE_REPLAY_GATE_MATRIX.md` | current | Matriz atual de gates obrigatorios e status final agregado de replay; atualizada para o latest recorrente `20260620_031128`, que esta `blocked` com `mandatory_gate_divergences=["forensic_audit=blocked","strategy_audit=review_required"]`. O fechamento de `BV-089` esta refletido nos contadores oficiais `human_replay_resolve_ability_kind_unknown_lines=0`, `human_replay_damage_cause_unknown_lines=0`, `human_replay_unknown_lines=0` e `human_replay_placeholder_lines=0`. `BV-081` a `BV-088` seguem abertos; `BV-086` agora aponta para o blocker atual `Breena, the Demagogue` via `functional_tags_json`. |
| `master_optimizer_reports/battle_latest_031128_human_replay_renderer_bv089_closure_20260620_0016.md` | current | Fonte corrente de fechamento de `BV-089`: renderer humano usa fallback de `trigger`, teste focado passa, o wrapper publica contadores de placeholder, e o latest oficial `20260620_031128` tem `kind=?=0`, `cause=?=0`, `UNKNOWN=0` e `PLACEHOLDER=0`. |
| `master_optimizer_reports/battle_latest_000720_global_learning_eligibility_recheck_20260619_211055.md` | current | Recheck do latest `20260620_000720`: fecha `BV-072` com `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds` e `global_learning_eligibility_reasons` no summary principal. |
| `master_optimizer_reports/battle_latest_000720_global_learning_eligibility_closure_20260619_211103.md` | current | Evidencia complementar de fechamento de `BV-072`: cruza summary atual com produtor `manaloom-battle-strategy-audit.sh`, helper `compute_global_learning_eligibility(...)` e testes de divergencia global. |
| `master_optimizer_reports/battle_optimizer_surface_gate_coverage_closure_20260619_211754.md` | current | Recheck e fechamento de `BV-074`: todas as superficies operacionais optimizer/scorecard publicam o Battle Replay Gate por report/CLI ou ficam marcadas como legacy/deprecated sem handoff. |
| `master_optimizer_reports/battle_latest_003647_aura_of_silence_forensic_blocker_closure_20260619_213732.md` | current | Fonte corrente de fechamento de `BV-067`: latest focado `20260620_003647` reproduz a seed `63210031`, muda `Aura of Silence` para `manual_runtime_waiver/verified`, zera forensic high/critical e deixa o aggregate trusted, embora sem seed globalmente elegivel por baixa confianca de estrategia. |
| `master_optimizer_reports/battle_latest_002832_learned_deck_opponent_provenance_closure_20260619_213159.md` | current | Fonte corrente de fechamento de `BV-075`: latest `20260620_002832` publica `12` learned opponents, `48` aparicoes, `source_url_missing_count=0` e mantem separado o blocker de engine `forensic_audit=blocked`. |
| `master_optimizer_reports/battle_latest_002832_learned_source_url_closure_forensic_recheck_20260619_2138.md` | superseded | Recheck historico do latest `20260620_002832`: confirmou fechamento de `BV-075`, mas sua leitura de `BV-067` aberto foi superada pelo latest focado `20260620_003647`. |
| `master_optimizer_reports/battle_latest_002230_forensic_blocker_learned_provenance_delta_20260619_2132.md` | superseded | Recheck historico do latest `20260620_002230`; a parte de `BV-067` foi confirmada no latest `002832`, e a parte de `BV-075` foi superada porque `source_url_missing_count=0`. |
| `master_optimizer_reports/battle_latest_000720_learned_deck_opponent_provenance_recheck_20260619_211603.md` | superseded | Recheck historico do latest `20260620_000720`; a parte de agregado learned ausente foi superada pelo latest `20260620_002230`, que ja publica `learned_deck_opponents`, `opponent_deck_provenance` e `learned_opponent_source_counts`. |
| `master_optimizer_reports/battle_latest_000720_learned_deck_source_key_stability_audit_20260619_212318.md` | superseded | Recheck historico que definiu o criterio de `source_url`; foi superado pelo latest `20260620_002832`, que publica `source_url=pg:meta_decks:<uuid>` para os learned opponents e fecha `BV-075`. |
| `master_optimizer_reports/battle_latest_235553_runtime_surface_closure_recheck_20260619_205915.md` | current | Recheck do latest `20260619_235553`: fecha `BV-071` com `runtime_surface_manifest_gate_expected_counts` e `runtime_surface_manifest_status=runtime_surface_manifest_ready`. |
| `master_optimizer_reports/battle_latest_235553_learning_provenance_recheck_20260619_210036.md` | superseded | Recheck historico do latest `20260619_235553`; foi superado para `BV-072` pelo report global-learning `000720` e para `BV-075` pelo report learned-provenance `000720`. |
| `master_optimizer_reports/battle_latest_235553_optimizer_surface_gate_coverage_recheck_20260619_210709.md` | superseded | Recheck de `BV-074` que mantinha o gap aberto; superado pelo fechamento `battle_optimizer_surface_gate_coverage_closure_20260619_211754.md`. |
| `master_optimizer_reports/battle_documentation_current_router_recheck_20260619_211033.md` | current | Recheck tardio de frescor dos docs roteadores; usar junto com register/latest. |
| `master_optimizer_reports/battle_unknown_effect_denominator_audit_20260619_195209.md` | current | Denominador tardio de `effect=unknown`; ver register para distinguir source-unknown de effect-unknown. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_233936.md` | current | Coverage atual que publica `Unknown Effect Denominator`; fechou `BV-068` como gap de denominador, mas nao como runtime completeness de todos os efeitos unknown. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_234917.md` | current | Coverage atual com `Deck Coverage` reconciliado contra `source_totals`/`deck_totals`; fechou `BV-069` como mismatch de source-key na tabela Markdown. |
| `master_optimizer_reports/battle_latest_action_template_effect_denominator_recheck_20260619_210435.md` | current | Recheck tardio do denominador effect/template no latest trusted. |
| `master_optimizer_reports/battle_latest_test_log_provenance_recheck_20260619_210807.md` | current | Recheck tardio de provenance de testes no summary principal. |
| `master_optimizer_reports/battle_optimizer_surface_gate_coverage_recheck_20260619_205344.md` | superseded | Recheck de `BV-074` sobre latest anterior; foi superado pelo report `battle_latest_235553_optimizer_surface_gate_coverage_recheck_20260619_210709.md`. |
| `master_optimizer_reports/battle_learned_deck_source_provenance_recheck_20260619_210007.md` | current | Recheck tardio de provenance dos oponentes learned-deck usados no latest. |
| `master_optimizer_reports/battle_action_event_contract_audit_20260619_1635.md` | current | Auditoria atual de denominador/action event contract; ver register para tratativa fechada posterior. |
| `master_optimizer_reports/battle_template_contract_crosscheck_20260619_162233.md` | current | Crosscheck atual de templates/focused evidence contra unknown backlog. |
| `master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md` | current | Manifesto atual de superficie Python battle e cobertura da automacao recorrente. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.md` | current | Coverage atual com separacao runtime-safe, needs-review, review-only e unknown. |
| `master_optimizer_reports/battle_forensic_audit_20260619_163318.md` | current | Auditoria forensic/linhagem current; usar junto com latest summary e register. |
| `master_optimizer_reports/battle_documentation_freshness_audit_20260619_1642.md` | current | Auditoria que verificou frescor deste indice e docs canonicos. |

## Historical Or Superseded Sources

| Documento | Status | Leitura segura |
| --- | --- | --- |
| `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md` | superseded | Resultado de gate/corpus antigo; nao usar como estado atual sem o register de 2026-06-19. |
| `master_optimizer_reports/battle_latest_231827_gate_lineage_recheck_20260619_202435.md` | superseded | Recheck historico do latest `20260619_231827`; foi superado por `20260619_232324`, que zerou os missing unaccepted de lineage e fechou `BV-080` como stale latest follow-up. |
| `master_optimizer_reports/battle_latest_232324_gate_recheck_20260619_202744.md` | superseded | Recheck historico do latest `20260619_232324`; foi superado por `20260619_234218` e pelo fechamento de `BV-068` no register. |
| `master_optimizer_reports/battle_latest_global_learning_and_learned_opponents_recheck_20260619_203626.md` | superseded | Recheck historico do latest `20260619_232324` para `BV-072` e `BV-075`; foi superado pelo report `battle_latest_234218_effect_learning_provenance_recheck_20260619_204548.md`. |
| `master_optimizer_reports/battle_latest_234218_effect_learning_provenance_recheck_20260619_204548.md` | superseded | Recheck historico do latest `20260619_234218`; foi superado pelo report `battle_latest_234922_current_open_recheck_20260619_205457.md` e pelo fechamento de `BV-069`. |
| `master_optimizer_reports/battle_latest_runtime_surface_manifest_denominator_recheck_20260619_205228.md` | superseded | Recheck de `BV-071` sobre `20260619_234218`; foi superado pelo report `battle_latest_235553_runtime_surface_closure_recheck_20260619_205915.md`. |
| `master_optimizer_reports/battle_latest_234922_current_open_recheck_20260619_205457.md` | superseded | Recheck historico do latest `20260619_234922`; foi superado pelo latest `20260619_235553`, que fechou `BV-071` e manteve `BV-072`/`BV-075` abertos. |
| `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md` | historical | Contexto da estrategia/decision trace; status e escopo mudaram em auditorias posteriores. |
| `DECISION_TRACE_V1_SLICE_2026-06-15.md` | historical | Historico do schema v1; nao prova cobertura atual de replay humano ou regras. |
| `BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md` | historical | Spec de implementacao anterior a novos findings de 2026-06-19. |
| `BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md` | historical | Consolidacao util, mas anterior ao register atual e aos gates novos. |
| `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md` | historical | Contexto amplo do caso Lorehold; usar apenas como background. |
| `BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md` | historical | Snapshot multi-rule anterior a separacao runtime-safe/review-only atual. |
| `BATTLE_PHASE_RULES_DEEP_AUDIT_2026-06-16.md` | historical | Auditoria de fases anterior a instrumentacao atual de replay/action/forensic. |
| `CARD_BATTLE_RULES_CANONICALIZATION_AUDIT_2026-06-16.md` | historical | Auditoria de canonicalizacao anterior a fila/template atual. |
| `LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` | superseded | Matriz de cobertura anterior ao coverage runtime-safe e ao audit de coerencia do deck. |
| `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md` | historical | Contexto de miracle/topdeck anterior aos fixes e event-contract findings de 2026-06-19. |

## Required Freshness Check

Antes de afirmar que battle esta pronto, consultar nesta ordem:

1. `BATTLE_VALIDATION_REGISTER_2026-06-19.md`.
2. `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`.
3. Escopo do run no `summary.json`: `run_dir`, `seeds_requested`,
   `seeds_completed` e `start_seed`. Se `seeds_requested < 16`, tratar como
   recheck focado/manual, nao como readiness recorrente completa.
4. Artefatos `latest/seed_<seed>/replay.events.jsonl`, `replay.txt`,
   `action_critic.json`, `strategy_audit.json`, `replay_decision_audit.json`
   e `forensic_audit.json`.
5. Coverage atual em `master_optimizer_reports/battle_effect_coverage_*`.
6. Docs historicos somente como explicacao de contexto, nunca como prova de
   fechamento atual.
