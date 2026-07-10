# PG709 Mass Return To Hand Evidence - 2026-07-10

Status: closed and pushed-ready evidence summary.

Database target:

- PostgreSQL wrapper: `server/bin/with_new_server_pg.sh`
- Resolved target during apply/sync/E2E: `127.0.0.1:15432/halder`

## Runtime Scope

PG709 added executable ManaLoom support for the XMage family:

- XMage unit: `ReturnToHandFromBattlefieldAllEffect`
- ManaLoom effect: `mass_return_to_hand`
- Battle model scope: `xmage_return_all_matching_permanents_to_hand_spell_v1`

Runtime support was implemented in:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`

Focused tests were added/updated in:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`

## Promoted Cards

PG709 promoted 10 Commander-legal cards:

- `Aetherize`
- `Evacuation`
- `Filter Out`
- `Hibernation`
- `Inundate`
- `Part the Veil`
- `Reduce to Dreams`
- `Retract`
- `Sunder`
- `Whelming Wave`

Post-apply package checks confirmed 10 promoted rows with:

- `review_status = verified`
- `execution_status = auto`
- non-empty `oracle_hash`
- matching `xmage_return_all_matching_permanents_to_hand_spell_v1` scope

## PG709B Hash Backfill

The first PG/Hermes/SQLite contract audit after PG709 exposed missing
`oracle_hash` on older trusted executable rules. PG709B backfilled only safe
rows where the trusted executable rule had a matching `cards.oracle_text`.

Precheck:

- backfillable rule rows: `55`
- affected card ids: `54`
- affected normalized names: `55`
- unsafe missing-hash rows: `0`

Apply/postcheck:

- rows backfilled: `55`
- remaining trusted executable missing hash rows: `0`
- rows with expected `md5(cards.oracle_text)` hash: `55`

## Sync And E2E

PostgreSQL to Hermes/SQLite sync after PG709B:

- PG rows loaded: `6200`
- SQLite inserted/updated: `6195`
- canonical snapshot rows exported: `6151`

E2E package validation after PG709B:

- status: `pass`
- PostgreSQL source rows validated: `10`
- SQLite/Hermes rows validated: `10`
- canonical snapshot rows validated: `10`
- runtime card effects validated: `10`
- battle execution scenarios: `10`
- battle execution event count: `40`

Scenario return counts:

- `Aetherize`: `2/2`
- `Evacuation`: `2/2`
- `Filter Out`: `2/2`
- `Hibernation`: `2/2`
- `Inundate`: `2/2`
- `Part the Veil`: `1/1`
- `Reduce to Dreams`: `4/4`
- `Retract`: `1/1`
- `Sunder`: `2/2`
- `Whelming Wave`: `2/2`

## Current Global Counters

Readiness after PG709B:

- all known cards: `34331`
- `battle_and_oracle_ready`: `6249`
- `battle_family_mapper_required`: `27627`
- `trusted_rule_oracle_hash_backfill`: `0`
- `commander_illegal_block`: `2997`
- `generic_runtime_or_no_card_rule`: `359`
- `official_oracle_identity_unavailable`: `3`

Commander-legal XMage queue after PG709B:

- target identity count: `24704`
- XMage authoritative source count: `24391`
- XMage missing source exception count: `313`
- XMage authoritative parser gap count: `0`
- XMage authoritative adapter required count: `24391`
- manual semantic decision units remaining: `313`
- adapter work unit count: `11305`

Exact-scope splitter recheck:

- proposal count: `0`
- safe for batch PG package count: `0`
- supported work-unit rows considered: `7122`

## Audits And Tests

Validation commands completed:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  - result: `1146 passed, 206 subtests passed in 4.26s`
- `./scripts/quality_gate.sh server-target`
  - result: pass
- `xmage_strategy_consistency_audit.py`
  - result: `26/26 pass`
- `operational_surface_alignment_audit.py`
  - result: pass
- `legacy_contamination_audit.py`
  - result: pass
- `pg_hermes_sqlite_contract_audit.py`
  - result: `51/51 pass`

Raw local evidence artifacts were intentionally left under
`docs/hermes-analysis/master_optimizer_reports/`, which is ignored by git for
JSON/MD reports. The SQL package files are tracked with this change; raw
large queue/readiness JSON and Markdown reports are not pushed.
