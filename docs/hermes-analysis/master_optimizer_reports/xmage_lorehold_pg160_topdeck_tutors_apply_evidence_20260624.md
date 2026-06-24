# XMage Lorehold PG160 Topdeck Tutors Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before this batch:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg159_postsync_real_v3_*`
- Residual: `215 xmage_source_valid_mapper_required`
- Isolated cards: `Mystical Tutor`, `Worldly Tutor`, `Vampiric Tutor`, `Imperial Seal`

## Runtime / mapper change

New exact scopes added for topdeck tutors:

- `instant_or_sorcery_tutor_to_top_v1`
- `creature_tutor_to_top_v1`
- `any_tutor_to_top_lose_two_life_v1`

Behavior encoded:

- `effect = tutor`
- destination encoded via top-of-library target variants:
  - `instant_or_sorcery_to_top`
  - `creature_to_top`
  - `any_to_top`
- life rider encoded for black unconditional variants:
  - `controller_loses_life_after_tutor = 2`

Runtime support added:

- tutor target filtering now understands destination suffixes such as `_to_top`
- tutor resolution now applies `controller_loses_life_after_tutor`
- zone-transition expectations updated for topdeck tutors

Sync fix added:

- `sync_battle_card_rules_pg.py` now preserves exact PG curated rows with explicit `battle_model_scope` even when `deck_role_json` still carries the generic `manual_review` placeholder
- this was required because `Mystical Tutor` had an older reviewed curated row and the sync filter was incorrectly suppressing the new PG160 exact rule

Touched files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Local validation:

- `python3 -m py_compile ...` -> `ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py` -> `101 tests ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py` -> `98 tests ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py` -> `ok`

## Presync pipeline impact

Source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg160_topdeck_tutors_presync_real_v1_*`

Presync summary:

- `severity_counts={"high": 196, "medium": 35, "pass": 303}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 4, "xmage_source_valid_mapper_required": 211}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 4, "mapper_metadata_or_test_scenario_required": 211}`

Isolated candidates:

- `Mystical Tutor`
  - `battle_model_scope=instant_or_sorcery_tutor_to_top_v1`
  - `logical_rule_key=battle_rule_v1:1252b9a6b4188206efa3cf5c921afaa3`
  - `oracle_hash=6a72f3c0228efaa3bb3bb616122ed036`
- `Worldly Tutor`
  - `battle_model_scope=creature_tutor_to_top_v1`
  - `logical_rule_key=battle_rule_v1:ac383562ba9547c71a9bb6932cf907b8`
  - `oracle_hash=0d52403c7394f384077c7ddcfdd9fa12`
- `Vampiric Tutor`
  - `battle_model_scope=any_tutor_to_top_lose_two_life_v1`
  - `logical_rule_key=battle_rule_v1:0d42202d79e9f7e0b0a65fe5848c9849`
  - `oracle_hash=7418e11fcf0c0158d2b754402dfaac8e`
- `Imperial Seal`
  - `battle_model_scope=any_tutor_to_top_lose_two_life_v1`
  - `logical_rule_key=battle_rule_v1:e8c744eeb299cbecc7234defb18d79ca`
  - `oracle_hash=7418e11fcf0c0158d2b754402dfaac8e`

## PG160 package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg160_topdeck_tutors_package.md`

Precheck rows:

- `Imperial Seal | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Mystical Tutor | target_card_rows=1 | existing_rule_rows=3 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=3`
- `Vampiric Tutor | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Worldly Tutor | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- `Imperial Seal | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=9`
- `Mystical Tutor | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=9`
- `Vampiric Tutor | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=9`
- `Worldly Tutor | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=9`

## Hermes sync

Initial sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg160_topdeck_tutors_20260624.json`

Important note:

- the first sync revealed a local precedence bug where the old reviewed curated `Mystical Tutor` partial row (`instant_or_sorcery_tutor_topdeck_partial_v1`) was still shadowing the new PG160 exact rule in the local SQLite/cache path
- after fixing the sync filter, the batch was mirrored again

Final sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg160_topdeck_tutors_20260624_v2.json`

Final sync summary:

- `selected_card_count=4`
- `pg_rows_loaded=13`
- `sqlite_inserted_or_updated=9`
- `manual_rows=0`
- `generated_rows=4`
- `canonical_snapshot_rows_exported=3220`

Verified final canonical snapshot:

- `Mystical Tutor -> instant_or_sorcery_tutor_to_top_v1`
- `Worldly Tutor -> creature_tutor_to_top_v1`
- `Vampiric Tutor -> any_tutor_to_top_lose_two_life_v1`
- `Imperial Seal -> any_tutor_to_top_lose_two_life_v1`

## Postsync pipeline impact

Important note:

- `v1` is not authoritative because the postsync pipeline was started in parallel with the SQLite sync and read stale cache state
- `v2` was the first sequential rerun after sync completion
- `v3` is the final authoritative evidence set after the sync-filter fix that allowed `Mystical Tutor` to mirror the exact PG160 rule locally

Authoritative postsync source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg160_postsync_real_v3_*`

Authoritative postsync summary:

- `severity_counts={"high": 192, "medium": 36, "pass": 306}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 211}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 211}`

Net effect:

- `Mystical Tutor` left the residual queue completely
- `Worldly Tutor` left the residual queue completely
- `Vampiric Tutor` left the residual queue completely
- `Imperial Seal` left the residual queue completely
- residual moved from `211 + 4 isolated ready` to `211 mapper_required`
