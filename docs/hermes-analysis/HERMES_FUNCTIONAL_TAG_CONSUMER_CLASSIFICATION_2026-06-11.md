# Hermes Functional Tag Consumer Classification

> Data: 2026-06-11
> Status: classificacao operacional apos Slice 1 + bridge de consumidores.
> Escopo: scripts Hermes que ainda mencionam `functional_tag`.
>
> Este documento existe para impedir que scripts historicos/manuais sejam
> tratados como consumidores ativos do novo contrato multi-tag. Ele tambem
> define quais scripts podem rodar automaticamente depois do snapshot agregado.

## 1. Regra canonica

`functional_tag` continua existindo como compatibilidade legada. O contrato real
para consumidores em contexto de deck e:

- cardinalidade: `SUM(deck_cards.quantity)`;
- roles: membership em `functional_tags_json`;
- fallback: `functional_tag` somente quando `functional_tags_json` nao existir
  ou estiver vazio;
- battle rules: `battle_rules_json`/tabela de battle rules para execucao e
  auditoria, nao para contagem de deckbuilding;
- hashes: `deck_hash` estrutural separado de `semantics_hash`.

## 2. Consumidores ativos migrados ou compatibilizados

Estes scripts podem participar do pipeline atual porque ja usam arrays, helper
set-based ou fallback explicitamente controlado.

| Script | Status | Observacao |
|---|---|---|
| `sync_pg_target_deck_to_hermes.py` | ACTIVE / MIGRATED | Agrega por `card_id`, grava `functional_tags_json`, `semantic_tags_v2_json`, `battle_rules_json`, `deck_hash`, `semantics_hash`, `sync_run_id`; rejeita fanout antes de escrever. |
| `semantic_role_metrics.py` | ACTIVE / NEW HELPER | Helper compartilhado para validadores/report-only; role membership overlay sem inflar cardinalidade. |
| `master_optimizer_common.py` | ACTIVE / MIGRATED | `deck_hash` estrutural, `semantics_hash` separado, `functional_tags_for_row()` e `roles_for_row()`. |
| `slot_optimizer.py` | ACTIVE / MIGRATED | Usa `functional_tags_for_row()` para roles reais antes de fallback por effect/category. |
| `_mana_validator.py` | ACTIVE / MIGRATED | Usa `load_deck_metric_rows()` e reporta `role_metric_source`. |
| `_run_validation.py` | ACTIVE / MIGRATED | Usa membership de `functional_tags_json`; notas deixam claro que role sums podem exceder total de cartas. |
| `_update_cron_status.py` | ACTIVE / MIGRATED | Usa membership de `functional_tags_json` e escreve status sem depender de colunas stale da tabela `decks`. |
| `battle_analyst_v9.py` | ACTIVE / MIGRATED | Carrega `functional_tags_json` quando existir, preserva fallback `functional_tag`, e usa membership de tags para efeitos heurísticos/contagens. |
| `battle_forensic_audit.py` | ACTIVE / COMPATIBLE | Reconhece `functional_tags_json` como fonte heurística esperada em replay/forensic. |
| `master_optimizer_apply.py` | ACTIVE / MIGRATED | Ao aplicar swap Hermes-local, preenche `functional_tags_json` quando a coluna existe. |

## 3. Consumidores ativos indiretos

Estes scripts podem continuar rodando porque consomem o deck por
`master_optimizer_common.py`, `battle_analyst_v9.py` ou outros helpers ja
migrados, sem query propria relevante de `functional_tag`.

| Script | Status | Dependencia |
|---|---|---|
| `master_optimizer_baseline.py` | ACTIVE / INDIRECT | Usa `get_deck_summary()`/battle runner do common. |
| `master_optimizer_confirmation.py` | ACTIVE / INDIRECT | Usa common e baseline hash. |
| `master_optimizer_quality_gate.py` | ACTIVE / INDIRECT | Usa `quality_gate_candidate()` do common. |
| `master_optimizer_handoff.py` | ACTIVE / INDIRECT | Usa baseline/hash e reports. |
| `master_optimizer_post_apply_gate.py` | ACTIVE / INDIRECT | Valida hash post-apply. |
| `master_optimizer_product_handoff.py` | ACTIVE / INDIRECT | Handoff de proposta, nao calcula roles. |
| `master_optimizer_loop.py` | ACTIVE / INDIRECT | Preflight/orquestracao. |
| `replay_decision_auditor.py` | ACTIVE / INDIRECT | Audita replay, nao calcula deck roles. |
| `battle_effect_coverage_audit.py` | ACTIVE / INDIRECT | Depende de battle rules/effects, nao de cardinalidade por tag. |

## 4. Scripts manuais/importers que ainda usam `functional_tag`

Estes nao devem virar bloqueio do rollout do snapshot agregado, mas precisam de
fase propria antes de qualquer automacao ampla de novos comandantes.

| Script | Classificacao | Proxima acao |
|---|---|---|
| `import_lorehold_decks.py` | MANUAL IMPORTER / COMPATIBLE | Desde 2026-06-12, preserva multiplos papeis inferidos em `card_deck_analysis.pg_roles`, mantendo `role_in_deck` como papel primario legado. Continua manual; nao virar cron amplo sem gates de learned-deck. |
| `materialize_learned_deck_to_deck_cards.py` | MANUAL MATERIALIZER / COMPATIBLE | Desde 2026-06-12, migra `deck_cards.functional_tags_json` de forma idempotente e grava array derivado do tag inferido ao materializar learned decks. Continua manual; nao virar cron amplo sem gates de learned-deck. |
| `knowledge_db.py` | SCHEMA/SEED HELPER / COMPATIBLE | Desde 2026-06-12, cria/migra `deck_cards.functional_tags_json` e preenche o snapshot a partir de `functional_tags_json`, `tags` ou `functional_tag` legado em inserts. O caminho `--insert-deck` tambem executa a migracao antes de gravar, preservando bancos SQLite criados antes da coluna multi-tag. |
| `scryfall_classifier.py` | CLASSIFIER / COMPATIBLE | Desde 2026-06-12, `classify_deck()` emite `tags` e `functional_tags_json`, preserva override do usuario como tag de alta confianca e `build_deck_json()` mantem `functional_tag` como papel legado mapeado. |
| `export_hermes_learned_deck.py` | MANUAL EXPORTER / COMPATIBLE | Desde 2026-06-12, agrega `card_deck_analysis.pg_roles` por carta sem `JOIN` com fanout e sem `LIMIT 1` arbitrario; se `pg_roles` nao existir, volta para `role_in_deck`. |
| `parse_collection.py` | COLLECTION IMPORT TOOL | Manter manual ate existir novo contrato de colecao multi-role. |
| `gen_edgar_seed.py` | SEED GENERATOR | Seed historico/manual; migrar so se Edgar virar pipeline ativo. |
| `reimport_lorehold_scryfall.py` | MANUAL REIMPORT | Pode continuar usando `functional_tag` como fallback de import. |
| `evolve_lorehold_20260527_cycle2.py` | HISTORICAL EVOLUTION | Nao usar como automacao atual sem reescrever para arrays. |

## 5. Scripts historicos, debug ou pausados

Estes podem continuar no repositorio como memoria, mas nao devem rodar em cron
nem ser usados para decidir swaps/produto.

| Script | Motivo |
|---|---|
| `battle_analyst.py`, `battle_analyst_v6.py`, `battle_analyst_v7.py`, `battle_analyst_v8.py` | Versoes antigas; `battle_analyst_v9.py` e o engine ativo. |
| `universal_optimizer.py` | Pausado por comportamento antigo de auto-apply; substituido pelo master optimizer flow. |
| `_mulligan_exec15.py`, `mulligan_sim_ciclo3.py` | Experimentos antigos de mulligan. |
| `_scout_report.py`, `deep_analysis.py`, `cross_ref.py`, `verify_matches.py` | Debug/report manual historico. |
| `ciclo4_swaps.py`, `apply_evolution.py`, `build_optimized_deck.py` | Fluxos antigos de evolucao/apply; nao usar como pipeline atual. |
| `_prepend_mulligan.py` | Documento/snippet antigo com referencias a `functional_tag`. |

## 6. Gates antes do apply no Hermes runtime real

1. Backup do SQLite real do Hermes.
2. `sync_pg_target_deck_to_hermes.py --apply` em janela controlada.
3. Conferir no report:
   - `cards_seen`;
   - `quantity_seen`;
   - `quantity_written`;
   - `SUM(deck_cards.quantity)`;
   - commander/main counts;
   - `deck_hash`;
   - `semantics_hash`.
4. Rodar:
   - `_mana_validator.py`;
   - `_run_validation.py`;
   - `_update_cron_status.py`;
   - `master_optimizer_preflight_cron.sh`;
   - `test_battle_analyst_v10_3.py`.
5. Se qualquer script historico tentar rodar como cron ativo, pausar ou migrar
   antes de confiar no resultado.

## 7. Criterio de conclusao desta classificacao

Esta classificacao fica valida enquanto:

- `battle_analyst_v9.py` continuar sendo o engine ativo;
- `master_optimizer_*` continuar usando `master_optimizer_common.py`;
- crons antigos como `universal_optimizer.py` ficarem pausados;
- novos importers learned-deck forem tratados como fase separada.

Se um script da secao 4 virar cron/apply automatico, ele deve primeiro migrar
para `functional_tags_json` e receber teste focado.
