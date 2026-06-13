# Hermes Master Optimizer Preflight

- generated_at: 2026-06-12 03:45:28 UTC
- status: approved

## Checks

| Check | Status | Detail |
| --- | --- | --- |
| knowledge_db | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db |
| battle | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py |
| battle_regression | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py |
| slot_optimizer | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py |
| universal_optimizer | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py |
| meta_decks_sync | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_meta_decks_to_hermes.py |
| metadata_sync | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py |
| battle_rules_sync | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py |
| effect_coverage_audit | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py |
| engine_metrics_report | ok | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/engine_metrics_report.py |
| sqlite_tables | ok | all essential tables present |
| sqlite_content | ok | deck_cards=100, learned_decks=120 |
| python_compile | ok | battle, metadata sync and battle rules sync compile |
| battle_regression | ok | test_battle_analyst_v10_3 passed |
| oracle_cache_coverage | ok | {"keywords_filled": 1474, "mana_cost_filled": 2853, "oracle_cache_rows": 3217, "oracle_text_filled": 3213, "power_filled": 1090, "toughness_filled": 1090} |

## Next action

- If status is `approved`, run baseline battle and isolated slot scan.
- If status is `blocked`, fix battle/metadata before running optimizer.
- Do not apply swaps from quick phase automatically.
