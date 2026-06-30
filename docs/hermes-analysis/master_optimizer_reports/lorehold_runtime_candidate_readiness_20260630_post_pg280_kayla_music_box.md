# Lorehold Runtime Candidate Readiness - 2026-06-30

- Generated at: `2026-06-30T15:22:55Z`
- Runtime queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json`
- Access model: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `13`
- Status counts: `{"pg_package_applied_synced": 2, "review_required": 4, "split_scope_review_required": 7}`
- Promotion lanes: `{"access_density_candidate": 5, "batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 7}`
- Cut-specific negatives: `0`
- Recommended next action: `split_scope_runtime_families_or_continue_cut_modeling`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Ancient Gold Dragon` | `split_scope_review_required` | `token_maker` | `split_family_scope_review_required` | `token_maker` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 2 | `Blood Moon` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 3 | `Chandra's Ignition` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `sweeper_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 4 | `Charmbreaker Devils` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | `Karn's Sylex` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `board_wipe` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | `Karn, the Great Creator` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | `Naktamun Lorespinner // Wheel of Fortune` | `split_scope_review_required` | `draw_engine` | `split_family_scope_review_required` | `draw_engine` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 8 | `Brainstone` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 9 | `Hidden Retreat` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 10 | `Enlightened Tutor` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 11 | `Gamble` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 12 | `Penance` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 13 | `Deathbellow War Cry` | `review_required` | `tutor` | `batch_metadata_candidate_requires_pg_precheck` | `tutor` | 0 | Review current evidence before gate. |

## Package Evidence And Blockers

### Brainstone
- Applied/synced package `pg272_brainstone_executable_topdeck_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`

### Hidden Retreat
- Applied/synced package `pg271` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`
