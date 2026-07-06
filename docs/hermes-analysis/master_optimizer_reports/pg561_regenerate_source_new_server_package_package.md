# pg561_regenerate_source_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T10:52:39+00:00`
- Selected cards: `["Ancient Silverback", "Asphodel Wanderer", "Clay Statue", "Cudgel Troll", "Diabolic Machine", "Drowned", "Drudge Skeletons", "Dutiful Thrull", "Gorilla Chieftain", "Horned Troll", "Metathran Zombie", "Odious Trow", "Pewter Golem", "Phyrexian Monitor", "Restless Dead", "Revered Dead", "Selesnya Sentry", "Skeletal Wurm", "Tangle Hulk", "Tel-Jilad Exile", "Unworthy Dead", "Uthden Troll", "Votary of the Conclave", "Walking Dead"]`
- Families: `{"xmage_permanent_simple_activated_regenerate_source": 24}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
