# PG266 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T06:16:24+00:00`
- Selected cards: `["Eight-and-a-Half-Tails"]`
- Families: `{"targeted_protection": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_package.md`

Apply gate:

- Completed sequence: focused runtime tests, precheck, apply, postcheck, PG -> SQLite sync, E2E validation, no-override runtime probe, affected runtime-gap queue rebuild.
- Precheck output: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_precheck.out`; one Oracle-hash-matched card row and zero stale shadow rows identified.
- Apply output: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_apply.out`; backup rows `0`, deprecated shadow rows `0`, upserted rows `1`.
- Postcheck output: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_postcheck.out`; `Eight-and-a-Half-Tails` has one promoted `verified/auto` Oracle-hash row.
- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_sync.json`; selected cards `1`, PG rows loaded `1`, SQLite rows inserted/updated `1`, canonical snapshot rows exported `3284`.
- E2E report: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_e2e_validation.md`; PostgreSQL `1/1`, SQLite `1/1`, canonical snapshot `1/1`, runtime `get_card_effect` `1/1`.
- Runtime probe: `docs/hermes-analysis/master_optimizer_reports/pg266_eight_tails_targeted_protection_20260630_runtime_probe.json`; synced rule responds to targeted commander removal, pays `{2}{W}`, does not tap, changes the source spell to white, and keeps the commander on battlefield.
- Post-sync queue: `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg266_eight_tails.md`; blocked runtime gaps reduced from `25` to `24`.
- Runtime scope: `creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1`.
