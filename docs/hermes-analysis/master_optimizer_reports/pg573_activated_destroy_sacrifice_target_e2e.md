# PG573 Activated Destroy Sacrifice Target E2E

- Date: `2026-07-06`
- Database target: `127.0.0.1:15432/halder`
- Scope: `xmage_permanent_simple_activated_destroy_target_v1`
- Cards: `Army Ants`, `Attrition`, `Aura Fracture`, `Elvish Skysweeper`, `Shivan Harvest`, `Stronghold Assassin`

## Runtime and Splitter

- Splitter now accepts exactly one safe `SacrificeTargetCost` on permanent activated destroy effects.
- Runtime pays the activation sacrifice target before destroy resolution and records sacrifice target details in the decision trace.
- Multi-sacrifice and unsupported cost shapes remain blocked by split precheck.

## Tests

- `python3 -m py_compile ...`: pass.
- `test_xmage_authoritative_exact_scope_split.py`: `664` tests passed.
- `test_battle_analyst_v10_3.py`: pass, including `test_attrition_activated_destroy_sacrifices_creature_cost`.

## PostgreSQL and SQLite

- Package: `pg573_activated_destroy_sacrifice_target_package.md`.
- Apply evidence: `6/6` cards promoted, `6/6` `verified/auto`, `6/6` with `oracle_hash`.
- PG -> SQLite sync: loaded `6` PostgreSQL rows and updated `6` SQLite rows.
- Direct PG/SQLite verification confirmed matching scope, sacrifice target, and removal target for all six cards.

## Queue and Readiness

- Post-PG573 queue: `target_identity_count=25375`, `xmage_authoritative_source_count=25061`, `xmage_missing_source_exception_count=314`, `adapter_work_unit_count=11343`.
- Exact split recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.
- Global readiness after hash backfill: `battle_and_oracle_ready=5575`, `battle_family_mapper_required=28298`.

## Gates

- XMage strategy consistency: `pass` (`26/26`).
- PG/Hermes/SQLite contract after hash backfill: `pass` (`51/51`).
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- Server target quality gate: `pass`.

## Required Companion Evidence

- `pg573_activated_destroy_sacrifice_target_apply_evidence.md`
- `pg573_activated_destroy_sacrifice_target_sync_report.json`
- `pg573_oracle_hash_integrity_backfill_new_server.md`
- `pg573_oracle_hash_integrity_backfill_sync_report.json`
- `xmage_authoritative_adaptation_queue_20260706_post_pg573_activated_destroy_sacrifice_target_commander_legal.md`
- `xmage_authoritative_exact_scope_split_20260706_post_pg573_activated_destroy_sacrifice_target_recheck.md`
- `global_card_oracle_battle_readiness_20260706_post_pg573_activated_destroy_sacrifice_target.md`
