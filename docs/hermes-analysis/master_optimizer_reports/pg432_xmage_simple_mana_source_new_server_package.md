# pg432 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:08:47+00:00`
- Selected cards: `["Agent of Stromgald", "Bog Initiate", "Charcoal Diamond", "Darksteel Ingot", "Deathbloom Gardener", "Druid of the Anima", "Fire Diamond", "Fire Sprites", "Hedron Crawler", "Helionaut", "Leyline Prowler", "Llanowar Envoy", "Lotus Guardian", "Maraleaf Pixie", "Marble Diamond", "Moss Diamond", "Nomadic Elf", "Noxious Newt", "Obelisk of Bant", "Obelisk of Esper", "Obelisk of Grixis", "Obelisk of Jund", "Obelisk of Naya", "Orochi Leafcaller", "Prismite", "Signpost Scarecrow", "Sky Diamond", "Steward of Valeron", "Sylvan Caryatid", "Timeless Lotus", "Urborg Elf", "Vine Trellis", "Viridian Acolyte", "Warden of Geometries"]`
- Families: `{"xmage_simple_mana_source_permanent": 34}`

Files:

- precheck: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg432_xmage_simple_mana_source_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
