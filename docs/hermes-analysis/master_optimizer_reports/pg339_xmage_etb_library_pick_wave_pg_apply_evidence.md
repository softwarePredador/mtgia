# PG339 XMage ETB Library Pick Wave PostgreSQL Apply Evidence

Status: `applied`.

Generated UTC: `2026-07-01T23:47:00Z`.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_rollback.sql`

Precheck:

- Target rows found: `4/4`.
- Expected rows already present: `0/4`.
- Stale shadow rows scheduled for deprecation: `0`.

Apply:

- Deprecated shadow rows: `0`.
- Upserted rows: `4`.

Postcheck:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows |
| --- | ---: | ---: | ---: |
| `Organ Hoarder` | 1 | 1 | 1 |
| `Sibsig Appraiser` | 1 | 1 | 1 |
| `Sultai Soothsayer` | 1 | 1 | 1 |
| `Tower Geist` | 1 | 1 | 1 |

Backup table rows: `0`.

Post-apply sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_pg_to_sqlite_sync.json`.
- PostgreSQL rows loaded: `7261`.
- SQLite rows inserted/updated from PostgreSQL: `7055`.
- Canonical snapshot rows exported: `4849`.

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_e2e_validation.md`.
- PostgreSQL source of truth: `4/4`.
- SQLite Hermes cache: `4/4`.
- Canonical snapshot fallback: `4/4`.
- Runtime `get_card_effect`: `4/4`.
