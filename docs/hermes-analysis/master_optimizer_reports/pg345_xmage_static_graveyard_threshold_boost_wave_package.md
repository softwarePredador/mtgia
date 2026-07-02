# PG345 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T02:15:23+00:00`
- Selected cards: `["Anurid Barkripper", "Basking Capybara", "Frilled Cave-Wurm", "Krosan Beast", "Metamorphic Wurm", "Seton's Scout", "Springing Tiger"]`
- Families: `{"xmage_static_source_boost_if_graveyard_threshold": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
