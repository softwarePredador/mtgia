# Lorehold Access Cut Model - 2026-06-28

- generated_at: `2026-06-28T09:51:20Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- strategy_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- seed_matrix_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_seed_matrix_all_20260628_v1_run.json`
- squee_probe_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_graveyard_entry_probe_20260628_v1.json`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- candidate_count: `5`
- evaluated_pair_count: `470`
- preflight_access_candidate_ready_count: `0`
- manual_review_count: `45`
- status_counts: `{"blocked_cut_or_prior_evidence": 425, "manual_review_required": 2, "manual_same_lane_cut_required": 43}`
- access_density_status: `squee_route_modeled_access_density_needed`
- squee_probe_status: `squee_route_modeled_but_access_gap_remains`
- target_access_cards: `Squee, Goblin Nabob, Sensei's Divining Top, Scroll Rack, Library of Leng`
- recommended_next_action: `no_access_swap_ready; apply_or_sync_hidden_retreat_package_then_gate_new_seed_safe_cut`
- hidden_retreat_package_status: `prepared_read_only_pending_apply_approval`
- hidden_retreat_runtime_model_status: `runtime_proposal_overlay_active`
- hidden_retreat_package_manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg244_hidden_retreat_runtime_scope_20260628_v1_manifest.json`
- runtime_package_overlay_card_count: `1`

## Access Candidates

| Candidate | Status | Lane | Score | Access Targets | Variant Decks | Active Rules | Blockers |
| --- | --- | --- | ---: | --- | --- | ---: | --- |
| Brainstone | `ready` | `topdeck_setup` | 27 | Sensei's Divining Top, Scroll Rack, Library of Leng | - | 1 | candidate_scope_warns_unexecuted |
| Penance | `ready` | `topdeck_protection` | 59 | Sensei's Divining Top, Scroll Rack, Library of Leng | 609,611,613,614 | 1 | none |
| Enlightened Tutor | `ready` | `access_tutor` | 67 | Sensei's Divining Top, Scroll Rack, Library of Leng | 608,611,612,613,614,615 | 1 | none |
| Gamble | `ready` | `access_tutor` | 63 | Squee, Goblin Nabob, Sensei's Divining Top, Scroll Rack, Library of Leng | 609,612,613,614,615 | 1 | none |
| Hidden Retreat | `ready` | `topdeck_protection` | 35 | Sensei's Divining Top, Scroll Rack, Library of Leng | - | 1 | none |

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
- `runtime_package_overlay_is_read_only`: Runtime proposal overlays make candidate modeling possible in copied DB gates, but PostgreSQL/product truth still requires explicit approved apply/sync.
