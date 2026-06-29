# XMage Current Replay Batch Pipeline

Generated at: `2026-06-29T17:33:14+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_111525`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artifact deck ids: `[6]`
- Learned deck ids: `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- Forced include deck ids: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Effective deck ids: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Combined severity counts: `{"critical": 1, "high": 108, "medium": 48, "pass": 634}`
- Validity status counts: `{"ready_for_structured_xmage_pull_review_required": 76, "xmage_source_valid_mapper_required": 63}`
- Family counts: `{"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 4, "free_cast": 9, "life_total_change": 1, "manual_model": 63, "passive": 5, "ramp_engine": 1, "ramp_permanent": 6, "ramp_ritual": 2, "recursion": 11, "targeted_interaction": 12, "targeted_protection": 8, "topdeck_play": 3, "tutor": 10}`
- Proposal status counts: `{"batch_pg_candidate_after_precheck": 1, "mapper_metadata_or_test_scenario_required": 63, "split_family_scope_review_required": 75}`
- Pattern status counts: `{"candidate_template_requires_review_tests": 8, "manual_model_observation_only": 1, "ready_for_pg_package_generation": 1, "requires_subpattern_split_before_promotion": 12}`
- Pattern promotion status: `shadow_only`

## Materialized Learned Decks

| learned_deck_id | target_deck_id | deck_name | rows | quantity | oracle_rows |
| --- | ---: | --- | ---: | ---: | ---: |
| 25 | 25 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |
| 31 | 31 | `Sisay, Weatherlight Captain` | 100 | 100 | 100 |
| 42 | 42 | `The Emperor of Palamecia` | 80 | 100 | 80 |
| 54 | 54 | `Thrasios, Triton Hero + Tymna the Weaver` | 100 | 100 | 99 |
| 58 | 58 | `Thrasios, Triton Hero + Vial Smasher the Fierce` | 100 | 100 | 100 |
| 62 | 62 | `Rograkh, Son of Rohgahh + Thrasios, Triton Hero` | 100 | 100 | 100 |
| 74 | 74 | `Dargo, the Shipwrecker + Tymna the Weaver` | 100 | 100 | 100 |
| 83 | 83 | `Kraum, Ludevic's Opus + Tymna the Weaver` | 100 | 100 | 100 |
| 84 | 84 | `Kinnan, Bonder Prodigy` | 100 | 100 | 100 |
| 104 | 104 | `Kinnan, Bonder Prodigy` | 94 | 100 | 94 |
| 105 | 105 | `Etali, Primal Conqueror` | 100 | 100 | 100 |
| 116 | 116 | `Tayam, Luminous Enigma` | 100 | 100 | 100 |

## Output Files

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_manifest.json`
- `manifest_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_manifest.md`
- `combined_coherence_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_combined_coherence.json`
- `combined_coherence_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_combined_coherence.md`
- `xmage_index_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_xmage_index.json`
- `xmage_index_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_xmage_index.md`
- `validity_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_validity.json`
- `validity_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_validity.md`
- `families_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_families.json`
- `families_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_families.md`
- `proposals_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_proposals.json`
- `proposals_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_proposals.md`
- `pattern_registry_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_pattern_registry.json`
- `pattern_registry_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1733_pg261_electro_mapper_pattern_registry.md`
