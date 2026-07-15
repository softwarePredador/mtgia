# ManaLoom Operational Lookup Guide - 2026-06-30

Status: `current_lookup_index`.

Use this file before starting ManaLoom/Hermes/XMage/Lorehold work. It is an
index of where to consult, how to consult, and which parameters are safe. It
does not replace the frozen contracts; it routes to them so agents do not create
parallel logic, duplicate fields, empty runners, or stale artifact flows.

## First Rule

Do not create a new script, runner, table, field, or report family until these
lookups prove the existing surface cannot answer the task.

If a current contract and an old report disagree, the contract wins. If
PostgreSQL/backend and Hermes SQLite disagree, PostgreSQL/backend wins.
Hermes SQLite is cache/lab evidence, not durable truth.

## Where To Consult

| Need | Consult first | Then validate with |
| --- | --- | --- |
| Data fields, joins, aliases, `oracle*`, `card_id`, names, rule keys | `DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md` and the `manaloom-data-semantic-layer` skill | `pg_hermes_sqlite_contract_audit.py` and `workspace_contract_drift_audit.py` |
| XMage to ManaLoom card-rule work | `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` | `xmage_strategy_consistency_audit.py` |
| Global card execution coverage and resumable external battles | `GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md` | `scripts/manaloom_global_battle_closure.sh` |
| Battle-rule family pipeline | `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md` | focused runtime tests plus PostgreSQL package evidence |
| Commander deckbuilding and optimize | `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md` | `deckbuilding_contract_surface_audit.py` |
| Lorehold current deckbuilder handoff | `manaloom-knowledge/scripts/README.md` section `Lorehold Deckbuilder Handoff` | `operational_surface_alignment_audit.py` |
| Lorehold historical artifact reuse | `lorehold_artifact_contract_audit.py` | never consume historical JSON directly without this audit |
| Current operational alignment across docs/scripts | this guide plus `docs/hermes-analysis/README.md` | `operational_surface_alignment_audit.py` |
| Workspace drift, stale DB paths, cron path rules | `workspace_contract_drift_audit.py` | no manual path assumptions |
| Broad legacy contamination | `LEGACY_CONTAMINATION_BASELINE_2026-06-30.json` | `legacy_contamination_audit.py`; new or increased old patterns fail |

## Global Coverage And Battle Entry Point

Do not create another coverage ledger or asynchronous battle runner. Use:

```bash
scripts/manaloom_global_battle_closure.sh coverage [output_root]
scripts/manaloom_global_battle_closure.sh battle <registry.json> [state_dir]
```

`coverage` is read-only and resolves every PostgreSQL card through exact live
XMage, exact Forge fallback, and verified native coverage. Local Java source
matches remain candidates until catalog reconciliation. `battle` accepts only
`external_battle_async_registry_v1`, persists its checkpoint in `state_dir`,
and never turns exposure into promotion.

## Canonical Database Lookup

Scripts must use `resolve_default_knowledge_db()` from
`manaloom-knowledge/scripts/master_optimizer_common.py`.

Resolution order:

1. `MANALOOM_KNOWLEDGE_DB`, when explicitly set.
2. local script `knowledge.db`, only if it exists and contains required tables.
3. canonical local DB:
   `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.

Do not hardcode `SCRIPT_DIR / "knowledge.db"` in new operational scripts. That
can create or read an empty worktree SQLite file.

For live PostgreSQL/Hermes/SQLite contract validation, use the new-server
wrapper so local runs do not try to resolve the internal EasyPanel host:

```bash
./scripts/quality_gate.sh pg-contract
```

When live PostgreSQL is intentionally unavailable and the task is only a local
SQLite drift triage, use:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py \
  --skip-pg \
  --sqlite-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --out-prefix /tmp/manaloom_pg_hermes_sqlite_skip_pg_current
```

## Query Surfaces

Use these tables/views by default:

| Data need | Preferred surface | Avoid |
| --- | --- | --- |
| One row per card intelligence | `card_intelligence_snapshot` | raw joins to multi-row rule/tag tables |
| Card identity/name resolution | `card_identity_bridge`, then `cards` | treating localized/name aliases as durable identity |
| Deck contents | `deck_cards` by `deck_cards.id` and `card_id` | multiplying rows through `card_battle_rules` or tags |
| Battle rules in PostgreSQL | `card_battle_rules` grouped by `card_id` or `logical_rule_key` | selecting one arbitrary rule and losing multi-function behavior |
| Hermes runtime mirror | SQLite `battle_card_rules` after PG -> Hermes sync | treating SQLite as final truth |
| Oracle/card cache | `card_oracle_cache` by `card_id` when present | name-only matching when `card_id` exists |

## Current Lorehold Handoff

Run the active chain in this order. Defaults are intentionally current; do not
replace them with old `20260626` or `20260628` paths.

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_failure_targeted_synergy_hypotheses.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_failure_targeted_trace_audit.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_focus_access_package_generator.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_exposure_aware_gate_queue.py
```

Current expected state after the 2026-06-30 alignment:

- natural gate-ready packages: `0`;
- focus-access package candidates: `52`;
- forced-exposure diagnostic packages: `11`;
- current runtime-rule gaps after SQLite verified/auto filtering: `0`
  after `lorehold_runtime_gap_family_queue_20260630_post_pg282_final_eight`;
- promotion from forced-exposure only: forbidden without natural confirmation;
- next work: review focus-access trace and cut-model evidence before any new
  deck package; do not resurrect the old runtime-gap batch unless a fresh queue
  shows new gaps.

When `lorehold_exposure_aware_gate_queue.py` reports forced-exposure diagnostic
packages but `natural_gate_ready_count` is `0`, treat that queue as diagnostic
inventory only. The next decision comes from the focus-access generator's
operational work queue and the planner trace review, not from a promotion gate.

## Required Parameters

| Script/flow | Required safe parameter rule |
| --- | --- |
| `manaloom_global_battle_closure.sh coverage` | optional `output_root`; defaults to compact `/tmp` evidence and never mutates PostgreSQL/Hermes |
| `manaloom_global_battle_closure.sh battle` | requires an `external_battle_async_registry_v1` file; optional persistent `state_dir`; every job needs unique `job_id` and integer `request.seed` |
| `xmage_current_replay_batch_pipeline.py` | use `--xmage-root /Users/desenvolvimentomobile/Downloads/mage-master`; include deck `6` and Lorehold `607-616` only when the scope requires Lorehold plus historical baseline comparison |
| Lorehold strategy/cut models | protected baseline is `607`; do not use historical deck `6` as current candidate shell |
| `lorehold_variant_battle_gate.py` | when testing a modified `607` candidate DB, pass `--candidate-deck-id 607` |
| natural promotion battle gates | forced access must be `none`; compare equal opponents and seed windows |
| forced-exposure probes | `--forced-access-mode opening_hand` is diagnostic only; `promotion_allowed=false` until natural confirmation |
| `lorehold_registry_candidate_runner.py` | blocked by default; historical replay requires `--allow-legacy-registry-runner`; never use it as current handoff |
| `xmage_strategy_consistency_audit.py` | uses `--output-prefix`, not `--out-prefix` |
| most report/audit scripts | use `--out-prefix`; check `--help` before inventing a parameter |

## Validation Commands

Before claiming the project is aligned, read
`MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md` and run the matching
gate set for the claim. The matrix is the cross-surface checklist for old bugs
such as raw fanout joins, historical baseline `deck_6`, legacy artifacts,
absolute EDHREC `inclusion` scoring, and PostgreSQL -> Hermes/SQLite drift.

Default alignment set:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
  --out-prefix /tmp/manaloom_operational_surface_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
  --out-prefix /tmp/manaloom_deckbuilding_contract_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --output-prefix /tmp/manaloom_xmage_strategy_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py \
  --out-prefix /tmp/manaloom_lorehold_artifact_contract_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/workspace_contract_drift_audit.py \
  --out-prefix /tmp/manaloom_workspace_contract_drift_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py \
  --out-prefix /tmp/manaloom_legacy_contamination_current
```

For a focused test suite after Lorehold/deckbuilder routing changes:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m unittest \
  test_lorehold_registry_candidate_runner.py \
  test_operational_surface_alignment_audit.py \
  test_lorehold_artifact_contract_audit.py \
  test_lorehold_variant_strategy_matrix.py \
  test_lorehold_runtime_gap_family_queue.py \
  test_lorehold_runtime_candidate_readiness.py \
  test_lorehold_variant_battle_gate.py \
  test_lorehold_607_research_candidate.py \
  test_lorehold_607_bridge_candidate.py \
  test_lorehold_ideal_deck_candidate_matrix.py \
  test_pg_hermes_sqlite_contract_audit.py \
  test_legacy_contamination_audit.py
```

## Redundancy Blocks

Do not do any of these:

- create another Lorehold handoff runner while the trace/focus/exposure chain
  exists;
- read historical `ranked_decks` artifacts directly; use
  `lorehold_artifact_contract_audit.py`;
- promote `xmage_*_review_v1` or pattern registry rows to executable truth;
- use broad XMage extraction as PostgreSQL truth;
- treat battle aggregate as card-level proof without drawn/cast/used evidence
  or a focused runtime test;
- create a new Oracle/name/id field because another path has a missing alias;
  resolve through `card_id`, `oracle_id`, `logical_rule_key`, and the field
  alias contract first;
- run deck promotion from forced-access diagnostics;
- use `build_optimized_deck.py` or `universal_optimizer.py` as active handoff;
  they are historical/blocked surfaces.
- update `LEGACY_CONTAMINATION_BASELINE_2026-06-30.json` just to make a gate
  green; first remove the new stale pattern or document why it is explicitly
  historical/test-only.

## If Something Looks Missing

1. Run `rg` for the existing concept before creating a new surface.
2. Check this guide and `docs/hermes-analysis/README.md`.
3. Run the relevant audit.
4. If the audit passes, follow the existing flow.
5. If the audit fails, fix the existing flow or document the exact missing
   contract before adding new code.
