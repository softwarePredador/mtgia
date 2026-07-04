# pg422 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T18:55:43+00:00`
- Selected cards: `["Amrou Kithkin", "Amrou Seekers", "Arlinn's Wolf", "Barrenton Cragtreads", "Bog Rats", "Deathcult Rogue", "Dread Warlock", "Duskmantle Operative", "Fleet-Footed Monk", "Goldmeadow Dodger", "Kor Castigator", "Mudbrawler Raiders", "Prowling Nightstalker", "Rampart Crawler", "Raven's Run Dragoon", "River Darter", "Rubblebelt Runner", "Sacred Knight", "Skirk Shaman", "Sootwalkers", "Wanderbrine Rootcutters"]`
- Families: `{"xmage_static_filtered_evasion_creature": 21}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg422_xmage_static_filtered_evasion_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
