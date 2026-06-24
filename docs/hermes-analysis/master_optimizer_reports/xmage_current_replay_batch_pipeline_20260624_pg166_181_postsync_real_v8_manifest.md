# XMage Current Replay Batch Pipeline

Generated at: `2026-06-24T15:32:14+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artifact deck ids: `[6]`
- Learned deck ids: `[25, 31, 42, 58, 62, 74, 83, 84, 104, 105, 116]`
- Forced include deck ids: `[6, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Effective deck ids: `[6, 25, 31, 42, 58, 62, 74, 83, 84, 104, 105, 116, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Combined severity counts: `{"high": 405, "medium": 67, "pass": 458}`
- Validity status counts: `{"blocked_missing_xmage_class": 2, "ready_for_structured_xmage_pull_review_required": 92, "xmage_source_found_metadata_mismatch": 1, "xmage_source_valid_mapper_required": 351}`
- Family counts: `{"board_wipe_choice": 4, "manual_model": 353, "static_cost_reducer": 2, "targeted_interaction": 66, "token_maker": 21}`
- Proposal status counts: `{"blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 352, "runtime_family_implementation_required": 24, "split_family_scope_review_required": 68}`
- Pattern status counts: `{"blocked_missing_xmage_source": 1, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 2, "requires_subpattern_split_before_promotion": 9, "runtime_template_candidate_requires_executor_tests": 2}`
- Pattern promotion status: `shadow_only`

## Materialized Learned Decks

| learned_deck_id | target_deck_id | deck_name | rows | quantity | oracle_rows |
| --- | ---: | --- | ---: | ---: | ---: |
| 25 | 25 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |
| 31 | 31 | `Sisay, Weatherlight Captain` | 100 | 100 | 100 |
| 42 | 42 | `The Emperor of Palamecia` | 80 | 100 | 80 |
| 58 | 58 | `Thrasios, Triton Hero + Vial Smasher the Fierce` | 100 | 100 | 100 |
| 62 | 62 | `Rograkh, Son of Rohgahh + Thrasios, Triton Hero` | 100 | 100 | 100 |
| 74 | 74 | `Dargo, the Shipwrecker + Tymna the Weaver` | 100 | 100 | 100 |
| 83 | 83 | `Kraum, Ludevic's Opus + Tymna the Weaver` | 100 | 100 | 100 |
| 84 | 84 | `Kinnan, Bonder Prodigy` | 100 | 100 | 100 |
| 104 | 104 | `Kinnan, Bonder Prodigy` | 94 | 100 | 94 |
| 105 | 105 | `Etali, Primal Conqueror` | 100 | 100 | 100 |
| 116 | 116 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |

## Output Files

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_manifest.json`
- `manifest_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_manifest.md`
- `combined_coherence_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_combined_coherence.json`
- `combined_coherence_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_combined_coherence.md`
- `xmage_index_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_xmage_index.json`
- `xmage_index_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_xmage_index.md`
- `validity_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_validity.json`
- `validity_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_validity.md`
- `families_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_families.json`
- `families_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_families.md`
- `proposals_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_proposals.json`
- `proposals_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_proposals.md`
- `pattern_registry_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_pattern_registry.json`
- `pattern_registry_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_pattern_registry.md`
