# PG052 Valakut Awakening Hash-Only Package

Scope: Deck 6 L2 provenance fix for `Valakut Awakening // Valakut Stoneforge`.

This package does not change executor behavior or `effect_json`. It only adds the oracle hash to the existing verified runtime rule:

- `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`
- `battle_model_scope=bottom_then_draw_plus_one_mdfc_land_v1`
- expected oracle hash: `22b42fcc181b7aed71f78b2e1e51e887`

Files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg052_hash_only_precheck_20260623_012000.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg052_hash_only_apply_20260623_012000.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg052_hash_only_postcheck_20260623_012000.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg052_hash_only_rollback_20260623_012000.sql`
