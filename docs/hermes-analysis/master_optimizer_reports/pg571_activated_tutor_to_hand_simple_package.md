# pg571 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T20:39:07+00:00`
- Selected cards: `["Captain Sisay", "Dragonstorm Forecaster", "Journeyer's Kite", "Planar Portal"]`
- Families: `{"xmage_permanent_simple_activated_library_search_to_hand": 4}`

Files:

- precheck: `/tmp/pg571_activated_tutor_to_hand_simple_package_precheck.sql`
- apply: `/tmp/pg571_activated_tutor_to_hand_simple_package_apply.sql`
- rollback: `/tmp/pg571_activated_tutor_to_hand_simple_package_rollback.sql`
- postcheck: `/tmp/pg571_activated_tutor_to_hand_simple_package_postcheck.sql`
- manifest: `/tmp/pg571_activated_tutor_to_hand_simple_package_manifest.json`
- package: `/tmp/pg571_activated_tutor_to_hand_simple_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
