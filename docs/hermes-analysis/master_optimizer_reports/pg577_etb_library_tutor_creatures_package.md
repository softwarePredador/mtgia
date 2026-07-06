# pg577 XMage Batch PostgreSQL Package

Status: `applied_pg577`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T22:24:20+00:00`
- Selected cards: `["Boggart Harbinger", "Campus Guide", "Compass Gnome", "Faerie Harbinger", "Flamekin Harbinger", "Giant Harbinger", "Giant Ladybug", "Kithkin Harbinger", "Loam Larva", "Scampering Surveyor", "Spider-Bot"]`
- Families: `{"xmage_creature_etb_library_search_to_battlefield": 1, "xmage_creature_etb_library_search_to_top": 10}`

Files:

- precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package_precheck.sql`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package_apply.sql`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package_rollback.sql`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package_postcheck.sql`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package_manifest.json`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg577_etb_library_tutor_creatures_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
