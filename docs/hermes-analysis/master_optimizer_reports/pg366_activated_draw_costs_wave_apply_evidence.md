# PG366 Activated Draw Costs Wave Apply Evidence

Status: `applied_verified_synced`.

Applied package:

- manifest: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_manifest.json`
- precheck: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_postcheck.sql`

Cards promoted:

- `Akki Scrapchomper`
- `Book of Rass`
- `Carnage Altar`
- `Destructive Digger`
- `Dockside Chef`
- `Greed`
- `Hardened Tactician`
- `Infernal Tribute`
- `Phyrexian Vault`
- `Slagdrill Scrapper`
- `Soulreaper of Mogis`
- `Thallid Soothsayer`

PostgreSQL evidence:

- precheck matched `12` target card rows and `0` existing expected rule rows.
- precheck found `2` nonmatching shadow rows for `Greed`.
- apply upserted `12` rows and deprecated `2` shadow rows.
- postcheck verified `1` promoted verified/auto Oracle-hash row for each promoted card.

Sync evidence:

- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_pg_to_sqlite_sync.json`
- metadata sync report: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_pg_metadata_sync.json`
- PG rows loaded: `7399`
- SQLite rows inserted/updated: `7194`
- canonical snapshot rows exported: `4972`
- metadata sync matched `5980` PostgreSQL card rows and `5907` SQLite alias rows.
- deck_cards backfill matched `2699/2699` rows and updated `95` card_id rows.

Validation evidence:

- focused splitter/runtime tests: `425` tests passed.
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_e2e_validation.md`
- post-PG366 queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.md`
- post-PG366 supported recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg366_supported_recheck.md`

Current queue after apply:

- target battle-gap identities: `27092`
- XMage authoritative source resolved: `26778`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26778`
- top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1834` identities.
