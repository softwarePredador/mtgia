# PG163 XMage extra-turn evidence

Date: `2026-06-24`
Branch: `codex/xmage-absorption-20260623`
Deploy id: `PG163`
Slug: `extra_turn`

## Scope

Cards promoted from the real Lorehold + used-opponent aggregate:

- `Final Fortune`
- `Last Chance`

Structured scope promoted:

- `single_extra_turn_then_lose_game_v1`

## Code changes

Added XMage mapping/classification and focused coverage for the extra-turn pair:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py`

## Local validation

Commands:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py
```

Results:

- `test_xmage_to_manaloom_effect_hints.py`: `Ran 111 tests ... OK`
- `test_xmage_semantic_family_batch_pipeline.py`: `Ran 108 tests ... OK`
- `battle_turn_flow_tests.py`: exit `0`

Focused runtime evidence added:

- `test_final_fortune_extra_turn_causes_loss_after_taken_turn`

## Real presync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg163_extra_turn_presync_real_v1
```

Presync summary:

- `severity_counts={"high": 184, "medium": 36, "pass": 314}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 2, "xmage_source_valid_mapper_required": 201}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 2, "mapper_metadata_or_test_scenario_required": 201}`

Ready proposals:

- `Final Fortune -> single_extra_turn_then_lose_game_v1`
- `Last Chance -> single_extra_turn_then_lose_game_v1`

## PG package

Generated files:

- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_package.md`

## PostgreSQL precheck/apply/postcheck

Precheck result:

- `Final Fortune`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Last Chance`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`

Apply result:

- `deprecated_shadow_rows=4`
- `upserted_rows=2`

Postcheck result:

- both cards: `promoted_rule_rows=1`
- both cards: `promoted_verified_auto_rows=1`
- both cards: `promoted_oracle_hash_rows=1`
- backup rows in `manaloom_deploy_audit.pg163_extra_turn_20260624_102023`: `4`

Direct PG verification:

```text
Final Fortune|curated|verified|auto|2|single_extra_turn_then_lose_game_v1
Last Chance|curated|verified|auto|2|single_extra_turn_then_lose_game_v1
```

## Hermes / SQLite sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --only-card "Final Fortune" \
  --only-card "Last Chance" \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg163_extra_turn_20260624.json
```

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg163_extra_turn_20260624.json`
- `selected_card_count=2`
- `generated_rows=2`
- `sqlite_inserted_or_updated=6`

## Real postsync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg163_postsync_real_v1
```

Postsync summary:

- `severity_counts={"high": 182, "medium": 36, "pass": 316}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 201}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 201}`

Residual reduction:

- presync ready batch candidates: `2`
- postsync ready batch candidates: `0`
- mapper-required residual: `203 -> 201`

