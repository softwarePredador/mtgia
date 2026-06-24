# XMage Lorehold PG158 Fetchlands Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before this batch:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg157_postsync_real_v2_*`
- Residual: `217 xmage_source_valid_mapper_required`
- Isolated cards: `Misty Rainforest`, `Polluted Delta`, `Verdant Catacombs`

## Runtime / mapper change

New exact scope added for XMage-local fetchlands:

- `self_sacrifice_fetch_land_two_land_subtypes_v1`

Behavior encoded:

- `effect = ramp_permanent`
- `ability_kind = activated`
- `activated_self_sacrifice_land_tutor = true`
- `activation_requires_tap = true`
- `activation_cost_generic = 0`
- `activated_pay_life = 1`
- `lands_to_battlefield = 1`
- `land_enters_tapped = false`
- `land_subtypes_any` inferred from Oracle/XMage subtype pair

Runtime support added:

- subtype-filter land selection for fetchlands
- life payment handling for activation cost
- lethal/life-locked activation guard
- zero generic activation cost respected without fallback-to-2 bug

Touched files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Local validation:

- `python3 -m py_compile ...` -> `ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py` -> `97 tests ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py` -> `94 tests ok`
- fetchland runtime harness:
  - `test_fetch_land_activation_filters_targets_by_subtype_and_pays_life` -> `PASS`
  - `test_fetch_land_skips_when_life_payment_would_be_lethal` -> `PASS`

## Presync pipeline impact

Source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg158_fetchlands_presync_real_v1_*`

Presync summary:

- `severity_counts={"high": 198, "medium": 38, "pass": 298}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 3, "xmage_source_valid_mapper_required": 217}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 3, "mapper_metadata_or_test_scenario_required": 217}`

Isolated candidates:

- `Misty Rainforest`
- `Polluted Delta`
- `Verdant Catacombs`

All three promoted with:

- `battle_model_scope=self_sacrifice_fetch_land_two_land_subtypes_v1`

## PG158 package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg158_fetchlands_package.md`

Precheck rows:

- `Misty Rainforest | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Polluted Delta | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Verdant Catacombs | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- `Misty Rainforest | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=6`
- `Polluted Delta | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=6`
- `Verdant Catacombs | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=6`

## Hermes sync

Report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg158_fetchlands_20260624.json`

Sync summary:

- `selected_card_count=3`
- `pg_rows_loaded=9`
- `sqlite_inserted_or_updated=9`
- `canonical_snapshot_rows_exported=3219`

## Postsync pipeline impact

Authoritative postsync source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg158_postsync_real_v1_*`

Authoritative postsync summary:

- `severity_counts={"high": 198, "medium": 35, "pass": 301}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 217}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 217}`

Net effect:

- fetchland batch left the residual queue completely
- residual moved from `217 + 3 isolated ready` to `217 mapper_required`

