# Lorehold Access Cut Model - 2026-06-28

- generated_at: `2026-06-28T06:01:23Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- strategy_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- seed_matrix_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_seed_matrix_all_20260628_v1_run.json`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- candidate_count: `5`
- evaluated_pair_count: `470`
- preflight_access_candidate_ready_count: `0`
- manual_review_count: `36`
- status_counts: `{"blocked_candidate_runtime": 94, "blocked_cut_or_prior_evidence": 340, "manual_review_required": 2, "manual_same_lane_cut_required": 34}`
- recommended_next_action: `no_access_swap_ready; upgrade_hidden_retreat_runtime_or_build_new_cut_not_in_reject_set`

## Access Candidates

| Candidate | Status | Lane | Score | Variant Decks | Active Rules | Blockers |
| --- | --- | --- | ---: | --- | ---: | --- |
| Brainstone | `ready` | `topdeck_setup` | 27 | - | 1 | candidate_scope_warns_unexecuted |
| Penance | `ready` | `topdeck_protection` | 59 | 609,611,613,614 | 1 | none |
| Enlightened Tutor | `ready` | `access_tutor` | 67 | 608,611,612,613,614,615 | 1 | none |
| Gamble | `ready` | `access_tutor` | 63 | 609,612,613,614,615 | 1 | none |
| Hidden Retreat | `blocked` | `topdeck_protection` | 0 | - | 0 | candidate_runtime_review_only |

## Preflight Access Candidates

- None.

## Top Manual Review Candidates

| Rank | Candidate | Cut | Status | Score | Candidate Lane | Cut Lane | Negative Cut Count | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Brainstone | Redirect Lightning | `manual_review_required` | 57 | `topdeck_setup` | `draw_value` | 0 | candidate_scope_warns_unexecuted |
| 2 | Enlightened Tutor | High Noon | `manual_same_lane_cut_required` | 55 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 3 | Enlightened Tutor | Winds of Abandon | `manual_same_lane_cut_required` | 55 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 4 | Gamble | High Noon | `manual_same_lane_cut_required` | 51 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 5 | Gamble | Winds of Abandon | `manual_same_lane_cut_required` | 51 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 6 | Brainstone | Improvisation Capstone | `manual_review_required` | 47 | `topdeck_setup` | `draw_value` | 0 | candidate_scope_warns_unexecuted |
| 7 | Enlightened Tutor | Generous Gift | `manual_same_lane_cut_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 8 | Enlightened Tutor | Path to Exile | `manual_same_lane_cut_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 9 | Enlightened Tutor | Redirect Lightning | `manual_same_lane_cut_required` | 47 | `access_tutor` | `draw_value` | 0 | cut_cross_lane:draw_value |
| 10 | Enlightened Tutor | Stroke of Midnight | `manual_same_lane_cut_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 11 | Penance | High Noon | `manual_same_lane_cut_required` | 47 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 12 | Penance | Winds of Abandon | `manual_same_lane_cut_required` | 47 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 13 | Gamble | Generous Gift | `manual_same_lane_cut_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 14 | Gamble | Path to Exile | `manual_same_lane_cut_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 15 | Gamble | Redirect Lightning | `manual_same_lane_cut_required` | 43 | `access_tutor` | `draw_value` | 0 | cut_cross_lane:draw_value |
| 16 | Gamble | Stroke of Midnight | `manual_same_lane_cut_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 17 | Penance | Generous Gift | `manual_same_lane_cut_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 18 | Penance | Path to Exile | `manual_same_lane_cut_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 19 | Penance | Redirect Lightning | `manual_same_lane_cut_required` | 39 | `topdeck_protection` | `draw_value` | 0 | cut_cross_lane:draw_value |
| 20 | Penance | Stroke of Midnight | `manual_same_lane_cut_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 21 | Enlightened Tutor | Improvisation Capstone | `manual_same_lane_cut_required` | 37 | `access_tutor` | `draw_value` | 0 | cut_cross_lane:draw_value |
| 22 | Enlightened Tutor | Smothering Tithe | `manual_same_lane_cut_required` | 37 | `access_tutor` | `early_mana` | 0 | cut_cross_lane:early_mana |
| 23 | Enlightened Tutor | Swords to Plowshares | `manual_same_lane_cut_required` | 37 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 24 | Gamble | Improvisation Capstone | `manual_same_lane_cut_required` | 33 | `access_tutor` | `draw_value` | 0 | cut_cross_lane:draw_value |
| 25 | Gamble | Smothering Tithe | `manual_same_lane_cut_required` | 33 | `access_tutor` | `early_mana` | 0 | cut_cross_lane:early_mana |

## Guardrails

- `preserve_seed42_shell`: Seed 42 is the known success anchor; a package that regresses it cannot be promoted.
- `do_not_cut_repeated_reject_slots`: Promise of Loyalty, Avatar's Wrath, Tibalt's Trickery, Prismari Pianist, and similar slots need a new rationale after repeated matrix regressions.
- `hidden_retreat_runtime_first`: Hidden Retreat currently has only review_only rules in the local runtime, so it is not battle-gate reliable yet.
