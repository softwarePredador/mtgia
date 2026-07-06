# pg558_creature_enters_life_gain_new_server XMage Batch PostgreSQL Package

Status: `generated_package_applied_by_evidence`.

This package was generated from XMage batch proposals. SQL execution is tracked
in
`docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_apply_evidence.md`.

- Generated at: `2026-07-06T07:49:11+00:00`
- Selected cards: `["Ajani's Welcome", "Bogwater Lumaret", "Essence Warden", "Healer of the Pride", "Hinterland Sanctifier", "Impassioned Orator", "Kor Celebrant", "Soul Warden", "Soul's Attendant"]`
- Families: `{"xmage_creature_enters_life_gain_trigger": 9}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_package.md`

Apply gate:

- Explicit apply approval was already provided in the active global goal.
- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused
  tests, package E2E, post-sync queue rebuild, readiness, and alignment audits.
