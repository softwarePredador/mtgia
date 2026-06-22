# PG-012 Flame Wave Battle Rule Package

Generated: `2026-06-20 19:57:00 -0300`

## Purpose

Promote `Flame Wave` from stale generated `remove_creature` / `review_only`
semantics to a curated executable battle rule:

```json
{
  "effect": "damage_player_and_creatures",
  "amount": 4,
  "target": "player_or_planeswalker_controller",
  "battle_model_scope": "target_player_and_controller_creatures",
  "cmc": 7.0
}
```

Oracle evidence: `Flame Wave deals 4 damage to target player or planeswalker and each creature that player or that planeswalker's controller controls.`

Source checked: Scryfall `https://scryfall.com/card/plst/STH-81/flame-wave`.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_precheck_20260620_195700.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_apply_20260620_195700.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_rollback_20260620_195700.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_postcheck_20260620_195700.sql`

## Commands

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_precheck_20260620_195700.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_apply_20260620_195700.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_postcheck_20260620_195700.sql
```

## Rollback

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/flame_wave_battle_rule_pg012_rollback_20260620_195700.sql
```

## Local Runtime Evidence Before PG Apply

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`

All passed after adding `damage_player_and_creatures` runtime support and the
`test_flame_wave_oracle_and_runtime_damage_target_player_creatures` regression.
