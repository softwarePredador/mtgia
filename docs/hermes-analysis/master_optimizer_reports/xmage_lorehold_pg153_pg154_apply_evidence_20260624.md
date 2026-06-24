# XMage Lorehold PG153 + PG154 Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before these two batches:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg152_postsync_real_v1_*`
- Residual queue: `234` before PG153 presync work
- Pure manual residual after PG152 postsync: `234`

## PG153: simple mana dorks

Cards promoted from XMage exact scopes:

- `Birds of Paradise`
- `Llanowar Elves`
- `Elvish Mystic`
- `Avacyn's Pilgrim`
- `Fyndhorn Elves`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg153_simple_mana_dorks_package.md`

Presync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg153_mana_dorks_presync_real_v1_*`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 5, "xmage_source_valid_mapper_required": 229}`
- `family_counts={"creature": 5, "manual_model": 229}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 5, "mapper_metadata_or_test_scenario_required": 229}`

Precheck rows:

- `Avacyn's Pilgrim | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Birds of Paradise | target_card_rows=30 | existing_rule_rows=4 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=4`
- `Elvish Mystic | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Fyndhorn Elves | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Llanowar Elves | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- Each of the 5 cards ended with `expected_rule_rows_after=1`, `verified_rows=1`, `active_enabled_rows=1`
- Backup table captured `12` prior rows

Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg153_simple_mana_dorks_20260624.json`
- `selected_card_count=5`
- `pg_rows_loaded=17`
- `sqlite_inserted_or_updated=17`

Postsync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg153_postsync_real_v1_*`
- `severity_counts={"high": 207, "medium": 38, "pass": 289}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 229}`
- `family_counts={"manual_model": 229}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 229}`

Net effect:

- Manual queue reduced from `234` to `229`

## PG154: simple artifact mana rocks

Cards promoted from XMage exact scopes:

- `Sol Ring`
- `Izzet Signet`
- `Simic Signet`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg154_simple_artifact_mana_rocks_package.md`

Presync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg154_artifact_mana_rocks_presync_real_v1_*`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 3, "xmage_source_valid_mapper_required": 226}`
- `family_counts={"manual_model": 226, "ramp_permanent": 3}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 3, "mapper_metadata_or_test_scenario_required": 226}`

Precheck rows:

- `Izzet Signet | target_card_rows=1 | existing_rule_rows=3 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=3`
- `Simic Signet | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Sol Ring | target_card_rows=31 | existing_rule_rows=4 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=3`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- Each of the 3 cards ended with `expected_rule_rows_after=1`, `verified_rows=1`, `active_enabled_rows=1`
- Backup table captured `9` prior rows

Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg154_simple_artifact_mana_rocks_20260624.json`
- `selected_card_count=3`
- `pg_rows_loaded=12`
- `sqlite_inserted_or_updated=11`

Postsync pipeline impact:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg154_postsync_real_v1_*`
- `severity_counts={"high": 204, "medium": 38, "pass": 292}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 226}`
- `family_counts={"manual_model": 226}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 226}`

Net effect:

- Manual queue reduced from `229` to `226`

## Combined delta from this turn

- Total cards promoted and applied: `8`
- Manual residual moved from `234` to `226`
- Exact scopes added this turn:
  - `one_mana_one_one_green_mana_dork_v1`
  - `one_mana_one_one_white_mana_dork_v1`
  - `one_mana_zero_one_flying_any_color_mana_dork_v1`
  - `two_colorless_mana_rock_v1`
  - `signet_filter_mana_rock_v1`

## Next highest-yield residual clusters after PG154

- `Copy Enchantment`, `Mirrormade`, `Copy Artifact`
- `Mana Leak`, `Miscast`, `Spell Pierce`
- `Misty Rainforest`, `Verdant Catacombs`, `Polluted Delta`
- `Springleaf Drum`, `Relic of Legends`
