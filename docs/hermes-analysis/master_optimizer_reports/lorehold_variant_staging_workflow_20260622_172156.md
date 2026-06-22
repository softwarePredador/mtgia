# Lorehold Variant Staging Workflow - 2026-06-22 17:21 UTC

## Purpose

Prepare ManaLoom to receive a full list of Lorehold deck variants, register
each variant locally, validate every card against the local PostgreSQL-synced
oracle cache, and then materialize one valid variant at a time for battle
testing.

This workflow is local Hermes staging only. It does not write PostgreSQL and it
does not promote a deck to production.

## New Tool

- Script:
  `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py`
- Test:
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_stager.py`

The tool creates local SQLite staging tables when run:

- `lorehold_variant_decks`
- `lorehold_variant_deck_cards`
- `lorehold_variant_target_backups`

## Input Format

One file can contain many decks:

```text
=== Lorehold Variant A ===
Source: manual
Archetype: anti-combat
Commander
1 Lorehold, the Historian
1 Sol Ring
1 Approach of the Second Sun
...

=== Lorehold Variant B ===
Source: manual
Archetype: faster-approach
1 Sol Ring
1 Approach of the Second Sun
...
```

The commander can be present or omitted. If omitted, validation treats the deck
as 99 main cards plus `Lorehold, the Historian`.

## Validation Rules

Each variant is checked for:

- Total Commander quantity: `100`.
- Main deck quantity: `99`.
- Commander quantity in list: `0` or `1`.
- Oracle cache match in `card_oracle_cache`.
- Canonical oracle name normalization, including front-face aliases for modal
  double-faced cards when present in the cache.
- Color identity subset of Lorehold color identity: `R/W`.
- Commander singleton rule, except basic lands.
- Basic land duplicate exception through oracle `type_line`.
- Battle rule presence count and verified/executable battle rule count.
- Functional tag inference from existing `deck_cards`, `battle_card_rules`, or
  oracle text fallback.

Validation does not prove a card is strategically correct. It only proves the
variant is structurally safe enough to enter the battle test queue.

## Commands

Dry-run validation:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py /path/to/lorehold_variants.txt --fail-on-invalid
```

Register valid/invalid variants into local staging tables:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py /path/to/lorehold_variants.txt --apply --fail-on-invalid
```

Materialize one valid variant into a temporary battle deck id:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py /path/to/lorehold_variants.txt --apply --materialize "Lorehold Variant A" --target-deck-id 606 --fail-on-invalid
```

Materialize one valid variant into the standard battle deck id `6` for a
controlled battle run:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py /path/to/lorehold_variants.txt --apply --materialize "Lorehold Variant A" --target-deck-id 6 --fail-on-invalid
```

Every materialization creates a backup id. Restore with:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py --restore-backup <backup_id>
```

## Smoke Evidence

Commands run:

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_stager.py
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_stager.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py <(sqlite3 docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db "SELECT quantity || ' ' || card_name FROM deck_cards WHERE deck_id=6 ORDER BY is_commander DESC, card_name;") --name "PG026 current deck smoke" --source sqlite-deck-6 --fail-on-invalid
```

Results:

- `py_compile`: pass.
- Unit tests: `3` tests pass.
- Current PG026 deck smoke: `variants=1 valid=1 invalid=0`.
- Smoke reports:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_172156.json`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_172156.md`

## Next Step

When Rafael provides the full deck-by-deck Lorehold list:

1. Save or parse the pasted list as one input batch.
2. Run dry-run validation with `--fail-on-invalid`.
3. Fix missing oracle/name/quantity/color issues before battle.
4. Register with `--apply`.
5. Materialize one variant at a time into deck id `6` for comparable battle
   windows.
6. Rank variants only from trusted battle artifacts, not from validation alone.
