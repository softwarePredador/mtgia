# Lorehold Runtime Candidate Readiness - 2026-06-28

- Generated at: `2026-06-30T09:35:26Z`
- Runtime queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg272_brainstone.json`
- Access model: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg272_brainstone.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `25`
- Status counts: `{"manual_mapper_required": 12, "pg_package_applied_synced": 1, "review_required": 4, "split_scope_review_required": 8}`
- Promotion lanes: `{"access_density_candidate": 5, "mapper_metadata_or_test_scenario_required": 12, "split_family_scope_review_required": 8}`
- Cut-specific negatives: `0`
- Recommended next action: `split_scope_runtime_families_or_continue_cut_modeling`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Assemble the Players` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 2 | `Chaos Wand` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 3 | `Charmbreaker Devils` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 4 | `Codex Shredder` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | `Deathbellow War Cry` | `split_scope_review_required` | `tutor` | `split_family_scope_review_required` | `tutor` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | `Karn's Sylex` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `board_wipe` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | `Naktamun Lorespinner // Wheel of Fortune` | `split_scope_review_required` | `draw_engine` | `split_family_scope_review_required` | `draw_engine` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 8 | `Perpetual Timepiece` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 9 | `Ancient Gold Dragon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 10 | `Blood Moon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 11 | `Chandra's Ignition` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 12 | `Ghoulcaller's Bell` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 13 | `Karn, the Great Creator` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 14 | `Kayla's Music Box` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 15 | `Lantern of Insight` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 16 | `Leyline Dowser` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 17 | `Orcish Spy` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 18 | `Possibility Storm` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 19 | `Prototype Portal` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 20 | `Pyxis of Pandemonium` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |

## Package Blockers

### Hidden Retreat
- PG package `pg244` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg244_hidden_retreat_runtime_scope_20260628_v1_apply.sql`
- Missing package files: `apply`, `postcheck`, `precheck`, `rollback`
