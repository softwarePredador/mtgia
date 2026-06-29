# Battle Documentation Status Index - 2026-06-19

## Status

Este indice define como ler a documentacao battle/Hermes depois das auditorias
de 2026-06-19. Ele nao substitui o registro vivo de validacao. Quando houver
divergencia, omissao ou artefato novo ainda nao listado aqui, o register
prevalece. A tabela de fontes atuais e um roteador de leitura, nao uma lista
exaustiva de todos os artefatos citados no register.

Ultima reconciliacao do Auditor Central: `2026-06-20 13:12 -0300`.
O latest battle vivo neste momento e
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.

Snapshot atual do latest vivo:

- `run_scope=recurring_full`
- `invocation_kind=manual_cli`
- `seeds_requested=16`, `seeds_completed=16`
- `start_seed=63211604`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`
- `test_results_total=16`, `test_results_status_counts={"pass":16}`
- `execution_status_counts={"auto":1704,"review_only":1457}`

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
| `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` | current | Fluxo operacional atual para absorcao XMage/Oracle -> ManaLoom; supersede o uso operacional dos planos XMage de 2026-06-23/24 e fixa gates contra promocao automatica de escopos genericos. |
| `BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md` | current | Matriz de trabalho atualizada em 2026-06-19; usar como backlog/priorizacao. |
| `ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md` | current | Fila atual de candidatos/templates/review. |
| `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` | current | Fonte atual sobre coerencia do deck aprendido Lorehold e metadata resolvida. |
| `master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md` | current | Snapshot read-only atual de coerencia do corpus learned-deck apos PG-002: `60` decks ativos, `high=2`, `medium=13`, `metadata_total_lands_mismatch=0`, `metadata_zero_lands=0`, `all_core_metadata_zero=0` e `partner_identity_not_modeled=0`. Usar com o register porque os residuais atuais sao QA pontual: Korvold quantity/commander mismatch, land-count review e `some_core_metadata_zero=5`. |
| `master_optimizer_reports/battle_flow_inventory_audit_20260619_154320.md` | current | Inventario atual de fluxo/gates battle. |
| `master_optimizer_reports/battle_template_gap_audit_20260619_155005.md` | current | Inventario atual de template gaps contra unknowns. |
| `master_optimizer_reports/battle_event_contract_audit_20260619_155726.md` | current | Inventario atual de superficie de eventos/consumidores. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_153722_runtime_safe.md` | current | Snapshot atual de runtime-safe/review-only/unknown coverage. |
| `master_optimizer_reports/battle_documentation_runtime_inventory_audit_20260619_1608.md` | current | Inventario que motivou este indice. |
| `master_optimizer_reports/battle_runtime_logic_map_audit_20260619_161623.md` | current | Mapa atual da superficie runtime/decision/effect/test, ainda report-only. |
| `BATTLE_DECISION_TRACE_TAXONOMY.md` | current | Taxonomia atual de tipos de decision trace, campos obrigatorios e dono/auditor por tipo; atualizada para o latest `20260620_040120`, com `2326` rows e `179` linhas field-contract-only (`BV-085`). |
| `BATTLE_REPLAY_GATE_MATRIX.md` | current | Matriz atual de gates obrigatorios e status final agregado de replay; atualizada para o latest recorrente `20260620_160459` (16 seeds), que esta `trusted_for_strategy_learning` com `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`, `test_results_status_counts={"pass":16}` e `execution_status_counts={"auto":1704,"review_only":1457}`. O run `20260620_150241` fica retido como blocker pre-PG-008 e `20260620_132812` fica retido como fechamento PG-007. |
| `master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json` | current | Fonte atual do fechamento PG-008 -> Hermes runtime cache: `apply_pg=false`, `apply_sqlite_from_pg=true`, `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108` e `canonical_snapshot_rows_exported=3161`. |
| `master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_package_20260620_1210.md` | current | Pacote de deploy PG-008 aplicado/validado: `Machine God's Effigy` foi promovida para `card_battle_rules` como `curated/active/auto`, fechando o blocker `functional_tags_json` do latest `20260620_150241`. |
| `master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json` | historical | Fonte retida do fechamento PG-007 -> Hermes runtime cache: `apply_pg=false`, `apply_sqlite_from_pg=true`, `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107` e `canonical_snapshot_rows_exported=3160`; superada pelo sync PG-008 `20260620_1210`. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md` | historical | Coverage pos-PG-007 retida: `runtime_safe_rule_names=1703`, `active_or_review_rule_names=3160`, `execution_status_counts={"auto":1703,"review_only":1457}`, `needs_review_rule_names=1457` e `review_only_rule_names=1457`; superada pela validacao PG-008/latest `20260620_160459`. |
| `master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json` | historical | Fonte retida do fechamento PG-006 -> Hermes runtime cache: `apply_pg=false`, `apply_sqlite_from_pg=true`, `pg_rows_loaded=5188`, `sqlite_inserted_or_updated=5106` e `canonical_snapshot_rows_exported=3159`; superada pelo sync PG-007 `20260620_102701`. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md` | historical | Coverage pos-PG-006 retida para comparacao: `runtime_safe_rule_names=1702`, `active_or_review_rule_names=3159`, `execution_status_counts={"auto":1702,"review_only":1457}`; superada pela coverage pos-PG-007 `20260620_102701`. |
| `master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md` | historical | Evidencia retida de fechamento de `BV-083`: wrapper local publica `action_event_types_seed_sum=561`, `action_event_types_distinct_total=55`, `action_event_type_class_seed_sum` e `action_event_type_class_distinct_counts`; nao usar como latest atual porque foi superado pelo latest recorrente vivo `20260620_160459`. |
| `master_optimizer_reports/battle_latest_040120_research_review_bv084_closure_20260620_0101.md` | current | Fonte corrente de fechamento de `BV-084`: `research_review.json/md` do run oficial `20260620_040120` publicam `finding_samples` e tabela Markdown para as seis ocorrencias `forced_keep_after_bad_mulligan`; `test_battle_decision_research_review` passou no `test_results.jsonl`. |
| `master_optimizer_reports/battle_latest_033246_run_scope_and_replay_renderer_revalidation_20260620_0039.md` | current | Fonte corrente de fechamento de `BV-081` e revalidacao de `BV-089`: compara run focado `033208` contra run recorrente `033246`, prova `run_scope`/`run_profile`/`invocation_kind`, corrige fallback de dano `Lightning Bolt`, e confirma placeholders humanos zerados no latest recorrente. |
| `master_optimizer_reports/battle_latest_031128_human_replay_renderer_bv089_closure_20260620_0016.md` | superseded | Fechamento historico de `BV-089` para o run `20260620_031128`; continua util como evidencia da correcao de `kind=?`, mas foi superado pela revalidacao atual `20260620_033246`. |
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
