# PG501 Token Basic Landwalk New Server Apply Evidence

Status: applied, synced, and validated.

Deploy id: `xmage_pg501_token_basic_landwalk_new_server`

Runtime family: `xmage_fixed_create_creature_tokens_spell_v1`

XMage signature: `CreateTokenEffect` with `GoblinScoutsToken`

Promoted card:

- `Goblin Scouts`

## Scope

PG501 closes the safe token subpattern where XMage creates fixed creature
tokens whose only token keyword addition is a basic landwalk keyword already
supported by the ManaLoom combat runtime.

Promoted effect payload:

- `token_count=3`
- `token_name=Goblin Scout Token`
- `token_power=1`
- `token_toughness=1`
- `token_colors=["R"]`
- `token_keywords=["mountainwalk"]`
- `token_landwalk=true`
- `token_landwalk_land_type="mountain"`
- `token_landwalk_land_types=["mountain"]`

Safety boundary:

- This package covers basic landwalk token metadata only.
- `changeling`, `defender`, `shroud`, conditional token text, dynamic token
  counts, copied text, custom ability text, and token classes with unsupported
  ability semantics remain blocked for separate exact runtime families.
- This package does not promote broad `xmage_*_review_v1` rows or token
  planning artifacts.

## Parser And Runtime Changes

- `xmage_authoritative_exact_scope_split.py` now recognizes
  `ForestwalkAbility`, `IslandwalkAbility`, `MountainwalkAbility`,
  `PlainswalkAbility`, and `SwampwalkAbility` on fixed token classes.
- The splitter emits `token_landwalk`, `token_landwalk_land_type`, and
  `token_landwalk_land_types` for fixed token maker effects.
- `battle_analyst_v9.py` carries landwalk metadata into created creature
  tokens and preserves it through generic spell, ETB, and dies token creation
  paths.
- The combat runtime uses existing `landwalk_land_types` unblockability logic;
  PG501 adds no shortcut that bypasses blocker legality checks.

## Evidence

Candidate split:

- File:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_pg501_token_basic_landwalk_candidate.json`
- `proposal_count=1`
- `safe_for_batch_pg_package_count=1`
- `considered_supported_work_unit_rows=7416`
- Selected card: `Goblin Scouts`
- Logical rule key:
  `battle_rule_v1:3ac463b68b0acd2aba49dae3bbb0eca9`

Package:

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_manifest.json`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_package.md`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_rollback.sql`

PostgreSQL execution:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_precheck.out`
  found 1 canonical `Goblin Scouts` target row, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, and `would_deprecate_shadow_rows=2`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_apply.out`
  reported `deprecated_shadow_rows=2`, `upserted_rows=1`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_postcheck.out`
  confirmed `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, and `backup_rows=2`.

Sync and validation:

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_pg_to_sqlite_sync.json`
  reported `pg_rows_loaded=8425`, `sqlite_inserted_or_updated=8189`, and
  `canonical_snapshot_rows_exported=5952`.
- SQLite validation:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_sqlite_validation.json`
  reported `status=pass`, `validated_card_count=1`, and `issue_count=0`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg501_token_basic_landwalk_new_server.md`
  reported `status=pass` with `51/51` checks passing.

Tests:

- Splitter tests:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_splitter_tests.out`
  ran `510` tests and passed.
- Full battle suite before sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_full_battle_suite.out`
  reported `628` `PASS` lines, including
  `test_pg501_token_landwalk_is_unblockable_against_matching_basic_land`.
- Full battle suite after sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg501_token_basic_landwalk_new_server_full_battle_suite_post_sync.out`
  reported `628` `PASS` lines, including
  `test_pg501_token_landwalk_is_unblockable_against_matching_basic_land`.

Post-sync queue:

- Queue file:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg501_token_basic_landwalk_new_server_commander_legal.json`
- `target_identity_count=26066`
- `xmage_authoritative_source_count=25752`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25752`
- `adapter_work_unit_count=11385`
- Token maker `CreateTokenEffect::no_ability_class::no_target_class` work unit:
  `35`
- `token_creation` Oracle family count: `3178`

Global readiness:

- File:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg501_token_basic_landwalk_new_server.json`
- `battle_and_oracle_ready=4884`
- `battle_family_mapper_required=28989`
- `generic_runtime_or_no_card_rule=360`
- `oracle_data_sync=4`
- `commander_legality_sync=3`
- `oracle_identity_rule_link_or_copy=2`

Final exact split recheck:

- File:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg501_token_basic_landwalk_new_server_final_recheck.json`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7415`

## Decision

PG501 is applied and should not be rebuilt. Continue from the rebuilt
post-PG501 queue and select the next exact XMage family/subpattern; do not
revisit generic token landwalk as a card-specific manual task.
