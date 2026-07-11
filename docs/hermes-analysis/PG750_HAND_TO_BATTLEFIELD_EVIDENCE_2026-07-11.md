# PG750 Hand To Battlefield Evidence - 2026-07-11

Status: `applied_synced_validated`

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG750 promotes the exact XMage/ManaLoom scope
`xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1`.

Cards promoted:

- `Copper Gnomes`
- `Didgeridoo`
- `Dragon Arch`
- `Elvish Piper`
- `Firebrand Ranger`
- `Krosan Wayfarer`
- `Llanowar Scout`
- `Quicksilver Amulet`
- `Sakura-Tribe Scout`
- `Scaled Herbalist`
- `Thran Temporal Gateway`
- `Walking Atlas`

Supported target classes:

- artifact card;
- creature card;
- land card;
- basic land card;
- Minotaur permanent card;
- multicolored creature card;
- historic permanent card.

Runtime behavior:

- checks main-phase activation, mana cost, tap state, summoning sickness, and
  source sacrifice;
- selects the highest-value matching hand card;
- moves the selected card from hand to battlefield;
- triggers landfall for land entries;
- emits `activated_ability` replay evidence with
  `effect=put_from_hand_onto_battlefield`.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - added exact split support for
    `PutCardFromHandOntoBattlefieldEffect + SimpleActivatedAbility`;
  - blocks unsupported Oracle/source mismatches and unsupported activation
    costs.
- `battle_analyst_v9.py`
  - executes the activated hand-to-battlefield ability from promoted permanent
    rules;
  - scores valid hand candidates by target class and value.
- `xmage_batch_pg_package_builder.py`
  - carries `put_from_hand_target` in package manifests;
  - emits focused E2E scenarios for this scope.
- `battle_package_end_to_end_validation.py`
  - validates real runtime execution for the new scenario type.

## PostgreSQL Evidence

PG750 postcheck:

- promoted rule rows: `12/12`
- promoted verified/auto rows: `12/12`
- promoted Oracle hash rows: `12/12`
- backup rows: `0`

PG750B hash backfill:

- safe `auto/verified` missing hash rows: `32`
- rows backfilled: `32`
- remaining `auto/verified` missing hash rows: `0`
- matching backup/hash rows: `32/32`

PG750C hash backfill:

- safe `auto/active` missing hash rows: `23`
- rows backfilled: `23`
- remaining `auto/active` missing hash rows: `0`
- matching backup/hash rows: `23/23`

## Sync Evidence

PG750 PG -> Hermes/SQLite:

- `pg_rows_loaded`: `6388`
- `sqlite_inserted_or_updated`: `6383`
- `canonical_snapshot_rows_exported`: `6337`

PG750C final metadata sync:

- `requested_unique_names`: `7293`
- `postgres_cards_matched`: `7476`
- `sqlite_cache_alias_rows`: `7398`
- `deck_cards_backfill.card_id_updates`: `107`
- `unresolved_count`: `1`

## Runtime And E2E Evidence

Focused tests:

- `1486` unittest cases passed for exact split/runtime coverage.
- `297` pytest cases passed for package builder and E2E validator coverage.
- `py_compile` passed for all touched Python modules/tests.

E2E report:

- `status`: `pass`
- `scenario_count`: `12`
- `event_count`: `12`
- every promoted card moved the expected matching hand card to battlefield,
  including source-sacrifice cases for `Copper Gnomes` and `Krosan Wayfarer`.

## Readiness Delta

Final all-card readiness after PG750C:

- `all_known_cards`: `34331`
- `snapshot_has_verified_rule`: `6462`
- `battle_and_oracle_ready`: `6437`
- `battle_family_mapper_required`: `27439`
- `trusted_rule_oracle_hash_backfill`: `0`

Compared with post-PG749:

- `snapshot_has_verified_rule`: `6450 -> 6462`
- `battle_and_oracle_ready`: `6425 -> 6437`
- `battle_family_mapper_required`: `27451 -> 27439`

## Queue After PG750C

Commander-legal adaptation queue:

- `target_identity_count`: `24516`
- `xmage_authoritative_source_count`: `24203`
- `xmage_missing_source_exception_count`: `313`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `24203`
- `adapter_work_unit_count`: `11291`

The post-PG750C exact split recheck produced
`safe_for_batch_pg_package_count=0`; only the known mana-source
`runtime_partial_requires_family_runtime` proposals remained.

## Alignment Gates

- `xmage_strategy_consistency_audit`: `pass` (`26/26`)
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass` (`51/51`)
- `quality_gate.sh server-target`: `pass`

## Key Artifacts

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg750_hand_to_battlefield_candidate.json`
- `docs/hermes-analysis/master_optimizer_reports/pg750_hand_to_battlefield_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg750_hand_to_battlefield_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg750c_active_hash_backfill_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg750c_active_hash_backfill_new_server_commander_legal.json`
