\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 09.
DELETE FROM deck_cards WHERE deck_id = 'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid;
DELETE FROM decks WHERE id = 'b51c8f24-fa8b-50ee-8200-d78fe9908ffa'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant09_20260624_9370b6170e00';
COMMIT;
