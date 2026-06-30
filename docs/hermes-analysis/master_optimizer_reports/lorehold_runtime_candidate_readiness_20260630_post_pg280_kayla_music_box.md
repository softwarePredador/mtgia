# Lorehold Runtime Candidate Readiness - 2026-06-30

- Generated at: `2026-06-30T12:44:25Z`
- Runtime queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json`
- Access model: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `17`
- Status counts: `{"pg_package_applied_synced": 2, "review_required": 3, "split_scope_review_required": 12}`
- Promotion lanes: `{"access_density_candidate": 5, "split_family_scope_review_required": 12}`
- Cut-specific negatives: `0`
- Recommended next action: `split_scope_runtime_families_or_continue_cut_modeling`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Ancient Gold Dragon` | `split_scope_review_required` | `token_maker` | `split_family_scope_review_required` | `token_maker` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 2 | `Blood Moon` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 3 | `Chandra's Ignition` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `sweeper_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 4 | `Charmbreaker Devils` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | `Deathbellow War Cry` | `split_scope_review_required` | `tutor` | `split_family_scope_review_required` | `tutor` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | `Karn's Sylex` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `board_wipe` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | `Karn, the Great Creator` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 8 | `Leyline Dowser` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 9 | `Naktamun Lorespinner // Wheel of Fortune` | `split_scope_review_required` | `draw_engine` | `split_family_scope_review_required` | `draw_engine` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 10 | `Orcish Spy` | `split_scope_review_required` | `topdeck_play` | `split_family_scope_review_required` | `topdeck_play` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 11 | `Prototype Portal` | `split_scope_review_required` | `token_maker` | `split_family_scope_review_required` | `token_maker` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 12 | `Pyxis of Pandemonium` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 13 | `Brainstone` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 14 | `Hidden Retreat` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 15 | `Enlightened Tutor` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 16 | `Gamble` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 17 | `Penance` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |

## Package Evidence And Blockers

### Brainstone
- Applied/synced package `pg272_brainstone_executable_topdeck_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`

### Hidden Retreat
- Applied/synced package `pg271` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`
