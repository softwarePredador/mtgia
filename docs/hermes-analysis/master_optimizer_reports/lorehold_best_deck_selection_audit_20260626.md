# Lorehold Best Deck Selection Audit 2026-06-26

- status: `ready`
- current_best_deck: `deck_607`
- postgres_writes: `false`
- local_hermes_sqlite_mutated: `true`
- source_runtime_changed: `true`
- candidate_tested_this_run: `candidate_607_birgi_v1`

## Current Decision

`deck_607` remains the best Lorehold deck. It is the only registered Lorehold list with commander intent score `100.0`, no intent risks, and a passing real-opponent battle gate.

Latest equal gate after the `Molecule Man` runtime fix:

| Deck | Result | WR | Winota | Miracle Games | Topdeck Games | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `deck_607` | 5W/4L/0S | 55.56% | 2W/1L | 8/9 | 3/9 | keep baseline |
| `candidate_607_birgi_v1` | 3W/6L/0S | 33.33% | 1W/2L | 4/9 | 2/9 | reject |

Birgi was a good hypothesis but failed as an isolated same-function swap. Replacing `Bender's Waterskin` reduced miracle conversion and the pressure matchup. `Bender's Waterskin` is now protected until a same-function replacement beats it.

## What Was Missing

1. `Molecule Man` had no executable `battle_card_rules` row in local Hermes SQLite, even though `deck_607` depends on its miracle `{0}` ceiling.
2. The battle runtime only accepted the Lorehold-style miracle lane for instants/sorceries and ignored cost `0` because the engine lookup used truthy flag detection.
3. Candidate learning existed, but Birgi had not been tested as an isolated swap.
4. Gates only write partial output after a deck finishes all games. Long games can leave the run opaque for several minutes.
5. The hypothesis registry was not yet updated with the Birgi failure and did not protect `Bender's Waterskin`.

## What Was Implemented

- Added runtime support for miracle engines whose `grants_miracle_cost` is `0`.
- Added nonland miracle scope through `grants_miracle_card_scope=nonland` / `grants_miracle_nonland=true`.
- Kept opponent-upkeep rummage exclusive to `Lorehold, the Historian`; `Molecule Man` does not create extra rummage.
- Fixed miracle replay telemetry to report the actual `miracle_engine`.
- Added a focused regression test for `Molecule Man` casting a nonland first draw for miracle `{0}`.
- Applied a local SQLite/Hermes rule for `Molecule Man` with scope `nonland_hand_miracle_zero_static_v1`.
- Generated and tested `candidate_607_birgi_v1`.
- Updated the hypothesis registry and protected-card list.

## Remaining Implementation Backlog

| Priority | Work | Why |
| --- | --- | --- |
| P0 | Promote the `Molecule Man` rule to PostgreSQL and resync Hermes after approval | PostgreSQL is source of truth; current fix is local SQLite/runtime evidence. |
| P0 | Add per-game timeout/checkpoint to `lorehold_variant_battle_gate.py` | A best-deck workflow cannot depend on multi-minute silent runs. |
| P1 | Build a registry-driven candidate runner | It should read the hypothesis registry, generate one-card candidates, run gates, and write decisions automatically. |
| P1 | Define exact same-function cuts for `Reprieve`, `Galvanoth`, and `Ghostly Prison` before testing | The failed candidates show that cutting the wrong function is the main source of false improvements. |
| P1 | Persist per-candidate decision evidence in one compact matrix | Structural score, rule readiness, battle result, Winota result, miracle/topdeck rates, and final decision should sit together. |
| P2 | Run expanded gate only for a candidate that ties or beats `deck_607` in the 3x3 gate | Avoid spending time proving failed candidates failed harder. |

## Selection Rules

A candidate fails immediately if any of these happen on the same 3x3 real-opponent gate:

- win rate below `deck_607`,
- Winota result below `deck_607`,
- miracle games below `deck_607`,
- topdeck games below `deck_607`,
- construction report invalid,
- swap cuts a protected card without same-function replacement evidence.

A candidate can move to expanded testing only if it ties or beats `deck_607` and does not regress Winota, miracle games, or topdeck games. Expanded testing should use a larger opponent and seed sample before promotion.

## Next Queue

1. `candidate_607_reprieve_v1`: choose a same-function protection/counter cut, then generate and gate.
2. `candidate_607_galvanoth_v1`: choose an expensive topdeck/value cut, then generate and gate.
3. `candidate_607_ghostly_prison_v1`: test only as pressure-absorber replacement, not as a spell-density cut.
4. `candidate_607_guttersnipe_v1`: lower priority because the similar payoff lane already failed through Longshot.

## Evidence

- Runtime rule lookup: `Molecule Man` resolves to `nonland_hand_miracle_zero_static_v1`.
- Focused tests passed: miracle baseline tests plus `test_molecule_man_grants_zero_miracle_to_nonland_first_draw`.
- Unit tests passed:
  - `test_lorehold_607_research_candidate.py`
  - `test_lorehold_strategy_profile.py`
  - `test_lorehold_variant_battle_gate.py`
- Gate artifact:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule.md`
- Candidate artifact:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1.md`
- Local runtime SQL package:
  - `docs/hermes-analysis/master_optimizer_reports/molecule_man_battle_rule_pg244_local_runtime_20260626.sql`
