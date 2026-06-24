# PG142 Apply Evidence

Generated at: `2026-06-24T04:28:00Z`

Applied package:

- `PG142`
- cards: `Jaxis, the Troublemaker`, `Rionya, Fire Dancer`, `The Jolly Balloon Man`
- families: `copy_creature_token=3`

## PostgreSQL

Oracle-hash-matched target rows:

- `Jaxis, the Troublemaker`: `target_card_rows=1`
- `Rionya, Fire Dancer`: `target_card_rows=1`
- `The Jolly Balloon Man`: `target_card_rows=1`

Apply result:

- `Jaxis, the Troublemaker` promoted as `battle_rule_v1:082e6fbdbbb20e5efed4de5cf8ab3bf1`
- `Rionya, Fire Dancer` promoted as `battle_rule_v1:c907c29d4de7bea750538d5110daa852`
- `The Jolly Balloon Man` promoted as `battle_rule_v1:e2ff37fab414ef5ed43b5dc17b921f63`
- prior shadow rows deprecated/disabled: `4`

Postcheck confirmed promoted rows:

- `Jaxis, the Troublemaker`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Rionya, Fire Dancer`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `The Jolly Balloon Man`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Backup table:

- `manaloom_deploy_audit.pg142_current_replay_copy_token_trio_two_20260624_042157`
- `backup_rows=4`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Jaxis, the Troublemaker' --only-card 'Rionya, Fire Dancer' --only-card 'The Jolly Balloon Man'`

Observed sync result:

- `selected_card_count=3`
- `sqlite_inserted_or_updated=7`
- `pg_rows_loaded=7`
- `canonical_snapshot_rows_exported=3216`

## Validation

Validated before PG apply:

- `test_xmage_to_manaloom_effect_hints.py`: `72` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `67` pass
- `test_reviewed_battle_card_rules.py`: `29` pass
- `test_battle_analyst_v10_3.py`: pass

Validated after adding static contract classification for the new end-step draw event:

- `test_battle_event_contract_static_audit.py`: `7 tests passed`
- `test_battle_action_critic.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- remaining gate signal: `event_contract_static_status=review_required`
- replay final status: `blocked`
- replay final reason: `one_or_more_mandatory_gates_blocked`

Static contract rerun after the classification hotfix:

- report: `pg142_event_contract_static_rerun_20260624_042318.json`
- `observed_unclassified_total=0`
- `static_unclassified_total=8`
- `end_step_token_death_draw_resolved` is no longer unclassified

## Residual After PG142

Pipeline artifacts:

- presync: `xmage_current_replay_batch_pipeline_20260624_pg142_presync_real_v1_manifest.json`
- postsync: `xmage_current_replay_batch_pipeline_20260624_pg142_postsync_real_v1_manifest.json`
- postaudit: `xmage_current_replay_batch_pipeline_20260624_pg142_postaudit_real_v1_manifest.json`

Residual summary after PG -> SQLite sync and the fresh audit:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=231`
- `runtime_family_implementation_required=9`
- `split_family_scope_review_required=1`

Delta versus pre-PG142 residual:

- runtime family queue reduced from `12` to `9`
- `Jaxis, the Troublemaker`, `Rionya, Fire Dancer`, and `The Jolly Balloon Man` left the residual queue

Remaining runtime-family cards:

- `Insidious Roots`
- `Eldrazi Confluence`
- `Knuckles the Echidna`
- `Springheart Nantuko`
- `Tataru Taru`
- `Magda, Brazen Outlaw`
- `Hazel's Brewmaster`
- `Patrol Signaler`
- `Treasure Vault`
