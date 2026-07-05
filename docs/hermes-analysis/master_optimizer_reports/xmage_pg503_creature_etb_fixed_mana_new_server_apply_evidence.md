# XMage PG503 Creature ETB Fixed Mana Apply Evidence

- Generated at: `2026-07-05T11:41:00Z`
- Deploy id: `xmage_pg503_creature_etb_fixed_mana_new_server`
- Runtime family: `xmage_creature_etb_add_fixed_mana_v1`
- PostgreSQL target: remote server, sanitized in command output; no credentials stored here
- Deck 607 mutated: `false`
- Deck materialized: `false`
- Natural battle run: `false`

## Scope

Promoted exact creature enters-the-battlefield fixed mana rules only:

- `Akki Rockspeaker`: `{R}`
- `Burning-Tree Emissary`: `{R}{G}`
- `Priest of Gix`: `{B}{B}{B}`
- `Priest of Urabrask`: `{R}{R}{R}`

Conditional ETB mana such as "if you cast it from your hand" remains blocked for a separate runtime family.

## Apply

- SQL file: `docs/hermes-analysis/master_optimizer_reports/xmage_pg503_creature_etb_fixed_mana_new_server_apply.sql`
- transaction: `COMMIT`
- deprecated_shadow_rows: `0`
- upserted_rows: `4`
- backup_rows_before_apply: `0`

## Postcheck

Each promoted card has:

- promoted_rule_rows: `1`
- promoted_verified_auto_rows: `1`
- promoted_oracle_hash_rows: `1`
- backup_rows: `0`

## Effect Field Postcheck

- `Akki Rockspeaker`: `etb_mana=1`, `produces=R`, `symbols=["R"]`
- `Burning-Tree Emissary`: `etb_mana=2`, `produces=RG`, `symbols=["R","G"]`
- `Priest of Gix`: `etb_mana=3`, `produces=B`, `symbols=["B","B","B"]`
- `Priest of Urabrask`: `etb_mana=3`, `produces=R`, `symbols=["R","R","R"]`

## SQLite And Runtime

- Sync report: `docs/hermes-analysis/master_optimizer_reports/xmage_pg503_creature_etb_fixed_mana_new_server_pg_to_sqlite_sync.json`
- pg_rows_loaded: `8435`
- sqlite_inserted_or_updated: `8199`
- canonical_snapshot_rows_exported: `5961`
- Runtime lookup: all four cards resolve with scope `xmage_creature_etb_add_fixed_mana_v1`.
- Battle suite output: `docs/hermes-analysis/master_optimizer_reports/xmage_pg503_creature_etb_fixed_mana_new_server_full_battle_suite_post_sync.out`

## Register Decision

- PG503 is applied and should not be rebuilt.
- The local runtime supports exact fixed ETB mana by adding the specified symbols to the controller mana pool.
- The package does not authorize conditional, variable, delayed, or noncreature ETB mana patterns.
