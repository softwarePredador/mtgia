# Lorehold Runtime Candidate Readiness - 2026-06-30

- Generated at: `2026-06-30T10:17:38Z`
- Runtime queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg274_perpetual_timepiece.json`
- Access model: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg272_brainstone.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `23`
- Status counts: `{"manual_mapper_required": 12, "pg_package_applied_synced": 2, "review_required": 3, "split_scope_review_required": 6}`
- Promotion lanes: `{"access_density_candidate": 5, "mapper_metadata_or_test_scenario_required": 12, "split_family_scope_review_required": 6}`
- Cut-specific negatives: `0`
- Recommended next action: `split_scope_runtime_families_or_continue_cut_modeling`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Assemble the Players` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 2 | `Chaos Wand` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 3 | `Charmbreaker Devils` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 4 | `Deathbellow War Cry` | `split_scope_review_required` | `tutor` | `split_family_scope_review_required` | `tutor` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | `Karn's Sylex` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `board_wipe` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | `Naktamun Lorespinner // Wheel of Fortune` | `split_scope_review_required` | `draw_engine` | `split_family_scope_review_required` | `draw_engine` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | `Ancient Gold Dragon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 8 | `Blood Moon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 9 | `Chandra's Ignition` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 10 | `Ghoulcaller's Bell` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 11 | `Karn, the Great Creator` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 12 | `Kayla's Music Box` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 13 | `Lantern of Insight` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 14 | `Leyline Dowser` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 15 | `Orcish Spy` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 16 | `Possibility Storm` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 17 | `Prototype Portal` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 18 | `Pyxis of Pandemonium` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 19 | `Brainstone` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 20 | `Hidden Retreat` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |

## Package Evidence And Blockers

### Brainstone
- Applied/synced package `pg272_brainstone_executable_topdeck_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`

### Hidden Retreat
- Applied/synced package `pg271` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`
