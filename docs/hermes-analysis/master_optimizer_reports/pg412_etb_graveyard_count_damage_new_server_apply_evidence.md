# PG412 ETB Graveyard-Count Damage Evidence

Status: `applied_postchecked_synced`.

PG412 promoted the XMage-backed creature ETB dynamic graveyard-count damage family for:

- `Cyclops Electromancer`
- `Lotleth Giant`
- `Ossuary Rats`
- `Warfire Javelineer`

Runtime scope: `xmage_creature_etb_dynamic_graveyard_count_damage_v1`.

Validation:

- Precheck: 4 Oracle-hash-matched cards, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 4 upserted rows, 0 deprecated shadow rows.
- Postcheck: 4 promoted rows, all `verified` / `auto`, all Oracle hash matched.
- PG -> SQLite sync: 4 PG rows loaded, 4 SQLite rows inserted/updated, canonical snapshot rows `5381`.
- Queue delta: adapter-required `26334 -> 26330`; recursion work unit `1803 -> 1799`.
- Post-PG412 exact-scope recheck: `proposal_count=0`.

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg412_etb_graveyard_count_damage_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg412_etb_graveyard_count_damage_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg412_etb_graveyard_count_damage_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg412_etb_graveyard_count_damage_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg412_etb_graveyard_count_damage_new_server_recheck.json`
