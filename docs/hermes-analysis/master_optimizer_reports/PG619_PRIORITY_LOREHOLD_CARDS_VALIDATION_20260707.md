# PG619 Priority Lorehold Cards Validation - 2026-07-07

Status: `applied_and_validated`
Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Follow-up Revalidation - 2026-07-07

Status: `superseded_by_full_priority_pass`

The original PG619 closure left `Hit the Mother Lode`, `Improvisation
Capstone`, and `Tibalt's Trickery` as active because their executors were not
fully proven at that point. The later focused priority audit revalidated the
entire requested set against PostgreSQL, Hermes SQLite, the canonical snapshot,
and focused runtime tests:

- `priority_lorehold_card_validation_audit_20260707_new_server`: `pass`,
  `24/24` target cards have PostgreSQL + SQLite + snapshot battle rules, and
  `9/9` requested functional-classification cards have the required tags.
- `test_priority_lorehold_card_runtime.py`: `12/12 OK`, including runtime
  coverage for `Hit the Mother Lode`, `Improvisation Capstone`, and
  `Tibalt's Trickery`.
- `test_reviewed_battle_card_rules.py`: `32/32 OK`.
- `xmage_strategy_consistency_audit_20260707_priority_lorehold_cards_new_server`:
  `26/26 pass`.
- `pg_hermes_sqlite_contract_audit_20260707_priority_lorehold_cards_new_server`:
  `51/51 pass`.

Current interpretation: the "remaining runtime families" section below is kept
as historical context only. It no longer describes the current state of these
three cards.

## Scope

Priority cards requested:

- Full battle verification candidates: Lorehold, the Historian; Farewell; Fellwar Stone; Flawless Maneuver; Hit the Mother Lode; Improvisation Capstone; Land Tax; Library of Leng; Scroll Rack; Swords to Plowshares; Talisman of Conviction; Teferi's Protection; Tibalt's Trickery.
- Adapter/check candidates: Command Tower; Sol Ring; Thor, God of Thunder.
- Functional classification gaps: Furygale Flocking; Molecule Man; Pearl Medallion; Prismari Pianist; Redirect Lightning; The Mind Stone; The Scarlet Witch; Thor, God of Thunder; Turbulent Steppe.

## Runtime Changes

- Added `modal_exile_board_wipe` runtime handling for board wipes with `exile_modes`.
- `Farewell` now exiles battlefield artifacts, creatures, enchantments, and graveyards instead of falling through to destructive creature-wipe behavior.
- Added pain-mana metadata to explicit conditional mana modes so `Talisman of Conviction` exposes colorless modes with no life loss and red/white modes with `life_loss_on_spend=1`.

## PostgreSQL Apply

Applied:

- `pg619_priority_lorehold_cards_20260707_package.sql`
  - dry-run rollback: `UPDATE 10`, `INSERT 1`, `INSERT 27`, `INSERT 9`
  - real apply: `UPDATE 10`, `INSERT 1`, `INSERT 27`, `INSERT 9`
- `pg619_trusted_rule_oracle_hash_backfill_20260707.sql`
  - dry-run rollback: `UPDATE 40`
  - real apply: `UPDATE 40`

Postcheck over the 24 requested cards:

- Before: `verified=10`, `function_classified=15`, `semantic_v2=15`
- After: `verified=21`, `function_classified=24`, `semantic_v2=24`
- Final PG postcheck by canonical name: `summary|24|verified=21|function=24|semantic_v2=24`

Newly verified battle rows:

- Farewell
- Fellwar Stone
- Flawless Maneuver
- Land Tax
- Library of Leng
- Lorehold, the Historian
- Scroll Rack
- Swords to Plowshares
- Talisman of Conviction
- Teferi's Protection
- Thor, God of Thunder

Already verified before this package:

- Command Tower
- Sol Ring
- Furygale Flocking
- Molecule Man
- Pearl Medallion
- Prismari Pianist
- Redirect Lightning
- The Mind Stone
- The Scarlet Witch
- Turbulent Steppe

## Remaining Runtime Families

Kept as `active`, not promoted to `verified`:

- Hit the Mother Lode: requires real `discover 10` executor plus treasure-difference resolution.
- Improvisation Capstone: requires real exile-until-total-mana-value/free-cast/Paradigm executor.
- Tibalt's Trickery: requires real counter + random mill/free replacement spell executor.

These were intentionally not marked complete because the current runtime has no explicit executor for `discover_value`, `exile_until_total_mana_value_at_least`, or `random_mill_then_free_replacement_spell`.

## Hermes Sync

Synced:

- `pg619_priority_lorehold_cards_20260707_pg_to_sqlite_sync.json`
- `pg619_priority_lorehold_cards_20260707_metadata_sync.json`
- `pg619_priority_lorehold_cards_20260707_pg_to_sqlite_sync_after_hash_backfill.json`

SQLite spot-check:

- Verified rows present for Farewell, Fellwar Stone, Flawless Maneuver, Land Tax, Library of Leng, Lorehold, Scroll Rack, Swords, Talisman, Teferi, Thor.
- Hit the Mother Lode, Improvisation Capstone, and Tibalt's Trickery remain `active`.

## Validation

Passed:

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_priority_lorehold_card_runtime.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
- `xmage_strategy_consistency_audit_20260707_pg619_priority_lorehold_cards_final`: `pass`, 26/26
- `operational_surface_alignment_audit_20260707_pg619_priority_lorehold_cards_final`: `pass`
- `pg_hermes_sqlite_contract_audit_20260707_pg619_priority_lorehold_cards_final`: `pass`, 51/51
