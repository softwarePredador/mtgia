# PG-013 Brainstone Battle Rule Package

Generated: `2026-06-20 20:08:01 -0300`

## Purpose

Promote `Brainstone` from generated `draw_cards` / `review_only` semantics to
the reviewed activated topdeck/filter rule already present in
`reviewed_battle_card_rules.json`:

```json
{
  "effect": "topdeck_manipulation",
  "activation_cost_generic": 2,
  "requires_sacrifice_artifact": true,
  "draw_count": 3,
  "put_from_hand_on_top_count": 2,
  "hand_to_top_exchange": true,
  "battle_model_scope": "brainstone_draw_three_put_two_back_unexecuted_v1",
  "cmc": 1.0
}
```

Oracle evidence from PostgreSQL `cards.oracle_text`: `{2}, {T}, Sacrifice this
artifact: Draw three cards, then put two cards from your hand on top of your
library in any order.`

The key correction is that Brainstone is not free immediate draw. It is an
activated artifact/filter piece used by Lorehold topdeck and Approach lines.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_precheck_20260620_200801.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_apply_20260620_200801.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_rollback_20260620_200801.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_postcheck_20260620_200801.sql`

## Commands

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_precheck_20260620_200801.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_apply_20260620_200801.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_postcheck_20260620_200801.sql
```

## Rollback

```bash
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/brainstone_battle_rule_pg013_rollback_20260620_200801.sql
```

## Local Evidence Before PG Apply

- `reviewed_battle_card_rules.json` has `Brainstone` as `source=curated`,
  `review_status=active`, `confidence=0.88`, effect
  `topdeck_manipulation`.
- PostgreSQL precheck showed only two generated `draw_cards` /
  `needs_review` / `review_only` rows before this package.
- `test_battle_analyst_v10_3.py` exposed the drift after the strict PG mirror:
  the Brainstone topdeck line stopped triggering because PG lacked the curated
  rule.
