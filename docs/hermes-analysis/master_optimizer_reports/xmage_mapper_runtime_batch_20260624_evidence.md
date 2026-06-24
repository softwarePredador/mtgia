# XMage Mapper Runtime Batch Evidence - 2026-06-24

Scope:

- Current branch: `codex/xmage-mapper-runtime-batch-20260624`
- Source battle artifact for queue expansion: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_154831`
- Deck expansion included Lorehold `608` through `616` plus newly registered non-Lorehold decks `617` through `619`, alongside replay/opponent decks already present in the artifact.

Implementation:

- Added XMage mapper families for storm mill, threshold ritual, storm soft counter, stack spell copy, Chain of Vapor bounce/copy, Blood Artist style life drain, and broader tutor-to-hand variants.
- Added semantic classifier support for `mill_spell` and `life_drain_engine`, including XMage condition classes and exact batch-safe scopes for `Brain Freeze` and `Cabal Ritual`.
- Added runtime/audit coverage:
  - `test_brain_freeze_runtime_resolves_storm_mill_event`
  - `static_cost_reduction` accepted by forensic supported-effect audit because Dargo runtime cost reduction is already executed in battle replay events.

Pipeline artifacts:

- `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_manifest.json`
- `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_validity.json`
- `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_families.json`
- `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json`
- `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_pattern_registry.json`
- `xmage_effective_queue_20260624_mapper_runtime_batch_v2.json`
- `xmage_effective_queue_20260624_mapper_runtime_batch_v3_post_pg184.json`

Queue result:

- Before PG184 apply: 2 package-ready cards, 337 manual mapper backlog, 24 runtime-family backlog, 81 split-scope backlog, 2 missing local XMage source.
- After PG184 package generation/apply: 0 unprepared package-ready cards, 2 package-already-prepared cards.

PostgreSQL package:

- Deploy id: `PG184`
- Package: `pg184_mill_threshold_ritual_batch_package.md`
- Cards: `Brain Freeze`, `Cabal Ritual`
- Precheck output: `pg184_mill_threshold_ritual_batch_precheck_current_20260624.tsv`
- Apply output: `pg184_mill_threshold_ritual_batch_apply_current_20260624.out`
- Postcheck output: `pg184_mill_threshold_ritual_batch_postcheck_current_20260624.tsv`
- Rollback SQL retained: `pg184_mill_threshold_ritual_batch_rollback.sql`
- Postcheck confirmed one promoted verified/auto rule row and one oracle-hash row per card, with four backup rows available.

Hermes/SQLite sync:

- Sync report: `battle_card_rules_sqlite_from_pg_pg184_mill_threshold_ritual_20260624.json`
- Selected cards: 2
- SQLite inserted/updated rows: 6
- Canonical snapshot updated only for `Brain Freeze` and `Cabal Ritual`.

Validation:

- `python3 -m py_compile` for mapper/classifier/audit/runtime touched files: pass
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`: 164 tests pass
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`: 149 tests pass
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`: pass, including Brain Freeze runtime mill resolution and static-cost-reduction forensic support
- Focused battle audit artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_193554`
  - 18 audit tests executed
  - `forensic_rule_findings`: 0
  - `forensic_severity_counts`: `{}`
  - `battle_replay_final_status`: `review_required`
  - Remaining review gates: `decision_trace_taxonomy_status=review_required`, `event_contract_static_status=review_required`

