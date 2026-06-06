# Hermes Master Optimizer Preflight

- generated_at: 2026-06-06 23:43:01 UTC
- status: approved

## Checks

| Check | Status | Detail |
| --- | --- | --- |
| knowledge_db | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db |
| battle | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\battle_analyst_v8.py |
| battle_regression | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\test_battle_analyst_v10_3.py |
| slot_optimizer | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\slot_optimizer.py |
| universal_optimizer | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\universal_optimizer.py |
| metadata_sync | ok | C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\sync_pg_card_metadata_to_hermes.py |
| sqlite_tables | ok | all essential tables present |
| sqlite_content | ok | deck_cards=543, learned_decks=82 |
| python_compile | ok | battle and metadata sync compile |
| battle_regression | ok | test_battle_analyst_v10_3 passed |
| oracle_cache_coverage | ok | {"keywords_filled": 551, "mana_cost_filled": 1051, "oracle_cache_rows": 1260, "oracle_text_filled": 1258, "power_filled": 454, "toughness_filled": 454} |

## Next action

- If status is `approved`, run baseline battle and isolated slot scan.
- If status is `blocked`, fix battle/metadata before running optimizer.
- Do not apply swaps from quick phase automatically.
