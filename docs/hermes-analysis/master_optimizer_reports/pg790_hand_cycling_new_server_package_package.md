# pg790_hand_cycling_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-11T21:54:37+00:00`
- Selected cards: `["Angel of the God-Pharaoh", "Barkhide Mauler", "Desert Cerodon", "Granitic Titan", "Hundroog", "Imposing Vantasaur", "Jungle Weaver", "Keeneye Aven", "Lava Serpent", "Lurching Rotbeast", "Macetail Hystrodon", "Moaning Wall", "Pendrell Drake", "Primoc Escapee", "Rampaging Hippo", "Ridge Rannet", "Sandbar Merfolk", "Sandbar Serpent", "Shimmering Barrier", "Shimmerscale Drake", "Striped Riverwinder", "Wasteland Scorpion", "Winged Shepherd", "Yoked Plowbeast"]`
- Families: `{"xmage_creature_hand_cycling": 24}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
