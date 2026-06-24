\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 06.
DELETE FROM deck_cards WHERE deck_id = '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid;
DELETE FROM decks WHERE id = '0936dae3-32c4-5fb8-9c6f-d986670de794'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant06_20260624_a073b0fdc0db';
COMMIT;
