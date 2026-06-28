# Lorehold Runtime Candidate Readiness - 2026-06-28

- Generated at: `2026-06-28T09:55:11Z`
- Runtime queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v6_current_miner.json`
- Access model: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260628_v2.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `66`
- Status counts: `{"manual_mapper_required": 52, "pg_package_prepared_pending_apply_approval": 1, "pg_precheck_blocked": 2, "review_required": 3, "runtime_model_blocked": 1, "split_scope_review_required": 7}`
- Promotion lanes: `{"access_density_candidate": 5, "batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 52, "split_family_scope_review_required": 7}`
- Cut-specific negatives: `2`
- Recommended next action: `rerun_pg245_precheck_then_sync_or_split_scope_runtime_families`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Twinflame Tyrant` | `pg_precheck_blocked` | `static_damage_modifier` | `batch_metadata_candidate_requires_pg_precheck` | `damage_modifier` | 1 | Rerun PostgreSQL precheck; do not apply package until every selected card has a matched card row. |
| 2 | `Verge Rangers` | `pg_precheck_blocked` | `topdeck_play` | `batch_metadata_candidate_requires_pg_precheck` | `topdeck_play` | 1 | Rerun PostgreSQL precheck; do not apply package until every selected card has a matched card row. |
| 3 | `Hidden Retreat` | `pg_package_prepared_pending_apply_approval` | `access_density` | `access_density_candidate` | `` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 4 | `Goliath Daydreamer` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | `Boros Reckoner` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | `Terror of the Peaks` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | `Balefire Liege` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 8 | `Firesong and Sunspeaker` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 9 | `Repercussion` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 10 | `Toralf, God of Fury // Toralf's Hammer` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `direct_damage` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 11 | `Ancient Copper Dragon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 12 | `Beacon of Immortality` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 13 | `Heroes Remembered` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 14 | `Invincible Hymn` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 15 | `Planetarium of Wan Shi Tong` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 16 | `Semblance Anvil` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 17 | `Taunt from the Rampart` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 18 | `Alhammarret's Archive` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 19 | `Ancient Gold Dragon` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 20 | `Assemble the Players` | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | `external_reference_required_manual_model` | 0 | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |

## Package Blockers

### Twinflame Tyrant
- PG package `PG245` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_apply.sql`
- Precheck blocker `postgres_precheck_blocked_connection_closed` at `precheck`: server closed the connection unexpectedly before precheck execution
- Negative swap `pg245_twinflame_damage_payoff_cut_thor` cut `Thor, God of Thunder`: `tested_negative_do_not_promote`, delta `-33.34` pp

### Verge Rangers
- PG package `PG245` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_apply.sql`
- Precheck blocker `postgres_precheck_blocked_connection_closed` at `precheck`: server closed the connection unexpectedly before precheck execution
- Negative swap `pg245_verge_rangers_topdeck_land_cut_waterskin` cut `Bender's Waterskin`: `tested_negative_do_not_promote`, delta `-100.0` pp

### Hidden Retreat
- PG package `pg244` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg244_hidden_retreat_runtime_scope_20260628_v1_apply.sql`
