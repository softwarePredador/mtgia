# Lorehold Squee Graveyard Entry Probe

- Generated at: `2026-06-30T20:26:17Z`
- Trace audit: `docs/hermes-analysis/master_optimizer_reports/lorehold_failure_targeted_trace_audit_20260630_goal_learning_defaults_current.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Status: `squee_route_modeled_but_access_gap_remains`
- Next action: `target_access_density_not_squee_sequencing`
- Modeled when accessed: `true`
- Weak seeds missing Squee material events: `7, 20260625`
- Weak seeds missing focus access to Squee: `7, 20260625`
- Seed-42 anchor record: `{'wins': 3, 'losses': 0, 'stalls': 0, 'win_rate': 100.0}`

## Runtime Gates

| Seed | Record | Squee Discards | Squee GY | Squee Return | Miracle | Topdeck |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 20260625 | `1-2-0` | 0 | 0 | 0 | 2 | 0 |
| 42 | `3-0-0` | 2 | 3 | 2 | 13 | 12 |
| 7 | `0-3-0` | 1 | 2 | 2 | 1 | 2 |

## Focus Trace Access

| Seed | Record | Squee Reached Hand/Battlefield | Material Squee Events | Min Library Pos | Early Zones |
| ---: | --- | --- | ---: | ---: | --- |
| 20260625 | `0-0-0` | `false` | 0 | 9 | `{"library": 144}` |
| 42 | `0-0-0` | `true` | 0 | 1 | `{"hand": 13, "library": 131}` |
| 7 | `0-0-0` | `false` | 0 | 4 | `{"library": 144}` |

## Decision

- `keep_squee_runtime_model`: `True`
- `do_not_cut_squee_for_current_recursion_candidates`: `True`
- `do_not_create_squee_sequencing_swap`: `True`
- `next_package_constraint`: `Any next package must increase access/conversion while preserving seed-42 Squee/miracle/topdeck telemetry.`
