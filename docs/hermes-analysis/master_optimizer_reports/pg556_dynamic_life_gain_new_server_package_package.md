# pg556_dynamic_life_gain_new_server XMage Batch PostgreSQL Package

Status: `generated_package_applied_by_evidence`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.
The package was later applied through the standard precheck/apply/postcheck
workflow. Current apply evidence:
`docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_apply_evidence.md`.

- Generated at: `2026-07-06T06:53:01+00:00`
- Selected cards: `["Blessed Reversal", "Bountiful Harvest", "Festival of Trokin", "Fruition", "Gerrard's Wisdom", "Invigorating Falls", "Joyous Respite", "Landbind Ritual", "Peach Garden Oath", "Presence of the Wise", "Toil to Renown", "Wandering Stream"]`
- Families: `{"xmage_dynamic_life_gain_spell": 12}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_package.md`

Apply gate at generation time:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
