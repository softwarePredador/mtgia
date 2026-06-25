# PG195 Battle Strategy Gate Closure - Young Pyromancer

Generated: 2026-06-25

Scope:

- Card: `Young Pyromancer`
- Logical rule key: `battle_rule_v1:8d0d283a016e6e8d51c0807ef0ae6cf9`
- Oracle hash: `aa19f3984202416be7c877fc90ca0a1b`
- Battle model scope: `instant_sorcery_cast_create_1_1_red_elemental_v1`
- Affected Lorehold decks: `612`, `616`

Implementation summary:

- Added exact XMage mapper for `YoungPyromancer` from
  `SpellCastControllerTriggeredAbility` + `CreateTokenEffect` +
  `RedElementalToken`.
- Added batch-safe classifier guard for only the exact
  1/1 red Elemental instant/sorcery cast trigger.
- Added focused battle runtime proof using the existing
  `instant_sorcery_cast` token-maker trigger path.

PostgreSQL evidence:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg195_young_pyromancer_package_20260625_package.md`
- Precheck:
  `target_card_rows=1`, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`.
- Apply:
  backup rows `2`, `deprecated_shadow_rows=2`, `upserted_rows=1`, `COMMIT`.
- Postcheck:
  `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=2`.
- PG -> Hermes sync:
  `selected_card_count=1`, `pg_rows_loaded=1`,
  `sqlite_inserted_or_updated=3`, `canonical_snapshot_rows_exported=3240`.

Matrix and deck evidence:

- Post-sync matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg195_young_pyromancer_postsync_v1.json`
- Matrix movement:
  `needs_rule_before_strategy=222`, `battle_ready=358`, `runtime_needed=18`.
- `Young Pyromancer` row:
  `rule_status=battle_ready`, `recommendation_lane=watchlist_candidate`,
  `executable_rule_count=1`, `deck_ids=[612,616]`.
- Deck audits:
  - deck `612`: `Young Pyromancer` is `pass/coherent_for_current_gate`.
  - deck `616`: `Young Pyromancer` is `pass/coherent_for_current_gate`.

Test evidence:

- `python3 -m py_compile ...`: pass.
- `test_xmage_to_manaloom_effect_hints.py`: 175 tests OK.
- `test_xmage_semantic_family_batch_pipeline.py`: 161 tests OK.
- `battle_card_specific_tests.py`: pass.
- `test_battle_analyst_v10_3.py`: pass.
- `battle_decision_trace_tests.py`: pass.
- `test_battle_event_contract_static_audit.py`: 7 tests passed.
- `test_battle_decision_trace_taxonomy_audit.py`: 3 tests passed.
- `test_battle_forensic_audit_supported_effects.py`: pass.
- `test_sync_battle_card_rules_pg_selection.py`: 16 tests OK.

Gate evidence:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_001857/summary.json`
- Command:
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 61592520`
- Result:
  `battle_replay_final_status=trusted_for_strategy_learning`
- Reason:
  `battle_replay_final_status_reason=all_mandatory_gates_pass`
- Mandatory gates:
  `mandatory_gate_divergences=[]`
- Event contract:
  `event_contract_static_status=event_contract_static_ready`
- Decision trace:
  `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`,
  `decision_trace_contract_findings=0`
- Forensic:
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`
- Test suite inside gate:
  `test_results_status_counts={"pass":18}`, `test_results_total=18`

Decision:

- PG195 is closed and must not be reused.
- Continue with PG196 from the remaining Lorehold `needs_rule_before_strategy`
  queue, prioritizing `Taii Wakeen, Perfect Shot`, `Deflecting Palm`,
  `Primal Amulet // Primal Wellspring`, `Squee, Goblin Nabob`, and
  `Goldspan Dragon`.
