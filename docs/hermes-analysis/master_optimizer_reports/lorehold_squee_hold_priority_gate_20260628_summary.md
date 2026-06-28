# Lorehold Squee Hold Priority Gate Summary - 2026-06-28

- Scope: current runtime correction for `audit_squee_graveyard_entry_route`.
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Candidate DB: `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Opponent sample: real decks, opponent seed `20260626`, 1 game per opponent, deck-process isolation, game timeout `20s`.

| Seed | Deck | Record | Miracle | Topdeck | Rummage | Squee GY | Squee Return | Squee Rummage Discard |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | `deck_6` | 0-3 | 0 | 0 | 2 | 0 | 0 | 0 |
| 7 | `candidate_607_squee_hold_priority_v1` | 0-3 | 0 | 0 | 3 | 0 | 0 | 0 |
| 20260625 | `deck_6` | 1-2 | 4 | 7 | 1 | 0 | 0 | 0 |
| 20260625 | `candidate_607_squee_hold_priority_v1` | 1-2 | 2 | 0 | 14 | 0 | 0 | 0 |
| 42 | `deck_6` | 1-2 | 12 | 23 | 7 | 0 | 0 | 0 |
| 42 | `candidate_607_squee_hold_priority_v1` | 3-0 | 13 | 12 | 8 | 4 | 3 | 4 |

## Decision

Keep the runtime correction as a model-quality fix: when Lorehold is already active, `Squee, Goblin Nabob` should be held as discard-recursion fuel instead of being spent as a generic main-phase creature.

Do not treat this as sufficient deck improvement. The weak seeds remain weak:

- Seed `7`: still `0-3`; no Squee graveyard or return events.
- Seed `20260625`: still `1-2`; no Squee graveyard or return events.
- Seed `42`: positive anchor preserved and strengthened in this small recut (`3-0`, with Squee graveyard/return and spell-rummage discard observed).

## Next Action

The Squee route is now modeled, so the next package should target access density rather than Squee sequencing:

- increase early reach to `Squee, Goblin Nabob`, `Sensei's Divining Top`, `Scroll Rack`, and `Library of Leng`;
- avoid repeating rejected Land Tax tutor cuts;
- preserve seed `42` miracle/topdeck/Squee telemetry as the regression anchor.
