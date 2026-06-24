# PG140 Apply Evidence

Generated at: `2026-06-24T03:40:00Z`

Applied package:

- `PG140`
- cards: `Impulsive Pilferer`
- families: `creature=1`

## PostgreSQL

Oracle-hash-matched target rows:

- `Impulsive Pilferer`: `target_card_rows=1`

Apply result:

- promoted row inserted as `battle_rule_v1:dee9ffe02f85f08536dbd78b3ed9217c`
- prior shadow rows deprecated/disabled: `2`

Postcheck confirmed promoted row:

- `Impulsive Pilferer`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Backup table:

- `manaloom_deploy_audit.pg140_current_replay_batch_three_impulsive_pilferer_2026`
- `backup_rows=2`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Impulsive Pilferer'`

Observed sync result:

- `selected_card_count=1`
- `sqlite_inserted_or_updated=3`
- `pg_rows_loaded=3`
- `canonical_snapshot_rows_exported=3212`

## Validation

Validated after PG -> SQLite sync:

- `test_xmage_to_manaloom_effect_hints.py`: `65` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `61` pass
- `test_reviewed_battle_card_rules.py`: `29` pass
- `test_battle_analyst_v10_3.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_033214`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- remaining gate signal: `event_contract_static_status=review_required`

## Residual After PG140

Pipeline artifacts:

- postsync: `xmage_current_replay_batch_pipeline_20260624_pg140_postsync_real_v3_manifest.json`
- postaudit: `xmage_current_replay_batch_pipeline_20260624_pg140_postaudit_real_v4_manifest.json`

Residual summary after the fresh audit:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=237`
- `runtime_family_implementation_required=15`
- `split_family_scope_review_required=1`

Delta versus post-PG139 residual:

- runtime family queue reduced from `16` to `15`
- `Impulsive Pilferer` left the residual queue

Remaining runtime-family cards:

- `Insidious Roots`
- `Eldrazi Confluence`
- `Jaxis, the Troublemaker`
- `Knuckles the Echidna`
- `Rionya, Fire Dancer`
- `Springheart Nantuko`
- `Tataru Taru`
- `Magda, Brazen Outlaw`
- `Flash Photography`
- `Astral Dragon`
- `Clone Legion`
- `Hazel's Brewmaster`
- `Patrol Signaler`
- `The Jolly Balloon Man`
- `Treasure Vault`
