# pg563 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T11:24:24+00:00`
- Selected cards: `["Carnassid", "Carrion Wall", "Charging Troll", "Drudge Reavers", "Fog of Gnats", "Ghost Ship", "Lim-D\u00fbl's High Guard", "Living Airship", "Living Wall", "Malach of the Dawn", "Manor Skeleton", "Ranger en-Vec", "Sanguine Guard", "Screeching Harpy", "Tattered Drake", "Trestle Troll", "Wall of Bone", "Wall of Brambles", "Wall of Pine Needles", "Will-o'-the-Wisp", "Wolfir Avenger", "Yavimaya Gnats"]`
- Families: `{"xmage_permanent_simple_activated_regenerate_source": 22}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
