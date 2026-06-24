# PG141 Apply Evidence

Generated at: `2026-06-24T04:00:00Z`

Applied package:

- `PG141`
- cards: `Flash Photography`, `Astral Dragon`, `Clone Legion`
- families: `copy_creature_token=2`, `creature=1`

## PostgreSQL

Oracle-hash-matched target rows:

- `Flash Photography`: `target_card_rows=1`
- `Astral Dragon`: `target_card_rows=1`
- `Clone Legion`: `target_card_rows=1`

Apply result:

- `Flash Photography` promoted as `battle_rule_v1:e5ea20bd49a563c1256183af42e86c71`
- `Astral Dragon` promoted as `battle_rule_v1:7f8364137188a184510b1cfc4ebeac33`
- `Clone Legion` promoted as `battle_rule_v1:391956936dfadf0b7bd0f0123226279f`
- prior shadow rows deprecated/disabled: `0`

Postcheck confirmed promoted rows:

- `Flash Photography`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Astral Dragon`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Clone Legion`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Backup table:

- `manaloom_deploy_audit.pg141_current_replay_copy_token_trio_20260624_035857`
- `backup_rows=0`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Flash Photography' --only-card 'Astral Dragon' --only-card 'Clone Legion'`

Observed sync result:

- `selected_card_count=3`
- `sqlite_inserted_or_updated=3`
- `pg_rows_loaded=3`
- `canonical_snapshot_rows_exported=3215`

## Validation

Validated after PG -> SQLite sync:

- `test_xmage_to_manaloom_effect_hints.py`: `69` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `64` pass
- `test_reviewed_battle_card_rules.py`: `29` pass
- `test_battle_analyst_v10_3.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_040104`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- remaining gate signal: `event_contract_static_status=review_required`
- replay final status: `blocked`
- replay final reason: `one_or_more_mandatory_gates_blocked`

## Residual After PG141

Pipeline artifacts:

- postsync: `xmage_current_replay_batch_pipeline_20260624_pg141_postsync_real_v1_manifest.json`
- postaudit: `xmage_current_replay_batch_pipeline_20260624_pg141_postaudit_real_v1_manifest.json`

Residual summary after the fresh audit:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=237`
- `runtime_family_implementation_required=12`
- `split_family_scope_review_required=1`

Delta versus pre-PG141 residual:

- runtime family queue reduced from `15` to `12`
- `Flash Photography`, `Astral Dragon`, and `Clone Legion` left the residual queue

Remaining runtime-family cards:

- `Insidious Roots`
- `Eldrazi Confluence`
- `Jaxis, the Troublemaker`
- `Knuckles the Echidna`
- `Rionya, Fire Dancer`
- `Springheart Nantuko`
- `Tataru Taru`
- `Magda, Brazen Outlaw`
- `Hazel's Brewmaster`
- `Patrol Signaler`
- `The Jolly Balloon Man`
- `Treasure Vault`
