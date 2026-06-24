# PG162 XMage activated tutor-to-hand evidence

Date: `2026-06-24`
Branch: `codex/xmage-absorption-20260623`
Deploy id: `PG162`
Slug: `activated_tutor_to_hand`

## Scope

Cards promoted from XMage exact-scope mapping for the real Lorehold + used-opponent aggregate:

- `Expedition Map`
- `Moonsilver Key`
- `Weathered Wayfarer`

## Code changes

Runtime, mapper, classifier, and focused tests were added for:

- `activated_self_sacrifice_land_tutor_to_hand_artifact_v1`
- `activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1`
- `activated_opponent_more_lands_land_tutor_to_hand_creature_v1`

Touched files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`

## Local validation

Commands:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py
```

Results:

- `test_xmage_to_manaloom_effect_hints.py`: `Ran 109 tests ... OK`
- `test_xmage_semantic_family_batch_pipeline.py`: `Ran 106 tests ... OK`
- `battle_zone_transition_tests.py`: exit `0`

## Real presync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_activated_tutor_to_hand_presync_real_v1
```

Outputs:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_activated_tutor_to_hand_presync_real_v1_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_activated_tutor_to_hand_presync_real_v1_validity.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_activated_tutor_to_hand_presync_real_v1_proposals.json`

Presync summary:

- `severity_counts={"high": 187, "medium": 36, "pass": 311}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 3, "xmage_source_valid_mapper_required": 203}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 3, "mapper_metadata_or_test_scenario_required": 203}`

Ready proposals:

- `Expedition Map -> activated_self_sacrifice_land_tutor_to_hand_artifact_v1`
- `Moonsilver Key -> activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1`
- `Weathered Wayfarer -> activated_opponent_more_lands_land_tutor_to_hand_creature_v1`

## PG package

Generated files:

- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_package.md`

## PostgreSQL precheck/apply/postcheck

Precheck result:

- `Expedition Map`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Moonsilver Key`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Weathered Wayfarer`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`

Apply result:

- `deprecated_shadow_rows=6`
- `upserted_rows=3`

Postcheck result:

- all three cards: `promoted_rule_rows=1`
- all three cards: `promoted_verified_auto_rows=1`
- all three cards: `promoted_oracle_hash_rows=1`
- backup rows in `manaloom_deploy_audit.pg162_activated_tutor_to_hand_20260624_101026`: `6`

Direct PG verification:

```text
Expedition Map|curated|verified|auto|2|activated_self_sacrifice_land_tutor_to_hand_artifact_v1
Moonsilver Key|curated|verified|auto|2|activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1
Weathered Wayfarer|curated|verified|auto|2|activated_opponent_more_lands_land_tutor_to_hand_creature_v1
```

## Hermes / SQLite sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --only-card "Expedition Map" \
  --only-card "Moonsilver Key" \
  --only-card "Weathered Wayfarer" \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg162_activated_tutor_to_hand_20260624.json
```

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg162_activated_tutor_to_hand_20260624.json`
- `selected_card_count=3`
- `generated_rows=3`
- `sqlite_inserted_or_updated=9`

## Real postsync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_postsync_real_v1
```

Outputs:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_postsync_real_v1_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_postsync_real_v1_validity.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg162_postsync_real_v1_proposals.json`

Postsync summary:

- `severity_counts={"high": 184, "medium": 36, "pass": 314}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 203}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 203}`

Residual reduction:

- presync ready batch candidates: `3`
- postsync ready batch candidates: `0`
- mapper-required residual: `206 -> 203`

