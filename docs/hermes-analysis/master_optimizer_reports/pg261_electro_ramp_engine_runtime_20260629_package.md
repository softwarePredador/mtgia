# pg261 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes/SQLite, and validated end to end.

- Generated at: `2026-06-29T17:33:24+00:00`
- Selected cards: `["Electro, Assaulting Battery"]`
- Families: `{"ramp_engine": 1}`
- Apply result: backup rows `2`, deprecated shadow rows `2`, upserted rows `1`
- Postcheck: promoted rows `1`, verified/auto rows `1`, Oracle-hash rows `1`
- Sync: PG rows loaded `1`, SQLite rows inserted/updated `3`, canonical snapshot rows `3285`
- Runtime probe: `get_card_effect` resolves `battle_rule_v1:806bda250ae81f2871b2e6a30ab8235b`; instant/sorcery cast adds `R`; creature follow-up adds `0`
- E2E validation: PostgreSQL, SQLite/Hermes, canonical snapshot, runtime lookup all `pass`
- Strategy consistency audit: `23/23` pass
- Deck 611 coherence: Electro is `pass` with one trusted executable rule

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg261_electro_ramp_engine_runtime_20260629_package.md`

Apply gate:

- Already applied under the active XMage -> ManaLoom goal scope with explicit PostgreSQL/sync/commit authorization.
