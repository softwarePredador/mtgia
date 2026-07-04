# PG414 Static Keyword Protection-From-Colors Evidence

Status: `applied_postchecked_synced`.

PG414 promoted the XMage-backed static creature protection-from-colors family
for 32 additional cards where `ProtectionAbility` is combined with existing
static self keywords such as flying, first strike, defender, double strike,
trample, vigilance, haste, and lifelink.

Runtime scope: `xmage_static_self_protection_from_colors_creature_v1`.

Validation:

- Split: 32 exact proposals selected; 22 non-color protection rows stayed blocked as `static_protection_oracle_not_color_exact`.
- Precheck: 32 Oracle-hash-matched cards, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 32 upserted rows, 0 deprecated shadow rows.
- Postcheck: 32 promoted rows, all `verified` / `auto`, all Oracle hash matched.
- PG -> SQLite sync: 32 PG rows loaded, 32 SQLite rows inserted/updated, canonical snapshot rows `5432`.
- Integrity cleanup: 44 older trusted executable PG rows had missing `oracle_hash` backfilled from current `cards.oracle_text`; full PG -> SQLite sync then loaded 4298 PG rows and updated 4293 SQLite rows.
- Direct PG validation: 51 total rows with `battle_model_scope=xmage_static_self_protection_from_colors_creature_v1`, all `verified` / `auto`.
- Direct SQLite validation: 51 total rows with `battle_model_scope=xmage_static_self_protection_from_colors_creature_v1`, all `verified` / `auto`.
- Queue delta: adapter-required `26311 -> 26279`.
- Post-PG414 exact-scope recheck: `proposal_count=0`.

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg414_static_keyword_protection_colors_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_after_hash_backfill_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg414_static_keyword_protection_colors_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg414_static_keyword_protection_colors_new_server_recheck.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg414_static_keyword_protection_colors_new_server.json`
