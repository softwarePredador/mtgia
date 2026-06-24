\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 08.
DELETE FROM deck_cards WHERE deck_id = '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid;
DELETE FROM decks WHERE id = '6df74eb3-c4a7-5398-bcf5-febb38d80d7a'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant08_20260624_1a76c69c236f';
COMMIT;
