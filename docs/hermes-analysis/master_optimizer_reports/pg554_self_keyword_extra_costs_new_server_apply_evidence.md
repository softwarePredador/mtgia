# PG554 Self Keyword Extra Costs New Server Evidence

Generated at: `2026-07-06T06:16:00Z`

## Scope

PG554 extends the already-promoted simple activated self-keyword-until-EOT
runtime lane to exact XMage activation costs that were blocked after PG553:

- `DiscardCardCost`
- `PayLifeCost(N)`
- phyrexian mana symbols such as `{G/P}`

Promoted cards:

- `Fledgling Imp`
- `Insatiable Souleater`
- `Olivia's Dragoon`
- `Patrol Hound`
- `Shadowcloak Vampire`

Battle model scope:
`xmage_permanent_simple_activated_self_keyword_until_eot_v1`.

## PostgreSQL Apply

Precheck:

- target card rows: `5/5`
- existing matching executable rows before apply: `0`
- shadow rows scheduled for deprecation: `0`

Apply:

- upserted rows: `5`
- deprecated shadow rows: `0`

Postcheck:

- promoted rule rows: `5/5`
- promoted verified/auto rows: `5/5`
- promoted rows with `oracle_hash`: `5/5`

## Sync

PostgreSQL -> Hermes/SQLite sync:

- PostgreSQL rows loaded: `8948`
- SQLite inserted/updated rows: `8712`
- canonical snapshot rows exported: `6450`

## E2E Validation

Package E2E status: `pass`.

- scenarios: `5`
- battle events: `10`
- `Fledgling Imp`: discarded `1`, gained `flying`
- `Insatiable Souleater`: paid `{G/P}` path, gained `trample`
- `Olivia's Dragoon`: discarded `1`, gained `flying`
- `Patrol Hound`: discarded `1`, gained `first_strike`
- `Shadowcloak Vampire`: paid `2` life, gained `flying`

Focused tests:

- `python3 -m py_compile` over splitter, package builder, E2E validator, and battle runtime: `pass`
- `pytest` package builder + E2E tests: `54 passed`
- `unittest` exact-scope splitter tests: `620 passed`

## Post-Cycle Rechecks

Post-PG554 queue:

- `target_identity_count`: `25543`
- `xmage_authoritative_source_count`: `25229`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `25229`
- `adapter_work_unit_count`: `11354`

Post-PG554 exact split:

- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`
- residual `activated_self_keyword_oracle_cost_not_supported`: `2`

Final audits:

- XMage strategy consistency: `26/26 pass`
- operational surface alignment: `pass`
- legacy contamination: `pass`
- PG/Hermes/SQLite contract with env loaded: `51/51 pass`

## Cleanup

The raw 40 MB PG554 queue JSON files were deleted from the workspace. The
kept evidence is the compact package/evidence/audit surface plus SQL package
and rollback.

## Residual Boundary

PG554 does not authorize activation costs that require untapping the source,
tapping another target creature/permanent, sacrifice, exile, target discard, or
composite/or costs. The two remaining self-keyword blockers from this lane are
still routed as unsupported activation-cost subpatterns.
