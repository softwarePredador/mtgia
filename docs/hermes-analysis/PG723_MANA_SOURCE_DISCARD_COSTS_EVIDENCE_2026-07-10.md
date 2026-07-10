# PG723 Mana Source Discard Costs Evidence - 2026-07-10

Status: `closed`

Database target: `127.0.0.1:15432/halder` through
`./server/bin/with_new_server_pg.sh`.

## Scope

PG723 closes the XMage -> ManaLoom exact-scope lane for simple activated mana
sources whose executable mana ability either:

- has an actual discard cost on the mana ability; or
- has a safe independent mana ability while other auxiliary abilities remain
  deliberately partial/unmodeled.

Promoted cards:

- `Bog Witch`
- `Bramble Familiar // Fetch Quest`
- `Izzet Keyrune`
- `Network Terminal`
- `Skirge Familiar`
- `Starting Column`

`Face of Fear` was found by the split as a separate safe candidate in
`xmage_permanent_simple_activated_self_keyword_until_eot_v1`; it was not
included in PG723 because this package is only the mana-source discard-cost
lane.

## Runtime And Mapper Changes

- `xmage_authoritative_exact_scope_split.py`
  - Parses `discard a card` as a simple mana-source activation cost.
  - Accepts `new DiscardCardCost(false)` from XMage as chosen discard.
  - Avoids merging multiline Oracle text, preventing Bramble Familiar from
    reading `{1}{G}` on Fetch Quest as part of the mana ability.
  - Propagates activation cost fields into all simple mana-source branches.
  - Allows safe partial mana-only mapping when unrelated auxiliary discard text
    belongs to a separate ability.
- `battle_analyst_v9.py`
  - Pays mana-source discard activation costs before adding mana.
  - Emits `mana_source_activation_discard_cost_paid`.
  - Skips activation with explicit reason when the controller lacks hand cards.
- `xmage_batch_pg_package_builder.py`
  - Adds E2E controller-hand fixtures and expected discard assertions for
    mana-source packages.
- `battle_package_end_to_end_validation.py`
  - Seeds controller hand from package scenarios.
  - Verifies discard-payment replay events during mana-source refresh.

## PostgreSQL Package

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_package_rollback.sql`

Precheck:

- target cards found by Oracle hash: `6/6`
- existing matching rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- deprecated shadow rows: `0`
- upserted rows: `6`
- transaction: `COMMIT`

Postcheck:

- promoted rule rows: `6/6`
- promoted `verified/auto` rows: `6/6`
- promoted matching `oracle_hash` rows: `6/6`
- backup rows: `0`

## Sync And E2E

PG -> SQLite rule sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_pg_to_sqlite_sync.json`
- PG rows loaded: `6`
- SQLite inserted/updated: `6`
- canonical snapshot rows exported: `7316`

PG metadata -> Hermes sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8263`
- SQLite cache alias rows: `8200`
- deck card backfill: `2699/2699`
- card-id updates applied: `108`
- unresolved metadata aliases: `1` (`Surgical Suite/Hospital Room`), unrelated
  to PG723 and covered by the passing contract audit.

E2E validation:

- report: `docs/hermes-analysis/master_optimizer_reports/pg723_mana_source_discard_costs_new_server_e2e_validation.md`
- status: `pass`
- PostgreSQL source-of-truth rows: `6`
- SQLite/Hermes rows: `6`
- canonical snapshot cards: `6`
- runtime `get_card_effect` cards: `6`
- battle execution scenarios: `6`
- replay events: `9`

Battle evidence:

- `Bog Witch`: produced `3` mana, tapped, paid `1` discard cost.
- `Skirge Familiar`: produced `1` black mana, did not tap, paid `1` discard
  cost.
- `Bramble Familiar // Fetch Quest`: produced only `1` green mana from the
  independent mana ability; Fetch Quest remains unmodeled auxiliary behavior.
- `Izzet Keyrune`, `Network Terminal`, and `Starting Column`: produced one
  conditional mana and retained partial mana-only modeling for auxiliary text.

## Tests

Focused parser/runtime tests:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m py_compile xmage_authoritative_exact_scope_split.py battle_analyst_v9.py xmage_batch_pg_package_builder.py battle_package_end_to_end_validation.py
python3 -m unittest \
  test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_simple_mana_ability_source_maps_tap_and_discard_cost \
  test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_simple_mana_source_with_unmodeled_discard_auxiliary_maps_partial_mana \
  test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_simple_mana_source_multiline_oracle_does_not_merge_auxiliary_mana_cost \
  test_xmage_exact_scope_runtime.XMageExactScopeRuntimeTest.test_simple_mana_source_permanent_pays_discard_cost_on_refresh -v
```

Result: `4 tests OK`.

Package builder and E2E runner focused tests:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m pytest test_xmage_batch_pg_package_builder.py \
  -k 'simple_mana_source_execution_scenario_pays_discard_cost or simple_mana_source_execution_scenario_pays_life_cost or simple_mana_source_execution_scenario_pays_activation_cost' -q
python3 -m pytest test_battle_package_end_to_end_validation.py \
  -k 'simple_mana_source_refresh_runner_pays_discard_cost or simple_mana_source_refresh_runner_pays_activation_cost_from_support_source or simple_mana_source_refresh_runner_executes_partial_mana_rule' -q
```

Result: `3 passed, 160 deselected` and `3 passed, 80 deselected`.

Note: one root-level `unittest` attempt used an invalid import path for the
hyphenated scripts directory. The same tests passed when run from the scripts
directory, which is the supported invocation for this script suite.

## Post-PG723 Readiness

Report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260710_post_pg723_mana_source_discard_costs_new_server.md`

- all known cards: `34331`
- `snapshot_has_verified_rule`: `6346`
- `battle_and_oracle_ready`: `6321`
- `battle_family_mapper_required`: `27555`
- ready-product QA cards: `275` ready, `89` mapper-required

Delta from the pre-PG723 state:

- `snapshot_has_verified_rule`: `6340 -> 6346`
- `battle_and_oracle_ready`: `6315 -> 6321`
- `battle_family_mapper_required`: `27561 -> 27555`

Authoritative XMage queue:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260710_post_pg723_mana_source_discard_costs_new_server_commander_legal.md`
- target identities: `24632`
- XMage authoritative source count: `24319`
- missing-source exceptions: `313`
- parser gaps: `0`
- adapter-required identities: `24319`
- adapter work units: `11299`

Exact-scope recheck:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260710_post_pg723_mana_source_discard_costs_new_server_recheck.md`
- proposals: `1`
- safe for batch package: `1`
- next safe candidate: `Face of Fear`

## Final Gates

- `xmage_strategy_consistency_audit`: `pass`, `26/26`
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`

## Current Next Work

The next exact safe candidate is `Face of Fear`, but the larger queue is now
blocked by many subpattern-specific unsupported costs and non-simple Oracle
forms. Continue with the same flow:

1. package `Face of Fear` if the family/runtime gate remains narrow;
2. then target the highest blocker-reducing subpatterns from the post-PG723
   split, especially activation costs and simple source-cost lanes that unlock
   multiple blocked cards.
