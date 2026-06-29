# PGC058 Deck 607 Land Oracle Hash Backfill

Purpose: fill missing `oracle_hash` provenance for active/executable deck 607
land rules whose `card_id` already points at canonical PostgreSQL
`cards.oracle_text`.

Scope: provenance only. No deck composition, runtime behavior, or effect JSON is
changed.

Updated rows:

- `Ancient Tomb`
- `Command Beacon`
- `Eiganjo, Seat of the Empire`
- `Reliquary Tower`
- `Sunbaked Canyon`
- `Urza's Saga`
- `War Room`

Excluded rows:

- `Mountain // Mountain`
- `Plains // Plains`

Those two rows are deprecated/disabled duplicates. The active executable
Mountain and Plains rows already have `oracle_hash` and
`battle_model_scope=basic_one_color_land_v1`.

Evidence:

- PostgreSQL source: `md5(cards.oracle_text)`
- Online source artifact:
  `pgc058_deck607_land_oracle_hash_scryfall_oracle_20260629.json`
- Local XMage files under `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/`

Files:

- `pgc058_deck607_land_oracle_hash_backfill_precheck_20260629.sql`
- `pgc058_deck607_land_oracle_hash_backfill_apply_20260629.sql`
- `pgc058_deck607_land_oracle_hash_backfill_postcheck_20260629.sql`
- `pgc058_deck607_land_oracle_hash_backfill_rollback_20260629.sql`
