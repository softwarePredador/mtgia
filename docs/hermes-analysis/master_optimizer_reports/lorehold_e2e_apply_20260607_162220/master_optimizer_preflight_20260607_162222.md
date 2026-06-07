# Hermes Master Optimizer Preflight

- generated_at: 2026-06-07 16:22:22 UTC
- status: approved

## Checks

| Check | Status | Detail |
| --- | --- | --- |
| knowledge_db | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db |
| battle | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py |
| battle_regression | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py |
| slot_optimizer | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py |
| universal_optimizer | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py |
| metadata_sync | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py |
| sqlite_tables | ok | all essential tables present |
| sqlite_content | ok | deck_cards=543, learned_decks=82 |
| python_compile | ok | battle and metadata sync compile |
| battle_regression | ok | test_battle_analyst_v10_3 passed |
| oracle_cache_coverage | ok | {"keywords_filled": 1138, "mana_cost_filled": 2249, "oracle_cache_rows": 2501, "oracle_text_filled": 2500, "power_filled": 807, "toughness_filled": 807} |

## Next action

- If status is `approved`, run baseline battle and isolated slot scan.
- If status is `blocked`, fix battle/metadata before running optimizer.
- Do not apply swaps from quick phase automatically.
