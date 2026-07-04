# pg428 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T20:12:00+00:00`
- Selected cards: `["Baneslayer Angel", "Dragonstalker", "Elite Inquisitor", "Grave Bramble", "Kitsune Riftwalker", "Midnight Duelist", "Nath's Buffoon", "Shoreline Raider", "Tel-Jilad Archers"]`
- Families: `{"xmage_static_self_protection_from_card_types_creature": 1, "xmage_static_self_protection_from_subtypes_creature": 8}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg428_xmage_static_protection_subtypes_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
