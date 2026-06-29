# PGC059 Deck 607 Active Nonland Oracle Hash Backfill

Purpose: fill missing `oracle_hash` provenance for active/executable deck 607
nonland rules whose `card_id` already points at canonical PostgreSQL
`cards.oracle_text`.

Scope: provenance only. No deck composition, runtime behavior, rule version, or
effect JSON is changed.

Updated rows:

- `Fellwar Stone`
- `Library of Leng`
- `Scroll Rack`
- `Talisman of Conviction`
- `Unexpected Windfall`

Evidence:

- PostgreSQL source: `md5(cards.oracle_text)`
- Online source artifact:
  `pgc059_deck607_active_nonland_oracle_hash_scryfall_oracle_20260629.json`
- Local XMage files under `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/`

Files:

- `pgc059_deck607_active_nonland_oracle_hash_backfill_precheck_20260629.sql`
- `pgc059_deck607_active_nonland_oracle_hash_backfill_apply_20260629.sql`
- `pgc059_deck607_active_nonland_oracle_hash_backfill_postcheck_20260629.sql`
- `pgc059_deck607_active_nonland_oracle_hash_backfill_rollback_20260629.sql`
