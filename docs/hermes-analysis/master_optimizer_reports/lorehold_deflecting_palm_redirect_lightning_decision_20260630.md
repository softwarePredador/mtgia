# Lorehold Deflecting Palm Pressure Probe Decision 2026-06-30

- status: `ready`
- scope: pressure/protection lane for protected baseline `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- decision: `reject_exact_swap_keep_deck_607`

## Question

The frozen Lorehold contract says the next useful work should look for pressure
matchup improvements that do not reduce the miracle/topdeck shell. The tested
question was whether `Deflecting Palm` improves the current `607` fast-pressure
lane if it replaces the nonprotected cheap redirect slot `Redirect Lightning`.

This is not a test of whether `Deflecting Palm` is executable. It is executable
locally and appears in Lorehold variants `614`, `615`, and `616`. The test is
only whether this exact replacement improves the protected `607` shell.

## Candidate

| Candidate | Add | Cut | Structural result |
| --- | --- | --- | --- |
| `candidate_607_deflecting_palm_redirect_lightning_v1` | `Deflecting Palm` | `Redirect Lightning` | rank `1`, score `141.058`, intent `100.0`, lands `34`, rule-ready `97.9%` |

The structural matrix ranked the candidate narrowly above `607` because the
swap increased the pressure/protection read while preserving land count,
rule-readiness, and the protected miracle/ramp/finisher anchors. Structure was
therefore sufficient to run a battle smoke gate, but not sufficient to promote.

## Battle Gate

Smoke gate used `opponent_seed=20260629`, `simulation_seed=20260630`, 8 real
opponents, 3 games per opponent, no forced access, and isolated deck processes.

| Deck | Result | Winota slice | Miracle casts | Discard-to-top replacements | Lorehold rummage discard-to-top |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `11W/12L/1S` | `2W/1L` | `48` | `14` | `14` |
| `candidate_607_deflecting_palm_redirect_lightning_v1` | `11W/13L/0S` | `1W/2L` | `37` | `6` | `2` |

Direct card-use evidence was sufficient:

| Card | Games with card events | Cost paid | Spell cast | Miracle cast | Resolved |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Redirect Lightning` in `607` | `1` | `0` | `1` | `0` | `0` |
| `Deflecting Palm` in candidate | `8` | `6` | `6` | `1` | `8` |

## Decision

Reject `candidate_607_deflecting_palm_redirect_lightning_v1` as a deck upgrade.

`Deflecting Palm` was exercised and the runtime handled it, but the candidate
only tied the baseline in total wins, lost the fast-pressure Winota slice, and
reduced the miracle/discard-to-top cadence that makes Lorehold work. Under the
contract, a candidate must tie or beat `607`, must not regress Winota, and must
preserve or improve miracle/topdeck frequency. This exact swap fails those
promotion conditions.

`Redirect Lightning` is not promoted as a protected anchor from this result.
The narrower learning is that replacing it with `Deflecting Palm` does not
improve the current `607` shell. Future pressure tests should either use a
different same-lane cut or prove the pressure gain across the confirmed
72-game window before touching the real deck.

## Evidence Paths

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_deflecting_palm_redirect_lightning_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_deflecting_palm_redirect_lightning_v1.decklist.txt`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_deflecting_palm_redirect_lightning_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
