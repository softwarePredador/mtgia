\pset pager off
BEGIN;
-- Rollback for Sauron Variant 01 manual registration.
DELETE FROM deck_cards WHERE deck_id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid;
DELETE FROM decks WHERE id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid;
DELETE FROM commander_learned_decks
WHERE id = '28600f83-7925-5ce8-99ed-833d7c00febc'::uuid
  AND source_system = 'manual_user_deck_registration'
  AND source_ref = 'sauron_variant01_20260624_6aa4f012e11d';
COMMIT;
