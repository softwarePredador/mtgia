# PG143 Apply Evidence

Generated at: `2026-06-24T05:10:00Z`

Applied package:

- `PG143`
- cards: `Tataru Taru`
- families: `ramp_engine=1`

## PostgreSQL

Oracle-hash-matched target rows:

- `Tataru Taru`: `target_card_rows=1`

Apply result:

- `Tataru Taru` promoted as `battle_rule_v1:78e8097d6f3437e339ab729d87e5099a`
- prior shadow rows deprecated/disabled: `2`

Postcheck confirmed promoted row:

- `Tataru Taru`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Current PostgreSQL rule state:

- active verified auto row: `battle_rule_v1:78e8097d6f3437e339ab729d87e5099a`
- deprecated shadow rows: `battle_rule_v1:960ad0edc1ebb1be6c68610387478149`, `battle_rule_v1:faf0412d36f280c62b14904ec21807cc`

Backup table:

- `manaloom_deploy_audit.pg143_current_replay_tataru_taru_off_turn_treasure_20260`
- `backup_rows=2`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Tataru Taru'`

Observed sync result:

- `selected_card_count=1`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=3216`

SQLite verification:

- active verified auto row present for `battle_rule_v1:78e8097d6f3437e339ab729d87e5099a`
- `battle_model_scope=etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1`
- `trigger=opponent_draw`
- `treasure_tokens_tapped=true`
- `trigger_only_off_turn_opponent_draw=true`
- `trigger_limit_each_turn=1`

## Validation

Validated before PG apply:

- `test_xmage_to_manaloom_effect_hints.py`: `73` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `69` pass
- `test_reviewed_battle_card_rules.py`: `29` pass
- `test_battle_analyst_v10_3.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_050152`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- remaining gate signal: `event_contract_static_status=review_required`
- `battle_replay_final_status=blocked`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`

Static contract state in the new artifact:

- `observed_unclassified_total=0`
- `static_unclassified_total=8`

## Residual After PG143

Pipeline artifacts:

- presync: `xmage_current_replay_batch_pipeline_20260624_pg143_presync_real_v2_manifest.json`
- postsync: `xmage_current_replay_batch_pipeline_20260624_pg143_postsync_real_v1_manifest.json`
- postaudit: `xmage_current_replay_batch_pipeline_20260624_pg143_postaudit_real_v1_manifest.json`

Residual summary after PG -> SQLite sync and the fresh audit:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=231`
- `runtime_family_implementation_required=8`
- `split_family_scope_review_required=1`

Delta versus pre-PG143 residual:

- proposal count reduced from `244` to `243`
- safe batch candidates reduced from `1` to `0`
- `Tataru Taru` left the residual queue

Remaining runtime-family cards:

- `Insidious Roots`
- `Eldrazi Confluence`
- `Knuckles the Echidna`
- `Springheart Nantuko`
- `Magda, Brazen Outlaw`
- `Hazel's Brewmaster`
- `Patrol Signaler`
- `Treasure Vault`
