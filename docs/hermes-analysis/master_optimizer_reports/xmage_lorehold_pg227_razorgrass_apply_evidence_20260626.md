# XMage Lorehold PG227 Razorgrass Apply Evidence (2026-06-26)

## Scope

- Card: `Razorgrass Ambush // Razorgrass Field`
- XMage class: `RazorgrassAmbush`
- Goal: split the Lorehold-facing `targeted_damage_variant_v1` scope into an exact MDFC scope with combat-only target legality, promote it through PostgreSQL, sync SQLite, and confirm the Lorehold matrix moves from `package_ready` to `battle_ready`.

## Local implementation

Updated runtime / mapper / classifier / tests:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Implemented scope:

- `damage_target_attacking_or_blocking_creature_or_tapped_white_land_v1`

Implemented runtime behavior:

- `direct_damage` now respects `target_constraints.combat_state`.
- Combat participants now carry transient `attacking` / `blocking` markers during combat only.
- Creature-only direct damage no longer falls back to damaging a player when no legal creature target exists.

## Focused validation

Executed on `2026-06-26`:

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
- Focused runtime invocation:
  `test_direct_damage_combat_restriction_only_hits_attacking_or_blocking_creatures`

Observed result:

- hints suite: `220 tests`, `OK`
- batch pipeline suite: `206 tests`, `OK`
- runtime focused test: `runtime_test_passed`

## Presync routing

Pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg227_razorgrass_loreholdscope_presync_v2_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg227_razorgrass_loreholdscope_presync_v2_proposals.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg227_razorgrass_loreholdscope_presync_v2_pattern_registry.json`

Key presync counts:

- `proposal_status_counts={"batch_pg_candidate_after_precheck": 1, "blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 268, "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck": 1, "runtime_family_implementation_required": 3, "split_family_scope_review_required": 22}`

Razorgrass presync status:

- `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
- `proposal_status=batch_pg_candidate_after_precheck`
- `safe_for_batch_pg_package=true`

Lorehold matrix presync:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg227_razorgrass_loreholdscope_presync_v1.json`

Matrix delta vs previous Bedlam postsync checkpoint:

- `needs_rule_before_strategy`: `82 -> 81`
- `split_scope`: `10 -> 9`
- `Razorgrass Ambush // Razorgrass Field`: `rule_status=package_ready`

## PostgreSQL package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_package.md`

Precheck output:

- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_precheck.out`
- result:
  - `target_card_rows=1`
  - `existing_rule_rows=2`
  - `expected_rule_rows_before=0`
  - `would_deprecate_shadow_rows=2`

Apply output:

- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_apply.out`
- result:
  - `deprecated_shadow_rows=2`
  - `upserted_rows=1`

Postcheck output:

- `docs/hermes-analysis/master_optimizer_reports/pg227_razorgrass_ambush_exact_scope_postcheck.out`
- result:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`
  - `backup_rows=2`

## SQLite sync

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg227_razorgrass_ambush_exact_scope_20260626.json`

Observed sync result:

- `selected_card_count=1`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=3253`

Tracked snapshot updated:

- `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Postsync routing

Pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg227_razorgrass_loreholdscope_postsync_v1_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg227_razorgrass_loreholdscope_postsync_v1_proposals.json`

Key postsync counts:

- `severity_counts={"critical": 1, "high": 253, "medium": 60, "pass": 490}`
- `proposal_status_counts={"blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 268, "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck": 1, "runtime_family_implementation_required": 3, "split_family_scope_review_required": 22}`

Lorehold matrix postsync:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg227_razorgrass_loreholdscope_postsync_v1.json`

Observed postsync matrix result:

- `rule_status_counts={"battle_ready": 314, "blocked_missing_xmage_source": 2, "mapper_manual": 70, "split_scope": 9}`
- `Razorgrass Ambush // Razorgrass Field`:
  - `rule_status=battle_ready`
  - `executable_rule_count=1`
  - `battle_rule_effects=["direct_damage"]`
  - `battle_model_scopes=["damage_target_attacking_or_blocking_creature_or_tapped_white_land_v1"]`
  - `recommendation_lane=watchlist_candidate`

## Remaining top split-scope Lorehold targets after PG227

- `Primal Amulet // Primal Wellspring`
- `Blood Sun`
- `Palantír of Orthanc`
- `Firesong and Sunspeaker`

## Conclusion

PG227 closed the `Razorgrass Ambush // Razorgrass Field` Lorehold split-scope lane end to end:

- exact XMage/ManaLoom scope implemented
- runtime legality added and tested
- package generated / prechecked / applied / postchecked
- SQLite canonical snapshot synced
- Lorehold matrix confirmed the card moved from `package_ready` to `battle_ready`
