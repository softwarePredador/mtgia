# PG203 Recursion Lorehold 610 Gate Closure

Generated: 2026-06-25.

## Scope

- Cards: `Brilliant Restoration`, `Wake the Past`.
- Deck: `610`.
- Family: `recursion`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg203_recursion_lorehold_610_package_20260625_manifest.json`.

## XMage to ManaLoom Mapping

- `Brilliant Restoration`:
  `ReturnFromYourGraveyardToBattlefieldAllEffect(FilterArtifactOrEnchantmentCard)`
  maps to
  `return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1`.
- `Wake the Past`: custom `WakeThePastEffect` returns all artifact cards from
  controller graveyard to battlefield and grants haste until end of turn,
  mapped to
  `return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1`.

## PostgreSQL Evidence

- Precheck: both cards had `target_card_rows=1`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`.
- Apply: backup rows `4`, `deprecated_shadow_rows=4`, `upserted_rows=2`,
  `COMMIT`.
- Postcheck: each card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`,
  `backup_rows=4`.
- Rollback file retained:
  `docs/hermes-analysis/master_optimizer_reports/pg203_recursion_lorehold_610_package_20260625_rollback.sql`.

## Hermes Sync

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg203_recursion_lorehold_610_20260625.json`.
- `selected_card_count=2`.
- `pg_rows_loaded=6`.
- `sqlite_inserted_or_updated=6`.
- `canonical_snapshot_rows_exported=3242`.
- `generated_rows=2`.

## Post-Sync Matrix

- Matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg203_recursion_postsync_v1.json`.
- `rows=567`.
- `battle_ready=354`.
- `needs_rule_before_strategy=213`.
- Lorehold-touching `needs_rule_before_strategy` rows across decks `608`
  through `616`: `104`.
- Both PG203 cards moved to `priority_benchmark_candidate` with score `48.5`.

## Runtime and Gate

- `battle_analyst_v9` now supports recursion `grants_haste_until_eot`.
- Combat legality now blocks summoning-sick attackers without haste before
  strategic attack scoring; this closes the failed seed from the first PG203
  gate attempt where a same-turn `Clone Legion` copy token attacked.
- Final gate:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_045925/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `decision_audit_statuses={"turn_invariants_clean":16}`.
- `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`.
- `action_findings=0`.
- `event_contract_static_status=event_contract_static_ready`.
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`.
- `effect_coverage_residual_status=effect_coverage_residual_accepted`.

## Next

- Do not reuse PG203.
- Next package number is PG204.
- Continue Lorehold-first rule closure on the `104` remaining Lorehold-touching
  `needs_rule_before_strategy` rows before broad benchmark/deck swaps.
