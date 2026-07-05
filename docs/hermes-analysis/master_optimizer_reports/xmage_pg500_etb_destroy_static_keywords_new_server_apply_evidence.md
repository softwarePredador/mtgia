# PG500 ETB Destroy Static Keywords New Server Apply Evidence

Status: `applied_synced_validated`.

PG500 closed a narrow exact XMage -> ManaLoom subpattern for creature
enter-the-battlefield destroy effects where the only auxiliary abilities are
static self keywords such as flying, flash, reach, deathtouch, or lifelink.

## Scope

- Deploy id: `xmage_pg500_etb_destroy_static_keywords_new_server`.
- Runtime family: `xmage_creature_etb_destroy_target_v1`.
- XMage signature:
  `EntersBattlefieldTriggeredAbility + DestroyTargetEffect`.
- Candidate report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_pg500_etb_destroy_static_keywords_candidate.json`.
- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_package.md`.

Promoted cards:

- `Acid Web Spider`
- `Acidic Slime`
- `Aven Cloudchaser`
- `Cloudchaser Eagle`
- `Manticore`
- `Rooftop Assassin`
- `Stingblade Assassin`

## Runtime And Splitter Changes

- `is_creature_etb_destroy_unit` now accepts ETB destroy source rows with only
  static self keyword abilities besides `EntersBattlefieldTriggeredAbility`.
- ETB destroy Oracle parsing now ignores leading static keyword lines before the
  ETB sentence.
- `artifact_or_enchantment_or_land` is now a supported exact ETB destroy target
  only when XMage source contains artifact, enchantment, and land target
  predicates.
- PG500 proposals preserve self keywords in `effect_json.keywords` and boolean
  keyword fields so battle runtime can keep both the body and the triggered
  destroy behavior.
- Non-static auxiliary mechanics such as kicker, evoke, conditional/reflexive
  triggers, unsupported target filters, and non-simple destroy effects remain
  blocked.

## Validation

- Splitter unit tests:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_splitter_tests.out`
  ran `509` tests and passed.
- Battle runtime before sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_full_battle_suite.out`
  passed the focused ETB destroy coverage.
- Battle runtime after sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_full_battle_suite_post_sync.out`
  includes `PASS test_pg493_etb_destroy_respects_extended_target_constraints`.
- SQLite validation:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_sqlite_validation.json`
  reported `status=pass`, `validated_card_count=7`, and `issue_count=0`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg500_etb_destroy_static_keywords_new_server.md`
  passed `51/51` checks.

## PostgreSQL Apply Evidence

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_precheck.out`.
  All 7 target cards matched exactly one canonical card row. `Acidic Slime`
  had 2 older shadow/executable rows to deprecate; the other 6 target cards had
  no rows to deprecate.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_apply.out`
  reported `deprecated_shadow_rows=2`, `upserted_rows=7`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_postcheck.out`
  confirmed every promoted card with `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync And Queue Impact

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg500_etb_destroy_static_keywords_new_server_pg_to_sqlite_sync.json`
  reported `pg_rows_loaded=8424`, `sqlite_inserted_or_updated=8188`, and
  `canonical_snapshot_rows_exported=5952`.
- Post-sync Commander-legal queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg500_etb_destroy_static_keywords_new_server_commander_legal.json`
  reported `target_identity_count=26067`, `xmage_authoritative_source_count=25753`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=25753`.
- Post-sync global readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg500_etb_destroy_static_keywords_new_server.json`
  reported `battle_and_oracle_ready=4883` and
  `battle_family_mapper_required=28990`.
- Final exact splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg500_etb_destroy_static_keywords_new_server_final_recheck.json`
  reported `proposal_count=0` and `safe_for_batch_pg_package_count=0`.

## Residual Boundary

PG500 must not be expanded to all targeted destroy rows. The remaining
`targeted_destroy_variant_v1` queue still includes activated costs, unsupported
targets, composite effects, kicker/evoke-like auxiliary abilities, and
conditional/reflexive ETB destroy variants that need separate exact runtime
families.
