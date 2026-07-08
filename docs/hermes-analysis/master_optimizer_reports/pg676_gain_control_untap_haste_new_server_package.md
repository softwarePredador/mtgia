# PG676 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T23:07:49+00:00`
- Selected cards: `["Act of Treason", "Blind with Anger", "Claim the Firstborn", "Hijack", "Metallic Mastery", "Threaten", "Wrangle"]`
- Families: `{"xmage_gain_control_untap_haste_until_eot_spell": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg676_gain_control_untap_haste_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
