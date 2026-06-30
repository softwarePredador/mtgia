# PG265 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T05:58:46+00:00`
- Selected cards: `["Lens of Clarity"]`
- Families: `{"topdeck_play": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_package.md`

Apply gate:

- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused runtime tests, E2E validation, runtime probe, affected runtime-gap queue rebuild.
- Precheck output: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_precheck.out`; one Oracle-hash-matched card row and two stale shadow rows identified.
- Apply output: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_apply.out`; backup rows `2`, deprecated shadow rows `2`, upserted rows `1`.
- Postcheck output: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_postcheck.out`; `Lens of Clarity` has one promoted `verified/auto` Oracle-hash row.
- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_sync.json`.
- E2E report: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_e2e_validation.md`; PostgreSQL `1/1`, SQLite `1/1`, canonical snapshot `1/1`, runtime `get_card_effect` `1/1`.
- Runtime probe: `docs/hermes-analysis/master_optimizer_reports/pg265_lens_clarity_visibility_20260630_runtime_probe.json`; resolves as visibility-only `topdeck_play`, with no land-play or free-cast permission.
- Post-sync queue: `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg265_lens.md`; blocked runtime gaps reduced from `26` to `25`.
- Runtime scope: `look_top_library_any_time_and_opponent_face_down_creatures_v1`.
