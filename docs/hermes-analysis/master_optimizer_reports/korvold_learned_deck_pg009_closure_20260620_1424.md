# Korvold Learned Deck PG009 Closure - 2026-06-20

## Scope

End-to-end correction for `Korvold, Fae-Cursed King` after
`learned_deck_coherence_audit_20260620_115918` reported:

- `commander_deck_quantity_mismatch`: actual `90`, expected `100`;
- `commander_quantity_mismatch`: actual `0`, expected `1`.

No user deck, saved `deck_cards`, or deck swap was applied.

## Root Cause

Read-only PostgreSQL inspection proved the active row was incomplete:

- table: `commander_learned_decks`;
- old source: `source_system=edhrec`, `source_ref=learned_deck:7`;
- row id: `01a1c848-04ef-4c48-b1eb-e69b8836a9cd`;
- `card_count=90`;
- parsed entries `90`;
- parsed quantity `90`;
- commander quantity in `card_list` `0`;
- no unresolved card names.

The card identity was not the problem. `card_intelligence_snapshot` and
`card_identity_bridge` both resolved `Korvold, Fae-Cursed King` with legal
Commander status.

## Replacement Source

The accepted replacement source was already in PostgreSQL:

- table: `commander_reference_decks` plus `commander_reference_deck_cards`;
- source ref:
  `edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14`;
- source URL: `https://edhrec.com/average-decks/korvold-fae-cursed-king`;
- accepted: `true`;
- main quantity: `99`;
- commander quantity: `1`;
- total card quantity from cards table: `100`;
- unresolved quantity: `0`;
- off-color quantity: `0`.

## Code Guard

Runtime loaders now reuse `validateCommanderLearnedDeckInput` through
`isCompleteCommanderLearnedDeckInput` before exposing an active learned deck.
Touched consumers:

- `server/lib/ai/commander_learned_deck_support.dart`;
- `server/routes/ai/commander-learning/index.dart`;
- `server/routes/ai/commander-reference/index.dart`;
- `server/bin/commander_generate_provenance_audit.dart`;
- `server/lib/ai/commander_learning_snapshot_support.dart`.

## PostgreSQL Apply

SQL package:

- `korvold_learned_deck_pg009_precheck_20260620_1417.sql`;
- `korvold_learned_deck_pg009_apply_20260620_1417.sql`;
- `korvold_learned_deck_pg009_rollback_20260620_1417.sql`;
- `korvold_learned_deck_pg009_postcheck_20260620_1417.sql`.

Precheck passed:

- old partial active count: `1`;
- replacement source deck count: `1`;
- source quantity: `100`;
- source commander quantity: `1`;
- source unresolved quantity: `0`;
- source off-color quantity: `0`;
- existing replacement source rows: `0`.

Apply:

- first apply: `UPDATE 1`, `INSERT 0 1`, `COMMIT`;
- idempotent metadata reapply: `UPDATE 0`, `INSERT 0 1`, `COMMIT`.

Postcheck passed:

- active Korvold count: `1`;
- active source system: `commander_reference_decks`;
- active source ref:
  `edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14`;
- active card count: `100`;
- parsed quantity: `100`;
- parsed commander quantity: `1`;
- old partial active count: `0`;
- old partial card count: `90`;
- canonical metadata includes lands `34`, ramp `65`, draw `10`, removal `9`,
  tutor `5`, engine `18`, wincon `4`, protection `3`.

## Validation

- `dart analyze lib/ai/commander_learned_deck_support.dart lib/ai/commander_learning_snapshot_support.dart routes/ai/commander-learning/index.dart routes/ai/commander-reference/index.dart bin/commander_generate_provenance_audit.dart test/commander_learned_deck_support_test.dart`:
  PASS.
- `dart test test/commander_learned_deck_support_test.dart -r expanded`:
  PASS, `21/21`.
- `python3 server/bin/learned_deck_coherence_audit.py --stdout` after PG009:
  PASS summary with `severity_counts={"medium":13}` and no high findings.
- Full artifact:
  `learned_deck_coherence_audit_20260620_172437.json`.

Korvold in the fresh artifact:

- `card_count_declared=100`;
- `parsed_quantity=100`;
- `resolved_quantity=100`;
- commander deck shape `passes_shape=true`;
- `commander_quantity=1`;
- `issues=[]`.

## Remaining Work

This closes the Korvold high-priority learned-deck issue. The remaining learned
deck backlog is medium-only: land-count reviews and `some_core_metadata_zero`
reviews listed in the latest coherence artifact.
