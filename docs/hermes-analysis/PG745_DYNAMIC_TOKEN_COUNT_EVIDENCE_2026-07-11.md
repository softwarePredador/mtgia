# PG745 Dynamic Token Count Evidence - 2026-07-11

Status: `closed`

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG745 promotes seven XMage-authoritative dynamic token-count rules:

- `Evangel of Heliod` - ETB tokens equal to devotion to white.
- `Fresh Meat` - Beast tokens equal to creatures you control that died this turn.
- `Hallowed Spiritkeeper` - dies tokens equal to creature cards in controller graveyard.
- `Revenge of the Rats` - tapped Rat tokens equal to creature cards in controller graveyard.
- `Reverent Hoplite` - ETB tokens equal to devotion to white.
- `Spider Spawning` - Spider tokens equal to creature cards in controller graveyard.
- `Underworld Hermit` - ETB tokens equal to devotion to black.

## Implementation

- `xmage_authoritative_exact_scope_split.py` now recognizes safe dynamic
  `CreateTokenEffect` counts from devotion, creature cards in controller
  graveyard, and creatures that died this turn.
- `battle_analyst_v9.py` now resolves these dynamic token counts for spell,
  ETB, and dies token-maker paths.
- `battle_package_end_to_end_validation.py` now builds focused dynamic token
  states for package E2E: devotion support permanents, graveyard creature
  fixtures, and died-this-turn counters.
- `xmage_batch_pg_package_builder.py` now carries prefixed dynamic count fields
  into E2E scenarios so generated manifests do not hide dynamic sources.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_package_rollback.sql`

Postcheck rerun result:

- `7/7` promoted rule rows.
- `7/7` promoted rows are `verified` + `auto`.
- `7/7` promoted rows have `oracle_hash`.
- `0` backup/shadow rows.

## Sync And E2E

Sync reports:

- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_sync_battle_rules_report.json`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_sync_pg_card_metadata_report.json`

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_e2e_after_full_sync_report.json`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_e2e_after_full_sync_report.md`

E2E status: `pass`.

Validated stages:

- PostgreSQL source of truth: `7` rows.
- SQLite/Hermes cache: `7` rows.
- Canonical snapshot fallback: `7` cards.
- Runtime `get_card_effect`: `7` cards.
- Battle execution: `7` scenarios, `11` replay events.

Battle execution proved dynamic count `3` for each promoted scenario, including
devotion, died-this-turn, and graveyard-count fixtures.

## Tests

Commands passed:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts \
python3 -m unittest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
```

Result: `1476` tests passed.

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts \
python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py
```

Result: `291` tests passed.

## Global Counters After PG745

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg745_dynamic_token_count_new_server.json`
- `battle_and_oracle_ready=6417`
- `snapshot_has_verified_rule=6442`
- `battle_family_mapper_required=27459`
- `generic_runtime_or_no_card_rule=359`
- `commander_illegal_block=2997`

XMage queue report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg745_dynamic_token_count_commander_legal.json`
- `target_identity_count=24536`
- `xmage_authoritative_adapter_required_count=24223`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
## Alignment Audits

All passed:

- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_xmage_strategy_consistency_audit.md`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_operational_surface_alignment_audit.md`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_pg_hermes_sqlite_contract_audit.md`
- `docs/hermes-analysis/master_optimizer_reports/pg745_dynamic_token_count_legacy_contamination_audit.md`

## Residual

The global goal remains active. After PG745, the next executable work should
start from:

- `xmage_authoritative_adapter_required_count=24223`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
