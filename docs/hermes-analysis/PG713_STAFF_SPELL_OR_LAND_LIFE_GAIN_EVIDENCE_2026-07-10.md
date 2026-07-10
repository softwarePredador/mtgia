# PG713 Staff Spell Or Land Life Gain Evidence - 2026-07-10

## Scope

- Runtime family: `xmage_spell_cast_gain_life_v1`
- Cards promoted by PG713:
  - Staff of the Death Magus
  - Staff of the Flame Magus
  - Staff of the Mind Magus
  - Staff of the Sun Magus
  - Staff of the Wild Magus

## PostgreSQL Apply

- Target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`
- PG713 precheck: 5 target rows, 0 existing executable rule rows.
- PG713 apply: 5 upserted rows, 0 deprecated shadow rows.
- PG713 postcheck: each promoted Staff row has one `verified`/`auto` rule with `oracle_hash`.
- PG713B integrity backfill precheck: 55 safe trusted auto rows with one distinct Oracle hash.
- PG713B apply: 55 rows updated.
- PG713B postcheck: 55/55 backup rows have `oracle_hash`; remaining trusted auto missing hash rows: 0.

## Sync

- Battle rule PG -> SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg713b_oracle_hash_integrity_backfill_new_server_pg_to_sqlite_sync.json`
- Metadata PG -> Hermes sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg713b_oracle_hash_integrity_backfill_new_server_metadata_sync.json`
- Battle sync result: 6,229 PG rows loaded, 6,224 SQLite rows inserted or updated.
- Metadata sync result: 7,324 PostgreSQL cards matched; deck card backfill matched 2,699/2,699.

## Runtime And Tests

- E2E report:
  `docs/hermes-analysis/master_optimizer_reports/pg713_staff_spell_or_land_life_gain_new_server_e2e_validation_post_pg713b.md`
- E2E status: pass.
- E2E coverage: PostgreSQL source of truth, SQLite cache, canonical fallback snapshot, runtime `get_card_effect`, and battle execution.
- Battle execution: 5 scenarios, 20 events.
- Positive evidence: each Staff gains 1 life on matching spell cast and 1 life on matching basic land subtype entering.
- Negative evidence: nonmatching land scenario is generated and validated by the E2E runner.
- Focused unit tests: `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`
- Unit test result: 937 tests passed.
- Compile check: `py_compile` passed for the changed parser, runtime, package builder, and E2E runner scripts.

## Readiness And Queue

- Readiness report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260710_post_pg713b_oracle_hash_integrity_backfill_new_server.md`
- All known cards: 34,331.
- `battle_and_oracle_ready`: 6,278.
- `battle_family_mapper_required`: 27,598.
- `trusted_rule_oracle_hash_backfill`: absent after PG713B.
- XMage queue report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260710_post_pg713b_oracle_hash_integrity_backfill_new_server_commander_legal.md`
- Commander-legal target identities: 24,675.
- XMage authoritative source identities: 24,362.
- Missing XMage source exceptions: 313.
- Parser gaps: 0.
- Adapter-required identities: 24,362.
- Exact split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260710_post_pg713b_oracle_hash_integrity_backfill_new_server_recheck.md`
- Exact split recheck result: `proposal_count=0`, proving the Staff subpattern is no longer pending.

## Alignment Gates

- `pg_hermes_sqlite_contract_audit`: pass, 51/51 checks.
- `xmage_strategy_consistency_audit`: pass, 26/26 checks.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `./scripts/quality_gate.sh server-target`: pass.
