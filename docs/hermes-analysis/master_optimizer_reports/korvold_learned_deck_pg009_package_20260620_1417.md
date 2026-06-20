# PG009 - Korvold Learned Deck Replacement

## Scope

Replace the active partial Korvold learned deck row with an accepted PostgreSQL
Commander reference corpus row.

This package does not touch user decks or `deck_cards`.

## Problem

Live read-only evidence showed:

- active row: `commander_learned_decks.source_system=edhrec`,
  `source_ref=learned_deck:7`;
- commander: `Korvold, Fae-Cursed King`;
- `card_count=90`;
- parsed quantity `90`;
- commander quantity in `card_list` `0`;
- card identity for `Korvold, Fae-Cursed King` exists and is legal in
  `card_intelligence_snapshot` / `card_identity_bridge`.

Therefore this is not an identity-resolution failure. The active learned deck
row is incomplete.

## Replacement Source

The replacement source is:

- table: `commander_reference_decks` plus `commander_reference_deck_cards`;
- `source_deck_key=edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14`;
- `source_url=https://edhrec.com/average-decks/korvold-fae-cursed-king`;
- `accepted=true`;
- `main_quantity=99`;
- `commander_quantity=1`;
- `unresolved_count=0`;
- `off_color_count=0`;
- card-row quantity from `commander_reference_deck_cards` is `100`.
- canonical metadata counters are carried from the current
  `learned_deck_coherence_audit.py` derivation for the replacement card list:
  lands `34`, ramp `65`, draw `10`, removal `9`, tutor `5`, engine `18`,
  wincon `4`, protection `3`, recursion `6`, board wipe `1`.

## Files

- `korvold_learned_deck_pg009_precheck_20260620_1417.sql`
- `korvold_learned_deck_pg009_apply_20260620_1417.sql`
- `korvold_learned_deck_pg009_rollback_20260620_1417.sql`
- `korvold_learned_deck_pg009_postcheck_20260620_1417.sql`

## Apply Policy

Run precheck first. Apply only if the old partial active count is `1` and the
replacement source validates to `100` total cards, commander quantity `1`,
unresolved `0`, and off-color `0`.

After apply, run postcheck and `server/bin/learned_deck_coherence_audit.py`.
