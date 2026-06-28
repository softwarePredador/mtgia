# Lorehold Penance Runtime Topdeck Gate - 2026-06-28

## Scope

- Runtime changed: `battle_analyst_v9.activate_lorehold_topdeck_artifacts` now treats permanents with `activation_requires_put_card_from_hand_on_top_library` as proactive Lorehold miracle setup during upkeep/opponent upkeep.
- Guardrails: activate only when the hand card is a miracle-eligible high-priority spell, the current library top is worse, activation cost is payable, and the permanent has not already been used this turn.
- Telemetry added: `hand_to_topdeck_activation` plus the existing `topdeck_manipulation_activated` lane.
- PostgreSQL writes: none.
- Source DB mutated: no.

## Preflight

| Package | Result | Reason |
| --- | --- | --- |
| `penance_topdeck_protection_cut_squelcher` | blocked | `Hexing Squelcher` is locked by cut-safety evidence. |
| `penance_runtime_topdeck_cut_promise` | ready | No previous blocker evidence for `Promise of Loyalty`; retest is justified by new runtime behavior. |

## Gate Results

Package: `Penance` over `Promise of Loyalty`.

| Seed | Baseline | Candidate | Delta pp | Baseline Miracle | Candidate Miracle | Baseline Topdeck | Candidate Topdeck | Hand-to-Top Activations |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 0-3 | 0-3 | 0.00 | 0 | 0 | 0 | 0 | 0 |
| 20260625 | 1-2 | 1-2 | 0.00 | 2 | 3 | 0 | 2 | 0 |
| 42 | 3-0 | 1-2 | -66.67 | 13 | 8 | 12 | 13 | 0 |

## Decision

Reject `penance_runtime_topdeck_cut_promise` for deck promotion.

The runtime improvement is valid and covered by focused tests, but the deck swap is not. The candidate never produced a `hand_to_topdeck_activation` in the three seed gate, so the package did not prove the intended Penance line. It also collapses seed 42 from 3-0 to 1-2 while reducing miracle casts from 13 to 8.

## Next Action

- Keep the runtime support because it is a generic executable family improvement for future hand-to-library cards.
- Do not cut `Hexing Squelcher` for Penance.
- Do not cut `Promise of Loyalty` for Penance.
- If Penance is revisited, use a forced-exposure micro-scenario or a non-core flex cut before running a full promotion gate.
