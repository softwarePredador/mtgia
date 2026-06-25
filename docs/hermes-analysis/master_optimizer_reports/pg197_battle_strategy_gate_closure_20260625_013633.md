# PG197 Battle Strategy Gate Closure - Goldspan Dragon

Status: passed.

## Scope

- Card: `Goldspan Dragon`.
- Decks touched by current Lorehold matrix: `608`, `611`, `614`, `615`.
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/g/GoldspanDragon.java`.
- ManaLoom battle model scope:
  `goldspan_dragon_attack_or_target_treasure_double_mana_v1`.
- Logical rule key:
  `battle_rule_v1:dfaa0b9820c90a7835fb1fcb506ae9f3`.
- Oracle hash:
  `09b0aa8dc38ce303b42a28e2aece420e`.

## Runtime Implemented

- XMage mapper recognizes the exact Goldspan pattern:
  `OrTriggeredAbility` over `AttacksTriggeredAbility` and
  `BecomesTargetSourceTriggeredAbility`, with `CreateTokenEffect(new
  TreasureToken())`.
- Semantic classifier promotes only the exact Goldspan scope as batch-safe.
- Battle runtime now:
  - creates one Treasure when Goldspan attacks;
  - creates one Treasure when Goldspan becomes the target of a spell;
  - treats Treasures controlled by Goldspan's controller as producing two mana
    while Goldspan is on the battlefield;
  - emits `trigger_resolved` with rule provenance for both trigger paths.

## PostgreSQL Evidence

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg197_goldspan_dragon_package_20260625_package.md`.
- Precheck:
  `target_card_rows=1`, canonical card id
  `2581a523-f87a-4237-8029-20088a10ab98`,
  `existing_rule_rows=2`, `expected_rule_rows_before=0`,
  `would_deprecate_shadow_rows=2`.
- Apply:
  backup rows `2`, `deprecated_shadow_rows=2`, `upserted_rows=1`, `COMMIT`.
- Postcheck:
  `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=2`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg197_goldspan_dragon_package_20260625_rollback.sql`.

## Sync And Matrix Evidence

- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg197_goldspan_dragon_20260625.json`.
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg197_goldspan_dragon_evidence_20260625/sync_pg_to_sqlite.json`;
  `selected_card_count=1`, `pg_rows_loaded=1`,
  `sqlite_inserted_or_updated=3`, `canonical_snapshot_rows_exported=3240`.
- Runtime cache verification:
  `get_card_effect("Goldspan Dragon")` returns
  `review_status=verified`, `execution_status=auto`,
  `treasure_mana_value=2`, and both attack/spell-target Treasure triggers.
- Post-sync pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg197_goldspan_postsync_v1_manifest.json`;
  expanded scope moved to `high=400`, `medium=63`, `pass=499`.
- Post-sync matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg197_goldspan_postsync_v1.json`;
  scoped rows `567`, `battle_ready=347`,
  `needs_rule_before_strategy=220`, `runtime_needed=17`,
  `mapper_manual=144`, `split_scope=55`.
- Strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg197_goldspan_postsync_v1.json`;
  `18/18` checks passed.

## Deck Coherence

Affected deck audits:

- `docs/hermes-analysis/master_optimizer_reports/deck608_battle_rule_coherence_pg197_goldspan_postsync_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/deck611_battle_rule_coherence_pg197_goldspan_postsync_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/deck614_battle_rule_coherence_pg197_goldspan_postsync_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/deck615_battle_rule_coherence_pg197_goldspan_postsync_v1.json`

All four report `Goldspan Dragon` as `pass/coherent_for_current_gate` with
`trusted_executable_rule_count=1`.

## Tests

- `python3 -m py_compile ...` passed for mapper, classifier, runtime, and tests.
- `test_xmage_to_manaloom_effect_hints.py`: `177` tests OK.
- `test_xmage_semantic_family_batch_pipeline.py`: `163` tests OK.
- `battle_card_specific_tests.py`: passed and includes
  `test_pg197_goldspan_attack_and_spell_target_create_double_mana_treasures`.
- `test_battle_analyst_v10_3.py`: passed.
- `test_battle_event_contract_static_audit.py`: `7` tests passed.
- `test_battle_forensic_audit_supported_effects.py`: passed.

## Battle Strategy Gate

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_013633/summary.json`.
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

Current next Lorehold-touching `needs_rule_before_strategy` items after PG197:

- `Surly Badgersaur` - `runtime_needed`, decks `608/617`.
- `Taii Wakeen, Perfect Shot` - `split_scope`, deck `612`.
- `Trouble in Pairs` - `split_scope`, decks `614/619`.
- `Deflecting Palm` - `mapper_manual`, decks `614/615/616`.
- `Primal Amulet // Primal Wellspring` - `split_scope`, decks `610/615`.

