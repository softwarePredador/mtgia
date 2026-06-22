# PG024 Mental Misstep Target Rule Package - 2026-06-22 13:02 UTC

## Scope

- Promote `Mental Misstep` from runtime waiver to durable PostgreSQL `card_battle_rules`.
- Preserve the real oracle restriction: counter only a target spell with mana value `1`.
- Disable broad enabled counter approximations that could counter higher-mana-value spells such as `Windborn Muse`.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_precheck_20260622_130251.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_apply_20260622_130251.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_postcheck_20260622_130251.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_rollback_20260622_130251.sql`

## Expected Precheck

- `card_rows=1`
- `expected_oracle_hash_rows=1`
- `broad_enabled_counter_rows>=1` before first apply, or `exact_target_rule_rows=1` after idempotent re-apply.
- Current broad rows observed before package creation:
  - curated verified/auto `{"effect":"counter","instant":true}`
  - generated needs_review/review_only `{"cmc":1.0,"effect":"counter","instant":true}`

## Expected Apply Result

- One curated verified/auto rule:
  `battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`
- `effect_json` includes:
  `{"effect":"counter","instant":true,"counter_target_cmc":1,"battle_model_scope":"mental_misstep_mana_value_one_counter_v1"}`
- Broad enabled counter rows for `Mental Misstep`: `0`.

## Commands

```bash
cd server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_precheck_20260622_130251.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_apply_20260622_130251.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_postcheck_20260622_130251.sql
```

Rollback command, only if post-apply validation fails:

```bash
cd server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_rollback_20260622_130251.sql
```
