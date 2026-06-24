# PG165 XMage pile-selection evidence

Date: `2026-06-24`
Branch: `codex/xmage-absorption-20260623`
Deploy id: `PG165`
Slug: `pile_selection_draw`

## Scope

Cards promoted from the real Lorehold + used-opponent aggregate:

- `Fact or Fiction`
- `Steam Augury`

Structured scope promoted:

- `reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1`

## Code changes

Added XMage mapping/classification and focused runtime coverage for the two-pile reveal pair:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
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
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py
```

Results:

- `test_xmage_to_manaloom_effect_hints.py`: `Ran 115 tests ... OK`
- `test_xmage_semantic_family_batch_pipeline.py`: `Ran 112 tests ... OK`
- `battle_turn_flow_tests.py`: exit `0`

Focused runtime evidence added:

- `test_fact_or_fiction_minimizes_best_available_pile`
- `test_steam_augury_maximizes_worst_available_pile`

## Real presync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg165_pile_selection_presync_real_v1
```

Presync summary:

- `severity_counts={"high": 180, "medium": 36, "pass": 318}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 2, "xmage_source_valid_mapper_required": 197}`
- `family_counts={"manual_model": 197, "pile_selection_spell": 2}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 2, "mapper_metadata_or_test_scenario_required": 197}`

Ready proposals:

- `Fact or Fiction -> reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1`
- `Steam Augury -> reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1`

## PG package

Generated files:

- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_package.md`

## PostgreSQL precheck/apply/postcheck

Precheck result:

- `Fact or Fiction`: `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Steam Augury`: `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`

Apply result:

- `deprecated_shadow_rows=2`
- `upserted_rows=2`

Postcheck result:

- both cards: `promoted_rule_rows=1`
- both cards: `promoted_verified_auto_rows=1`
- both cards: `promoted_oracle_hash_rows=1`
- backup rows: `2`

Direct PG verification:

```text
Fact or Fiction|curated|deprecated|disabled|1|
Fact or Fiction|curated|verified|auto|2|reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1
Steam Augury|curated|verified|auto|2|reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1
```

## Hermes / SQLite sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --only-card "Fact or Fiction" \
  --only-card "Steam Augury" \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg165_pile_selection_draw_20260624.json
```

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg165_pile_selection_draw_20260624.json`
- `selected_card_count=2`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=4`

## Real postsync pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg165_pile_selection_postsync_real_v2
```

Postsync summary:

- `severity_counts={"high": 178, "medium": 36, "pass": 320}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 197}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 197}`

Residual reduction:

- presync ready batch candidates: `2`
- postsync ready batch candidates: `0`
- mapper-required residual: `199 -> 197`
