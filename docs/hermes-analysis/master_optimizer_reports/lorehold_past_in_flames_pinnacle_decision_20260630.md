# Lorehold Past in Flames Recursion Probe Decision 2026-06-30

- status: `ready`
- scope: graveyard-recursion/spell-chain lane for protected baseline `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- decision: `reject_smoke_swap_keep_deck_607`

## Question

The tested question was whether `Past in Flames` improves the current `607`
recursion/spell-chain lane if it replaces `Pinnacle Monk // Mystic Peak`.
The candidate preserved protected miracle/topdeck, ramp, protection, and
finisher anchors. The hypothesis was that a one-turn flashback engine could
convert Lorehold's discarded and used instant/sorcery cards better than
Pinnacle Monk's single-card instant/sorcery recursion.

This is not a runtime rejection of `Past in Flames`. It has active local
battle-rule support and was exercised in the smoke gate.

## Candidate

| Candidate | Add | Cut | Structural result |
| --- | --- | --- | --- |
| `candidate_607_past_in_flames_pinnacle_monk_v1` | `Past in Flames` | `Pinnacle Monk // Mystic Peak` | rank `2`, score `141.0`, intent `100.0`, lands `34`, rule-ready `97.9%` |

The structural matrix kept `deck_607` ahead, while the candidate stayed close
enough for a smoke-only gate because it targeted the recurring recursion-role
shortfall without touching protected anchors.

## Battle Gate

Smoke gate used `opponent_seed=20260629`, `simulation_seed=20260630`, 8 real
opponents, 3 games per opponent, no forced access, and isolated deck processes.

| Deck | Result | Winota slice | Miracle casts | Topdeck activations | Lorehold spell casts |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `11W/12L/1S` | `2W/1L` | `48` | `32` | `240` |
| `candidate_607_past_in_flames_pinnacle_monk_v1` | `8W/16L/0S` | `0W/3L` | `67` | `61` | `307` |

Direct card-use evidence was sufficient:

| Card | Games with card events | Cost paid | Spell cast | Miracle cast | Resolved |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Pinnacle Monk // Mystic Peak` in `607` | `5` | `5` | `0` | `0` | `0` |
| `Past in Flames` in candidate | `6` | `4` | `4` | `2` | `6` |

## Decision

Reject `candidate_607_past_in_flames_pinnacle_monk_v1` at smoke.

`Past in Flames` did increase spell-chain telemetry, miracle casts, and topdeck
activation, but it lost three total games and collapsed the Winota slice to
`0/3`. The exact cut also reduced the candidate's removal count from `16` to
`15` in the battle report. Under the frozen contract, a recursion upgrade
cannot be promoted if it regresses fast-pressure survival.

`Pinnacle Monk // Mystic Peak` is not globally protected by this result, but it
must not be replaced by `Past in Flames` in the current `607` shell without a
different cut or a materially changed gate.

## Evidence Paths

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_past_in_flames_pinnacle_monk_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_past_in_flames_pinnacle_monk_v1.decklist.txt`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_past_in_flames_pinnacle_monk_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
