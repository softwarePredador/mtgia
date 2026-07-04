# PG413 Static Protection-From-Colors Evidence

Status: `applied_postchecked_synced`.

PG413 promoted the XMage-backed static creature protection-from-colors family for:

- `Death Speakers`
- `Galina's Knight`
- `Goblin Outlander`
- `Guma`
- `Ihsan's Shade`
- `Karoo Meerkat`
- `Llanowar Knight`
- `Nacatl Outlander`
- `Oraxid`
- `Oversoul of Dusk`
- `Repentant Blacksmith`
- `Scalebane's Elite`
- `Shivan Zombie`
- `Valeron Outlander`
- `Vedalken Outlander`
- `Vodalian Zombie`
- `Vulshok Refugee`
- `Yavimaya Barbarian`
- `Zombie Outlander`

Runtime scope: `xmage_static_self_protection_from_colors_creature_v1`.

Validation:

- Split: 19 exact proposals selected; 12 non-color `ProtectionAbility` rows stayed blocked as `static_protection_oracle_not_color_exact`.
- Precheck: 19 Oracle-hash-matched cards, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 19 upserted rows, 0 deprecated shadow rows.
- Postcheck: 19 promoted rows, all `verified` / `auto`, all Oracle hash matched.
- PG -> SQLite sync: 19 PG rows loaded, 19 SQLite rows inserted/updated, canonical snapshot rows `5400`.
- Direct PG validation: 19 rows with `battle_model_scope=xmage_static_self_protection_from_colors_creature_v1`, all `verified` / `auto`.
- Direct SQLite validation: 19 rows with `battle_model_scope=xmage_static_self_protection_from_colors_creature_v1`, all `verified` / `auto`.
- Queue delta: adapter-required `26330 -> 26311`.
- Post-PG413 exact-scope recheck: `proposal_count=0`.

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg413_static_protection_colors_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg413_static_protection_colors_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg413_static_protection_colors_new_server_recheck.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg413_static_protection_colors_new_server.json`
