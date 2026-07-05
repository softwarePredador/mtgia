# Lorehold External Identity Cache Simulation

- Generated at: `2026-07-05T01:56:30Z`
- Status: `external_identity_cache_simulation_pass_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Simulation DB removed: `True`

## Simulation Summary

| Metric | Value |
| --- | ---: |
| `source_marker_rows_before` | `0` |
| `source_marker_rows_after` | `0` |
| `temp_precheck_existing_cache_rows` | `0` |
| `temp_apply_returncode` | `0` |
| `temp_postcheck_resolved_cache_rows` | `6` |
| `temp_rollback_remaining_direct_count` | `0` |
| `post_apply_identity_missing_count` | `0` |
| `post_apply_runtime_or_manual_review_required_count` | `5` |
| `post_apply_shell_contract_required_count` | `9` |
| `deck_test_ready_count` | `0` |

## Post-Apply Queues

- `identity_import_required`: -
- `runtime_or_manual_review_required`: Brain in a Jar, Burning Prophet, Entreat the Angels, Haze of Rage, Inti, Seneschal of the Sun
- `combo_runtime_required`: Haze of Rage
- `shell_contract_required`: Anointed Procession, Blackblade Reforged, Cathars' Crusade, Excalibur, Sword of Eden, Karmic Guide, Late to Dinner, Miraculous Recovery, Storm of Souls, Strata Scythe
- `cut_safety_contract_required`: -

## Postcheck Rows

| Normalized Name | Name | Commander Status |
| --- | --- | --- |
| `brain in a jar` | Brain in a Jar | `legal` |
| `entreat the angels` | Entreat the Angels | `legal` |
| `haze of rage` | Haze of Rage | `legal` |
| `late to dinner` | Late to Dinner | `legal` |
| `miraculous recovery` | Miraculous Recovery | `legal` |
| `strata scythe` | Strata Scythe | `legal` |

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: The package applies and rolls back cleanly on a temporary copy, and the post-apply preflight removes identity blockers. It still does not produce a deck-test-ready or promotion-ready package.
