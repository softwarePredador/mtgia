# PG672 Boost + Untap Target - New Server PostgreSQL Apply Evidence

Date: 2026-07-08

Database target: new EasyPanel PostgreSQL via `server/bin/with_new_server_pg.sh`

Package:

- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_manifest.json`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_apply.sql`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_precheck.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_postcheck.sql`

Promoted scope: `xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1`

Promoted cards:

- Fancy Footwork
- Gerrard's Command
- Hope and Glory
- Inspirit
- Join Forces
- Ornamental Courage
- Refuse to Yield
- Savage Surge
- Synchronized Strike
- Veteran's Reflexes

Blocked neighbors kept out of PG672:

- Alarum: filtered `TargetPermanent(filter)` / nonattacking target needs a separate exact target-constraint mapper.
- Boon of Boseiju: dynamic `+X/+X` boost needs dynamic greatest-mana-value support.
- Defiant Stand: Oracle shape is not this exact boost-and-untap pattern.

## Precheck

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_precheck.sql
```

Result:

- target card rows: 10/10
- expected rule rows before apply: 0/10
- active shadow rows to deprecate: 0

## Apply

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_apply.sql
```

Result:

- transaction committed
- upserted rows: 10
- deprecated shadow rows: 0

## Postcheck

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_package_postcheck.sql
```

Result:

- promoted rule rows: 10/10
- promoted verified/auto rows: 10/10
- promoted Oracle hash rows: 10/10
- backup rows: 0

## Sync And E2E

- Metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_metadata_sync.json`
- PG -> SQLite battle rule sync: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg672_boost_untap_target_new_server_e2e_validation.md`

E2E result:

- PostgreSQL source of truth: pass, 10/10 rows.
- SQLite/Hermes cache: pass, 10/10 rows.
- Canonical snapshot fallback: pass, 10/10 cards.
- `runtime_get_card_effect`: pass, 10/10 cards.
- Battle execution: pass, 10 scenarios, all expected targets buffed and untapped.

## Queue Impact

Before PG672, post-PG671 authoritative queue:

- `target_identity_count=24895`
- `xmage_authoritative_adapter_required_count=24582`
- `untap_target::xmage_targeted_untap_variant_review_v1=260`

After PG672:

- `target_identity_count=24885`
- `xmage_authoritative_adapter_required_count=24572`
- `untap_target::xmage_targeted_untap_variant_review_v1=250`
- `xmage_authoritative_parser_gap_count=0`

Readiness after PG672:

- `battle_and_oracle_ready=6068`
- `battle_family_mapper_required=27808`
- `snapshot_has_verified_rule=6096`
- `snapshot_has_any_rule=7298`

Exact-scope recheck after PG672:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

Final alignment gates:

- `xmage_strategy_consistency_audit`: pass, 26/26.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `pg_hermes_sqlite_contract_audit`: pass, 51/51.
