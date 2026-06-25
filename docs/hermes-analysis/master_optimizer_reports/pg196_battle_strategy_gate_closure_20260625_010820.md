# PG196 Battle Strategy Gate Closure - Squee, Goblin Nabob

Date: 2026-06-25

Artifact:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_010820`

## Scope

- Primary card: `Squee, Goblin Nabob`.
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SqueeGoblinNabob.java`.
- XMage family:
  graveyard beginning-of-upkeep optional self-return to hand.
- ManaLoom scope:
  `graveyard_upkeep_return_self_to_hand_v1`.
- Logical rule:
  `battle_rule_v1:4565272d5decc69322e01a4f919df77e`.
- Oracle hash:
  `f8f6891272310b0d70a2b23621f7ea5d`.

## PostgreSQL And Sync Evidence

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg196_squee_goblin_nabob_package_20260625_package.md`.
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg196_squee_goblin_nabob_package_20260625_apply.sql`.
- Precheck:
  `target_card_rows=1`, `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`.
- Apply:
  `deprecated_shadow_rows=2`, `upserted_rows=1`, `COMMIT`.
- Postcheck:
  `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=2`.
- PG -> SQLite sync:
  `selected_card_count=1`, `pg_rows_loaded=1`,
  `sqlite_inserted_or_updated=3`,
  `canonical_snapshot_rows_exported=3240`.

## Runtime/Test Evidence

- `Squee, Goblin Nabob` focused runtime test passed:
  `test_pg196_squee_returns_from_graveyard_to_hand_on_upkeep`.
- Mapper tests: `176` tests OK.
- Classifier tests: `162` tests OK.
- Battle integrated test suite:
  `test_battle_analyst_v10_3.py` passed, including Squee and Teferi
  regression coverage.
- Event contract tests: `7` tests passed.
- Forensic supported-effect tests passed and now include `planeswalker`.

## Matrix And Deck Evidence

- Post-sync pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg196_squee_postsync_v1_manifest.json`;
  severity counts: `critical=1`, `high=391`, `medium=59`, `pass=486`.
- Lorehold candidate matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg196_squee_postsync_v1.json`;
  rows `567`, `battle_ready=346`,
  `needs_rule_before_strategy=221`, `runtime_needed=18`,
  `mapper_manual=144`, `split_scope=55`.
- Strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg196_squee_postsync_v1.json`;
  `18/18` checks passed.
- Deck `609` coherence:
  `total_cards=92`, `severity_counts={"high":17,"medium":8,"pass":67}`;
  Squee is `pass/coherent_for_current_gate`.
- Deck `610` coherence:
  `total_cards=95`, `severity_counts={"high":37,"medium":7,"pass":51}`;
  Squee is `pass/coherent_for_current_gate`.

## Gate Result

Final gate artifact:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_010820/summary.json`

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

## Side Runtime Closure

The first PG196 gate attempt found a real replayed `Teferi, Time Raveler`
resolution blocked by missing planeswalker runtime/audit contract coverage. The
runtime now resolves `effect="planeswalker"` cards as battlefield permanents,
emits `planeswalker_resolved`, and registers `planeswalker` in forensic support.

The final gate observed `planeswalker_resolved` in seed `61592609` and accepted
the event contract with no unclassified observed or static event types.

## Decision

PG196 is closed for the current Lorehold rule-readiness lane. Continue with
PG197 from the remaining `needs_rule_before_strategy` matrix candidates.
