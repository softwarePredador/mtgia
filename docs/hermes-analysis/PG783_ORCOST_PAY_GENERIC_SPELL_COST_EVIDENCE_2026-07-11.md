# PG783 OrCost Pay Generic Spell Cost Evidence - 2026-07-11

## Scope

PG783 promotes the narrow XMage OrCost subpattern where a normal instant/sorcery
can choose a supported non-mana additional cost or pay a fixed generic amount
that exactly matches Oracle text.

Promoted cards:

- Annihilating Glare
- Deadly Precision
- Lash of the Balrog
- Lightning Axe
- Pumpkin Bombardment

PG783B is metadata-only cleanup discovered by the final contract audit:
55 older trusted executable curated rules were missing `oracle_hash` in
PostgreSQL and were backfilled from `cards.oracle_text`.

## PostgreSQL

- PG783 precheck: 5 target rows, 0 existing rule rows.
- PG783 apply: 5 upserted rows, 0 deprecated shadow rows.
- PG783 postcheck: 5 promoted verified/auto rows with oracle hashes.
- PG783B precheck: 55 trusted executable rows missing `oracle_hash`.
- PG783B apply/postcheck: 55 backup rows, 55 updated rows, 0 remaining missing
  trusted executable hashes.

## Hermes Sync

- Metadata sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg783_sync_pg_card_metadata_to_hermes_report.json`
- PG783 battle sync:
  `docs/hermes-analysis/master_optimizer_reports/pg783_sync_battle_card_rules_pg_report.json`
  loaded 5 PG rows and updated 5 SQLite rows.
- PG783B battle sync:
  `docs/hermes-analysis/master_optimizer_reports/pg783b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`
  loaded 10134 PG rows, updated 9912 SQLite rows, and exported 7524 canonical
  fallback snapshot rows.

## End-To-End Validation

`docs/hermes-analysis/master_optimizer_reports/pg783_orcost_pay_generic_spell_cost_new_server_e2e_validation.json`
passed all stages:

- PostgreSQL source of truth: 5 rows.
- SQLite Hermes cache: 5 rows.
- Canonical snapshot fallback: 5 cards.
- Runtime `get_card_effect`: 5 cards.
- Battle execution: 5 scenarios, 26 events.

Runtime evidence included:

- Annihilating Glare paid generic 4 and removed one legal creature/planeswalker
  target.
- Deadly Precision paid generic 4 and removed one legal creature target.
- Lash of the Balrog used sacrifice-creature additional cost and removed one
  legal creature target.
- Lightning Axe used discard-card additional cost and dealt 5 damage.
- Pumpkin Bombardment used discard-card additional cost and dealt 3 damage.

## Readiness After PG783B

`global_card_oracle_battle_readiness_20260711_post_pg783b_hash_backfill_new_server`
reported:

- total cards: 34331
- `battle_and_oracle_ready`: 6539
- `battle_family_mapper_required`: 27337
- `generic_runtime_or_no_card_rule`: 359
- `commander_illegal_block`: 2997
- `official_oracle_identity_unavailable`: 3
- `digital_non_commander_rule_exception`: 3
- `trusted_rule_oracle_hash_backfill`: 0

The official readiness classifier plus `card_function_tags` reports:

- `battle_and_oracle_ready`: 6539
- `battle_and_oracle_ready_with_function_tag`: 4994
- `function_tagged_distinct`: 25380

## Queue After PG783B

`xmage_authoritative_adaptation_queue_20260711_post_pg783b_hash_backfill_new_server`
reported:

- target identities: 24414
- XMage authoritative adapter required: 24101
- XMage missing source exception: 313
- parser gap: 0
- adapter work units: 11285

`xmage_authoritative_exact_scope_split_20260711_post_pg783b_hash_backfill_new_server`
reported:

- `safe_for_batch_pg_package_count`: 0
- `proposal_count`: 3
- remaining proposals are runtime-partial simple mana source rows with
  unmodeled auxiliary behavior.

## Test And Audit Gates

- Focused unittest suite: 1067 tests, OK, 3 skipped.
- `pg_hermes_sqlite_contract_audit_20260711_post_pg783b_hash_backfill_new_server_final`: pass, 51/51.
- `xmage_strategy_consistency_audit_20260711_post_pg783b_hash_backfill_new_server_final`: pass, 26/26.
- `operational_surface_alignment_audit_20260711_post_pg783b_hash_backfill_new_server_final`: pass.
- `legacy_contamination_audit_20260711_post_pg783b_hash_backfill_new_server_final`: pass.
- `./scripts/quality_gate.sh server-target`: pass.
