# PG139 Apply Evidence

Generated at: `2026-06-24T03:08:20Z`

Applied package:

- `PG139`
- cards: `Lotho, Corrupt Shirriff`, `Prized Statue`
- families: `ramp_engine=1`, `ramp_permanent=1`

## PostgreSQL

Precheck confirmed Oracle-hash-matched `cards` rows for both targets:

- `Lotho, Corrupt Shirriff`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Prized Statue`: `target_card_rows=1`, `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`

Apply executed successfully.

Postcheck confirmed promoted rows:

- `Lotho, Corrupt Shirriff`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Prized Statue`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Backup table:

- `manaloom_deploy_audit.pg139_current_replay_batch_two_lotho_prized_statue_20260`
- `backup_rows=2`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Lotho, Corrupt Shirriff' --only-card 'Prized Statue'`

Observed sync result:

- `selected_card_count=2`
- `sqlite_inserted_or_updated=5`
- `pg_rows_loaded=4`
- `canonical_snapshot_rows_exported=3212`

## Validation

Validated after PG -> SQLite sync:

- `test_xmage_to_manaloom_effect_hints.py`: `64` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `60` pass
- `test_reviewed_battle_card_rules.py`: `29` pass
- `test_battle_analyst_v10_3.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_030759`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- gate divergences remained:
  - `event_contract_static=review_required`
  - `forensic_audit=blocked`

## Residual After PG139

Pipeline artifacts:

- same-artifact postsync: `xmage_current_replay_batch_pipeline_20260624_pg139_postsync_real_v9_manifest.json`
- post-audit rerun: `xmage_current_replay_batch_pipeline_20260624_pg139_postaudit_real_v10_manifest.json`

Residual summary after the fresh audit:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=237`
- `runtime_family_implementation_required=16`
- `split_family_scope_review_required=1`
- `batch_pg_candidate_after_precheck=0`

Delta versus pre-PG139 residual:

- runtime family queue reduced from `18` to `16`
- `Lotho, Corrupt Shirriff` and `Prized Statue` left the residual queue

Remaining runtime-family cards:

- `Astral Dragon`
- `Clone Legion`
- `Eldrazi Confluence`
- `Flash Photography`
- `Hazel's Brewmaster`
- `Impulsive Pilferer`
- `Insidious Roots`
- `Jaxis, the Troublemaker`
- `Knuckles the Echidna`
- `Magda, Brazen Outlaw`
- `Patrol Signaler`
- `Rionya, Fire Dancer`
- `Springheart Nantuko`
- `Tataru Taru`
- `The Jolly Balloon Man`
- `Treasure Vault`

Non-runtime residual separated:

- `blocked_missing_xmage_source`:
  - `Bartolomé del Presidio`
  - `Mountain`
  - `Plains`
- `split_family_scope_review_required`:
  - `Kindle the Inner Flame`
