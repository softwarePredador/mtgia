# PG305 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to the local Hermes SQLite/cache snapshot, and validated end to end.

- Generated at: `2026-07-01T12:45:29+00:00`
- Selected cards: `["Awaken the Bear", "Bestow Greatness", "Colossal Might", "Crash the Ramparts", "Fanatical Fever", "Fanatical Strength", "Fit of Rage", "Flowstone Strike", "Gift of Strength", "Give In to Violence", "Interjection", "Larger Than Life", "Lash of Thorns", "Mighty Leap", "Precise Strike", "Rise to the Challenge", "Rush of Adrenaline", "Sangrite Surge", "Screaming Fury", "Seize the Initiative", "Skillful Lunge", "Staggering Size", "Tread Upon", "Uncaged Fury", "Uncanny Speed", "Unnatural Predation", "Zealous Strike"]`
- Families: `{"xmage_boost_keyword_target_creature_until_eot_spell": 27}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_package.md`
- PG apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_pg_apply_evidence.md`
- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_e2e_validation.md`

Apply gate:

- Applied after explicit global PG authorization in the launch goal workflow.
- Evidence: 27/27 target cards promoted in PostgreSQL with
  `review_status=verified`, `execution_status=auto`, oracle hashes present and
  no failed cards.
- Follow-up sequence completed: PG -> SQLite sync, canonical snapshot export,
  focused/family tests, runtime get-card-effect validation, and operational
  consistency audits.
