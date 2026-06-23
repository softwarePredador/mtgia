# PG051 Deck 6 L1B Non-Fetch Land Mana Package

Scope: Deck 6 non-fetch lands with real mana-production impact. PostgreSQL is the source of truth; Hermes SQLite is a cache/runtime mirror after apply.

Included cards:

- Battlefield Forge
- City of Brass
- Clifftop Retreat
- Elegant Parlor
- Inspiring Vantage
- Mana Confluence
- Rugged Prairie
- Sacred Foundry
- Spectator Seating
- Sunbillow Verge
- Sundown Pass

Excluded from this package:

- Arid Mesa
- Bloodstained Mire
- Flooded Strand
- Marsh Flats
- Prismatic Vista
- Scalding Tarn
- Windswept Heath
- Wooded Foothills

Reason: fetchlands require sacrifice/search/shuffle behavior; current runtime has fetch-aware opening-hand scoring, but not a full land self-activation executor. They remain open for a separate waiver/model package.

Expected precheck:

- `deck_target_cards=11`
- `fetchland_names_in_target=0`
- `target_rule_rows=22`
- `generated_review_only_rows=11`
- `trusted_missing_hash_rows=11`
- `trusted_without_scope_rows=11`
- `trusted_without_produces_rows=11`
- `active_card_id_mismatch_same_oracle_rows=0`
- `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`
- `target_names_missing_rules=0`

Files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_precheck_20260623_011438.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_apply_20260623_011438.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_postcheck_20260623_011438.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_rollback_20260623_011438.sql`

Commands:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_precheck_20260623_011438.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_apply_20260623_011438.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_postcheck_20260623_011438.sql
```

Rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_rollback_20260623_011438.sql
```
