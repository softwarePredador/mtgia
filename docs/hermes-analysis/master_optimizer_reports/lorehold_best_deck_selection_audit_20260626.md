# Lorehold Best Deck Selection Audit 2026-06-26

- status: `ready`
- current_best_deck: `deck_607`
- postgres_writes: `true`
- local_hermes_sqlite_mutated: `true`
- source_runtime_changed: `true`
- candidate_tested_this_run: `registry_queue_closed`

## Current Decision

`deck_607` remains the best Lorehold deck. It is the only registered Lorehold list with commander intent score `100.0`, no intent risks, and a passing real-opponent battle gate.

Registry queue result after the `Molecule Man` PostgreSQL promotion and per-game checkpoint work:

| Deck | Result | WR | Winota | Miracle Games | Topdeck Games | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `deck_607` | 5W/4L/0S | 55.56% | 2W/1L | 8/9 | 3/9 | keep baseline |
| `candidate_607_reprieve_v1` | 0W/9L/0S | 0.00% | 0W/3L | 4/9 | 2/9 | reject |
| `candidate_607_galvanoth_v1` | 4W/5L/0S | 44.44% | 1W/2L | 6/9 | 1/9 | reject |
| `candidate_607_ghostly_prison_v1` | 3W/6L/0S | 33.33% | 0W/3L | 6/9 | 2/9 | reject |
| `candidate_607_guttersnipe_v1` | 1W/8L/0S | 11.11% | 0W/3L | 8/9 | 5/9 | reject |

Every isolated candidate preserved `Molecule Man`, kept construction valid, and retained commander intent score `100.0`, but none beat the battle acceptance rule. `deck_607` remains the protected baseline.

## What Was Missing

1. `Molecule Man` had no executable `battle_card_rules` row in local Hermes SQLite, even though `deck_607` depends on its miracle `{0}` ceiling.
2. The battle runtime only accepted the Lorehold-style miracle lane for instants/sorceries and ignored cost `0` because the engine lookup used truthy flag detection.
3. Candidate learning existed, but the active registry queue still had TBD cuts and no automatic runner evidence.
4. The current queue lacked one compact decision matrix tying swaps, battle result, Winota result, miracle/topdeck rates, and final decision together.

## What Was Implemented

- Added runtime support for miracle engines whose `grants_miracle_cost` is `0`.
- Added nonland miracle scope through `grants_miracle_card_scope=nonland` / `grants_miracle_nonland=true`.
- Kept opponent-upkeep rummage exclusive to `Lorehold, the Historian`; `Molecule Man` does not create extra rummage.
- Fixed miracle replay telemetry to report the actual `miracle_engine`.
- Added a focused regression test for `Molecule Man` casting a nonland first draw for miracle `{0}`.
- Applied a local SQLite/Hermes rule for `Molecule Man` with scope `nonland_hand_miracle_zero_static_v1`.
- Generated and tested `candidate_607_birgi_v1`.
- Promoted `Molecule Man` to PostgreSQL and synchronized the Hermes SQLite cache from PostgreSQL.
- Added per-game timeout/checkpoint support to the battle gate.
- Added the registry-driven candidate runner.
- Generated and tested `candidate_607_reprieve_v1`.
- Generated and tested `candidate_607_galvanoth_v1`.
- Generated and tested `candidate_607_ghostly_prison_v1`.
- Generated and tested `candidate_607_guttersnipe_v1`.
- Persisted a compact decision matrix for the closed registry queue.
- Updated the hypothesis registry and protected-card list.

## Remaining Implementation Backlog

| Priority | Work | Why |
| --- | --- | --- |
| P1 | Mine a fresh hypothesis queue from deck logs and external strategy evidence | The current registry queue is closed and all tested swaps failed. |
| P1 | Add runner writeback automation for tested/rejected entries | Current writeback is still reviewed and committed by Codex after the runner finishes. |
| P2 | Run expanded gate only for a future candidate that ties or beats `deck_607` in the 3x3 gate | Avoid spending time proving failed candidates failed harder. |

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

Current queue is closed: `Reprieve`, `Galvanoth`, `Ghostly Prison`, and `Guttersnipe` were all tested and rejected. Next work should mine a fresh queue instead of retrying these same swaps.

## Evidence

- Runtime rule lookup: `Molecule Man` resolves to `nonland_hand_miracle_zero_static_v1`.
- Focused tests passed: miracle baseline tests plus `test_molecule_man_grants_zero_miracle_to_nonland_first_draw`.
- Unit tests passed:
  - `test_lorehold_607_research_candidate.py`
  - `test_lorehold_strategy_profile.py`
  - `test_lorehold_variant_battle_gate.py`
- Gate artifact:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_decision_matrix_20260626_registry_queue_closed.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_decision_matrix_20260626_registry_queue_closed.md`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_reprieve_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_reprieve_v1.md`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_galvanoth_v1_galvanoth_v1_gate.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_ghostly_prison_v1_ghostly_prison_v1_gate.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_guttersnipe_v1_guttersnipe_v1_gate.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule.md`
- Candidate artifact:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_reprieve_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_reprieve_v1.md`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_galvanoth_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_ghostly_prison_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_guttersnipe_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1.md`
- PostgreSQL/Hermes promotion:
  - `docs/hermes-analysis/master_optimizer_reports/molecule_man_pg244_apply_20260626.json`
  - `docs/hermes-analysis/master_optimizer_reports/molecule_man_pg244_sqlite_sync_20260626.json`
