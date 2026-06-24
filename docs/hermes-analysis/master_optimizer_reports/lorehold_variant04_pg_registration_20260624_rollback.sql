\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 04.
DELETE FROM deck_cards WHERE deck_id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid;
DELETE FROM decks WHERE id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant04_20260624_ba7d06f86f23';
COMMIT;
