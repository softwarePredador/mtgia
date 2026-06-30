# Lorehold Runtime Candidate Readiness - 2026-06-30

- Generated at: `2026-06-30T13:47:51Z`
- Runtime queue: `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_agent3_runtime_finisher_draw_recursion.json`
- Access model: `/Users/desenvolvimentomobile/.codex/worktrees/lorehold-agent3-runtime-finisher-draw-recursion/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/.codex/worktrees/lorehold-agent3-runtime-finisher-draw-recursion/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/.codex/worktrees/lorehold-agent3-runtime-finisher-draw-recursion/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `66`
- Status counts: `{"manual_mapper_required": 16, "pg_package_prepared_pending_apply_approval": 10, "review_required": 20, "split_scope_review_required": 18, "swap_negative_not_card_global_reject": 2}`
- Promotion lanes: `{"access_density_candidate": 5, "batch_metadata_candidate_requires_pg_precheck": 23, "mapper_metadata_or_test_scenario_required": 16, "split_family_scope_review_required": 22}`
- Cut-specific negatives: `2`
- Recommended next action: `run_approved_precheck_apply_postcheck_sync_or_split_scope_runtime_families`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Brainstone` | `pg_package_prepared_pending_apply_approval` | `access_density` | `access_density_candidate` | `` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 2 | `Hidden Retreat` | `pg_package_prepared_pending_apply_approval` | `access_density` | `access_density_candidate` | `` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 3 | `Assemble the Players` | `pg_package_prepared_pending_apply_approval` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 4 | `Chaos Wand` | `pg_package_prepared_pending_apply_approval` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 5 | `Codex Shredder` | `pg_package_prepared_pending_apply_approval` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 6 | `Ghoulcaller's Bell` | `pg_package_prepared_pending_apply_approval` | `mill_spell` | `batch_metadata_candidate_requires_pg_precheck` | `mill_engine` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 7 | `Kayla's Music Box` | `pg_package_prepared_pending_apply_approval` | `free_cast` | `batch_metadata_candidate_requires_pg_precheck` | `free_cast` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 8 | `Lantern of Insight` | `pg_package_prepared_pending_apply_approval` | `topdeck_play` | `batch_metadata_candidate_requires_pg_precheck` | `topdeck_play` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 9 | `Perpetual Timepiece` | `pg_package_prepared_pending_apply_approval` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 10 | `Possibility Storm` | `pg_package_prepared_pending_apply_approval` | `free_cast` | `batch_metadata_candidate_requires_pg_precheck` | `free_cast` | 0 | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 11 | `Heroes Remembered` | `split_scope_review_required` | `life_total_change` | `split_family_scope_review_required` | `life_gain` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 12 | `Blood Moon` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 13 | `Deathbellow War Cry` | `split_scope_review_required` | `tutor` | `split_family_scope_review_required` | `tutor` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 14 | `Ephemerate` | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | `blink` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 15 | `Karn's Sylex` | `split_scope_review_required` | `board_wipe_choice` | `split_family_scope_review_required` | `board_wipe` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 16 | `Karn, the Great Creator` | `split_scope_review_required` | `passive` | `split_family_scope_review_required` | `passive` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 17 | `Leyline Dowser` | `split_scope_review_required` | `recursion` | `split_family_scope_review_required` | `recursion` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 18 | `Orcish Spy` | `split_scope_review_required` | `topdeck_play` | `split_family_scope_review_required` | `topdeck_play` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 19 | `Prototype Portal` | `split_scope_review_required` | `token_maker` | `split_family_scope_review_required` | `token_maker` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |
| 20 | `Pyxis of Pandemonium` | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | `free_cast` | 0 | Split the family scope and write focused runtime tests before creating a metadata package. |

## Package Evidence And Blockers

### Brainstone
- PG package `pg272_brainstone_executable_topdeck_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`

### Hidden Retreat
- PG package `pg271` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`

### Assemble the Players
- PG package `PG276` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_apply.sql`

### Chaos Wand
- PG package `PG275` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_apply.sql`

### Codex Shredder
- PG package `pg273_codex_shredder_mill_recursion_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_apply.sql`

### Ghoulcaller's Bell
- PG package `PG277` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg277_ghoulcaller_each_player_mill_20260630_apply.sql`

### Kayla's Music Box
- PG package `PG280` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg280_kayla_music_box_exile_play_20260630_apply.sql`

### Lantern of Insight
- PG package `PG278` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg278_lantern_top_reveal_shuffle_20260630_apply.sql`

### Perpetual Timepiece
- PG package `pg274_perpetual_timepiece_graveyard_shuffle_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_apply.sql`

### Possibility Storm
- PG package `PG279` status `prepared_read_only_pending_apply_approval`; apply `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_apply.sql`

### Twinflame Tyrant
- Negative swap `pg245_twinflame_damage_payoff_cut_thor` cut `Thor, God of Thunder`: `tested_negative_do_not_promote`, delta `-33.34` pp

### Verge Rangers
- Negative swap `pg245_verge_rangers_topdeck_land_cut_waterskin` cut `Bender's Waterskin`: `tested_negative_do_not_promote`, delta `-100.0` pp
