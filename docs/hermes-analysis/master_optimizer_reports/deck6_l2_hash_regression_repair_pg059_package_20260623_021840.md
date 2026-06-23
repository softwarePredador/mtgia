# PG059 Deck 6 L2 Hash-Only Regression Repair

Scope: official Lorehold `deck_id=6`, L2 hash-only lane.

Included target cards:

- `Fellwar Stone`
- `Mana Vault`
- `Mox Amber`
- `Seething Song`
- `Silence`
- `Talisman of Conviction`
- `Valakut Awakening // Valakut Stoneforge`

The package also includes the active `Valakut Awakening` alias runtime row for
the same card identity so the hash repair is not partial.

## Intent

The current PostgreSQL source of truth has trusted executable rows with
card-specific `battle_model_scope` and disabled shadows, but blank
`oracle_hash`. This package restores the hash from current PostgreSQL
`cards.oracle_text` only.

No `effect_json`, executor, deck, or shadow state is changed.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_precheck_20260623_021840.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_apply_20260623_021840.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_postcheck_20260623_021840.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_rollback_20260623_021840.sql`

## Expected Precheck

- `deck_target_cards=7`
- `target_runtime_rows=8`
- `target_runtime_missing_hash_rows=8`
- `target_runtime_hash_mismatch_rows=0`
- `target_runtime_live_hash_mismatch_rows=0`
- `target_runtime_bad_effect_rows=0`
- `target_runtime_bad_scope_rows=0`
- `backup_candidate_rows=23`
- `target_deck_cards_missing=0`

## Rollback

Rollback restores every pre-PG059 `card_battle_rules` row for the seven target
card identities from
`manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840`.
