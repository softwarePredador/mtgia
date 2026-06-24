# PG150 Insidious Roots Apply Evidence

Status: `applied_postchecked_synced_validated`.

## Scope

- Card: `Insidious Roots`
- Family: `passive`
- Scope: `creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1`
- Logical rule key: `battle_rule_v1:5b1b7855a7ce144d00f051016c03a361`
- Oracle hash: `a21bec05e4d8f86d9179e3169c35f117`

## Precheck

- `target_card_rows=1`
- `existing_rule_rows=2`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=2`

## Apply

- SQL apply completed successfully against PostgreSQL target `143.198.230.247:5433/halder`.
- Backup table created: `manaloom_deploy_audit.pg150_insidious_roots_20260624_071922`

## Postcheck

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- `backup_rows=2`

## Hermes Sync

- Command path: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Insidious Roots'`
- `selected_card_count=1`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- Report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg150_insidious_roots_20260624.json`

## Validation

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py` -> `OK`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py` -> `OK`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` -> `OK`

## Post-sync Residual Queue

- `Magda, Brazen Outlaw` -> `runtime_family_implementation_required`
- `Bartolomé del Presidio` -> `blocked_missing_xmage_source`
- `Mountain` -> `blocked_missing_xmage_source`
- `Plains` -> `blocked_missing_xmage_source`

## Pipeline Artifacts

- Presync manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg150_presync_real_v1_manifest.json`
- Postsync manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg150_postsync_real_v1_manifest.json`
