# PG143 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T04:57:08+00:00`
- Selected cards: `["Tataru Taru"]`
- Families: `{"ramp_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg143_current_replay_tataru_taru_off_turn_treasure_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
