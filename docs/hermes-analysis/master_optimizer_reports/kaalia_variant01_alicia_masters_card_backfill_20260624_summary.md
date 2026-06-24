# Kaalia Variant 01 Alicia Masters Card Backfill

- Date: 2026-06-24
- Reason: `Kaalia Variant 01` could not be registered because
  `Alicia Masters, Skilled Sculptor` was absent from PostgreSQL `cards`.
- External source: Scryfall API `https://api.scryfall.com/cards/msc/48`
- Scryfall page:
  `https://scryfall.com/card/msc/48/alicia-masters-skilled-sculptor`
- Internal PostgreSQL card id: `2beb2cbd-d9d7-5b59-9c70-b72cc76c2b47`
- Scryfall id: `3db94749-340c-4454-a15d-ba6353e0c4a4`
- Oracle id: `223504ba-174a-46f2-a4a2-5d663a82dfd3`

## Source Data

- Raw Scryfall artifact:
  `kaalia_variant01_alicia_masters_scryfall_msc48_20260624.json`
- Manifest:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_manifest.json`
- Resolved fields:
  - `name=Alicia Masters, Skilled Sculptor`
  - `set_code=msc`
  - `collector_number=48`
  - `mana_cost={1}{R}`
  - `type_line=Legendary Creature — Human Artificer`
  - `cmc=2.0`

## PostgreSQL Evidence

- Precheck artifact:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_precheck.out`
  - `by_scryfall_id=0`
  - `by_name=0`
  - `by_oracle_id=0`
  - `legality_rows=0`
- Apply artifact:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_apply.out`
  - `INSERT 0 1` into `cards`
  - `INSERT 0 23` into `card_legalities`
  - `COMMIT`
- Postcheck artifact:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_postcheck.out`
  - one `cards` row found for Scryfall id
    `3db94749-340c-4454-a15d-ba6353e0c4a4`
  - `legality_rows=23`
  - `commander_legal_rows=1`
- Rollback SQL:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_rollback.sql`

## Scope

This was a single-card catalog backfill to unblock deck registration. It did
not add executable battle rules for Alicia Masters.
