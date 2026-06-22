# PG-014 Sphere of Safety Battle Rule Package

Generated: `2026-06-20 20:19:24 -0300`

## Purpose

Promote `Sphere of Safety` from generated `draw_engine` / `review_only`
semantics to an executable pillowfort rule:

```json
{
  "effect": "attack_tax",
  "attack_tax_per_enchantment": 1,
  "minimum_attack_tax_per_creature": 1,
  "battle_model_scope": "sphere_of_safety_enchantment_scaled_attack_tax",
  "cmc": 5.0
}
```

Oracle evidence from PostgreSQL `cards.oracle_text`: `Creatures can't attack you
or planeswalkers you control unless their controller pays {X} for each of those
creatures, where X is the number of enchantments you control.`

Runtime evidence: `battle_analyst_v9.py` now supports
`attack_tax_per_enchantment`, and `test_sphere_of_safety_scales_attack_tax_with_enchantments`
passed inside `test_battle_analyst_v10_3.py`.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_precheck_20260620_201924.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_apply_20260620_201924.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_rollback_20260620_201924.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_postcheck_20260620_201924.sql`

## Commands

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_precheck_20260620_201924.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_apply_20260620_201924.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_postcheck_20260620_201924.sql
```

## Rollback

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/sphere_of_safety_battle_rule_pg014_rollback_20260620_201924.sql
```

## Local Evidence Before PG Apply

- Current trusted battle `20260620_231053` has `target_pressure_statuses={"pass":16}`,
  `target_pressure_opponent_combat_to_target=238`, and Lorehold win-rate
  `1/16`.
- The current deck has only two direct attack-pressure permanents:
  `Ghostly Prison` and `Crawlspace`.
- PostgreSQL precheck showed `Sphere of Safety` had two generated
  `draw_engine` / `needs_review` / `review_only` rows and no executable
  `attack_tax` rule.
