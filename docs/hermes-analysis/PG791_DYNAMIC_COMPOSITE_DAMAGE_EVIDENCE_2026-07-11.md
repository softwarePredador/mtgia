# PG791 Dynamic Composite Damage Evidence - 2026-07-11

## Scope

PG791 promoted the safe `xmage_dynamic_count_damage_spell_v1` subfamily where
XMage damage is determined by a composite battlefield permanent count.

Promoted cards:

- Focus Fire
- Hobbit's Sting
- Road Rage
- Slash of Light

Runtime fields added or validated:

- `damage_amount_source = composite_battlefield_permanent_count`
- `battlefield_count_composite_mode = sum | union`
- `battlefield_count_components`

PG791B then backfilled `oracle_hash` for old trusted executable rules that were
already trusted but failed the current PostgreSQL/Hermes/SQLite contract audit.

## PostgreSQL Apply Evidence

PG791 package:

- Precheck: 4 target card rows, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 4 rows upserted.
- Postcheck: each promoted card has 1 trusted auto-verified rule with
  `oracle_hash`.

PG791B hash backfill:

- Precheck: 55 trusted executable rules missing `oracle_hash`; 55 matched card
  rows; 55 proposed hash rows.
- Apply: 55 backup rows, 55 updated rows.
- Postcheck: 0 trusted executable rules missing `oracle_hash`; 55 updated rows
  carry the current Oracle hash.

## Sync Evidence

Hermes SQLite/canonical snapshot refresh after PG791B:

- PostgreSQL rows loaded: 10194
- SQLite inserted or updated: 9972
- Canonical snapshot rows exported: 7582

Direct field parity checked for the 4 promoted cards across PostgreSQL and
SQLite:

- Focus Fire: `composite_battlefield_permanent_count`, `union`, 2 components
- Hobbit's Sting: `composite_battlefield_permanent_count`, `sum`, 2 components
- Road Rage: `composite_battlefield_permanent_count`, `union`, 2 components
- Slash of Light: `composite_battlefield_permanent_count`, `sum`, 2 components

## Validation Evidence

Focused tests:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
- Result: 1440 passed, 241 subtests passed in 9.07s

Package E2E:

- Status: pass
- PostgreSQL source of truth: 4 validated rows
- SQLite Hermes cache: 4 validated rows
- Canonical snapshot fallback: 4 validated cards
- Runtime `get_card_effect`: 4 validated cards
- Battle execution: 4 scenarios, 12 events

Battle execution expected damage:

- Focus Fire: 4
- Hobbit's Sting: 2
- Road Rage: 4
- Slash of Light: 2

Final audits:

- XMage strategy consistency: pass, 26 checks
- Operational surface alignment: pass, 48 checks
- Legacy contamination: pass, 32 checks
- PostgreSQL/Hermes/SQLite contract: pass, 51 checks
- `./scripts/quality_gate.sh server-target`: pass

## Readiness Delta

Latest global readiness:

- All known cards: 34331
- Battle and Oracle ready: 6588
- Battle family mapper required: 27277

Delta from the previous readiness checkpoint:

- Battle and Oracle ready: 6584 -> 6588
- Verified rule rows: 6620 -> 6624

Post-PG791B exact split recheck:

- Proposal count: 3
- Safe for batch PG package: 0
- Remaining exact split proposals are partial mana-source cases, not dynamic
  composite damage candidates.

The raw post-PG791B XMage queue JSON is intentionally not committed because it is
approximately 38 MB; the markdown summary and readiness/evidence artifacts are
kept instead.
