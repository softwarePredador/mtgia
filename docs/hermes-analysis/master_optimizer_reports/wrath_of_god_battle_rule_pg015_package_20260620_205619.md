# PG-015 Wrath of God Battle Rule Package

Generated: `2026-06-20 20:56:19 -0300`

## Purpose

Promote `Wrath of God` from generated `board_wipe` / `review_only` semantics
to an executable curated board wipe for Lorehold survival variant testing.

Oracle evidence from PostgreSQL `cards.oracle_text`: `Destroy all creatures.
They can't be regenerated.`

Runtime evidence: `board_wipe` is already a supported executable effect in
`battle_analyst_v9.py`.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_precheck_20260620_205619.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_apply_20260620_205619.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_rollback_20260620_205619.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_postcheck_20260620_205619.sql`

## Commands

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_precheck_20260620_205619.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_apply_20260620_205619.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_postcheck_20260620_205619.sql
```

## Rollback

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/wrath_of_god_battle_rule_pg015_rollback_20260620_205619.sql
```

## Local Evidence Before PG Apply

- Latest real-deck run `20260620_235219` is trusted, but Lorehold remains
  `1/16`.
- In that run, Lorehold reached very low life in many losses and did not cast
  `Blasphemous Act` or `Austere Command` in the sampled 16 seeds.
- `Wrath of God` already has PostgreSQL function tag `board_wipe`; only the
  battle rule was stuck as generated `review_only`.
