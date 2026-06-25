# PG198 Battle Strategy Gate Closure - Surly Badgersaur

Status: passed.

## Scope

- Card: `Surly Badgersaur`.
- Decks touched by current Lorehold matrix: `608`, `617`.
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SurlyBadgersaur.java`.
- ManaLoom battle model scope:
  `surly_badgersaur_discard_card_type_triggers_v1`.
- Logical rule key:
  `battle_rule_v1:a4b42e4cef8bbab31819346e7b68a263`.
- Oracle hash:
  `14e07cfa7107a44732b5631f2136be3e`.

## Runtime Implemented

- XMage mapper recognizes the exact Surly Badgersaur structure:
  `DiscardCardControllerTriggeredAbility` split over creature, land, and
  noncreature/nonland discarded-card filters.
- Semantic classifier promotes only the exact Surly scope as batch-safe.
- Battle runtime now:
  - adds one +1/+1 counter when the controller discards a creature card;
  - creates one Treasure when the controller discards a land card;
  - resolves an optional fight against a beneficial opponent creature when the
    controller discards a noncreature, nonland card;
  - emits `trigger_resolved` with rule provenance for all three discard paths.

## PostgreSQL Evidence

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg198_surly_badgersaur_package_20260625_package.md`.
- Precheck:
  `target_card_rows=1`, canonical card id
  `efe36db9-c638-4388-905f-e4d2ddf93065`,
  `existing_rule_rows=2`, `expected_rule_rows_before=0`,
  `would_deprecate_shadow_rows=2`.
- Apply:
  backup rows `2`, `deprecated_shadow_rows=2`, `upserted_rows=1`, `COMMIT`.
- Postcheck:
  `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=2`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg198_surly_badgersaur_package_20260625_rollback.sql`.

## Sync And Matrix Evidence

- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg198_surly_badgersaur_20260625.json`.
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg198_surly_badgersaur_evidence_20260625/sync_pg_to_sqlite.json`;
  `selected_card_count=1`, `pg_rows_loaded=1`,
  `sqlite_inserted_or_updated=3`, `canonical_snapshot_rows_exported=3240`.
- Runtime cache verification:
  `get_card_effect("Surly Badgersaur")` returns
  `review_status=verified`, `execution_status=auto`,
  `controller_discard_creature_add_plus_one_counter=true`,
  `controller_discard_land_create_treasure=true`, and
  `controller_discard_noncreature_nonland_fight=true`.
- Post-sync pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg198_surly_badgersaur_postsync_v1_manifest.json`;
  expanded scope moved to `high=399`, `medium=63`, `pass=500`.
- Post-sync matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg198_surly_badgersaur_postsync_v1.json`;
  scoped rows `567`, `battle_ready=348`,
  `needs_rule_before_strategy=219`, `runtime_needed=16`,
  `mapper_manual=144`, `split_scope=55`.
- Strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg198_surly_badgersaur_postsync_v1.json`;
  `18/18` checks passed.

## Deck Coherence

Affected deck audits:

- `docs/hermes-analysis/master_optimizer_reports/deck608_battle_rule_coherence_pg198_surly_badgersaur_postsync_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/deck617_battle_rule_coherence_pg198_surly_badgersaur_postsync_v1.json`

Both report `Surly Badgersaur` as `pass/coherent_for_current_gate` with
`trusted_executable_rule_count=1`.

## Tests

- `python3 -m py_compile ...` passed for mapper, classifier, runtime, and tests.
- `test_xmage_to_manaloom_effect_hints.py`: `178` tests OK.
- `test_xmage_semantic_family_batch_pipeline.py`: `164` tests OK.
- `battle_card_specific_tests.py`: passed and includes
  `test_pg198_surly_badgersaur_discard_card_type_triggers_counter_treasure_and_fight`.
- `test_battle_analyst_v10_3.py`: passed.
- `test_battle_event_contract_static_audit.py`: `7` tests passed.
- `test_battle_forensic_audit_supported_effects.py`: passed.

## Battle Strategy Gate

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_015839/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `event_contract_static_status=event_contract_static_ready`.
- `forensic_rule_findings=0`.
- `forensic_turn_findings=0`.
- `decision_audit_decision_findings=0`.
- `decision_trace_contract_findings=0`.
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`.
- `test_results_status_counts={"pass":18}`.

## Next Queue

Current next Lorehold-touching `needs_rule_before_strategy` items after PG198:

- `Taii Wakeen, Perfect Shot` - `split_scope`, deck `612`.
- `Trouble in Pairs` - `split_scope`, decks `614/619`.
- `Deflecting Palm` - `mapper_manual`, decks `614/615/616`.
- `Primal Amulet // Primal Wellspring` - `split_scope`, decks `610/615`.
- `Redress Fate` - `mapper_manual`, deck `610`.

