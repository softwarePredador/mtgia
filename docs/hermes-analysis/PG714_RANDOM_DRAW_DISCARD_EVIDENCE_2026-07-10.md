# PG714 Random Draw Discard Evidence - 2026-07-10

## Scope

- Runtime family: `xmage_fixed_draw_discard_spell_v1`
- Cards promoted by PG714:
  - Control of the Court
  - Goblin Lore

## Parser Correction

- `fixed_draw_discard_spell_from_oracle` now parses `discard ... at random`.
- Exact-scope comparison now requires `discard_random` to match between Oracle and XMage.
- A mismatch where XMage has `DiscardControllerEffect(..., true)` but Oracle lacks `at random` is blocked with `draw_discard_spell_source_oracle_mismatch`.

## PostgreSQL Apply

- Target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.
- PG714 precheck: 2 target card rows, 0 existing rule rows, 0 expected rows before apply, 0 shadow rows to deprecate.
- PG714 apply: 2 upserted rows, 0 deprecated shadow rows.
- PG714 postcheck: both cards have one `verified`/`auto` row with the expected `oracle_hash`.
- Trusted auto missing `oracle_hash` after apply: 0.

## Sync And E2E

- Battle rule PG -> SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg714_random_draw_discard_new_server_pg_to_sqlite_sync.json`
- Metadata PG -> Hermes sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg714_random_draw_discard_new_server_metadata_sync.json`
- Battle sync result: 6,231 PG rows loaded, 6,226 SQLite rows inserted or updated, 6,182 fallback snapshot rows exported.
- E2E report:
  `docs/hermes-analysis/master_optimizer_reports/pg714_random_draw_discard_new_server_e2e_validation.md`
- E2E status: pass.
- E2E coverage: PostgreSQL source of truth, SQLite cache, canonical fallback snapshot, runtime `get_card_effect`, and battle execution.
- Battle execution: 2 scenarios, 4 events.
- Execution evidence: both cards drew 4, discarded 3, used `draw_then_discard`, and preserved `discard_random=true`.

## Readiness And Queue

- Readiness report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260710_post_pg714_random_draw_discard_new_server.md`
- `snapshot_has_verified_rule`: 6,305.
- `battle_and_oracle_ready`: 6,280.
- `battle_family_mapper_required`: 27,596.
- XMage queue report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260710_post_pg714_random_draw_discard_new_server_commander_legal.md`
- Commander-legal target identities: 24,673.
- XMage authoritative source identities: 24,360.
- Missing XMage source exceptions: 313.
- Parser gaps: 0.
- Adapter-required identities: 24,360.
- Exact split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260710_post_pg714_random_draw_discard_new_server_recheck.md`
- Exact split recheck result: `proposal_count=0`, proving the random draw/discard subpattern is no longer pending.

## Validation

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: 938 tests passed.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`: 232 tests passed.
- `py_compile` passed for the changed parser, package builder, E2E validator, and battle runtime scripts.
- `pg_hermes_sqlite_contract_audit`: pass, 51/51 checks.
- `xmage_strategy_consistency_audit`: pass, 26/26 checks.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `./scripts/quality_gate.sh server-target`: pass.
