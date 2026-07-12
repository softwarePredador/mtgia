# PG829 Draw Additional Cost Evidence

Generated on 2026-07-12 for the new ManaLoom PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

PG829 promotes the XMage-backed fixed controller draw spell family for two
additional-cost subpatterns:

- `Necrologia`: pay X life as an additional cost, then draw X cards.
- `Shared Discovery`: tap four untapped creatures you control as an additional
  cost, then draw three cards.

The implementation is intentionally narrow: both Oracle text and local XMage
source must match the supported additional-cost shape before a proposal is
eligible for PostgreSQL promotion.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py`
  - Recognizes `PayVariableLifeCost` plus Oracle `pay X life`.
  - Recognizes `TapTargetCost(4, FILTER_CONTROLLED_UNTAPPED_CREATURES)`.
  - Maps `DrawCardSourceControllerEffect(GetXValue.instance)` to
    `draw_count_source=x_value` for pure draw spells.
- `battle_analyst_v9.py`
  - Resolves `pay_life_amount_source=x_value` through the existing cast context.
  - Pays/taps N untapped creatures as an additional card cost.
  - Resolves pure draw spell counts from `draw_count_source=x_value`.
- `xmage_batch_pg_package_builder.py`
  - Builds E2E scenarios for X-life draw and tap-four-creatures draw.
- `battle_package_end_to_end_validation.py`
  - Injects X cast context for fixed draw scenarios.
  - Validates life paid and tapped creature cost evidence.

## PostgreSQL Apply Evidence

Package manifest:
`docs/hermes-analysis/master_optimizer_reports/pg829_draw_additional_cost_new_server_package_manifest.json`

Precheck:

| Card | Target card rows | Existing rules | Expected rows before | Shadows to deprecate |
| --- | ---: | ---: | ---: | ---: |
| Necrologia | 1 | 0 | 0 | 0 |
| Shared Discovery | 1 | 0 | 0 | 0 |

Apply:

- `deprecated_shadow_rows=0`
- `upserted_rows=2`

Postcheck:

| Card | Logical rule key | Promoted rows | Verified/auto rows | Oracle hash rows |
| --- | --- | ---: | ---: | ---: |
| Necrologia | `battle_rule_v1:e3bf57c754ce063817330ee3cebe8ba5` | 1 | 1 | 1 |
| Shared Discovery | `battle_rule_v1:293b839a6e5308eb46342ecfe620afae` | 1 | 1 | 1 |

## Sync And E2E Evidence

PG to SQLite/canonical sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg829_draw_additional_cost_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=2`
- `sqlite_inserted_or_updated=2`
- `canonical_snapshot_rows_exported=6670`

Metadata sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg829_draw_additional_cost_new_server_metadata_sync.json`
- Target: `127.0.0.1:15432/halder`
- `deck_cards` backfill matched `2699/2699`

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg829_draw_additional_cost_new_server_e2e_validation.json`
- Status: `pass`
- PostgreSQL validated rows: `2`
- SQLite validated rows: `2`
- Canonical snapshot validated cards: `2`
- Runtime `get_card_effect` validated cards: `2`
- Battle execution:
  - `Necrologia`: paid `3` life via X and drew `3` cards.
  - `Shared Discovery`: tapped `4` untapped creatures and drew `3` cards.

## Readiness After PG829

Readiness report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg829_draw_additional_cost_new_server.json`

- Status: `action_required`
- All known cards: `34331`
- `battle_and_oracle_ready=6686`
- `battle_family_mapper_required=27108`
- `battle_rule_verification_required=70`
- `snapshot_has_any_rule=7946`
- `snapshot_has_verified_rule=6793`

Queue report:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg829_draw_additional_cost_new_server_commander_legal.json`

- `target_identity_count=24197`
- `xmage_authoritative_source_count=23884`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23884`

Exact split recheck:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg829_draw_additional_cost_new_server_recheck.json`

- Status: `ready`
- `safe_for_batch_pg_package_count=0`
- Remaining proposal count: `2`, both runtime-partial mana-source proposals.

## Audits

- `xmage_strategy_consistency_audit`: `pass`, 26 checks.
- `operational_surface_alignment_audit`: `pass`.
- `legacy_contamination_audit`: `pass`.
- `pg_hermes_sqlite_contract_audit`: `pass`, 51 checks.
- `./scripts/quality_gate.sh server-target`: `pass`.

## Tests

Focused PG828/PG829 parser/runtime tests:

```text
Ran 8 tests in 0.626s
OK
```

Package E2E:

```text
status=pass
scenario_count=2
```

Full Python unittest discovery after PG829:

```text
Ran 3034 tests in 48.177s
FAILED (failures=1, skipped=4)
```

The remaining failure is still `test_report_retention_audit`, with summary:

```text
tracked_raw_count=2816
referenced_tracked_raw_count=883
unreferenced_tracked_raw_count=1933
unreferenced_tracked_raw_bytes=115087988
ignored_local_count=3472
ignored_local_bytes=9466278942
```

This is a repository report-retention/hygiene failure, not a PG829 runtime,
PostgreSQL promotion, sync, or E2E failure.

## Current Goal State

The global XMage-to-ManaLoom objective is not complete. PG829 closes this
additional-cost draw microfamily, but the current global queue still has
`23884` XMage-authoritative adapter-required identities and `313` missing-source
exceptions.
