# XMage Current Replay Batch Pipeline

Generated at: `2026-06-24T20:23:10+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_193554`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artifact deck ids: `[6]`
- Learned deck ids: `[58, 74, 105]`
- Forced include deck ids: `[6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Effective deck ids: `[6, 58, 74, 105, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Combined severity counts: `{"high": 328, "medium": 54, "pass": 327}`
- Validity status counts: `{"blocked_missing_xmage_class": 4, "ready_for_structured_xmage_pull_review_required": 104, "xmage_source_found_metadata_mismatch": 1, "xmage_source_valid_mapper_required": 260}`
- Family counts: `{"board_wipe_choice": 4, "creature": 4, "manual_model": 264, "mill_spell": 1, "static_cost_reducer": 2, "targeted_interaction": 69, "token_maker": 21, "tutor": 4}`
- Proposal status counts: `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 261, "runtime_family_implementation_required": 24, "split_family_scope_review_required": 80}`
- Pattern status counts: `{"blocked_missing_xmage_source": 1, "candidate_template_requires_review_tests": 9, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 2, "requires_subpattern_split_before_promotion": 10, "runtime_template_candidate_requires_executor_tests": 2}`
- Pattern promotion status: `shadow_only`

## Materialized Learned Decks

| learned_deck_id | target_deck_id | deck_name | rows | quantity | oracle_rows |
| --- | ---: | --- | ---: | ---: | ---: |
| 58 | 58 | `Thrasios, Triton Hero + Vial Smasher the Fierce` | 100 | 100 | 100 |
| 74 | 74 | `Dargo, the Shipwrecker + Tymna the Weaver` | 100 | 100 | 100 |
| 105 | 105 | `Etali, Primal Conqueror` | 100 | 100 | 100 |

## Output Files

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_manifest.json`
- `manifest_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_manifest.md`
- `combined_coherence_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_combined_coherence.json`
- `combined_coherence_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_combined_coherence.md`
- `xmage_index_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_xmage_index.json`
- `xmage_index_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_xmage_index.md`
- `validity_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_validity.json`
- `validity_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_validity.md`
- `families_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_families.json`
- `families_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_families.md`
- `proposals_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_proposals.json`
- `proposals_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_proposals.md`
- `pattern_registry_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_pattern_registry.json`
- `pattern_registry_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_pattern_registry.md`
