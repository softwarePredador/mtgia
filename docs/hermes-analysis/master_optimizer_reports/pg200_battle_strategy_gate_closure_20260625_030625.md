# PG200 Battle Strategy Gate Closure - Trouble in Pairs

PG200 promoted `Trouble in Pairs` from XMage source into a verified ManaLoom
battle rule and closed the full recurring battle strategy gate.

## Rule Scope

- Card: `Trouble in Pairs`
- Decks: `614`, `619`
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TroubleInPairs.java`
- ManaLoom scope:
  `opponent_second_draw_second_spell_two_attackers_draw_v1`
- Logical rule key:
  `battle_rule_v1:4dce5bd251b51b0a4330813cca8bd1f5`
- Oracle hash:
  `518401cdd0b7850a6e29a0ec1c0b5935`

## Runtime Coverage

The battle runtime now models the exact Trouble in Pairs behavior:

- opponent second card draw each turn draws one card for the controller;
- opponent second spell each turn draws one card for the controller with no tax;
- opponent attack with two or more creatures at the controller draws one card;
- opponent extra turns are skipped while the enchantment is controlled.

## PostgreSQL And Sync Evidence

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
  `sqlite_inserted_or_updated=3`, `canonical_snapshot_rows_exported=3241`.

## Post-Sync Audits

- Post-sync pipeline:
  `high=397`, `medium=63`, `pass=502`, no remaining PG200 candidate.
- Matrix:
  `rows=567`, `battle_ready=350`, `needs_rule_before_strategy=217`,
  `runtime_needed=16`, `mapper_manual=144`, `split_scope=53`.
- Deck coherence:
  decks `614` and `619` both report `Trouble in Pairs` as
  `pass/coherent_for_current_gate`.
- Strategy consistency:
  `18/18` checks passed.

## Gate Result

Gate artifact:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_030625/summary.json`

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `event_contract_static_status=event_contract_static_ready`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_trace_contract_findings=0`
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`
- `test_results_status_counts={"pass":18}`
- `seeds_completed=16`
- `seeds_requested=16`

An earlier run artifact
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_025859`
was intentionally not used as closure evidence because the wrapper was
interrupted before writing `summary.json`; the successful closure is
`20260625_030625`.
