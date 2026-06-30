# pg267_neheb_postcombat_mana_20260630 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T06:30:28+00:00`
- Selected cards: `["Neheb, the Eternal"]`
- Families: `{"ramp_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_package.md`

Apply gate:

- Completed sequence: focused runtime tests, current replay/deck pipeline rebuild,
  precheck, apply, postcheck, PG -> SQLite sync, E2E validation, no-override
  runtime probe, affected runtime-gap queue rebuild, focus package refresh.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_precheck.out`;
  one Oracle-hash-matched card row, two existing rule rows, zero expected rows
  before apply, and two stale shadow rows identified.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_apply.out`;
  backup rows `2`, deprecated shadow rows `2`, upserted rows `1`.
- Postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_postcheck.out`;
  `Neheb, the Eternal` has one promoted `verified/auto` Oracle-hash row.
- PG -> SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_sync.json`;
  selected cards `1`, PG rows loaded `1`, SQLite rows inserted/updated `3`,
  canonical snapshot rows exported `3284`.
- E2E report:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_e2e_validation.md`;
  PostgreSQL `1/1`, SQLite `1/1`, canonical snapshot `1/1`, runtime
  `get_card_effect` `1/1`.
- Runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_runtime_probe.json`;
  synced no-override rule enters the stack at `beginning_postcombat_main` and
  adds `5` red mana for `5` life lost by opponents this turn.
- Post-sync queue:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg267_neheb.md`;
  blocked runtime gaps reduced from `24` to `23`.
- Runtime scope: `postcombat_main_add_red_for_opponents_life_lost_this_turn_v1`.
