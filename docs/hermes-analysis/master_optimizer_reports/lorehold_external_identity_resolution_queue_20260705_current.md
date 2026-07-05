# Lorehold External Identity Resolution Queue

- Generated at: `2026-07-05T01:41:32Z`
- Status: `external_identity_resolution_ready_for_apply_plan_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Deck 607 mutated: `False`
- SQLite apply allowed now: `False`

## Summary

| Metric | Value |
| --- | ---: |
| `identity_queue_count` | `7` |
| `scryfall_found_count` | `7` |
| `commander_legal_count` | `7` |
| `lorehold_color_identity_compatible_count` | `7` |
| `cache_insert_ready_count` | `7` |
| `deck_test_ready_count` | `0` |

## Resolution Rows

| Card | Lookup | Commander | Color Fit | Cache Ready | Post-Import Status |
| --- | --- | ---: | ---: | ---: | --- |
| Anointed Procession | `found` | `True` | `True` | `True` | `identity_ready_then_shell_contract_required` |
| Brain in a Jar | `found` | `True` | `True` | `True` | `identity_ready_then_runtime_or_cut_safety_required` |
| Entreat the Angels | `found` | `True` | `True` | `True` | `identity_ready_then_runtime_or_cut_safety_required` |
| Haze of Rage | `found` | `True` | `True` | `True` | `identity_ready_then_combo_runtime_and_cut_safety_required` |
| Late to Dinner | `found` | `True` | `True` | `True` | `identity_ready_then_shell_contract_required` |
| Miraculous Recovery | `found` | `True` | `True` | `True` | `identity_ready_then_shell_contract_required` |
| Strata Scythe | `found` | `True` | `True` | `True` | `identity_ready_then_shell_contract_required` |

## Queues

- `cache_insert_ready`: Anointed Procession, Brain in a Jar, Entreat the Angels, Haze of Rage, Late to Dinner, Miraculous Recovery, Strata Scythe
- `combo_runtime_after_identity`: Haze of Rage
- `shell_contract_after_identity`: Anointed Procession, Late to Dinner, Miraculous Recovery, Strata Scythe
- `runtime_or_cut_safety_after_identity`: Brain in a Jar, Entreat the Angels

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: The missing identity queue can be resolved externally, but this report intentionally does not apply cache rows and no card becomes battle- or promotion-ready from identity alone.

## Next Actions

- do_not_mutate_or_replace_deck_607
- prepare reviewed SQLite identity cache apply package if local cache should be updated
- after identity cache update, rerun identity/import preflight
- route Haze of Rage to combo runtime only after identity exists locally
- keep archetype-fork cards out of one-for-one 607 cut gates
