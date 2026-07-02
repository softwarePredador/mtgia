# PG367 Return-All Graveyard Battlefield Wave Apply Evidence

Status: `applied_verified_synced`.

Applied package:

- manifest: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_manifest.json`
- precheck: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_postcheck.sql`

Cards promoted:

- `Raise the Past`

PostgreSQL evidence:

- precheck matched `1` target card row and `0` existing expected rule rows.
- precheck found `0` nonmatching shadow rows.
- apply upserted `1` row and deprecated `0` shadow rows.
- postcheck verified `1/1` promoted row, `1/1` verified/auto row, and `1/1`
  matching Oracle hash row.

Sync evidence:

- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_pg_to_sqlite_sync.json`
- metadata sync report: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_pg_metadata_sync.json`
- PG rows loaded: `7400`
- SQLite rows inserted/updated: `7195`
- canonical snapshot rows exported: `4973`
- metadata sync matched `5981` PostgreSQL card rows and `5908` SQLite alias rows.
- deck_cards backfill matched `2699/2699` rows and updated `105` card_id rows.

Validation evidence:

- focused splitter/runtime tests: `429` tests passed.
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_e2e_validation.md`
- post-PG367 queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg367_return_all_graveyard_battlefield_wave_commander_legal.md`
- post-PG367 supported recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg367_supported_recheck.md`
- XMage strategy audit: `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
- operational surface audit: `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
- legacy contamination audit: `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
- PG/Hermes/SQLite contract audit: `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave.md`

Current queue after apply:

- target battle-gap identities: `27091`
- XMage authoritative source resolved: `26777`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26777`
- top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1`
  with `1833` identities.

Blocked neighbors:

- `Replenish` remains blocked as
  `recursion_battlefield_all_oracle_not_supported` because current Oracle text
  includes Aura attachment behavior that the simple return-all battlefield
  runtime does not model.
- `Fix What's Broken` remains blocked by additional cost and exact `mana value
  X` matching, which is not equivalent to the existing X-or-less runtime.
