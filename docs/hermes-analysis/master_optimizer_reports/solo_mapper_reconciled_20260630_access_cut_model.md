# Lorehold Access Cut Model - 2026-06-28

- generated_at: `2026-06-30T14:32:00Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- deck_id: `607`
- strategy_report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- seed_matrix_report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_seed_matrix_all_20260628_v1_run.json`
- squee_probe_report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_graveyard_entry_probe_20260628_v1.json`
- runtime_package_proposal_reports: `docs/hermes-analysis/master_optimizer_reports/solo_mapper_reconciled_20260630_effect_json_batch_proposals_from_queue.json`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- candidate_count: `5`
- evaluated_pair_count: `470`
- preflight_access_candidate_ready_count: `0`
- manual_review_count: `35`
- status_counts: `{"blocked_cut_or_prior_evidence": 435, "manual_cross_lane_cut_review_required": 35}`
- access_density_status: `squee_route_modeled_access_density_needed`
- squee_probe_status: `squee_route_modeled_but_access_gap_remains`
- target_access_cards: `Squee, Goblin Nabob, Sensei's Divining Top, Scroll Rack, Library of Leng`
- recommended_next_action: `no_access_swap_ready; build_new_seed_safe_cut`
- hidden_retreat_package_status: `applied_synced`
- hidden_retreat_runtime_model_status: `local_db_active`
- hidden_retreat_package_manifest: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_manifest.json`
- runtime_package_overlay_card_count: `0`

## Access Candidates

| Candidate | Status | Lane | Score | Access Targets | Variant Decks | Active Rules | Blockers |
| --- | --- | --- | ---: | --- | --- | ---: | --- |
| Brainstone | `ready` | `topdeck_setup` | 35 | Sensei's Divining Top, Scroll Rack, Library of Leng | - | 1 | none |
| Penance | `ready` | `topdeck_protection` | 59 | Sensei's Divining Top, Scroll Rack, Library of Leng | 609,611,613,614 | 1 | none |
| Enlightened Tutor | `ready` | `access_tutor` | 67 | Sensei's Divining Top, Scroll Rack, Library of Leng | 608,611,612,613,614,615 | 1 | none |
| Gamble | `ready` | `access_tutor` | 63 | Squee, Goblin Nabob, Sensei's Divining Top, Scroll Rack, Library of Leng | 609,612,613,614,615 | 1 | none |
| Hidden Retreat | `ready` | `topdeck_protection` | 35 | Sensei's Divining Top, Scroll Rack, Library of Leng | - | 1 | none |

## Preflight Access Candidates

- None.

## Top Manual Review Candidates

| Rank | Candidate | Cut | Status | Score | Candidate Lane | Cut Lane | Negative Cut Count | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Enlightened Tutor | High Noon | `manual_cross_lane_cut_review_required` | 55 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 2 | Enlightened Tutor | Winds of Abandon | `manual_cross_lane_cut_review_required` | 55 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 3 | Gamble | High Noon | `manual_cross_lane_cut_review_required` | 51 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 4 | Gamble | Winds of Abandon | `manual_cross_lane_cut_review_required` | 51 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 5 | Enlightened Tutor | Generous Gift | `manual_cross_lane_cut_review_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 6 | Enlightened Tutor | Path to Exile | `manual_cross_lane_cut_review_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 7 | Enlightened Tutor | Stroke of Midnight | `manual_cross_lane_cut_review_required` | 47 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 8 | Penance | High Noon | `manual_cross_lane_cut_review_required` | 47 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 9 | Penance | Winds of Abandon | `manual_cross_lane_cut_review_required` | 47 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 10 | Gamble | Generous Gift | `manual_cross_lane_cut_review_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 11 | Gamble | Path to Exile | `manual_cross_lane_cut_review_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 12 | Gamble | Stroke of Midnight | `manual_cross_lane_cut_review_required` | 43 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 13 | Penance | Generous Gift | `manual_cross_lane_cut_review_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 14 | Penance | Path to Exile | `manual_cross_lane_cut_review_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 15 | Penance | Stroke of Midnight | `manual_cross_lane_cut_review_required` | 39 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 16 | Enlightened Tutor | Smothering Tithe | `manual_cross_lane_cut_review_required` | 37 | `access_tutor` | `early_mana` | 0 | cut_cross_lane:early_mana |
| 17 | Enlightened Tutor | Swords to Plowshares | `manual_cross_lane_cut_review_required` | 37 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 18 | Gamble | Smothering Tithe | `manual_cross_lane_cut_review_required` | 33 | `access_tutor` | `early_mana` | 0 | cut_cross_lane:early_mana |
| 19 | Gamble | Swords to Plowshares | `manual_cross_lane_cut_review_required` | 33 | `access_tutor` | `removal` | 0 | cut_cross_lane:removal |
| 20 | Penance | Smothering Tithe | `manual_cross_lane_cut_review_required` | 29 | `topdeck_protection` | `early_mana` | 0 | cut_cross_lane:early_mana |
| 21 | Penance | Swords to Plowshares | `manual_cross_lane_cut_review_required` | 29 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 22 | Brainstone | High Noon | `manual_cross_lane_cut_review_required` | 23 | `topdeck_setup` | `removal` | 0 | cut_cross_lane:removal |
| 23 | Brainstone | Winds of Abandon | `manual_cross_lane_cut_review_required` | 23 | `topdeck_setup` | `removal` | 0 | cut_cross_lane:removal |
| 24 | Hidden Retreat | High Noon | `manual_cross_lane_cut_review_required` | 23 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |
| 25 | Hidden Retreat | Winds of Abandon | `manual_cross_lane_cut_review_required` | 23 | `topdeck_protection` | `removal` | 0 | cut_cross_lane:removal |

## Guardrails

- `preserve_seed42_shell`: Seed 42 is the known success anchor; a package that regresses it cannot be promoted.
- `do_not_cut_repeated_reject_slots`: Promise of Loyalty, Avatar's Wrath, Tibalt's Trickery, Prismari Pianist, and similar slots need a new rationale after repeated matrix regressions.
- `runtime_package_overlay_is_read_only`: Runtime proposal overlays make candidate modeling possible in copied DB gates, but PostgreSQL/product truth still requires explicit approved apply/sync.
