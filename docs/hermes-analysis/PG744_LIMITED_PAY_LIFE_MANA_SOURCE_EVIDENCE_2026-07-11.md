# PG744 Limited Pay-Life Mana Source Evidence

Date: 2026-07-11

## Scope

PG744 promotes the exact XMage subpattern for limited-times activated mana
sources that pay life instead of generic mana. The concrete promoted card is
`Kozilek's Translator`.

The source was local XMage:

- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/k/KozileksTranslator.java`

Translated ManaLoom runtime scope:

- `xmage_simple_tap_mana_source_permanent_v1`
- family: `xmage_limited_times_fixed_mana_source_permanent`
- effect: `ramp_permanent`
- behavior: pay 1 life, add `{C}`, once each turn, no tap required

The rule is marked runtime-partial only because the auxiliary `DevoidAbility`
is not part of the executable mana behavior. The mana ability itself is the
exact modeled scope.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Accepts Oracle activation costs of the form `Pay N life`.
  - Parses XMage `PayLifeCost(N)` in `LimitedTimesPerTurnActivatedManaAbility`.
  - Preserves `activation_life_cost` in exact-scope comparison and effect JSON.
  - Splits limited-times mana families into fixed, color-choice, and any-color.
- `test_xmage_authoritative_exact_scope_split.py`
  - Changes the Kozilek pay-life case from blocked to selected exact scope.

## PostgreSQL Apply

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg744_limited_pay_life_mana_source_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744_limited_pay_life_mana_source_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744_limited_pay_life_mana_source_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744_limited_pay_life_mana_source_package_rollback.sql`

Precheck:

- target card rows: 1
- existing rule rows: 0
- expected rule rows before: 0
- shadow rows to deprecate: 0

Apply/postcheck:

- deprecated shadow rows: 0
- upserted rows: 1
- promoted rule rows: 1
- promoted verified auto rows: 1
- promoted oracle-hash rows: 1

## PG744B Hash Contract Repair

The first post-PG744 contract audit exposed older trusted executable rules
without `oracle_hash`. That was unrelated to Kozilek, but it would make the
current readiness count misleading, so PG744B backfilled the missing hashes
using the project convention `md5(cards.oracle_text)`.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg744b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg744b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Precheck/apply/postcheck:

- missing trusted executable oracle hashes: 55
- computable from PostgreSQL Oracle text: 55
- missing Oracle text: 0
- rows backfilled: 55
- postcheck missing trusted executable oracle hashes: 0
- backup rows: 55
- rows matching `md5(cards.oracle_text)`: 55

## Sync And Runtime Evidence

PostgreSQL -> SQLite/Hermes sync after PG744B:

- database: `127.0.0.1:15432/halder`
- PG rows loaded: 6361
- SQLite rows inserted or updated: 6356
- canonical snapshot rows exported: 6310

E2E after final sync:

- status: pass
- card: `Kozilek's Translator`
- scenario: `Kozilek's Translator refreshes modeled mana source`
- available mana: 1
- life paid: 1
- life after refresh: 39
- activation limit per turn: 1
- tapped: false
- stages passed: PostgreSQL source, SQLite cache, canonical snapshot fallback,
  runtime `get_card_effect`, battle execution

## Final Global Counts

Readiness after PG744B:

- all known cards: 34331
- snapshot has verified rule: 6435
- battle and Oracle ready: 6410
- battle family mapper required: 27466
- commander legal cards: 31334
- commander legal with verified rule and Oracle identity: 6342

Commander-legal XMage queue after PG744B:

- target identities: 24543
- XMage authoritative source available: 24230
- XMage missing-source exceptions: 313
- parser gaps: 0
- adapter required: 24230
- authoritative source coverage ratio: 0.9872

## Validation

Commands run:

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - 1469 tests passed
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  - pass
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
  - 288 tests passed
- `pg_hermes_sqlite_contract_audit.py`
  - pass, 51/51
- `legacy_contamination_audit.py`
  - pass
- `xmage_strategy_consistency_audit.py`
  - pass, 26/26
- `operational_surface_alignment_audit.py`
  - pass
- `battle_package_end_to_end_validation.py`
  - pass

## Residual

PG744 reduced the `limited_mana_source_cost_not_supported` blocker by one.
The remaining global queue is still adapter-family work, not parser discovery:
the post-PG744B Commander-legal queue reports zero parser gaps and 24230
XMage-backed identities still requiring runtime/mapper adapters.
