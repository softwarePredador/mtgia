# Lorehold Return the Favor Redirect/Copy Probe Decision 2026-06-30

- status: `ready`
- scope: redirect/copy interaction lane for protected baseline `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- decision: `reject_smoke_swap_keep_deck_607`

## Question

The tested question was whether `Return the Favor` improves the current `607`
cheap redirect slot if it replaces `Redirect Lightning`. The hypothesis was
that the card keeps a similar single-target redirection mode while adding a
copy-spell mode that can support Lorehold's discounted instant/sorcery turns.

This was intentionally narrow: it did not cut miracle/topdeck, ramp, finisher,
or core removal anchors.

## Candidate

| Candidate | Add | Cut | Structural result |
| --- | --- | --- | --- |
| `candidate_607_return_the_favor_redirect_lightning_v1` | `Return the Favor` | `Redirect Lightning` | rank `2`, score `140.9`, intent `100.0`, lands `34`, rule-ready `97.9%` |

The structural matrix kept `deck_607` ahead because the candidate did not add
enough package value to offset losing the baseline card's role tags. That made
this a smoke-only battle probe.

## Battle Gate

Smoke gate used `opponent_seed=20260629`, `simulation_seed=20260630`, 8 real
opponents, 3 games per opponent, no forced access, and isolated deck processes.

| Deck | Result | Winota slice | Miracle casts | Topdeck activations | Lorehold spell casts |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `11W/12L/1S` | `2W/1L` | `48` | `32` | `240` |
| `candidate_607_return_the_favor_redirect_lightning_v1` | `8W/16L/0S` | `1W/2L` | `60` | `40` | `225` |

Direct card-use evidence was limited but sufficient for a smoke rejection:

| Card | Games with card events | Spell cast | Resolved |
| --- | ---: | ---: | ---: |
| `Redirect Lightning` in `607` | `1` | `1` | `0` |
| `Return the Favor` in candidate | `2` | `2` | `2` |

## Decision

Reject `candidate_607_return_the_favor_redirect_lightning_v1` at smoke.

`Return the Favor` is a coherent copy/redirect card and has executable local
runtime support, but this exact swap ranked below `607` structurally and lost
the first equal battle gate by three wins while regressing Winota. It should
not be confirmed in the current shell.

## Evidence Paths

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_return_the_favor_redirect_lightning_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_return_the_favor_redirect_lightning_v1.decklist.txt`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_return_the_favor_redirect_lightning_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_return_the_favor_redirect_gate_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
