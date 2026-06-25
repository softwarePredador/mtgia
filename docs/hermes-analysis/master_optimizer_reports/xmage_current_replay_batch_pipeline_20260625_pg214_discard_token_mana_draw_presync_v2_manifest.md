# XMage Current Replay Batch Pipeline

Generated at: `2026-06-25T09:53:34+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_093405`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artifact deck ids: `[6]`
- Learned deck ids: `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- Forced include deck ids: `[6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Effective deck ids: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Combined severity counts: `{"critical": 1, "high": 380, "medium": 63, "pass": 519}`
- Validity status counts: `{"blocked_missing_xmage_class": 4, "ready_for_structured_xmage_pull_review_required": 88, "xmage_source_found_metadata_mismatch": 1, "xmage_source_valid_mapper_required": 332}`
- Family counts: `{"board_wipe_choice": 1, "controlled_creature_etb_damage_engine": 2, "creature": 5, "manual_model": 336, "mill_spell": 1, "modal_spell": 1, "recursion": 2, "static_cost_reducer": 2, "targeted_interaction": 58, "token_maker": 13, "tutor": 4}`
- Proposal status counts: `{"batch_pg_candidate_after_precheck": 2, "blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 333, "runtime_family_implementation_required": 12, "split_family_scope_review_required": 74}`
- Pattern status counts: `{"blocked_missing_xmage_source": 1, "candidate_template_requires_review_tests": 12, "fragmented_runtime_observation_only": 11, "manual_model_observation_only": 2, "ready_for_pg_package_generation": 2, "requires_subpattern_split_before_promotion": 10, "runtime_observation_requires_taxonomy": 1}`
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

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_manifest.json`
- `manifest_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_manifest.md`
- `combined_coherence_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_combined_coherence.json`
- `combined_coherence_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_combined_coherence.md`
- `xmage_index_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_xmage_index.json`
- `xmage_index_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_xmage_index.md`
- `validity_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_validity.json`
- `validity_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_validity.md`
- `families_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_families.json`
- `families_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_families.md`
- `proposals_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_proposals.json`
- `proposals_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_proposals.md`
- `pattern_registry_json`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_pattern_registry.json`
- `pattern_registry_md`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg214_discard_token_mana_draw_presync_v2_pattern_registry.md`
