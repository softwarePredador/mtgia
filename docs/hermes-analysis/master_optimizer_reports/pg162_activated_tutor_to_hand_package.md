# PG162 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T10:10:26+00:00`
- Selected cards: `["Expedition Map", "Moonsilver Key", "Weathered Wayfarer"]`
- Families: `{"creature": 1, "ramp_permanent": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg162_activated_tutor_to_hand_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
