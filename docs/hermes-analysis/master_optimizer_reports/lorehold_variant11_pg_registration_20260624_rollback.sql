\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 11.
DELETE FROM deck_cards WHERE deck_id = '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid;
DELETE FROM decks WHERE id = '9df6ac2e-6620-5265-8008-1f57c8963d66'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant11_20260624_4f48eee5a34d';
COMMIT;
