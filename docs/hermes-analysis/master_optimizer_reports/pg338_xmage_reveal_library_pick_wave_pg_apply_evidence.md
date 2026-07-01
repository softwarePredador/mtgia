# PG338 XMage Reveal Library Pick Wave PostgreSQL Apply Evidence

Status: `applied`.

Generated UTC: `2026-07-01T23:35:00Z`.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_rollback.sql`

Precheck:

- Target rows found: `6/6`.
- Expected rows already present: `0/6`.
- Existing same-key rule rows: `2`, both for `Grisly Salvage`.
- Stale shadow rows scheduled for deprecation: `2`.

Apply:

- Deprecated shadow rows: `2`.
- Upserted rows: `6`.

Postcheck:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows |
| --- | ---: | ---: | ---: |
| `Commune with the Gods` | 1 | 1 | 1 |
| `Glacial Revelation` | 1 | 1 | 1 |
| `Grisly Salvage` | 1 | 1 | 1 |
| `Kruphix's Insight` | 1 | 1 | 1 |
| `Pieces of the Puzzle` | 1 | 1 | 1 |
| `Scout the Borders` | 1 | 1 | 1 |

Backup table rows: `2`.

Post-apply sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_pg_to_sqlite_sync.json`.
- PostgreSQL rows loaded: `7257`.
- SQLite rows inserted/updated from PostgreSQL: `7051`.
- Canonical snapshot rows exported: `4845`.

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_e2e_validation.md`.
- PostgreSQL source of truth: `6/6`.
- SQLite Hermes cache: `6/6`.
- Canonical snapshot fallback: `6/6`.
- Runtime `get_card_effect`: `6/6`.
