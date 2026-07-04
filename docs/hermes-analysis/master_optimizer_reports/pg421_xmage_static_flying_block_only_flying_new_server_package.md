# pg421 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T18:38:06+00:00`
- Selected cards: `["Belbe's Percher", "Cloud Djinn", "Cloud Dragon", "Cloud Elemental", "Cloud Pirates", "Cloud Spirit", "Cloud Sprite", "Hoverguard Observer", "Long-Finned Skywhale", "Rishadan Airship", "Scrapskin Drake", "Skywinder Drake", "Stratozeppelid", "Stronghold Zeppelin", "Tattered Haunter", "Vaporkin", "Wanderlight Spirit", "Welkin Tern"]`
- Families: `{"xmage_static_flying_can_block_only_flying_creature": 18}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg421_xmage_static_flying_block_only_flying_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
