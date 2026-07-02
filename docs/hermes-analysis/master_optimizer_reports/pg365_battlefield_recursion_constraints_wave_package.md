# PG365 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T08:42:52+00:00`
- Selected cards: `["Othelm, Sigardian Outcast", "Ramosian Revivalist", "Rise to Glory", "Squirming Emergence"]`
- Families: `{"xmage_graveyard_to_battlefield_choose_one_or_both_spell": 1, "xmage_graveyard_to_battlefield_spell": 1, "xmage_permanent_simple_activated_graveyard_to_battlefield": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
