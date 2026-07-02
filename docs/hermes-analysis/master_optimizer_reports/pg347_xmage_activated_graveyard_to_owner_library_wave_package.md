# PG347 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T02:58:54+00:00`
- Selected cards: `["Cogwork Archivist", "Jade-Cast Sentinel", "Junktroller", "Phyrexian Archivist", "Reito Lantern"]`
- Families: `{"xmage_permanent_simple_activated_graveyard_to_library": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
