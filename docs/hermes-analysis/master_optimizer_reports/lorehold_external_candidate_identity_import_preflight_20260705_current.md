# Lorehold External Candidate Identity Import Preflight

- Generated at: `2026-07-05T01:36:24Z`
- Status: `external_identity_preflight_blocks_gate_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Deck 607 mutated: `False`

## Summary

| Metric | Value |
| --- | ---: |
| `material_candidate_count` | `14` |
| `commander_legal_count` | `14` |
| `oracle_identity_ready_count` | `7` |
| `oracle_identity_missing_count` | `7` |
| `identity_ready_without_verified_rule_count` | `6` |
| `runtime_or_manual_review_required_count` | `2` |
| `shell_contract_required_count` | `5` |
| `format_staple_candidate_count` | `1` |
| `gate_ready_now_count` | `0` |

## Preflight Rows

| Card | Status | Oracle | Commander | Rules | Route |
| --- | --- | ---: | --- | ---: | --- |
| Anointed Procession | `identity_import_required` | `False` | `legal` | `0` | `archetype_fork` |
| Blackblade Reforged | `shell_contract_required_not_one_for_one_cut` | `True` | `legal` | `0` | `archetype_fork` |
| Brain in a Jar | `identity_import_required` | `False` | `legal` | `0` | `topdeck_pressure_reference` |
| Burning Prophet | `runtime_rule_or_manual_review_required` | `True` | `legal` | `0` | `topdeck_pressure_reference` |
| Cathars' Crusade | `shell_contract_required_not_one_for_one_cut` | `True` | `legal` | `0` | `archetype_fork` |
| Entreat the Angels | `identity_import_required` | `False` | `legal` | `0` | `topdeck_pressure_reference` |
| Excalibur, Sword of Eden | `shell_contract_required_not_one_for_one_cut` | `True` | `legal` | `0` | `archetype_fork` |
| Haze of Rage | `identity_import_required_before_combo_runtime` | `False` | `legal` | `0` | `combo_package` |
| Inti, Seneschal of the Sun | `runtime_rule_or_manual_review_required` | `True` | `legal` | `0` | `reference_corpus` |
| Karmic Guide | `shell_contract_required_not_one_for_one_cut` | `True` | `legal` | `1` | `archetype_fork` |
| Late to Dinner | `identity_import_required` | `False` | `legal` | `0` | `archetype_fork` |
| Miraculous Recovery | `identity_import_required` | `False` | `legal` | `0` | `archetype_fork` |
| Storm of Souls | `shell_contract_required_not_one_for_one_cut` | `True` | `legal` | `0` | `archetype_fork` |
| Strata Scythe | `identity_import_required` | `False` | `legal` | `0` | `archetype_fork` |

## Queues

- `identity_import_required`: Anointed Procession, Brain in a Jar, Entreat the Angels, Haze of Rage, Late to Dinner, Miraculous Recovery, Strata Scythe
- `runtime_or_manual_review_required`: Burning Prophet, Inti, Seneschal of the Sun
- `shell_contract_required`: Blackblade Reforged, Cathars' Crusade, Excalibur, Sword of Eden, Karmic Guide, Storm of Souls
- `cut_safety_contract_required`: -

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: The external material queue is legal in Commander, but it is not deck-test ready: several cards lack local Oracle identity, several identity-ready cards lack runtime/manual-review coverage, and the archetype-fork lanes are not one-for-one cuts from 607.

## Next Actions

- do_not_mutate_or_replace_deck_607
- resolve missing Oracle identities before local materialization
- separate full-shell archetype forks from single-card candidate work
- add or review battle runtime only after identity is resolved
- rerun cut-safety only after the candidate has identity and route classification
