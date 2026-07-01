# pg332_xmage_graveyard_exile_wave XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T21:32:53+00:00`
- Selected cards: `["Carrion Beetles", "Crypt Creeper", "Famished Ghoul", "Heap Doll", "Rag Dealer", "Thraben Heretic", "Withered Wretch"]`
- Families: `{"xmage_permanent_simple_activated_graveyard_exile": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
