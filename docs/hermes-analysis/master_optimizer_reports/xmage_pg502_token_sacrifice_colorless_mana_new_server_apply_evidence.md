# PG502 Token Sacrifice Colorless Mana New Server Apply Evidence

Status: applied, synced, and validated.

Deploy id: `xmage_pg502_token_sacrifice_colorless_mana_new_server`

Runtime families:

- `xmage_creature_etb_create_tokens_v1`
- `xmage_fixed_create_creature_tokens_spell_v1`

XMage signature: fixed `CreateTokenEffect` creating `EldraziSpawnToken`,
whose token class has `SimpleManaAbility(Zone.BATTLEFIELD,
Mana.ColorlessMana(1), new SacrificeSourceCost())`.

Promoted cards:

- `Dread Drone`
- `Emrakul's Hatcher`
- `Kozilek's Predator`
- `Nest Invader`
- `Skittering Invasion`

## Scope

PG502 closes the exact token subpattern where local XMage creates fixed
colorless Eldrazi Spawn creature tokens with the activated mana ability
`Sacrifice this token/creature: Add {C}.`

Promoted effect payload fields include:

- `token_sacrifice_for_colorless_mana=true` or
  `etb_token_sacrifice_for_colorless_mana=true`
- `token_mana_activation_requires_sacrifice=true` or
  `etb_token_mana_activation_requires_sacrifice=true`
- `token_mana_activation_requires_tap=false` or
  `etb_token_mana_activation_requires_tap=false`
- `token_mana_produced=1` or `etb_token_mana_produced=1`
- `token_produces="C"` or `etb_token_produces="C"`
- `token_produced_mana_symbols=["C"]` or
  `etb_token_produced_mana_symbols=["C"]`

Safety boundary:

- This package accepts only fixed creature-token creation whose token class has
  the exact `SimpleManaAbility + Mana.ColorlessMana(1) + SacrificeSourceCost`
  source pattern and matching token description.
- Other `sacrifice` token text remains blocked unless an exact runtime adapter
  exists.
- Infect, prowess, toxic, banding, triggered token text, dynamic token counts,
  additional token fanout, and custom token text remain blocked for separate
  exact families.
- This package does not promote broad `xmage_*_review_v1` rows or token
  planning artifacts.

## Parser And Runtime Changes

- `xmage_authoritative_exact_scope_split.py` now recognizes the exact XMage
  colorless self-sacrifice mana token subpattern and emits structured token
  mana fields.
- The splitter still rejects unsupported token abilities and unsupported token
  text.
- `battle_analyst_v9.py` now carries token self-sacrifice mana metadata through
  generic spell token creation, ETB token creation, dies-token creation, and the
  generic token factory.
- Created tokens use the existing
  `xmage_self_sacrifice_mana_source_permanent_v1` contextual activation path.
  Tokens vanish instead of moving to graveyard when sacrificed.

## Evidence

Candidate split:

- File:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_pg502_token_sacrifice_colorless_mana_candidate.json`
- `proposal_count=5`
- `safe_for_batch_pg_package_count=5`
- `considered_supported_work_unit_rows=7415`
- Selected cards: `Dread Drone`, `Emrakul's Hatcher`,
  `Kozilek's Predator`, `Nest Invader`, `Skittering Invasion`

Package:

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_manifest.json`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_package.md`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_rollback.sql`

PostgreSQL execution:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_precheck.out`
  found one Oracle-hash-matched canonical row for every promoted card and found
  two stale `Skittering Invasion` rows to deprecate.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_apply.out`
  reported `deprecated_shadow_rows=2`, `upserted_rows=5`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_postcheck.out`
  confirmed every promoted card with `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.
- Field postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_effect_field_postcheck.out`
  confirmed `token_sac_mana=true`, `produces=C`, and
  `produced_symbols=["C"]` for all five promoted rules.

Sync and validation:

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_pg_to_sqlite_sync.json`
  reported `pg_rows_loaded=8430`, `sqlite_inserted_or_updated=8194`, and
  `canonical_snapshot_rows_exported=5956`.
- SQLite validation:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_sqlite_rule_check.out`
  confirmed all five promoted rows in SQLite with token sacrifice mana fields.
- Runtime lookup validation:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_runtime_get_card_effect.out`
  confirmed all five cards resolve from the curated runtime cache with the
  expected scope and token mana metadata.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg502_token_sacrifice_colorless_mana_new_server.md`
  reported `status=pass` with `51/51` checks passing.

Tests:

- Splitter tests:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py -q`
  passed `511` tests and `55` subtests.
- Focused battle runtime tests:
  `test_eldrazi_confluence_creates_three_scions_when_no_other_modes_are_live`
  and `test_xmage_token_sacrifice_colorless_mana_unlocks_contextual_cast`
  passed.
- Full battle suite after sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg502_token_sacrifice_colorless_mana_new_server_full_battle_suite_post_sync.out`
  reported `630` `PASS` lines, including
  `test_xmage_token_sacrifice_colorless_mana_unlocks_contextual_cast`.

Post-sync queue:

- Queue file:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg502_token_sacrifice_colorless_mana_new_server_commander_legal.json`
- `target_identity_count=26061`
- `xmage_authoritative_source_count=25747`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25747`
- `adapter_work_unit_count=11385`

Global readiness:

- File:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg502_token_sacrifice_colorless_mana_new_server.json`
- `battle_and_oracle_ready=4889`
- `battle_family_mapper_required=28984`
- `generic_runtime_or_no_card_rule=360`
- `oracle_data_sync=4`
- `commander_legality_sync=3`
- `oracle_identity_rule_link_or_copy=2`

Final exact split recheck:

- File:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg502_token_sacrifice_colorless_mana_new_server_final_recheck.json`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7410`

## Decision

PG502 is applied and should not be rebuilt. Continue from the rebuilt
post-PG502 queue and select the next exact XMage family/subpattern; do not
promote generic token sacrifice text unless it matches a runtime-backed exact
source signature.
