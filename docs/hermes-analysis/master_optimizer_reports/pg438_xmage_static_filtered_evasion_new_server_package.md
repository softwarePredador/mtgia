# pg438 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:59:07+00:00`
- Selected cards: `["Amrou Kithkin", "Amrou Seekers", "Arlinn's Wolf", "Barrenton Cragtreads", "Bog Rats", "Deathcult Rogue", "Dread Warlock", "Duskmantle Operative", "Fleet-Footed Monk", "Goldmeadow Dodger", "Kor Castigator", "Mudbrawler Raiders", "Prowling Nightstalker", "Rampart Crawler", "Raven's Run Dragoon", "River Darter", "Rubblebelt Runner", "Sacred Knight", "Skirk Shaman", "Sootwalkers", "Wanderbrine Rootcutters"]`
- Families: `{"xmage_static_filtered_evasion_creature": 21}`

Files:

- precheck: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg438_xmage_static_filtered_evasion_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
