# PG025 The One Ring and Orim's Chant Battle Rules Package - 2026-06-22 15:21 UTC

## Scope

- Promote `The One Ring` from broad `draw_engine` to durable PostgreSQL semantics for:
  - cast/ETB protection from everything until next turn;
  - no ETB card draw;
  - upkeep life loss by burden counters;
  - activated tap burden draw.
- Promote `Orim's Chant` from broad `silence_spell` to durable PostgreSQL semantics for kicked attack prevention.
- Disable only the legacy executable/review-only approximations that could shadow the new exact rules.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_precheck_20260622_152115.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_apply_20260622_152115.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_postcheck_20260622_152115.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_rollback_20260622_152115.sql`

## Expected Precheck

- `The One Ring`:
  - `one_ring_card_rows=1`
  - `one_ring_expected_oracle_hash_rows=1`
  - `one_ring_exact_rule_rows=0` before first apply, or `1` after idempotent re-apply.
  - `one_ring_legacy_draw_engine_rows>=1` before first apply, or `0` after apply.
- `Orim's Chant`:
  - `orims_chant_card_rows=1`
  - `orims_chant_expected_oracle_hash_rows=1`
  - `orims_chant_exact_rule_rows=0` before first apply, or `1` after idempotent re-apply.
  - `orims_chant_legacy_silence_rows>=1` before first apply, or `0` after apply.

Observed live state before package creation:

- `The One Ring` curated verified/auto row was only `{"burden": true, "effect": "draw_engine"}`.
- `Orim's Chant` curated verified/auto row was only `{"effect": "silence_spell", "instant": true}`.
- `Orim's Chant` also had a generated `needs_review/review_only` `silence_opponents` approximation.

## Expected Apply Result

- `The One Ring` exact curated verified/auto rule:
  `battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`.
- `The One Ring` `effect_json` includes:
  `{"effect":"draw_engine","burden":true,"draw_on_enter":false,"protection_from_everything_on_enter":true,"activated_burden_draw":true,"activation_requires_tap":true,"battle_model_scope":"the_one_ring_etb_protection_burden_draw_v1"}`.
- `Orim's Chant` exact curated verified/auto rule:
  `battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.
- `Orim's Chant` `effect_json` includes:
  `{"effect":"silence_spell","instant":true,"kicker_prevent_attacks":true,"kicker_cost":"{W}","prevent_attacks_if_kicked":true,"battle_model_scope":"orims_chant_kicker_attack_prevention_v1"}`.
- Legacy executable/review-only broad approximations for these same modeled effects are `deprecated/disabled`.

## Commands

```bash
cd server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_precheck_20260622_152115.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_apply_20260622_152115.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_postcheck_20260622_152115.sql
```

Rollback command, only if post-apply validation fails:

```bash
cd server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_rollback_20260622_152115.sql
```
