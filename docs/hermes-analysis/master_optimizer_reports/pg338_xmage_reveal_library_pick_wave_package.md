# pg338_xmage_reveal_library_pick_wave XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T23:34:52+00:00`
- Selected cards: `["Commune with the Gods", "Glacial Revelation", "Grisly Salvage", "Kruphix's Insight", "Pieces of the Puzzle", "Scout the Borders"]`
- Families: `{"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
