# Lorehold Miracle Next Route Planner

- Generated at: `2026-07-05T10:07:40Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607`
- Candidate queue status: `miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607`
- Candidate queue matrix route governed: `true`
- Candidate queue matrix next-shell status: `next_shell_cut_path_closed_route_miracle_access_first_keep_607`
- Route candidates: `5`
- Selected card: `Brain in a Jar`
- Selected lane: `topdeck_miracle_access`
- Selected route state: `brain_floor_traces_protect_all_cut_slots_no_seed_safe_cut`
- Selected learning score: `110`
- Entreat safe cuts: `0`
- Entreat active rules: `0`
- Brain PG package status: `prepared_read_only_pending_apply_approval`
- Brain PG package route governed: `true`
- Brain apply ready for manual review: `true`
- Brain apply executed by this script: `false`
- Brain active rules: `0`
- Brain safe cuts: `0`
- Brain unlock audit status: `brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607`
- Brain unlockable now: `0`
- Brain targeted floor trace missing slots: `0`
- Named seed-safe cuts: `0`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action`

## Source Reports

- `brain_safe_cut_gap`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_safe_cut_gap_audit_20260705_current.json`
- `brain_unlock_audit`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_seed_safe_cut_unlock_audit_20260705_current.json`
- `candidate_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json`
- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `entreat_scout`: `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_same_lane_cut_scout_20260705_current.json`
- `post_identity`: `docs/hermes-analysis/master_optimizer_reports/lorehold_post_identity_queue_split_20260705_current.json`
- `runtime_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_entreat_haze_runtime_contract_20260705_current.json`

## Ranked Routes

| Card | Lane | State | Score | Runtime | Blockers |
| --- | --- | --- | ---: | --- | --- |
| Brain in a Jar | `topdeck_miracle_access` | `brain_floor_traces_protect_all_cut_slots_no_seed_safe_cut` | 110 | `blocked_requires_new_runtime_family` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Haze of Rage | `storm_combo_pressure` | `combo_package_runtime_lesson` | 66 | `blocked_complex_combo_runtime` | `combo_runtime_required, matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Burning Prophet | `spell_scry_pressure` | `defer_lower_priority_runtime_review` | 42 | `missing_runtime_contract` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Inti, Seneschal of the Sun | `rummage_pressure_access` | `defer_lower_priority_runtime_review` | 38 | `missing_runtime_contract` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Entreat the Angels | `miracle_finisher` | `parked_entreat_no_safe_cut` | 34 | `best_first_runtime_contract_candidate` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |

## Selected Route

- Card: `Brain in a Jar`
- Next action: `continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action`
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
- reason: Brain in a Jar now has targeted floor trace evidence for every current 607 cut slot. That evidence protects the slots rather than unlocking a seed-safe cut, so the planner keeps 607 and routes only to continued learning or explicit PG review.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_candidate_deck_from_route_planner_output
  - do_not_run_natural_battle_from_route_planner_output
  - continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action
  - rerun deckbuilding contract surface audit after generating the route report
