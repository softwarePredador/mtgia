# Lorehold Chaos Warp Removal Probe Decision 2026-06-30

- status: `ready`
- scope: interaction/removal lane for protected baseline `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- decision: `reject_confirmed_swap_keep_deck_607`

## Question

The tested question was whether `Chaos Warp` improves the current `607`
interaction suite if it replaces `Stroke of Midnight`. This was a strict
same-lane probe: both cards are three-mana instants that answer permanents, and
the candidate preserved the miracle/topdeck, ramp, protection, and finisher
anchors.

This is not a runtime rejection of `Chaos Warp`. It has a verified local
battle rule, appears in Lorehold variants `611`, `615`, and `616`, and was
exercised in the confirmation gates.

## Candidate

| Candidate | Add | Cut | Structural result |
| --- | --- | --- | --- |
| `candidate_607_chaos_warp_stroke_of_midnight_v1` | `Chaos Warp` | `Stroke of Midnight` | rank `1`, score `141.058`, intent `100.0`, lands `34`, rule-ready `97.9%` |

The structural matrix narrowly ranked the candidate above `607`, but the cut
removed an already-used removal card. The promotion bar was therefore a
confirmed 72-game gate with real card-use evidence.

## Battle Gates

Confirmed gates used `opponent_seed=20260629`, 8 real opponents, 3 games per
opponent, no forced access, isolated deck processes, and simulation seeds
`20260630`, `123`, and `999`.

| Seed | `deck_607` | Candidate |
| ---: | ---: | ---: |
| `20260630` | `11W/12L/1S` | `12W/12L/0S` |
| `123` | `8W/16L/0S` | `5W/19L/0S` |
| `999` | `11W/13L/0S` | `8W/16L/0S` |
| **Aggregate** | **`30W/41L/1S`** | **`25W/47L/0S`** |

Fast-pressure and strategy telemetry rejected promotion:

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| Winota slice | `3W/6L` | `2W/7L` |
| Miracle casts | `137` | `146` |
| Topdeck activations | `132` | `117` |
| Lorehold spell casts | `729` | `598` |
| Static cost-reduction casts | `99` | `85` |
| Static cost-reduction total | `221` | `144` |

Direct card-use evidence was sufficient:

| Card | Games with card events | Cost paid | Spell cast | Miracle cast | Resolved/removal resolved |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Stroke of Midnight` in `607` | `8` | `8` | `8` | `1` | `9` |
| `Chaos Warp` in candidate | `17` | `10` | `10` | `5` | `15` |

## Decision

Reject `candidate_607_chaos_warp_stroke_of_midnight_v1` as a deck upgrade.

`Chaos Warp` was drawn/cast/resolved enough for the result to matter, but the
confirmed gate lost five wins versus the protected baseline and regressed the
Winota slice. It also reduced topdeck activation, Lorehold spell-cast volume,
and cost-reduction conversion. Under the frozen contract, this exact same-lane
swap cannot replace `Stroke of Midnight` in the current `607` shell.

`Stroke of Midnight` should remain in `607` until a different same-lane removal
replacement beats the confirmed gate.

## Evidence Paths

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_chaos_warp_stroke_of_midnight_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_chaos_warp_stroke_of_midnight_v1.decklist.txt`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_chaos_warp_stroke_of_midnight_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed123_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed999_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
