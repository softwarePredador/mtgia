# PG555 Independent Mana Auxiliary New Server Apply Evidence

Generated UTC: `2026-07-06`

## Scope

PG555 promoted the exact `xmage_simple_mana_source_with_unmodeled_auxiliary`
subpattern into executable ManaLoom battle rules for permanents whose XMage
source has a direct independent safe mana ability plus a separate auxiliary
activated ability that remains deliberately unmodeled.

Selected cards:

- `Atzocan Seer`
- `Blitzball`
- `Infernal Idol`
- `Sunset Strikemaster`
- `Unstable Obelisk`

Runtime boundary:

- executes only the direct independent mana source ability;
- records the auxiliary ability as unmodeled metadata;
- does not promote cases where sacrifice/draw/destruction belongs to the same
  mana ability, such as Astrolabe/Sextant-style patterns.

## Files

- proposal report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg555_independent_mana_aux_candidate.md`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_package_package.md`
- precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_package_precheck.sql`
- apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_package_apply.sql`
- rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_package_rollback.sql`
- postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_package_postcheck.sql`
- sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_sync_report.json`
- package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg555_independent_mana_aux_new_server_e2e.md`
- post-sync queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg555_independent_mana_aux_new_server.md`
- final exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg555_independent_mana_aux_new_server_final.md`
- readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg555_independent_mana_aux_new_server.md`
- final audits:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260706_post_pg555_independent_mana_aux_new_server_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260706_post_pg555_independent_mana_aux_new_server_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260706_post_pg555_independent_mana_aux_new_server_final.md`

## PostgreSQL Apply Evidence

Database target: `143.198.230.247:5433/halder`

Precheck:

- target card rows: `5/5`
- existing matching rule rows before apply: `0`
- expected rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- deprecated shadow rows: `0`
- upserted rows: `5`

Postcheck:

- promoted rule rows: `5/5`
- promoted verified/auto rows: `5/5`
- promoted Oracle hash rows: `5/5`
- backup rows: `0`

PG -> SQLite/Hermes sync:

- PostgreSQL rows loaded: `8953`
- SQLite rows inserted or updated: `8717`
- canonical snapshot rows exported: `6455`

## Validation

Code/runtime tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  passed `621` tests.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
  passed `54` tests.

Package E2E:

- status: `pass`
- scenarios: `5`
- battle events: `5`
- all selected cards refreshed through PostgreSQL source, Hermes SQLite cache,
  canonical snapshot fallback, runtime `get_card_effect`, and battle execution.

Final exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7236`

Final audits:

- XMage strategy consistency: `pass`
- PostgreSQL/Hermes/SQLite contract: `pass`
- operational surface alignment: `pass`
- legacy contamination: `pass`

## Queue Impact

Pre-cycle queue:

- `target_identity_count=25543`
- `xmage_authoritative_source_count=25229`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25229`
- `adapter_work_unit_count=11354`

Post-cycle queue:

- `target_identity_count=25538`
- `xmage_authoritative_source_count=25224`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25224`
- `adapter_work_unit_count=11354`

Interpretation:

- the cycle removed `5` Commander-legal battle-gap identities from the global
  XMage-authoritative queue;
- artifact mana-source work units dropped from `151` to `148`;
- creature mana-source work units dropped from `286` to `284`;
- the exact subpattern is exhausted and should not be selected again unless the
  mapper/runtime boundary changes.
