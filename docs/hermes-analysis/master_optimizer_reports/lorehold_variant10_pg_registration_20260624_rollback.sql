\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 10.
DELETE FROM deck_cards WHERE deck_id = '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid;
DELETE FROM decks WHERE id = '43c026ae-2d92-5049-90fc-1fdad4b04298'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant10_20260624_69fc2e8dfcb4';
COMMIT;
