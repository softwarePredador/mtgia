# xmage_pg498_static_generic_cost_reduction_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T09:53:00+00:00`
- Selected cards: `["Ballyrush Banneret", "Bosk Banneret", "Dragonlord's Servant", "Dragonspeaker Shaman", "Emerald Medallion", "Etherium Sculptor", "Foundry Inspector", "Goblin Anarchomancer", "Goblin Electromancer", "Jet Medallion", "Kinjalli's Caller", "Knight of the Stampede", "Krosan Drover", "Mana Matrix", "Planar Gate", "Sapphire Medallion", "Starnheim Aspirant", "Stinkdrinker Daredevil", "Stone Calendar", "Thornscape Familiar", "Voyager Quickwelder"]`
- Families: `{"xmage_static_generic_cost_reduction_for_matching_spells": 21}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg498_static_generic_cost_reduction_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
