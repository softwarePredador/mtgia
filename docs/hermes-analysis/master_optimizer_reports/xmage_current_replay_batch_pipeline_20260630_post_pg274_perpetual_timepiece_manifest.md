# XMage Current Replay Batch Pipeline

Generated at: `2026-06-30T10:16:04+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_111525`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artifact deck ids: `[6]`
- Learned deck ids: `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- Forced include deck ids: `[6, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Effective deck ids: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Combined severity counts: `{"high": 100, "medium": 42, "pass": 649}`
- Validity status counts: `{"ready_for_structured_xmage_pull_review_required": 66, "xmage_source_valid_mapper_required": 61}`
- Family counts: `{"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 2, "free_cast": 9, "life_total_change": 1, "manual_model": 61, "passive": 5, "ramp_permanent": 5, "recursion": 9, "targeted_interaction": 12, "targeted_protection": 7, "topdeck_play": 2, "tutor": 10}`
- Proposal status counts: `{"mapper_metadata_or_test_scenario_required": 61, "split_family_scope_review_required": 66}`
- Pattern status counts: `{"candidate_template_requires_review_tests": 9, "manual_model_observation_only": 1, "requires_subpattern_split_before_promotion": 10}`
- Pattern promotion status: `shadow_only`

## Materialized Learned Decks

| learned_deck_id | target_deck_id | deck_name | rows | quantity | oracle_rows |
| --- | ---: | --- | ---: | ---: | ---: |
| 25 | 25 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |
| 31 | 31 | `Sisay, Weatherlight Captain` | 100 | 100 | 100 |
| 42 | 42 | `The Emperor of Palamecia` | 80 | 100 | 80 |
| 54 | 54 | `Thrasios, Triton Hero + Tymna the Weaver` | 100 | 100 | 100 |
| 58 | 58 | `Thrasios, Triton Hero + Vial Smasher the Fierce` | 100 | 100 | 100 |
| 62 | 62 | `Rograkh, Son of Rohgahh + Thrasios, Triton Hero` | 100 | 100 | 100 |
| 74 | 74 | `Dargo, the Shipwrecker + Tymna the Weaver` | 100 | 100 | 100 |
| 83 | 83 | `Kraum, Ludevic's Opus + Tymna the Weaver` | 100 | 100 | 100 |
| 84 | 84 | `Kinnan, Bonder Prodigy` | 100 | 100 | 100 |
| 104 | 104 | `Kinnan, Bonder Prodigy` | 94 | 100 | 94 |
| 105 | 105 | `Etali, Primal Conqueror` | 100 | 100 | 100 |
| 116 | 116 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |

## Output Files

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_manifest.json`
- `manifest_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_manifest.md`
- `combined_coherence_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_combined_coherence.json`
- `combined_coherence_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_combined_coherence.md`
- `xmage_index_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_xmage_index.json`
- `xmage_index_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_xmage_index.md`
- `validity_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_validity.json`
- `validity_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_validity.md`
- `families_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_families.json`
- `families_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_families.md`
- `proposals_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_proposals.json`
- `proposals_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_proposals.md`
- `pattern_registry_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_pattern_registry.json`
- `pattern_registry_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg274_perpetual_timepiece_pattern_registry.md`
