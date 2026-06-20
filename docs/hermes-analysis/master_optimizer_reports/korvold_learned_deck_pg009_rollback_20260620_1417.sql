-- PG009 rollback: restore the previous partial EDHREC learned_deck:7 active
-- state and deactivate the PG009 replacement row.

BEGIN;

UPDATE commander_learned_decks
SET is_active = FALSE,
    updated_at = NOW()
WHERE source_system = 'commander_reference_decks'
  AND source_ref =
    'edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14'
  AND commander_name = 'Korvold, Fae-Cursed King'
  AND is_active = TRUE;

UPDATE commander_learned_decks
SET is_active = TRUE,
    updated_at = NOW()
WHERE source_system = 'edhrec'
  AND source_ref = 'learned_deck:7'
  AND commander_name = 'Korvold, Fae-Cursed King';

COMMIT;
