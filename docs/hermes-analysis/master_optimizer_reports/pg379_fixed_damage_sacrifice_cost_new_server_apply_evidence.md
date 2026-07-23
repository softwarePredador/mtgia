# PG379 Fixed Damage Sacrifice Cost New Server Apply Evidence

Status: `applied_synced_validated`

Database target: new EasyPanel PostgreSQL through the local new-server tunnel,
validated by sync output as `database_target=127.0.0.1:15432/halder`.

## Scope

PG379 promoted `5` fixed direct-damage spells whose local XMage source uses a
pure `DamageTargetEffect` plus exact `SacrificeTargetCost` that ManaLoom can pay
deterministically:

- `Collateral Damage` - `3` damage to any target, additional cost
  `sacrifice_creature`
- `Fiery Conclusion` - `5` damage to target creature, additional cost
  `sacrifice_creature`
- `Magma Rift` - `5` damage to target creature, additional cost
  `sacrifice_land`
- `Reckless Abandon` - `4` damage to any target, additional cost
  `sacrifice_creature`
- `Shard Volley` - `3` damage to any target, additional cost `sacrifice_land`

Unsupported neighboring additional costs remain blocked: mixed sacrifice filters
such as creature-or-enchantment, creature-or-planeswalker, artifact-or-creature,
permanent, subtype-only, discard/random costs, and dynamic damage amounts.

## Implementation

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  now extracts supported fixed direct-damage spell additional costs for
  `sacrifice_creature` and `sacrifice_land` and blocks unsupported sacrifice
  target filters before package generation.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` now
  checks and pays `requires_sacrifice_land` in the generic spell additional-cost
  path, emits `additional_cost_paid`, and marks paid additional costs to avoid
  double payment on stack resolution.

## Validation

- Splitter tests:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  -> `305` tests OK.
- Exact runtime tests:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  -> `180` tests OK.
- Syntax:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  -> OK.
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_e2e.md`
  -> `status=pass`.

## PostgreSQL Package

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_precheck_new_server.txt`
  -> `5/5` target card rows, `0` existing exact rule rows, `0` shadow rows to
  deprecate.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_apply_new_server.txt`
  -> `upserted_rows=5`, `deprecated_shadow_rows=0`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_postcheck_new_server.txt`
  -> `5/5` promoted rows verified as `verified`, `auto`, and `oracle_hash`
  backed.
- Rollback package:
  `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_package_rollback.sql`.

## Sync And Queue

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg379_fixed_damage_sacrifice_cost_new_server.json`
  loaded `5` PostgreSQL rows, updated `5` SQLite rows, and exported `5084`
  canonical snapshot rows.
- Post-PG379 queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_commander_legal.md`
  reports `target_identity_count=26974`,
  `xmage_authoritative_source_count=26660`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26660`.
- Supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_supported_recheck.md`
  reports `proposal_count=0` over `7731` considered supported rows, so PG380
  must add another exact mapper/runtime subpattern before package generation.

## Audits

- `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
  -> pass, `26/26`.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  -> pass.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  -> pass.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  -> pass with `49` pass and `1` inherited warning
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG379).
- Final docs-after-update rerun:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_docs_after_update.md`
  -> pass with `49` pass and `1` inherited warning.
