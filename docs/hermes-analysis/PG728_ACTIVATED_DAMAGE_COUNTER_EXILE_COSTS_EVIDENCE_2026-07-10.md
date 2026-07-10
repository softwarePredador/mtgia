# PG728 Activated Damage Counter/Exile Costs Evidence - 2026-07-10

## Scope

PG728 closed the narrow XMage -> ManaLoom adapter subpattern for permanent
activated direct damage abilities whose activation cost requires either:

- exiling the top N cards of the controller library, or
- removing a supported counter from a controlled creature/permanent.

Promoted cards:

- Arc-Slogger
- Bolrac-Clan Crusher
- Ion Storm

Runtime scope:

- `xmage_permanent_simple_activated_damage_v1`

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` now extracts and compares:
  - `activation_exile_top_library_count`
  - `activation_remove_counter_cost`
- `battle_analyst_v9.py` now checks and pays those activation costs before
  executing activated direct damage.
- `xmage_batch_pg_package_builder.py` now emits focused E2E fixtures for
  library-exile costs and remove-counter costs.
- `battle_package_end_to_end_validation.py` now verifies the battle event and
  state mutation for top-library exile and counter removal.

## PostgreSQL Apply

Target database:

- `127.0.0.1:15432/halder`

PG728 package:

- selected cards: 3
- deprecated shadow rows: 0
- upserted rows: 3

Post-apply state confirmed live:

| Card | Review | Execution | Oracle hash | Scope |
| --- | --- | --- | --- | --- |
| Arc-Slogger | verified | auto | present | xmage_permanent_simple_activated_damage_v1 |
| Bolrac-Clan Crusher | verified | auto | present | xmage_permanent_simple_activated_damage_v1 |
| Ion Storm | verified | auto | present | xmage_permanent_simple_activated_damage_v1 |

PG728B hash backfill:

- trusted executable rules missing `oracle_hash` before backfill: 55
- rows backfilled: 55
- trusted executable rules missing `oracle_hash` after backfill: 0

## Sync And E2E Evidence

Post-apply sync:

- PG -> SQLite: 3 package rows synced for PG728.
- Full PG -> SQLite after PG728B: `pg_rows_loaded=9929`,
  `sqlite_inserted_or_updated=9707`, `canonical_snapshot_rows_exported=7329`.

Metadata sync after PG728B:

- requested unique names: 8085
- PostgreSQL cards matched: 8276
- SQLite cache alias rows: 8213
- card id updates: 80
- unresolved: 1

E2E package validation after PG728B:

- status: `pass`
- stages: PostgreSQL source, SQLite cache, canonical snapshot fallback,
  runtime `get_card_effect`, and battle execution all passed.
- battle scenarios: 3
- Arc-Slogger exiled 10 cards from library and dealt 2 damage.
- Bolrac-Clan Crusher removed one +1/+1 counter and dealt 2 damage.
- Ion Storm removed one +1/+1 counter and dealt 2 damage.

## Readiness After PG728B

Global readiness:

- total cards: 34331
- snapshot has any rule: 7535
- snapshot has verified rule: 6359
- `battle_and_oracle_ready`: 6334
- `battle_family_mapper_required`: 27542

XMage authoritative queue:

- target identities: 24619
- XMage authoritative source count: 24306
- `xmage_authoritative_adapter_required_count`: 24306
- `xmage_authoritative_parser_gap_count`: 0
- missing XMage source exceptions: 313
- `direct_damage::targeted_damage_variant_v1`: 750

Final exact-scope splitter recheck:

- proposals: 0
- safe package candidates: 0
- considered supported work unit rows: 7054
- `activated_damage_source_cost_not_supported` no longer appears as an
  actionable residual for this subpattern.

## Tests And Audits

Focused tests rerun on 2026-07-10:

- `python3 -m py_compile` for splitter, runtime, package builder, and E2E validator: pass
- splitter tests for the three new activation-cost mappings: 3 passed
- package builder tests for top-library exile and remove-counter fixtures: 2 passed
- E2E runner tests for top-library exile and remove-counter costs: 2 passed

Audits after PG728B:

- `xmage_strategy_consistency_audit`: pass, 26/26
- `operational_surface_alignment_audit`: pass, 48/48
- `legacy_contamination_audit`: pass, 32/32
- `pg_hermes_sqlite_contract_audit`: pass, 51/51
- `./scripts/quality_gate.sh server-target`: pass

## Residual

The global goal remains active. PG728 only closes this exact activated-damage
cost subpattern. The remaining global queue still requires family/subpattern
adapters, led by recursion, draw, protection, add-counters, direct damage,
life gain, tutor, and destroy lanes.
