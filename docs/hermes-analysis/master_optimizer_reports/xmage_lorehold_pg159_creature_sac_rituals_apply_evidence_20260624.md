# XMage Lorehold PG159 Creature Sacrifice Rituals Apply Evidence (2026-06-24)

## Scope

- Worktree: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Battle artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Baseline before this batch:

- Source report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg158_postsync_real_v1_*`
- Residual: `217 xmage_source_valid_mapper_required`
- Isolated cards: `Culling the Weak`, `Infernal Plunge`

## Runtime / mapper change

New exact scopes added for creature-sacrifice rituals:

- `sacrifice_creature_add_four_black_mana_ritual_v1`
- `sacrifice_creature_add_three_red_mana_ritual_v1`

Behavior encoded:

- `effect = ramp_ritual`
- `ability_kind = one_shot`
- `requires_sacrifice_creature = true`
- `Culling the Weak -> instant=true, produces=B, mana_produced=4`
- `Infernal Plunge -> instant=false, produces=R, mana_produced=3`

Touched files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Important runtime cleanup after PG apply:

- removed the local hardcoded `Infernal Plunge` manual waiver from `battle_analyst_v9.py`
- reason: local `manual` priority was shadowing the newly promoted `curated` PG159 rule in the canonical fallback snapshot

Local validation:

- `python3 -m py_compile ...` -> `ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py` -> `97 tests ok`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py` -> `94 tests ok`

## Presync pipeline impact

Source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg159_creature_sac_rituals_presync_real_v1_*`

Presync summary:

- `severity_counts={"high": 198, "medium": 35, "pass": 301}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 2, "xmage_source_valid_mapper_required": 215}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 2, "mapper_metadata_or_test_scenario_required": 215}`

Isolated candidates:

- `Culling the Weak`
  - `battle_model_scope=sacrifice_creature_add_four_black_mana_ritual_v1`
  - `logical_rule_key=battle_rule_v1:251a36ce251e58e59c75224f84568765`
  - `oracle_hash=94e09cb834f3730999bab3bb621006fc`
- `Infernal Plunge`
  - `battle_model_scope=sacrifice_creature_add_three_red_mana_ritual_v1`
  - `logical_rule_key=battle_rule_v1:6c79ee0d7eda6f8a02666036cad990fa`
  - `oracle_hash=ffe4781c7469d289573ea15e0e5adbd1`

## PG159 package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg159_creature_sac_rituals_package.md`

Precheck rows:

- `Culling the Weak | target_card_rows=1 | existing_rule_rows=2 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=2`
- `Infernal Plunge | target_card_rows=1 | existing_rule_rows=0 | expected_rule_rows_before=0 | would_deprecate_shadow_rows=0`

Apply:

- SQL apply executed successfully against `143.198.230.247:5433/halder`

Postcheck rows:

- `Culling the Weak | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=2`
- `Infernal Plunge | promoted_rule_rows=1 | promoted_verified_auto_rows=1 | promoted_oracle_hash_rows=1 | backup_rows=2`

## Hermes sync

Initial sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg159_creature_sac_rituals_20260624.json`

Final sync report after removing the stale local `Infernal Plunge` waiver:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg159_creature_sac_rituals_20260624_v2.json`

Final sync summary:

- `selected_card_count=2`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=3`
- `manual_rows=0`
- `generated_rows=1`
- `canonical_snapshot_rows_exported=3220`

## Postsync pipeline impact

Important note:

- `v1` is not authoritative because the postsync pipeline was started in parallel with the SQLite sync and read stale cache state.
- `v2` was the first sequential rerun after sync.
- `v3` is the final authoritative evidence set after removing the stale local `Infernal Plunge` waiver so the canonical snapshot reflects the PG159 curated rule.

Authoritative postsync source report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg159_postsync_real_v3_*`

Authoritative postsync summary:

- `severity_counts={"high": 196, "medium": 36, "pass": 302}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 215}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 215}`

Net effect:

- `Culling the Weak` left the residual queue completely
- `Infernal Plunge` left the residual queue completely
- residual moved from `215 + 2 isolated ready` to `215 mapper_required`
