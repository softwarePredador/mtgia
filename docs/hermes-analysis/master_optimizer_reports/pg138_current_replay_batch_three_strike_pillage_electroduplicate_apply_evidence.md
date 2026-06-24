# PG138 Apply Evidence

Generated at: `2026-06-24T02:50:00Z`

Applied package:

- `PG138`
- cards: `Electroduplicate`, `Pirate's Pillage`, `Strike It Rich`
- families: `copy_creature_token=1`, `treasure_maker=2`

## PostgreSQL

Precheck confirmed Oracle-hash-matched `cards` rows for all three targets:

- `Electroduplicate`: `target_card_rows=1`, `existing_rule_rows=3`, `would_deprecate_shadow_rows=3`
- `Pirate's Pillage`: `target_card_rows=1`, `existing_rule_rows=3`, `would_deprecate_shadow_rows=3`
- `Strike It Rich`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`

Apply executed successfully.

Postcheck confirmed promoted rows:

- `Electroduplicate`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Pirate's Pillage`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Strike It Rich`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Backup table:

- `manaloom_deploy_audit.pg138_current_replay_batch_three_strike_pillage_electrod`
- `backup_rows=8`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Electroduplicate' --only-card "Pirate's Pillage" --only-card 'Strike It Rich'`

Observed sync result:

- `selected_card_count=3`
- `sqlite_inserted_or_updated=8`
- `pg_rows_loaded=11`
- `canonical_snapshot_rows_exported=3211`

## Validation

Validated after PG -> SQLite sync:

- `test_xmage_to_manaloom_effect_hints.py`: `62` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `58` pass
- `test_battle_analyst_v10_3.py`: pass

Real audit rerun:

- artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_023703`
- `latest` now points to this artifact
- `test_results_status_counts={"pass": 18}`
- gate divergences remained:
  - `event_contract_static=review_required`
  - `forensic_audit=blocked`

## Residual After PG138

Pipeline artifact:

- `xmage_current_replay_batch_pipeline_20260624_pg138_postsync_real_v6_manifest.json`

Residual summary:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=237`
- `runtime_family_implementation_required=18`
- `split_family_scope_review_required=1`
- `batch_pg_candidate_after_precheck=0`

Separated residual lists:

- `blocked_missing_xmage_source`:
  - `Bartolomé del Presidio`
  - `Mountain`
  - `Plains`
- `split_family_scope_review_required`:
  - `Kindle the Inner Flame`
- `runtime_family_implementation_required`:
  - `Astral Dragon`
  - `Clone Legion`
  - `Eldrazi Confluence`
  - `Flash Photography`
  - `Hazel's Brewmaster`
  - `Impulsive Pilferer`
  - `Insidious Roots`
  - `Jaxis, the Troublemaker`
  - `Knuckles the Echidna`
  - `Lotho, Corrupt Shirriff`
  - `Magda, Brazen Outlaw`
  - `Patrol Signaler`
  - `Prized Statue`
  - `Rionya, Fire Dancer`
  - `Springheart Nantuko`
  - `Tataru Taru`
  - `The Jolly Balloon Man`
  - `Treasure Vault`
