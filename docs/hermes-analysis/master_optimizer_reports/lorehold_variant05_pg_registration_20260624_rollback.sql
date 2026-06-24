\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 05.
DELETE FROM deck_cards WHERE deck_id = '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid;
DELETE FROM decks WHERE id = '8aa57962-3a3e-5351-89fd-e4651456a3bd'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant05_20260624_5154c88a8b0b';
COMMIT;
