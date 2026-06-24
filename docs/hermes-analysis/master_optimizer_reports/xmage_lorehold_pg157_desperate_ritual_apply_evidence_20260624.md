# XMage Lorehold PG157 Desperate Ritual Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before this batch:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg156_postsync_real_v1_*`
- Residual: `220 mapper_required + 1 ready_for_structured_xmage_pull_review_required`
- Isolated card: `Desperate Ritual`

## Runtime / mapper change

New exact scope added for the XMage-local splice variant:

- `three_red_mana_arcane_splice_ritual_v1`

Behavior encoded:

- `effect = ramp_ritual`
- `instant = true`
- `mana_produced = 3`
- `produces = "R"`
- `subtype_arcane = true`
- `splice_arcane_cost = "{1}{R}"`

Touched files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Local validation:

- `python3 -m py_compile ...` -> `ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py` -> `93 tests ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py` -> `91 tests ok`

## Presync pipeline impact

Source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg157_desperate_ritual_presync_real_v1_*`

Presync summary:

- `severity_counts={"high": 199, "medium": 38, "pass": 297}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 1, "xmage_source_valid_mapper_required": 220}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 1, "mapper_metadata_or_test_scenario_required": 220}`

Isolated candidate:

- `Desperate Ritual`
- `battle_model_scope=three_red_mana_arcane_splice_ritual_v1`
- `logical_rule_key=battle_rule_v1:68a0d55c37b303fd715a47489725bf83`

## PG157 package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg157_desperate_ritual_arcane_splice_package.md`

Precheck row:

- `Desperate Ritual | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Verified PostgreSQL state after apply:

- Promoted row: `battle_rule_v1:68a0d55c37b303fd715a47489725bf83`
- Status: `review_status=verified`, `execution_status=auto`
- Shadow rows deprecated: `2`

Postcheck row:

- `Desperate Ritual | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=2`

## Hermes sync

Report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg157_desperate_ritual_20260624.json`

Sync summary:

- `selected_card_count=1`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`

## Postsync pipeline impact

Authoritative postsync source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg157_postsync_real_v2_*`

Important note:

- `v1` is not authoritative because the postsync pipeline was started in parallel with the SQLite sync and read stale cache state.
- `v2` was rerun sequentially after the sync completed and is the correct evidence set.

Authoritative postsync summary:

- `severity_counts={"high": 198, "medium": 38, "pass": 298}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 220}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 220}`

Net effect:

- `Desperate Ritual` left the residual queue completely
- Residual moved from `220 + 1 isolated ready` to `220 mapper_required`

## Next low-risk family candidates from the remaining 220

Current highest-signal clusters in the live residual:

- `5x` ETB copy permanents via `CopyPermanentEffect`: `Copy Enchantment`, `Mirrormade`, `Phyrexian Metamorph`, `Clever Impersonator`, `Copy Artifact`
- `3x` fetchlands via `FetchLandActivatedAbility`: `Misty Rainforest`, `Verdant Catacombs`, `Polluted Delta`
- `2x` `AnyColorManaAbility + TapTargetCost`: `Springleaf Drum`, `Relic of Legends`

Recommended next batch:

- fetchlands first if subtype-filter land tutor targeting is wired safely
- otherwise the copy-permanent cluster is the next highest-yield XMage-local family
