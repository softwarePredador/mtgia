# XMage Lorehold PG155 + PG156 Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before these two batches:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg154_postsync_real_v1_*`
- Manual residual: `226`

## PG155: soft counters

Cards promoted from XMage exact scopes:

- `Mana Leak`
- `Miscast`
- `Spell Pierce`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg155_soft_counters_package.md`

Presync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg155_soft_counters_presync_real_v1_*`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 3, "xmage_source_valid_mapper_required": 223}`
- `family_counts={"manual_model": 223, "targeted_interaction": 3}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 3, "mapper_metadata_or_test_scenario_required": 223}`

Precheck rows:

- `Mana Leak | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Miscast | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Spell Pierce | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- Each of the 3 cards ended with `expected_rule_rows_after=1`, `verified_rows=1`, `active_enabled_rows=1`
- Backup table captured `6` prior rows

Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg155_soft_counters_20260624.json`
- `selected_card_count=3`
- `pg_rows_loaded=9`
- `sqlite_inserted_or_updated=8`

Postsync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg155_postsync_real_v1_*`
- `severity_counts={"high": 201, "medium": 38, "pass": 295}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 223}`
- `family_counts={"manual_model": 223}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 223}`

Net effect:

- Manual residual reduced from `226` to `223`

## PG156: simple rituals

Cards promoted from XMage exact scopes:

- `Dark Ritual`
- `Pyretic Ritual`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg156_simple_rituals_package.md`

Presync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg156_rituals_presync_real_v1_*`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 3, "xmage_source_valid_mapper_required": 220}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 2, "manual_model_required": 1, "mapper_metadata_or_test_scenario_required": 220}`

Residual isolated during presync:

- `Desperate Ritual` normalized to the same three-red ritual baseline but still stayed `manual_model_required`; it was intentionally excluded from PG156 because its extra splice/manual nuance was not yet proven batch-safe.

Precheck rows:

- `Dark Ritual | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Pyretic Ritual | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- Each of the 2 cards ended with `expected_rule_rows_after=1`, `verified_rows=1`, `active_enabled_rows=1`
- Backup table captured `4` prior rows

Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg156_simple_rituals_20260624.json`
- `selected_card_count=2`
- `pg_rows_loaded=6`
- `sqlite_inserted_or_updated=6`

Postsync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg156_postsync_real_v1_*`
- `severity_counts={"high": 199, "medium": 38, "pass": 297}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 220, "ready_for_structured_xmage_pull_review_required": 1}`
- `family_counts={"manual_model": 221}`
- `proposal_status_counts={"manual_model_required": 1, "mapper_metadata_or_test_scenario_required": 220}`

Net effect:

- Manual residual reduced from `223` to `220`
- One isolated `ready_for_structured_xmage_pull_review_required` remains: `Desperate Ritual`

## Combined delta from this turn block

- Total cards promoted and applied: `5`
- Manual residual moved from `226` to `220`
- Exact scopes added this block:
  - `counter_spell_unless_controller_pays_three_v1`
  - `counter_instant_or_sorcery_unless_controller_pays_three_v1`
  - `counter_noncreature_spell_unless_controller_pays_two_v1`
  - `three_black_mana_ritual_v1`
  - `three_red_mana_ritual_v1`

## Current residual posture after PG156

- `220` cards remain in `xmage_source_valid_mapper_required`
- `1` card remains isolated in `ready_for_structured_xmage_pull_review_required`: `Desperate Ritual`
