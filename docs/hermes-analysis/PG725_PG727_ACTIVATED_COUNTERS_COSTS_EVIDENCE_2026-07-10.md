# PG725-PG727 Activated Counters Costs Evidence - 2026-07-10

Status: `applied_new_server_and_validated`

Database target: `127.0.0.1:15432/halder` via `./server/bin/with_new_server_pg.sh`.

## Scope

This batch closed the currently package-safe activated counters residuals from
the XMage authoritative queue:

- PG725: target add-counters activated abilities with extra costs.
- PG726: activated destroy with Human sacrifice cost surfaced by the same split.
- PG727: self add-counters activated abilities with extra costs.

## PostgreSQL Packages Applied

| Deploy id | Cards | Precheck | Apply | Postcheck |
| --- | ---: | --- | --- | --- |
| `pg725_activated_add_counters_costs_new_server` | 5 | no existing expected rows | `upserted_rows=5` | 5 promoted verified rows with `oracle_hash` |
| `pg726_activated_destroy_human_sacrifice_new_server` | 1 | no existing expected rows | `upserted_rows=1` | 1 promoted verified row with `oracle_hash` |
| `pg727_activated_self_add_counters_costs_new_server` | 3 | no existing expected rows | `upserted_rows=3` | 3 promoted verified rows with `oracle_hash` |

Cards promoted:

- PG725: `Amok`, `Deranged Outcast`, `Fume Spitter`, `Myr Scrapling`, `Unspeakable Symbol`
- PG726: `Skirsdag Flayer`
- PG727: `Hungry Ghoul`, `Markov Dreadknight`, `Souldrinker`

## Runtime Coverage

Implemented/validated activated cost handling for counters:

- Target add-counters: source sacrifice, sacrifice target, discard, life payment, tap/mana cost.
- Self add-counters: sacrifice another permanent target, discard, life payment, tap/mana cost.
- Self source-sacrifice remains intentionally unsupported for self counters; the splitter keeps that blocked.

Focused E2E proved:

- `Fume Spitter` and `Myr Scrapling`: source sacrifice before target counter.
- `Amok`: discard cost before target counter.
- `Deranged Outcast`: Human sacrifice cost before target counters.
- `Unspeakable Symbol`: 3 life paid before target counter.
- `Skirsdag Flayer`: Human sacrifice cost before target destroy.
- `Hungry Ghoul`: sacrifice another creature before self counter.
- `Markov Dreadknight`: discard one card before two self counters.
- `Souldrinker`: pay 3 life before self counter.

## Sync And Readiness

Post-PG727 state:

- `snapshot_has_any_rule=7532`
- `snapshot_has_verified_rule=6356`
- `battle_and_oracle_ready=6331`
- `battle_family_mapper_required=27545`
- `xmage_authoritative_adapter_required_count=24309`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- post-PG727 exact splitter: `safe_for_batch_pg_package_count=0`

SQLite/Hermes sync:

- PG725 loaded 5 PG rows, exported canonical snapshot rows `7322`.
- PG726 loaded 1 PG row, exported canonical snapshot rows `7323`.
- PG727 loaded 3 PG rows, exported canonical snapshot rows `7326`.

## Commands Validated

- `python3 -m py_compile` for `battle_analyst_v9.py`, `battle_package_end_to_end_validation.py`, and `xmage_batch_pg_package_builder.py`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k 'simple_activated_add_counters'`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k 'simple_activated_add_counters'`
- PG725/PG726/PG727 precheck, apply, postcheck via `with_new_server_pg.sh`
- PG725/PG726/PG727 `sync_battle_card_rules_pg.py --apply-sqlite-from-pg`
- PG725/PG726/PG727 `sync_pg_card_metadata_to_hermes.py`
- PG725/PG726/PG727 `battle_package_end_to_end_validation.py`
- post-PG727 `xmage_strategy_consistency_audit.py`: pass, 26/26
- post-PG727 `operational_surface_alignment_audit.py`: pass
- post-PG727 `pg_hermes_sqlite_contract_audit.py`: pass, 51/51
- post-PG727 `legacy_contamination_audit.py`: pass
- `./scripts/quality_gate.sh server-target`: pass

## Next Queue

The currently exact, runtime-backed package-safe activated counters subqueue is
closed. The global goal remains active because the commander-legal XMage queue
still has `24309` XMage-authoritative adapter-required identities and `313`
missing-source exceptions.
