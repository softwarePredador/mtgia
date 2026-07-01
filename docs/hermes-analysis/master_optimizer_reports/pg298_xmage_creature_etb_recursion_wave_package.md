# PG298 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T11:00:53+00:00`
- Selected cards: `["Anarchist", "Archaeomender", "Ardent Elementalist", "Auramancer", "Baloth Null", "Cartographer", "Elvish Regrower", "Golgari Findbroker", "Gravedigger", "Izzet Chronarch", "Monk Idealist", "Moriok Scavenger", "Pharika's Mender", "Restoration Gearsmith", "Salvager of Secrets", "Scrivener", "Stoic Builder", "Tilling Treefolk", "Treasure Hunter", "Trusty Packbeast", "Warden of the Eye", "Zealous Lorecaster"]`
- Families: `{"xmage_creature_etb_graveyard_to_hand": 22}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_package.md`

Apply/sync/E2E result:

- PostgreSQL precheck: `22/22` target rows found, `0` expected rows already
  present, and `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `22/22` promoted rows, `22/22` verified/auto,
  `22/22` matching Oracle hash, and `0` backup rows.
- PG -> Hermes/SQLite sync: `6720` PostgreSQL rows loaded, `6491` SQLite rows
  inserted/updated, and `4333` canonical snapshot rows exported.
- E2E validation: PostgreSQL `22/22`, SQLite `22/22`, canonical snapshot
  `22/22`, and runtime `get_card_effect` `22/22`.
