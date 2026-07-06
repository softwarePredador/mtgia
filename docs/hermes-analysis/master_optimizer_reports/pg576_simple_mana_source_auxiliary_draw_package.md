# pg576 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T21:57:33+00:00`
- Selected cards: `["All-Fates Scroll"]`
- Families: `{"xmage_simple_mana_source_with_unmodeled_auxiliary": 1}`

Files:

- precheck: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_precheck.sql`
- apply: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_apply.sql`
- rollback: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_rollback.sql`
- postcheck: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_postcheck.sql`
- manifest: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_manifest.json`
- package: `/tmp/pg576_simple_mana_source_auxiliary_draw_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
