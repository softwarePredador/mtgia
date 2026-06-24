# XMage Current Replay Batch Pipeline

Generated at: `2026-06-24T02:29:55+00:00`

- Artifact dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_020256`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck ids: `[6]`
- Learned deck ids: `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- Combined severity counts: `{"critical": 1, "high": 238, "medium": 38, "pass": 264}`
- Validity status counts: `{"blocked_missing_xmage_class": 3, "ready_for_structured_xmage_pull_review_required": 22, "xmage_source_valid_mapper_required": 237}`
- Family counts: `{"copy_creature_token": 2, "manual_model": 240, "token_maker": 18, "treasure_maker": 2}`
- Proposal status counts: `{"batch_pg_candidate_after_precheck": 3, "blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 237, "runtime_family_implementation_required": 18, "split_family_scope_review_required": 1}`

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

- `manifest_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_manifest.json`
- `manifest_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_manifest.md`
- `combined_coherence_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_combined_coherence.json`
- `combined_coherence_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_combined_coherence.md`
- `xmage_index_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_xmage_index.json`
- `xmage_index_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_xmage_index.md`
- `validity_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_validity.json`
- `validity_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_validity.md`
- `families_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_families.json`
- `families_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_families.md`
- `proposals_json`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_proposals.json`
- `proposals_md`: `xmage_current_replay_batch_pipeline_20260624_pg137_postsync_real_v5_proposals.md`
