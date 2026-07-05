# Lorehold Miracle Next Route Planner

- Generated at: `2026-07-05T09:06:42Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `miracle_next_route_planner_selected_brain_runtime_learning_keep_607`
- Candidate queue status: `miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607`
- Candidate queue matrix route governed: `true`
- Candidate queue matrix next-shell status: `next_shell_cut_path_closed_route_miracle_access_first_keep_607`
- Route candidates: `5`
- Selected card: `Brain in a Jar`
- Selected lane: `topdeck_miracle_access`
- Selected route state: `next_single_card_runtime_lesson`
- Selected learning score: `104`
- Entreat safe cuts: `0`
- Entreat active rules: `0`
- Named seed-safe cuts: `0`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `draft_brain_in_a_jar_runtime_contract_and_cut_miner_no_deck_action`

## Source Reports

- `candidate_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json`
- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `entreat_scout`: `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_same_lane_cut_scout_20260705_current.json`
- `post_identity`: `docs/hermes-analysis/master_optimizer_reports/lorehold_post_identity_queue_split_20260705_current.json`
- `runtime_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_entreat_haze_runtime_contract_20260705_current.json`

## Ranked Routes

| Card | Lane | State | Score | Runtime | Blockers |
| --- | --- | --- | ---: | --- | --- |
| Brain in a Jar | `topdeck_miracle_access` | `next_single_card_runtime_lesson` | 104 | `blocked_requires_new_runtime_family` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Haze of Rage | `storm_combo_pressure` | `combo_package_runtime_lesson` | 66 | `blocked_complex_combo_runtime` | `combo_runtime_required, matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Burning Prophet | `spell_scry_pressure` | `defer_lower_priority_runtime_review` | 42 | `missing_runtime_contract` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Inti, Seneschal of the Sun | `rummage_pressure_access` | `defer_lower_priority_runtime_review` | 38 | `missing_runtime_contract` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Entreat the Angels | `miracle_finisher` | `parked_entreat_no_safe_cut` | 34 | `best_first_runtime_contract_candidate` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |

## Selected Route

- Card: `Brain in a Jar`
- Next action: `draft Brain in a Jar runtime contract and cut miner, no deck action`
- Deckbuilding value: Potentially helps cast key spells on constrained turns, but only if charge-counter timing and spell mana values are modeled correctly.
- External source lane: `official_card_text_and_rulings`
- External learning signal: charge-counter timing, exact mana-value free casting, and scry form a single-card runtime lesson for miracle/topdeck access
- gatherer: https://gatherer.wizards.com/SOI/en-us/252/brain-in-a-jar
- scryfall: https://scryfall.com/card/soi/252/brain-in-a-jar

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- matrix_scoring_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- postgres_writes_allowed: `false`
- reason: Entreat remains blocked by named safe-cut and unapplied-rule gates; Brain in a Jar is the next best learning route because it teaches charge-counter/free-cast/scry timing for the miracle-access thesis without mutating deck 607.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_candidate_deck_from_route_planner_output
  - do_not_run_natural_battle_from_route_planner_output
  - draft_brain_in_a_jar_runtime_contract_and_cut_miner_no_deck_action
  - rerun deckbuilding contract surface audit after generating the route report
