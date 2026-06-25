# PG194 Glint-Horn Buccaneer Closure

Status: `applied_postchecked_synced_validated`.

Scope:

- Card: `Glint-Horn Buccaneer`
- Decks touched by matrix: `613`, `617`
- Promoted rule:
  `battle_rule_v1:ebffa5caeecaa96b52e0d4b5307874fe`
- Oracle hash: `8b64e70b97f5871e2203d6cabed377b4`
- Battle model scope:
  `glint_horn_buccaneer_discard_damage_attack_loot_v1`

Runtime closure:

- Added `resolve_attacking_discard_draw_activations`.
- The activation is legal only for declared attackers.
- The resolver pays `{1}{R}`, discards one card through
  `resolve_effect_discard_cards`, lets controller-discard triggers resolve, and
  then draws one card.
- Replay events use existing contract names:
  `activated_ability` and `activated_ability_skipped`, with
  `activation_kind=attacking_discard_draw`.

PostgreSQL package:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_package_20260624_package.md`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_evidence_20260624/precheck.txt`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_evidence_20260624/apply.txt`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_evidence_20260624/postcheck.txt`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_package_20260624_rollback.sql`

PostgreSQL evidence:

- Precheck: `target_card_rows=1`, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`.
- Apply: `deprecated_shadow_rows=2`, `upserted_rows=1`, `COMMIT`.
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=2`.

Hermes and audit evidence:

- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/pg194_glint_horn_buccaneer_evidence_20260624/sync_pg_to_sqlite.json`
- Canonical SQLite snapshot:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg194_glint_horn_20260624.json`
- Post-sync pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg194_glint_horn_postsync_v1_manifest.json`
- Post-sync matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_pg194_glint_horn_postsync_v1.json`
- Deck 613 audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck613_pg194_glint_horn_20260624.json`
- Final gate:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_235850/summary.json`

Final gate summary:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `event_contract_static_status=event_contract_static_ready`
- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `test_results_status_counts={"pass":18}`
