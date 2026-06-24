# PG149 Apply Evidence

Generated at: `2026-06-24T06:58:00Z`

Applied package:

- `PG149`
- cards: `Springheart Nantuko`
- families: `creature=1`

## PostgreSQL

Precheck confirmed a single Oracle-hash target row and the expected shadow cleanup:

- `Springheart Nantuko`: `target_card_rows=1`
- `expected_rule_rows_before=0`
- `existing_rule_rows=2`
- `would_deprecate_shadow_rows=2`

Apply result:

- promoted rule: `battle_rule_v1:bdb24c77e6b6dff83b1cdd01dbe09ba6`
- promoted oracle hash: `e0fb2f2b4e774063b3f8f8ee12f180da`
- prior shadow rows deprecated/disabled: `2`

Postcheck confirmed:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- backup table: `manaloom_deploy_audit.pg149_springheart_nantuko_20260624_065629`
- `backup_rows=2`

## Hermes SQLite Sync

Command path:

- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card 'Springheart Nantuko'`

Observed sync result:

- `selected_card_count=1`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=3218`

SQLite/PG state after sync:

- promoted row `battle_rule_v1:bdb24c77e6b6dff83b1cdd01dbe09ba6` is `verified/auto`
- legacy rows `battle_rule_v1:a48e59b8a7ed03df606ba36d44936260` and `battle_rule_v1:bfdd79b429a180d44480fbd19fb83528` are `deprecated/disabled`

## Validation

Validated before apply:

- `test_xmage_to_manaloom_effect_hints.py`: `78` pass
- `test_xmage_semantic_family_batch_pipeline.py`: `78` pass
- `test_battle_analyst_v10_3.py`: pass

Runtime-focused coverage added:

- Springheart fallback landfall path creates the 1/1 Insect token
- Springheart paid landfall path copies the attached creature

## Residual After PG149

Presync pipeline:

- `batch_pg_candidate_after_precheck=1`
- `runtime_family_implementation_required=2`
- candidate promoted by this package: `Springheart Nantuko`

Postsync pipeline:

- `blocked_missing_xmage_source=3`
- `mapper_metadata_or_test_scenario_required=232`
- `runtime_family_implementation_required=2`

Residual runtime-family cards with local XMage source:

- `Insidious Roots`
- `Magda, Brazen Outlaw`

Blocked without local XMage source:

- `Bartolomé del Presidio`
- `Mountain`
- `Plains`

Delta versus pre-PG149 residual:

- `Springheart Nantuko` left the residual queue
- high-severity actionable cards reduced from `216` to `215`
- pass cards increased from `280` to `281`
