# PG325 XMage Batch PostgreSQL Package

Status: `applied_pg325_with_evidence`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the package was later applied through the documented
precheck/apply/postcheck/sync flow.

- Generated at: `2026-07-01T19:45:11+00:00`
- Selected cards: `["Flood of Recollection", "Restock", "Treasured Find"]`
- Families: `{"xmage_graveyard_to_hand_exile_self_spell": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_package.md`
- apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_pg_apply_evidence.md`

Apply history:

- PostgreSQL precheck found `3/3` target card rows.
- PostgreSQL apply promoted `3` verified/auto executable rows and deprecated
  `0` stale shadow rows.
- PostgreSQL postcheck, PG -> Hermes/SQLite sync, focused tests, and E2E
  validation are recorded in the apply evidence artifact.
